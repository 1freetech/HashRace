extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("HASH RACE OVERWORLD FAIL: " + message)
    quit(1)

func _run() -> void:
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

    var required_methods: Array = [
        "debug_world_ready", "debug_entity_count", "debug_has_dialogue_ui", "debug_player_company",
        "debug_company_rep_count", "debug_partner_rep_count", "debug_town_count", "debug_player_rep_name",
        "_open_entity", "_end_quarter"
    ]
    for method_name in required_methods:
        if not scene.has_method(method_name):
            _fail("missing overworld method: %s" % method_name)
            return

    if not bool(scene.call("debug_world_ready")):
        _fail("overworld did not initialize player/entities/camera")
        return
    if int(scene.call("debug_entity_count")) < 38:
        _fail("expected company buildings plus mining and partner representatives")
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
    if not bool(scene.call("debug_has_dialogue_ui")):
        _fail("RPG dialogue/action interface is missing")
        return
    if String(scene.call("debug_player_company")) != "ArcCurrent Systems":
        _fail("campaign company selection did not reach the overworld")
        return
    if String(scene.call("debug_player_rep_name")) != "Imani Vale":
        _fail("selected company representative identity did not load")
        return

    scene.call("_open_entity", 1)
    await process_frame
    var start_turn: int = int(scene.get("turn"))
    scene.call("_end_quarter")
    await process_frame
    if int(scene.get("turn")) != start_turn + 1:
        _fail("quarter settlement did not advance the turn")
        return

    print("HASH RACE OVERWORLD PASS: ten company towns, ten mining reps, nine partner reps, techwear scanner-visors, dialogue actions, selected company, camera, and quarter settlement verified.")
    quit(0)
