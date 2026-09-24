extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-semiconductor-fab.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE SEMICONDUCTOR FAB PROOF FAIL: " + message)
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

    var target := Vector2.ZERO
    for raw in scene.get("entities"):
        var entity: Dictionary = raw
        if String(entity.get("kind", "")) == "partner" and int(entity.get("partner_idx", -1)) == 3:
            target = Vector2(entity.get("pos", Vector2.ZERO))
            break
    if target == Vector2.ZERO:
        _fail("semiconductor partner not found")
        return

    scene.set("rep_pos", target + Vector2(0.0, 170.0))
    var camera = scene.get("camera")
    if camera != null and is_instance_valid(camera):
        camera.position = target
        camera.zoom = Vector2(1.35, 1.35)
    scene.queue_redraw()
    for _frame in range(8):
        await process_frame
    await create_timer(0.18).timeout

    var image := root.get_texture().get_image()
    var output_dir := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var output_file := ProjectSettings.globalize_path(OUTPUT_PATH)
    if image == null or image.is_empty() or image.save_png(output_file) != OK:
        _fail("could not save proof")
        return
    print("HASH RACE SEMICONDUCTOR FAB PROOF PASS: %s" % output_file)
    quit(0)
