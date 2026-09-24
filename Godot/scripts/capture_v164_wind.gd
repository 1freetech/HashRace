extends SceneTree

# Exact-head rendered proof for the real wind_farm binary. Deploy the real
# inventory item, move the player to the live mining campus, and require the
# v0.164 renderer to report a grounded draw before saving the viewport.
const OUTPUT := "res://../visual-proof/v164-wind-overview.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("V164 WIND PROOF FAIL: " + message)
    quit(1)

func _capture() -> void:
    set_meta("hashrace_company_idx", 0)
    set_meta("hashrace_campaign_years", 4)
    set_meta("hashrace_campaign_turns", 16)
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live scene missing")
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _frame in range(12):
        await process_frame

    var inventory = scene.get("infrastructure_inventory")
    var company: Dictionary = scene.get("player")
    if inventory == null or inventory.item_resource("wind_farm") == null:
        _fail("wind_farm missing from the real infrastructure inventory")
        return
    if inventory.quantity("wind_farm") <= 0 and not inventory.add("wind_farm", 1):
        _fail("could not add wind_farm for proof fixture")
        return
    if inventory.deployed_quantity("wind_farm") <= 0 and not inventory.deploy("wind_farm", company, 1):
        _fail("could not deploy wind_farm for proof fixture")
        return
    scene.set("player", company)
    if scene.call("_v114_primary_energy_id", scene.call("_player_hq_center")) != "wind_farm":
        _fail("wind_farm is not the currently selected real energy source")
        return

    var origin: Vector2 = scene.call("_energy_campus_origin")
    scene.set("rep_pos", origin)
    var camera = scene.get("camera")
    if camera != null and is_instance_valid(camera):
        camera.position = origin
        camera.zoom = Vector2(0.78, 0.78)
    scene.queue_redraw()
    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout
    if not scene.has_method("debug_v164_wind_ready") or not scene.call("debug_v164_wind_ready"):
        _fail("committed wind PNG was not drawn and grounded in the live world")
        return
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
