extends SceneTree

const OUTPUT := "res://../visual-proof/gameplay-clean-runtime.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("GAMEPLAY PROOF FAIL: " + message)
    quit(1)

func _capture() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("world scene missing")
        return
    var scene := packed.instantiate()
    root.add_child(scene)

    # Match the proven v0.164 wind capture path: allow _ready(), imported
    # Texture2D resources, camera state, and queued redraws to settle before
    # validating or reading viewport pixels.
    for _frame in range(12):
        await process_frame
    if not scene.has_method("debug_runtime_ready") or not scene.call("debug_runtime_ready"):
        _fail("clean runtime validation failed")
        return

    scene.queue_redraw()
    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout
    await RenderingServer.frame_post_draw

    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport image missing after frame_post_draw")
        return
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("screenshot save failed")
        return
    print("GAMEPLAY PROOF PASS: " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
