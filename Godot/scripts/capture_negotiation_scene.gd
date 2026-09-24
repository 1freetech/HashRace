extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-negotiation-scene.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE NEGOTIATION PROOF FAIL: " + message)
    quit(1)

func _capture() -> void:
    var packed: PackedScene = load("res://scenes/NegotiationScene.tscn") as PackedScene
    if packed == null:
        _fail("NegotiationScene.tscn did not load")
        return

    var scene: Node = packed.instantiate()
    scene.call("configure", {
        "opponent_name":"Rhea Knox",
        "opponent_company":"NeonForge Mining",
        "player_company":"VantaGrid Mining",
        "opponent_power":76,
        "opponent_greed":68,
        "player_reputation":62,
        "player_leverage":57,
        "deal_value_usd":14800.0,
        "player_cash_usd":95000.0,
        "reward_mw":0.08,
        "deal_label":"SHARED POWER CAPACITY",
        "target_asset_label":"0.08 MW FLEX CAPACITY",
        "rival_idx":1
    })
    root.add_child(scene)

    for _frame in range(8):
        await process_frame
    await create_timer(0.95).timeout

    if not scene.has_method("debug_ready") or not bool(scene.call("debug_ready")):
        _fail("negotiation scene controller is not ready")
        return

    scene.call("_make_offer")
    await create_timer(0.12).timeout

    var snapshot: Dictionary = scene.call("debug_snapshot")
    if float(snapshot.get("player_offer", 0.0)) <= 0.0:
        _fail("live offer did not update before capture")
        return

    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport produced no image")
        return

    var output_dir: String = ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var output_file: String = ProjectSettings.globalize_path(OUTPUT_PATH)
    var save_error: Error = image.save_png(output_file)
    if save_error != OK:
        _fail("could not save negotiation PNG: %s" % error_string(save_error))
        return

    print("HASH RACE NEGOTIATION PROOF PASS: battle-style rival negotiation rendered to %s" % output_file)
    quit(0)
