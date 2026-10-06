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

    # Settle the exact live scene, then validate the current gameplay head rather
    # than the retired world.gd compatibility renderer.
    for _frame in range(12):
        await process_frame
    var live_script := scene.get_script() as Script
    if live_script == null or live_script.resource_path != "res://scripts/world_v165.gd":
        _fail("world_v165 is not the live gameplay head")
        return
    if not scene.has_method("debug_v165_runtime_ready") or not bool(scene.call("debug_v165_runtime_ready")):
        _fail("current v0.165 runtime validation failed")
        return
    var props := scene.get_node_or_null("ArchiveSpriteProps")
    if props == null or not props.has_method("debug_ready") or not bool(props.call("debug_ready")):
        _fail("promoted campus equipment layer is not live")
        return
    var survey := props.get_node_or_null("EquipmentSurvey")
    if survey == null or not survey.has_method("debug_ready") or not bool(survey.call("debug_ready")):
        _fail("equipment operations gameplay is not live")
        return

    scene.queue_redraw()
    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout

    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport image missing after proven capture cadence")
        return
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("screenshot save failed")
        return
    print("GAMEPLAY PROOF PASS: live world_v165 runtime + equipment operations layer; " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
