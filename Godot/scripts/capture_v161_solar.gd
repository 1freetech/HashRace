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
    for _frame in range(14):
        await process_frame

    var live_script := scene.get_script() as Script
    if live_script == null or live_script.resource_path != "res://scripts/world_v165.gd":
        _fail("full v0.165 gameplay world is not live")
        return

    # The normal campaign starts on Grid/Utility. Select the real Solar + Storage
    # gameplay energy option, then let the inherited v0.161 renderer draw its
    # permanent imported solar PNG into the live current-world campus.
    var player: Dictionary = scene.get("player")
    if player.is_empty():
        _fail("live player company state missing")
        return
    player["energy_idx"] = 4
    scene.queue_redraw()
    for _frame in range(10):
        await process_frame

    if not scene.has_method("debug_v161_solar_ready") or not bool(scene.call("debug_v161_solar_ready")):
        _fail("v0.161 imported solar renderer/collision is not ready in full gameplay world")
        return

    var bounds: Rect2 = scene.get("v161_solar_rect")
    var footprint: Rect2 = scene.get("v161_solar_footprint")
    var grid_nav = scene.get("grid_nav")
    if bounds.size.x <= 0.0 or bounds.size.y <= 0.0 or footprint.size.x <= 0.0 or grid_nav == null:
        _fail("solar render bounds/ground-contact footprint missing")
        return
    if bool(grid_nav.call("world_is_walkable", footprint.get_center())):
        _fail("solar ground-contact footprint was not registered in live navigation")
        return

    var camera: Camera2D = scene.get("camera")
    if camera == null:
        _fail("live gameplay camera missing")
        return
    camera.position_smoothing_enabled = false
    camera.position = bounds.get_center()
    camera.zoom = Vector2(1.25, 1.25)
    camera.force_update_scroll()
    scene.queue_redraw()
    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout

    var image := root.get_texture().get_image()
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../visual-proof"))
    if image == null or image.is_empty() or image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("screenshot missing")
        return
    print("V161 SOLAR PROOF PASS: imported solar PNG rendered in full v0.165 gameplay world with registered collision; " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
