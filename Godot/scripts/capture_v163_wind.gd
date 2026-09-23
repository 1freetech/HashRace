extends SceneTree

const OUTPUT := "res://../visual-proof/v163-wind-runtime.png"
const HIGHER_PRIORITY_ENERGY: Array[String] = [
    "nuclear_smr",
    "hydro_turbine",
    "gas_turbine",
    "coal_plant",
    "solar_array",
]

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("V163 WIND PROOF FAIL: " + message)
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
        _fail("wind farm missing from real infrastructure inventory")
        return

    # The live selector intentionally prefers other deployed energy sources before
    # wind. Isolate the proof fixture by undeploying only those higher-priority
    # sources through the real inventory API instead of mutating dictionaries.
    for item_id in HIGHER_PRIORITY_ENERGY:
        var deployed_count: int = inventory.deployed_quantity(item_id)
        if deployed_count > 0 and not inventory.undeploy(item_id, company, deployed_count):
            _fail("could not isolate wind fixture from " + item_id)
            return

    if inventory.quantity("wind_farm") <= 0 and not inventory.add("wind_farm", 1):
        _fail("could not add wind farm")
        return
    if inventory.deployed_quantity("wind_farm") <= 0 and not inventory.deploy("wind_farm", company, 1):
        _fail("could not deploy wind farm")
        return
    scene.set("player", company)
    if scene.call("_v114_primary_energy_id", scene.call("_player_hq_center")) != "wind_farm":
        _fail("wind farm is not the selected real energy source")
        return

    var origin: Vector2 = scene.call("_energy_campus_origin")
    scene.set("rep_pos", origin + Vector2(-40.0, 115.0))
    var camera = scene.get("camera")
    if camera != null and is_instance_valid(camera):
        camera.position = origin
        camera.zoom = Vector2(0.78, 0.78)
    scene.queue_redraw()
    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout
    if not scene.has_method("debug_v163_wind_ready") or not scene.call("debug_v163_wind_ready"):
        _fail("validated wind binary was not drawn and grounded in live gameplay")
        return
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport image missing")
        return
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("could not save wind runtime proof")
        return
    print("V163 WIND PROOF PASS: " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
