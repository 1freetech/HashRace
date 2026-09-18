extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("HASH RACE NEGOTIATION FAIL: " + message)
    quit(1)

func _run() -> void:
    var packed: PackedScene = load("res://scenes/NegotiationScene.tscn") as PackedScene
    if packed == null:
        _fail("NegotiationScene.tscn did not load")
        return

    var scene: Node = packed.instantiate()
    if scene == null:
        _fail("NegotiationScene.tscn did not instantiate")
        return

    scene.call("configure", {
        "opponent_name":"Stress Test Rival",
        "opponent_company":"Stress Test Mining",
        "player_company":"Hash Race QA",
        "opponent_power":90,
        "opponent_greed":90,
        "player_reputation":20,
        "player_leverage":20,
        "deal_value_usd":12000.0,
        "player_cash_usd":100000.0,
        "reward_mw":0.05,
        "rival_idx":1
    })
    root.add_child(scene)
    await process_frame
    await process_frame

    if not scene.has_method("debug_ready") or not bool(scene.call("debug_ready")):
        _fail("negotiation UI/controller did not initialize")
        return

    scene.call("debug_force_open")
    scene.call("_make_offer")
    await process_frame

    var snapshot: Dictionary = scene.call("debug_snapshot")
    if float(snapshot.get("player_offer", 0.0)) <= 0.0:
        _fail("MAKE OFFER did not create a player offer")
        return
    if float(snapshot.get("opponent_offer", 0.0)) <= 0.0:
        _fail("difficult rival did not generate a counteroffer")
        return
    if String(snapshot.get("deal", "")) == "":
        _fail("deal context was not preserved")
        return

    scene.call("_walk_away")
    await process_frame
    var final_snapshot: Dictionary = scene.call("debug_snapshot")
    if not bool(final_snapshot.get("resolved", false)):
        _fail("walk-away path did not resolve negotiation")
        return

    print("HASH RACE NEGOTIATION PASS: battle-style scene, offer, counteroffer, walk-away control, and result state initialized.")
    quit(0)
