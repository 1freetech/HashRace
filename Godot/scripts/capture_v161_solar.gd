extends SceneTree

const OUTPUT := "res://../visual-proof/v161-solar-overview.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("V161 SOLAR PROOF FAIL: " + message)
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
    if not scene.has_method("infrastructure_ready") or not scene.call("infrastructure_ready", "solar"):
        _fail("actual imported solar Sprite2D/collision missing")
        return
    scene.process_mode = Node.PROCESS_MODE_DISABLED
    var bounds: Rect2 = scene.call("infrastructure_rect", "solar")
    var camera: Camera2D = scene.get("camera")
    camera.position_smoothing_enabled = false
    camera.position = bounds.get_center()
    camera.zoom = Vector2(1.25, 1.25)
    camera.force_update_scroll()
    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout
    var image := root.get_texture().get_image()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../visual-proof"))
    if image == null or image.is_empty() or image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("screenshot missing")
        return
    print("V161 SOLAR PROOF PASS: current permanent solar sprite; " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
