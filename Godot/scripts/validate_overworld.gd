extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("HASH RACE OVERWORLD FAIL: " + message)
    quit(1)

func _run() -> void:
    if not ClassDB.class_exists(&"HashRaceRuntime"):
        _fail("HashRaceRuntime GDExtension class is not loaded")
        return

    set_meta("hashrace_company_idx", 2)
    set_meta("hashrace_campaign_years", 3)
    set_meta("hashrace_campaign_turns", 12)

    var packed: PackedScene = load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("world.tscn did not load")
        return

    var scene: Node = packed.instantiate()
    if scene == null:
        _fail("world.tscn did not instantiate")
        return
    root.add_child(scene)
    await process_frame
    await process_frame
    await process_frame

    var required_methods: Array = [
        "debug_world_ready", "debug_entity_count", "debug_has_dialogue_ui", "debug_player_company",
        "debug_company_rep_count", "debug_partner_rep_count", "debug_town_count", "debug_player_rep_name",
        "debug_has_land_market", "debug_grid_navigation_ready", "debug_grid_path_exists",
        "debug_gbc_map_ready", "debug_gbc_road_tiles", "debug_tile_ops_changed",
        "debug_visual_stack_ready", "debug_visual_reference_count",
        "debug_rpg_collision_ready", "debug_scanner_reachable_count", "debug_rep_animation_state",
        "debug_range_limited_path_exists", "debug_company_personality_ready", "debug_rival_personality_count",
        "debug_personality_ratings_in_range", "debug_culture_effects_ready", "debug_culture_effects_are_material",
        "debug_culture_effects_summary", "debug_native_runtime_ready", "debug_native_settlement_ready",
        "debug_native_inventory", "_open_entity", "_end_quarter"
    ]
    for method_name in required_methods:
        if not scene.has_method(method_name):
            _fail("missing overworld method: %s" % method_name)
            return

    if not bool(scene.call("debug_native_runtime_ready")):
        _fail("C++ runtime did not become authoritative")
        return
    if not bool(scene.call("debug_native_settlement_ready")):
        _fail("live turn settlement is not routed through C++")
        return
    if not scene.has_meta("hashrace_native_state_authority") or String(scene.get_meta("hashrace_native_state_authority")) != "C++":
        _fail("world does not advertise C++ as state authority")
        return
    if String(scene.get_meta("hashrace_native_runtime_revision", "")) != "v0.046-cpp-authoritative":
        _fail("unexpected native runtime revision")
        return
    var native_inventory: Array = scene.call("debug_native_inventory") as Array
    if native_inventory.is_empty():
        _fail("C++ native fleet inventory is empty")
        return
    var player_state: Dictionary = scene.get("player") as Dictionary
    if not bool(player_state.get("native_runtime", false)):
        _fail("GDScript player mirror is not marked as a C++ snapshot")
        return

    if not bool(scene.call("debug_world_ready")):
        _fail("overworld did not initialize player/entities/camera")
        return
    if int(scene.call("debug_entity_count")) < 39:
        _fail("expected company buildings, land market, mining reps and partner reps")
        return
    if int(scene.call("debug_company_rep_count")) != 10:
        _fail("each of the ten mining companies must have a representative")
        return
    if int(scene.call("debug_partner_rep_count")) != 9:
        _fail("each partner company must have a representative")
        return
    if int(scene.call("debug_town_count")) != 10:
        _fail("each mining company must have its own named town zone")
        return
    if not bool(scene.call("debug_has_land_market")):
        _fail("direct land market is missing")
        return
    if not bool(scene.call("debug_has_dialogue_ui")):
        _fail("RPG dialogue/action interface is missing")
        return
    if not bool(scene.call("debug_grid_navigation_ready")):
        _fail("grid navigation did not initialize")
        return
    if not bool(scene.call("debug_grid_path_exists")):
        _fail("grid navigation could not produce a valid route")
        return
    if not bool(scene.call("debug_gbc_map_ready")):
        _fail("GBC-style art tilemap did not initialize")
        return
    if int(scene.call("debug_gbc_road_tiles")) < 40:
        _fail("pixel tilemap does not contain enough road tiles")
        return
    if int(scene.call("debug_tile_ops_changed")) <= 0:
        _fail("ported tilemap operations did not modify the live map")
        return
    if not bool(scene.call("debug_visual_stack_ready")):
        _fail("nine-source 2D visual stack contract failed")
        return
    if int(scene.call("debug_visual_reference_count")) != 9:
        _fail("expected exactly nine 2D visual reference techniques")
        return
    if not bool(scene.call("debug_rpg_collision_ready")):
        _fail("RPG collision grid does not recognize a blocked world cell")
        return
    if int(scene.call("debug_scanner_reachable_count")) < 10:
        _fail("scanner did not produce a useful reachable-area set")
        return
    var animation_state: String = String(scene.call("debug_rep_animation_state"))
    if not animation_state.ends_with("_idle") and animation_state not in ["up", "down", "left", "right"]:
        _fail("representative directional animation state is invalid")
        return
    if not bool(scene.call("debug_range_limited_path_exists")):
        _fail("range-limited grid path could not be produced")
        return
    if scene.get_node_or_null("RPGStrategyLayer") == null:
        _fail("scanner / strategy UI layer is missing")
        return
    if String(scene.call("debug_player_company")) != "ArcShift Mining":
        _fail("campaign company selection did not reach the overworld")
        return
    if String(scene.call("debug_player_rep_name")) != "Imani Vale":
        _fail("selected company representative identity did not load")
        return
    if not bool(scene.call("debug_company_personality_ready")):
        _fail("player company personality did not initialize")
        return
    if int(scene.call("debug_rival_personality_count")) != 9:
        _fail("all nine rival companies need live personality state")
        return
    if not bool(scene.call("debug_personality_ratings_in_range")):
        _fail("company personality rating escaped the 0-100 scale")
        return
    if not bool(scene.call("debug_culture_effects_ready")):
        _fail("company ratings are not producing bounded gameplay modifiers")
        return
    if not bool(scene.call("debug_culture_effects_are_material")):
        _fail("company ratings initialized but do not materially affect gameplay")
        return
    if String(scene.call("debug_culture_effects_summary")).is_empty():
        _fail("company gameplay-effect summary is missing")
        return
    if scene.get_node_or_null("BootFallback") != null:
        _fail("loading fallback remained after successful world initialization")
        return

    var treasury_controls: Node = scene.get_node_or_null("LiveTreasuryControls")
    if treasury_controls == null or not treasury_controls.has_method("debug_live_treasury_ready"):
        _fail("live BTC treasury liquidity controls are missing")
        return
    if not bool(treasury_controls.call("debug_live_treasury_ready")):
        _fail("live BTC treasury liquidity buttons did not initialize")
        return
    if not treasury_controls.has_method("debug_native_treasury_ready") or not bool(treasury_controls.call("debug_native_treasury_ready")):
        _fail("BTC treasury controls are not writing through C++")
        return

    scene.call("_open_entity", 1)
    await process_frame
    var start_turn: int = int(scene.get("turn"))
    var start_elapsed: float = float(scene.get("elapsed_campaign_days"))
    var start_player: Dictionary = scene.get("player") as Dictionary
    var start_cash: float = float(start_player.get("cash", 0.0))
    var start_sats: float = float(start_player.get("sats", 0.0))
    scene.call("_end_quarter")
    await process_frame
    if int(scene.get("turn")) != start_turn:
        _fail("first END TURN click must preview instead of advancing time")
        return
    if not bool(scene.get("live_quarter_confirmation_pending")):
        _fail("turn preview did not arm the confirmation state")
        return
    scene.call("_end_quarter")
    await process_frame
    if int(scene.get("turn")) != start_turn + 1:
        _fail("confirmed C++ turn settlement did not advance the turn")
        return
    if float(scene.get("elapsed_campaign_days")) <= start_elapsed:
        _fail("C++ runtime did not advance elapsed campaign days")
        return
    var settled_player: Dictionary = scene.get("player") as Dictionary
    if float(settled_player.get("cash", 0.0)) == start_cash and float(settled_player.get("sats", 0.0)) == start_sats:
        _fail("C++ settlement did not change cash or BTC treasury state")
        return
    if not bool(settled_player.get("native_runtime", false)):
        _fail("post-settlement player state is not a native snapshot")
        return

    print("HASH RACE OVERWORLD PASS: C++ is authoritative for mining/economy state, native inventory and flexible-turn settlement; Godot world, collision-safe movement, scanner navigation, ten mining towns, partner firms, 2D visual stack, 0-100 company personalities, treasury controls, dialogue, camera and settlement are verified.")
    quit(0)
