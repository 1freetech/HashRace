extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-archive-sprite-props.png"
const PROOF_CENTER := Vector2(900.0, 1015.0)

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("ARCHIVE SPRITE PROOF FAIL: " + message)
    quit(1)

func _capture() -> void:
    var packed: PackedScene = load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("world.tscn did not load")
        return
    var scene: Node = packed.instantiate()
    if scene == null:
        _fail("world.tscn did not instantiate")
        return
    root.add_child(scene)

    for _frame in range(16):
        await process_frame

    var props: Node = scene.get_node_or_null("ArchiveSpriteProps")
    if props == null:
        _fail("ArchiveSpriteProps node is missing from the live world")
        return
    if not props.has_method("debug_ready") or not bool(props.call("debug_ready")):
        _fail("archive sprite layer did not validate all promoted sheets and cells")
        return
    if int(props.call("live_sheet_count")) != 11 or int(props.call("live_sprite_count")) != 33:
        _fail("expected 11 live sheets and 33 live atlas sprites")
        return
    var survey: Node = props.get_node_or_null("EquipmentSurvey")
    if survey == null or not survey.has_method("debug_ready") or not bool(survey.call("debug_ready")):
        _fail("live equipment survey/reliability gameplay is missing or invalid")
        return
    var treasury: Node = scene.get_node_or_null("LiveTreasuryControls")
    if treasury == null or not treasury.has_method("debug_live_treasury_ready") or not bool(treasury.call("debug_live_treasury_ready")):
        _fail("live treasury controls are missing or not initialized in the current world")
        return
    var treasury_before: String = String(treasury.call("debug_live_treasury_status"))
    if "Reliability: NOMINAL" not in treasury_before:
        _fail("treasury did not start with nominal equipment reliability")
        return
    var projected_profit_before: float = float(treasury.call("debug_projected_turn_profit"))
    if not treasury.has_method("debug_safe_liquidity_target") or absf(float(treasury.call("debug_safe_liquidity_target")) - 10000.0) > 0.01:
        _fail("nominal treasury safe-liquidity target is not the $10,000 operating reserve")
        return

    scene.set("rep_pos", PROOF_CENTER)
    var player_sprite := scene.get("player_sprite") as AnimatedSprite2D
    if player_sprite != null:
        player_sprite.position = PROOF_CENTER
    var camera := scene.get("camera") as Camera2D
    if camera == null:
        _fail("live camera is missing")
        return
    camera.position_smoothing_enabled = false
    camera.position = PROOF_CENTER
    scene.queue_redraw()

    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout

    var nearest_name := String(survey.call("nearest_equipment_name"))
    if nearest_name.is_empty():
        _fail("equipment survey did not acquire a nearby promoted prop")
        return
    var inspect_prompt := survey.get_node_or_null("EquipmentInspectPrompt") as Label
    if inspect_prompt == null or not inspect_prompt.visible or "[E/F] INSPECT" not in inspect_prompt.text:
        _fail("equipment survey prompt is not visibly rendered near the player")
        return

    var uptime_before := float(scene.call("_uptime_without_grid_penalty"))
    if not survey.has_method("debug_force_fault") or not bool(survey.call("debug_force_fault", nearest_name, 1)):
        _fail("could not force the nearby surveyed equipment into a major fault")
        return
    for _frame in range(20):
        await process_frame
    await create_timer(0.30).timeout

    if String(survey.call("active_fault_name")) != nearest_name:
        _fail("forced equipment fault did not persist on the promoted prop")
        return
    if inspect_prompt == null or not inspect_prompt.visible or "[R] REPAIR" not in inspect_prompt.text or "MAJOR" not in inspect_prompt.text:
        _fail("live repair prompt is not visibly rendered on the failed equipment")
        return
    var player_value: Variant = scene.get("player")
    if not player_value is Dictionary or float(player_value.get("equipment_uptime_penalty", 0.0)) <= 0.0:
        _fail("equipment fault did not persist a mining-uptime penalty in live player state")
        return
    var uptime_after := float(scene.call("_uptime_without_grid_penalty"))
    if uptime_after >= uptime_before - 0.02:
        _fail("equipment fault did not materially lower the live mining uptime")
        return

    var treasury_fault: String = String(treasury.call("debug_live_treasury_status"))
    if not bool(treasury.call("debug_fault_indicator_ready")):
        _fail("treasury did not synchronize the active equipment fault")
        return
    if "Reliability: FAULT" not in treasury_fault or "-3.5% uptime" not in treasury_fault or "repair $" not in treasury_fault:
        _fail("treasury fault line is missing the live major-fault uptime or repair consequence")
        return
    var projected_profit_fault: float = float(treasury.call("debug_projected_turn_profit"))
    var repair_liquidity_target: float = float(treasury.call("debug_safe_liquidity_target"))
    var live_repair_cost: float = float((scene.get("player") as Dictionary).get("equipment_fault_repair_cost", 0.0))
    if live_repair_cost <= 0.0 or absf(repair_liquidity_target - (10000.0 + live_repair_cost)) > 0.01:
        _fail("active equipment repair cost is not reserved in the treasury safe-liquidity target")
        return
    if projected_profit_fault >= projected_profit_before - 1.0:
        _fail("treasury projected turn profit did not fall after the live equipment uptime fault")
        return

    # The compact HUD intentionally hides detail modules until selected. Open the
    # real BTC Treasury module through that shipped UI path so the screenshot
    # visibly proves the synchronized reliability/economics state without making
    # the default map permanently cluttered.
    if not scene.has_method("_show_named_module"):
        _fail("compact Control Center cannot open the live treasury module")
        return
    scene.call("_show_named_module", "LiveTreasuryLayer")
    for _frame in range(6):
        await process_frame
    var treasury_layer := scene.get_node_or_null("LiveTreasuryLayer") as CanvasLayer
    var treasury_status_label := scene.get_node_or_null("LiveTreasuryLayer/TreasuryPanel/TreasuryStatus") as Label
    if treasury_layer == null or not treasury_layer.visible:
        _fail("BTC Treasury module did not become visible through the compact UI path")
        return
    if treasury_status_label == null or not treasury_status_label.is_visible_in_tree():
        _fail("treasury reliability status is not visibly rendered in the opened module")
        return
    if "Reliability: FAULT" not in treasury_status_label.text or "-3.5% uptime" not in treasury_status_label.text or "safe liquidity $%d" % int(repair_liquidity_target) not in treasury_status_label.text:
        _fail("visible treasury module does not show the active reliability penalty")
        return

    # Capture the fault state before repairing it so the artifact visibly proves
    # the highlighted failed unit, repair prompt, and synchronized treasury risk.
    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport produced no image")
        return

    var output_dir: String = ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var output_file: String = ProjectSettings.globalize_path(OUTPUT_PATH)
    var save_error: Error = image.save_png(output_file)
    if save_error != OK:
        _fail("could not save proof PNG: %s" % error_string(save_error))
        return

    var histogram: Dictionary = {}
    var sampled: int = 0
    var step_x: int = maxi(1, int(image.get_width() / 90.0))
    var step_y: int = maxi(1, int(image.get_height() / 56.0))
    for y in range(0, image.get_height(), step_y):
        for x in range(0, image.get_width(), step_x):
            var pixel: Color = image.get_pixel(x, y)
            var key: String = pixel.to_html(false)
            histogram[key] = int(histogram.get(key, 0)) + 1
            sampled += 1
    var dominant_count: int = 0
    for raw_count in histogram.values():
        dominant_count = maxi(dominant_count, int(raw_count))
    var dominant_ratio: float = float(dominant_count) / maxf(1.0, float(sampled))
    if histogram.size() < 20 or dominant_ratio > 0.88:
        _fail("proof frame is visually empty or dominated by one color")
        return

    # Exercise the other half of the gameplay loop after the screenshot: repair
    # on site, spend the quoted cash, clear the fault state and restore uptime.
    var repair_player: Dictionary = scene.get("player")
    var repair_cost: float = float(repair_player.get("equipment_fault_repair_cost", 0.0))
    if repair_cost <= 0.0:
        _fail("fault repair cost was not materialized in live player state")
        return
    if float(repair_player.get("cash", 0.0)) < repair_cost:
        repair_player["cash"] = repair_cost + 50000.0
        scene.set("player", repair_player)
    var cash_before_repair: float = float(repair_player.get("cash", 0.0))
    if not bool(survey.call("_repair_active_fault")):
        _fail("on-site equipment repair action did not execute")
        return
    for _frame in range(20):
        await process_frame
    await create_timer(0.30).timeout
    var repaired_player: Dictionary = scene.get("player")
    if not String(survey.call("active_fault_name")).is_empty():
        _fail("repair did not clear the active equipment fault")
        return
    if absf(float(repaired_player.get("cash", 0.0)) - (cash_before_repair - repair_cost)) > 1.0:
        _fail("repair did not deduct the quoted cash cost")
        return
    if float(repaired_player.get("equipment_uptime_penalty", 0.0)) > 0.0001:
        _fail("repair did not clear the persisted equipment uptime penalty")
        return
    var uptime_restored := float(scene.call("_uptime_without_grid_penalty"))
    if uptime_restored < uptime_before - 0.001:
        _fail("repair did not restore live mining uptime")
        return
    var treasury_restored: String = String(treasury.call("debug_live_treasury_status"))
    if "Reliability: NOMINAL" not in treasury_restored or not bool(treasury.call("debug_fault_indicator_ready")):
        _fail("treasury did not return to nominal reliability after the on-site repair")
        return
    var projected_profit_restored: float = float(treasury.call("debug_projected_turn_profit"))
    if absf(float(treasury.call("debug_safe_liquidity_target")) - 10000.0) > 0.01:
        _fail("treasury safe-liquidity target did not release the repair reserve after repair")
        return
    if projected_profit_restored < projected_profit_before - 1.0:
        _fail("treasury turn projection did not recover after equipment repair")
        return

    print("ARCHIVE SPRITE PROOF PASS: 11 exact sheets, 33 grounded live props, visible inspection + fault + repair gameplay, visible treasury fault sync %.0f -> %.0f -> %.0f, uptime %.3f -> %.3f, repair $%d, restored %.3f (%s); %dx%d PNG saved %s" % [projected_profit_before, projected_profit_fault, projected_profit_restored, uptime_before, uptime_after, int(repair_cost), uptime_restored, nearest_name, image.get_width(), image.get_height(), output_file])
    quit(0)
