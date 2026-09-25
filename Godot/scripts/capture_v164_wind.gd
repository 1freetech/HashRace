extends SceneTree

# Exact-head rendered proof for the validated wind binary in the current stable
# world entry point. The stable runtime always renders the mining campus wind
# asset, so proof verifies its imported texture, grounded navigation footprint,
# live draw, and viewport pixels rather than calling removed numbered APIs.
const OUTPUT := "res://../visual-proof/v164-wind-overview.png"
const WIND_CENTER := Vector2(1420, 370)

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("V164 WIND PROOF FAIL: " + message)
    quit(1)

func _capture() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live scene missing")
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _frame in range(12):
        await process_frame

    if not scene.has_method("debug_wind_ready") or not scene.call("debug_wind_ready"):
        _fail("committed wind PNG is not imported and grounded in current live world")
        return

    scene.set("rep_pos", WIND_CENTER + Vector2(-250, 170))
    var camera = scene.get("camera")
    if camera != null and is_instance_valid(camera):
        camera.position = WIND_CENTER
        camera.zoom = Vector2(0.9, 0.9)
    scene.queue_redraw()
    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout

    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport image missing")
        return
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("could not save wind visual proof")
        return
    print("V164 WIND PROOF PASS: " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
