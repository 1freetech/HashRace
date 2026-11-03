extends SceneTree

# Test the real camera with its normal limits at all four map edges. The default
# gray canvas is not terrain; a large gray region inside the camera view means
# terrain culling has fallen behind the camera's actual limited screen position.
const OUTPUT_DIR := "res://../visual-proof/world-edges"
const EDGES := [
    {"name": "west", "pos": Vector2(72.0, 960.0)},
    {"name": "east", "pos": Vector2(2928.0, 960.0)},
    {"name": "north", "pos": Vector2(1500.0, 120.0)},
    {"name": "south", "pos": Vector2(1500.0, 1830.0)},
]

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("WORLD EDGE PROOF FAIL: " + message)
    quit(1)

func _capture() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live campaign missing")
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _frame in range(20):
        await process_frame
    var camera := scene.get("camera") as Camera2D
    if camera == null:
        _fail("camera missing")
        return
    var folder := ProjectSettings.globalize_path(OUTPUT_DIR)
    DirAccess.make_dir_recursive_absolute(folder)

    for edge in EDGES:
        scene.call("_clear_nav_path")
        scene.set("rep_pos", edge["pos"])
        for _frame in range(12):
            await process_frame
        await create_timer(0.2).timeout
        var image := root.get_texture().get_image()
        if image == null or image.is_empty():
            _fail("empty viewport at %s edge" % edge["name"])
            return
        if image.save_png(folder.path_join(String(edge["name"]) + ".png")) != OK:
            _fail("could not save %s edge screenshot" % edge["name"])
            return
        var gray := 0
        var sampled := 0
        for y in range(20, image.get_height() - 20, 24):
            for x in range(20, image.get_width() - 20, 24):
                var pixel := image.get_pixel(x, y)
                if absf(pixel.r - 0.3) < 0.01 and absf(pixel.g - 0.3) < 0.01 and absf(pixel.b - 0.3) < 0.01:
                    gray += 1
                sampled += 1
        var ratio := float(gray) / float(maxi(sampled, 1))
        if ratio > 0.03:
            _fail("%s edge contains %.1f%% canvas gray; screen center %s, camera node %s" % [edge["name"], ratio * 100.0, camera.get_screen_center_position(), camera.global_position])
            return
        print("WORLD EDGE %s PASS: %.2f%% gray, screen center %s, camera node %s" % [edge["name"], ratio * 100.0, camera.get_screen_center_position(), camera.global_position])
    print("WORLD EDGE PROOF PASS: terrain rendered at all four limited camera edges")
    quit(0)
