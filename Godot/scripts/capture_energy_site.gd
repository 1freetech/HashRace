extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-energy-site.png"
const V117_CAPTURE_ENERGY_IDS: Array[String] = [
    "battery",
    "solar_array",
    "wind_farm",
    "gas_turbine",
    "hydro_turbine",
    "oil_field",
    "coal_plant",
    "nuclear_smr",
    "methane_generator",
    "diesel_generator",
    "geothermal_generator",
    "lpg_generator",
    "hydrogen_fuel_cell",
]

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE ENERGY SITE PROOF FAIL: " + message)
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
    await create_timer(0.25).timeout

    # Verification deliberately deploys one of every authored energy system.
    # This is a capture-only setup step; normal gameplay still requires the
    # player to acquire/deploy modules through the infrastructure inventory.
    var inventory = scene.get("infrastructure_inventory")
    var company: Dictionary = scene.get("player")
    if inventory == null:
        _fail("infrastructure inventory unavailable")
        return

    for asset_id in V117_CAPTURE_ENERGY_IDS:
        if inventory.item_resource(asset_id) == null:
            _fail("missing energy ItemResource: " + asset_id)
            return
        if inventory.quantity(asset_id) <= 0:
            if not inventory.add(asset_id, 1):
                _fail("could not add energy module: " + asset_id)
                return
        if inventory.deployed_quantity(asset_id) <= 0:
            if not inventory.deploy(asset_id, company, 1):
                _fail("could not deploy energy module: " + asset_id)
                return

    scene.set("player", company)
    scene.queue_redraw()

    var origin: Vector2 = scene.call("_energy_campus_origin")
    scene.set("rep_pos", origin)
    var camera = scene.get("camera")
    if camera != null and is_instance_valid(camera):
        camera.position = origin
        camera.zoom = Vector2(0.78, 0.78)
    scene.queue_redraw()

    for _frame in range(10):
        await process_frame
    await create_timer(0.20).timeout

    if not bool(scene.call("debug_v117_ready")):
        _fail("v0.117 energy renderer contract failed at runtime")
        return

    # Do not accept a source-only or hidden asset as a successful integration.
    # The scene must decode the cropped Library PNG, register its ground
    # footprint in navigation and retain the v0.114 capacity tiers.
    if not scene.has_method("debug_v160_transformer_ready") or not bool(scene.call("debug_v160_transformer_ready")):
        _fail("isolated v0.160 transformer sprite/footprint is not live")
        return

    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport produced no image")
        return

    var output_dir := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var output_file := ProjectSettings.globalize_path(OUTPUT_PATH)
    if image.save_png(output_file) != OK:
        _fail("could not save screenshot")
        return

    print("HASH RACE ENERGY SITE PROOF PASS: %s" % output_file)
    quit(0)
