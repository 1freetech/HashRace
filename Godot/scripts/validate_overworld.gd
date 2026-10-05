extends SceneTree

# Validate the actual full Hash Race campaign world. The live scene intentionally
# uses the v0.165 gameplay inheritance chain; this must never be reduced to the
# small standalone visual/runtime fixture again.

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("HASH RACE WORLD FAIL: " + message)
    quit(1)

func _run() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("world.tscn did not load through Godot ResourceLoader")
        return

    var scene := packed.instantiate()
    if scene == null:
        _fail("world.tscn did not instantiate")
        return
    root.add_child(scene)
    for _frame in range(8):
        await process_frame

    var script := scene.get_script() as Script
    if script == null or script.resource_path != "res://scripts/world_v165.gd":
        _fail("live campaign is not using world_v165.gd")
        return

    # These methods come from distinct gameplay layers and prove the campaign
    # still includes navigation, league/inventory, life operations and burnout.
    for method_name in [
        "debug_grid_navigation_ready",
        "debug_grid_path_exists",
        "debug_league_standings_ready",
        "debug_life_ops_ready",
        "debug_life_effects_material",
        "debug_burnout_ready",
        "_open_infrastructure_inventory",
        "_end_quarter",
    ]:
        if not scene.has_method(method_name):
            _fail("full gameplay method missing: %s" % method_name)
            return

    if not bool(scene.call("debug_grid_navigation_ready")):
        _fail("navigation grid did not initialize")
        return
    if not bool(scene.call("debug_grid_path_exists")):
        _fail("playable navigation route could not be found")
        return
    if not bool(scene.call("debug_league_standings_ready")):
        _fail("ten-company Bitcoin mining league did not initialize")
        return
    if not bool(scene.call("debug_life_ops_ready")) or not bool(scene.call("debug_life_effects_material")):
        _fail("life/operations gameplay is missing or non-material")
        return
    if not bool(scene.call("debug_burnout_ready")):
        _fail("burnout gameplay layer did not initialize")
        return

    var player: Dictionary = scene.get("player")
    var rivals: Array = scene.get("rivals")
    var entities: Array = scene.get("entities")
    if player.is_empty() or rivals.size() != 9 or entities.size() < 10:
        _fail("company/rival/overworld gameplay state is incomplete")
        return

    var grid_nav = scene.get("grid_nav")
    if grid_nav == null or int(grid_nav.call("blocked_count")) <= 0:
        _fail("world collision/navigation footprints were not registered")
        return

    var inventory = scene.get("infrastructure_inventory")
    if inventory == null or int(inventory.call("catalog_size")) <= 0:
        _fail("infrastructure inventory/catalog did not initialize")
        return
    for energy_id in ["solar_array", "wind_farm", "diesel_generator"]:
        if not inventory.has_method("stored_quantity"):
            _fail("inventory deployment API is missing")
            return
        # Reading each item exercises the same catalog used by the live UI.
        inventory.call("stored_quantity", energy_id)

    var camera := scene.get("camera") as Camera2D
    if camera == null or not camera.is_inside_tree():
        _fail("playable overworld camera did not initialize")
        return

    # Verify actual playable position is grounded and can participate in the
    # navigation system without relying on the retired standalone move_player API.
    var rep_pos: Vector2 = scene.get("rep_pos")
    if rep_pos == Vector2.ZERO or not bool(grid_nav.call("world_is_walkable", rep_pos)):
        _fail("player representative spawned outside the playable navigation grid")
        return

    scene.queue_free()
    await process_frame
    print("HASH RACE WORLD OK: v0.165 full gameplay chain, league, inventory, life ops, burnout, navigation, collisions and camera validated")
    quit(0)
