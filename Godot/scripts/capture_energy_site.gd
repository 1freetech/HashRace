extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-energy-site.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE ENERGY SITE PROOF FAIL: " + message)
    quit(1)

func _capture() -> void:
    set_meta("hashrace_company_idx", 0)
    set_meta("hashrace_campaign_years", 4)
    set_meta("hashrace_campaign_turns", 16)

    var packed: PackedScene = load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("world.tscn did not load")
        return
    var scene: Node = packed.instantiate()
    root.add_child(scene)

    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout

    var origin: Vector2 = scene.call("_energy_campus_origin")
    scene.set("rep_pos", origin)
    var camera = scene.get("camera")
    if camera != null and is_instance_valid(camera):
        camera.position = origin
        camera.zoom = Vector2(1.0, 1.0)
    scene.queue_redraw()

    for _frame in range(8):
        await process_frame
    await create_timer(0.18).timeout

    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport produced no image")
        return

    var output_dir := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var output_file := ProjectSettings.globalize_path(OUTPUT_PATH)
    if image.save_png(output_file) != OK:
        _fail("could not save screenshot")
        return

    print("HASH RACE ENERGY SITE PROOF PASS: %s" % output_file)
    quit(0)
