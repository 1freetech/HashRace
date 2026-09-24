extends SceneTree

const OUTPUT := "res://../visual-proof/gameplay-clean-runtime.png"

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        push_error("GAMEPLAY PROOF FAIL: world scene missing")
        quit(1)
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _frame in range(12):
        await process_frame
    if not scene.has_method("debug_runtime_ready") or not scene.call("debug_runtime_ready"):
        push_error("GAMEPLAY PROOF FAIL: clean runtime validation failed")
        quit(1)
        return
    var image := root.get_texture().get_image()
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image == null or image.is_empty() or image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        push_error("GAMEPLAY PROOF FAIL: screenshot save failed")
        quit(1)
        return
    print("GAMEPLAY PROOF PASS")
    quit(0)
