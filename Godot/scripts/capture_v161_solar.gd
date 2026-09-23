extends SceneTree

# A real rendered-frame proof: deploy the solar resource in an otherwise clean
# campaign, visit the live four-object site, and screenshot the actual viewport.
const OUTPUT := "res://../visual-proof/v161-solar-overview.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("V161 SOLAR PROOF FAIL: " + message)
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
    if inventory == null or inventory.item_resource("solar_array") == null:
        _fail("solar module missing from the real infrastructure inventory")
        return
    if inventory.quantity("solar_array") <= 0 and not inventory.add("solar_array", 1):
        _fail("could not add solar module for the proof fixture")
        return
    if inventory.deployed_quantity("solar_array") <= 0 and not inventory.deploy("solar_array", company, 1):
        _fail("could not deploy solar module for the proof fixture")
        return
    scene.set("player", company)
    if scene.call("_v114_primary_energy_id", scene.call("_player_hq_center")) != "solar_array":
        _fail("solar is not the currently selected real energy source")
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
    if not scene.has_method("debug_v161_solar_ready") or not scene.call("debug_v161_solar_ready"):
        _fail("committed solar PNG was not drawn/grounded in the live world")
        return
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport image missing")
        return
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("could not save solar visual proof")
        return
    print("V161 SOLAR PROOF PASS: " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
