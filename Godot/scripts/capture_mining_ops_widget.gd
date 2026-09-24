extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-mining-ops-widget.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE MINING OPS WIDGET PROOF FAIL: " + message)
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

    for _frame in range(14):
        await process_frame
    await create_timer(0.25).timeout

    if scene.get_node_or_null("BootFallback") != null:
        _fail("loading fallback is still covering the game")
        return
    if not scene.has_method("debug_mining_ops_widget_ready") or not bool(scene.call("debug_mining_ops_widget_ready")):
        _fail("live Mining Ops widget is not active")
        return

    var before: Dictionary = scene.call("debug_mining_ops_widget_snapshot")
    var player_variant: Variant = scene.get("player")
    if not (player_variant is Dictionary):
        _fail("player state is not available")
        return
    var player: Dictionary = player_variant
    var before_cash: float = float(before.get("cash", 0.0))
    var before_btc: float = float(before.get("btc", 0.0))

    # Prove the display is bound to actual company state, not baked screenshot text.
    player["cash"] = before_cash + 12345.0
    player["sats"] = float(player.get("sats", 0.0)) + 250000000.0
    scene.call("_refresh_ui")

    for _frame in range(4):
        await process_frame
    await create_timer(0.12).timeout

    var after: Dictionary = scene.call("debug_mining_ops_widget_snapshot")
    if absf(float(after.get("cash", 0.0)) - (before_cash + 12345.0)) > 0.01:
        _fail("USD cash card did not follow live company cash")
        return
    if float(after.get("btc", 0.0)) < before_btc + 2.49:
        _fail("BTC treasury card did not follow live company sats")
        return

    var widget := scene.get_node_or_null("MiningOpsHUD/MiningOpsWidget") as Control
    if widget == null:
        _fail("Mining Ops widget node could not be located")
        return
    if not widget.has_method("debug_resizable_ready") or not bool(widget.call("debug_resizable_ready")):
        _fail("edge-resize system did not initialize")
        return
    if int(widget.call("debug_resize_edge_mask", Vector2(1.0, 120.0))) == 0:
        _fail("left-side resize hit zone is missing")
        return
    if int(widget.call("debug_resize_edge_mask", Vector2(160.0, 1.0))) == 0:
        _fail("top resize hit zone is missing")
        return

    var original_size := widget.size
    widget.call("debug_set_widget_size", Vector2(700.0, 410.0))
    for _frame in range(3):
        await process_frame
    if widget.size.x < original_size.x + 100.0 or widget.size.y < original_size.y + 60.0:
        _fail("responsive Mining Ops widget did not grow after resize")
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
        _fail("could not save Mining Ops widget PNG: %s" % error_string(save_error))
        return

    print("HASH RACE MINING OPS WIDGET PROOF PASS: live six-card HUD changed with company state and rendered successfully after edge-resizing to %.0fx%.0f. Saved %s" % [widget.size.x, widget.size.y, output_file])
    quit(0)
