extends SceneTree

const OUTPUT := "res://../visual-proof/v165-diesel-overview.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("V165 DIESEL PROOF FAIL: " + message)
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
    if inventory == null or inventory.item_resource("diesel_generator") == null:
        _fail("diesel_generator missing from real infrastructure inventory")
        return
    if inventory.quantity("diesel_generator") <= 0 and not inventory.add("diesel_generator", 1):
        _fail("could not add diesel_generator")
        return
    if inventory.deployed_quantity("diesel_generator") <= 0 and not inventory.deploy("diesel_generator", company, 1):
        _fail("could not deploy diesel_generator")
        return
    scene.set("player", company)
    if scene.call("_v114_primary_energy_id", scene.call("_player_hq_center")) != "diesel_generator":
        _fail("diesel_generator is not selected")
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
    if not scene.has_method("debug_v165_diesel_ready") or not scene.call("debug_v165_diesel_ready"):
        _fail("diesel asset was not drawn and grounded")
        return
    var image := root.get_texture().get_image()
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image == null or image.is_empty() or image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("could not save proof")
        return
    print("V165 DIESEL PROOF PASS: " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
