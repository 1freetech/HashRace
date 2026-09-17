extends Node

# Live treasury controls for the shipped RPG strategy world.
# Strategy ratings use Hash Race's universal 0-100 scale.

const SATS_PER_BTC: float = 100000000.0
const OPERATING_RESERVE: float = 10000.0

var world: Node
var sell_button: Button
var auto_fund_button: Button
var hold_policy_slider: HSlider
var hold_policy_label: Label
var status_label: Label

func _ready() -> void:
    world = get_parent()
    call_deferred("_install_controls")

func _install_controls() -> void:
    if world == null or not world.has_method("_project_live_quarter_profit"):
        return
    var layer := CanvasLayer.new()
    layer.name = "LiveTreasuryLayer"
    layer.layer = 11
    world.add_child(layer)

    var panel := Panel.new()
    panel.position = Vector2(1038.0, 548.0)
    panel.size = Vector2(390.0, 340.0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("071018f2")
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color("8a6cff")
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    panel.add_theme_stylebox_override("panel", style)
    layer.add_child(panel)

    var title := Label.new()
    title.position = Vector2(16.0, 12.0)
    title.size = Vector2(355.0, 28.0)
    title.text = "BTC TREASURY // LIQUIDITY"
    title.add_theme_font_size_override("font_size", 16)
    title.add_theme_color_override("font_color", Color("c5b8ff"))
    panel.add_child(title)

    status_label = Label.new()
    status_label.position = Vector2(16.0, 42.0)
    status_label.size = Vector2(355.0, 58.0)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", 11)
    status_label.add_theme_color_override("font_color", Color("d7eef3"))
    panel.add_child(status_label)

    hold_policy_label = Label.new()
    hold_policy_label.position = Vector2(16.0, 102.0)
    hold_policy_label.size = Vector2(355.0, 24.0)
    hold_policy_label.add_theme_font_size_override("font_size", 12)
    hold_policy_label.add_theme_color_override("font_color", Color("c5b8ff"))
    panel.add_child(hold_policy_label)

    hold_policy_slider = HSlider.new()
    hold_policy_slider.position = Vector2(16.0, 126.0)
    hold_policy_slider.size = Vector2(355.0, 34.0)
    hold_policy_slider.min_value = 0.0
    hold_policy_slider.max_value = 100.0
    hold_policy_slider.step = 1.0
    hold_policy_slider.value = float(_player().get("treasury_hold", 0.30)) * 100.0
    hold_policy_slider.tooltip_text = "Set exactly 0-100% of newly mined Bitcoin to hold. The remainder is sold for operating cash."
    hold_policy_slider.value_changed.connect(_on_hold_policy_changed)
    panel.add_child(hold_policy_slider)

    sell_button = Button.new()
    sell_button.position = Vector2(16.0, 174.0)
    sell_button.size = Vector2(355.0, 46.0)
    sell_button.text = "SELL 25% BTC TREASURY"
    sell_button.tooltip_text = "Sell one quarter of held sats at the current simulated Bitcoin price."
    sell_button.pressed.connect(sell_quarter_treasury)
    panel.add_child(sell_button)

    auto_fund_button = Button.new()
    auto_fund_button.position = Vector2(16.0, 230.0)
    auto_fund_button.size = Vector2(355.0, 46.0)
    auto_fund_button.text = "AUTO-FUND SAFE TURN"
    auto_fund_button.tooltip_text = "Sell only enough held Bitcoin to target $10,000 cash after the projected turn."
    auto_fund_button.pressed.connect(auto_fund_safe_quarter)
    panel.add_child(auto_fund_button)
    _refresh_status()

func _player() -> Dictionary:
    return world.get("player") as Dictionary

func _btc_price() -> float:
    return float(world.get("btc_price"))

func _projected_turn_profit() -> float:
    if world.has_method("turn_length_days") and world.has_method("_project_scaled_profit"):
        return float(world.call("_project_scaled_profit", float(world.call("turn_length_days"))))
    return float(world.call("_project_live_quarter_profit"))

func _projected_end_cash() -> float:
    return float(_player().get("cash", 0.0)) + _projected_turn_profit()

func _projected_risk(projected_profit: float, projected_end_cash: float) -> String:
    if world.has_method("_quarter_preview_risk"):
        return String(world.call("_quarter_preview_risk", projected_profit, projected_end_cash))
    if projected_end_cash < 0.0:
        return "DANGER: INSOLVENT"
    if projected_end_cash < OPERATING_RESERVE:
        return "CRITICAL: LOW RESERVE"
    if projected_profit < 0.0:
        return "WARNING: CASH BURN"
    return "READY"

func _on_hold_policy_changed(value: float) -> void:
    var player := _player()
    var percent: int = clampi(int(round(value)), 0, 100)
    player["treasury_hold"] = float(percent) / 100.0
    _reset_turn_preview()
    if world.has_method("_refresh_ui"):
        world.call("_refresh_ui")
    _refresh_status()

func _sell_sats(sats_to_sell: float) -> float:
    var player := _player()
    var held_sats := float(player.get("sats", 0.0))
    sats_to_sell = clampf(floor(sats_to_sell), 0.0, held_sats)
    if sats_to_sell < 1.0:
        return 0.0
    var cash_raised := (sats_to_sell / SATS_PER_BTC) * _btc_price()
    player["sats"] = held_sats - sats_to_sell
    player["cash"] = float(player.get("cash", 0.0)) + cash_raised
    _reset_turn_preview()
    if world.has_method("_refresh_ui"):
        world.call("_refresh_ui")
    return cash_raised

func sell_quarter_treasury() -> void:
    var player := _player()
    var held_sats := float(player.get("sats", 0.0))
    if held_sats < 1.0:
        _feedback("No held Bitcoin to sell yet. Mine and hold sats first.")
        return
    var sats_to_sell := maxf(1.0, floor(held_sats * 0.25))
    var raised := _sell_sats(sats_to_sell)
    _feedback("Treasury sale raised $%d by selling %d sats. %d sats remain." % [int(raised), int(sats_to_sell), int(player["sats"])])
    _refresh_status()

func auto_fund_safe_quarter() -> void:
    var player := _player()
    var projected_end := _projected_end_cash()
    var cash_needed := OPERATING_RESERVE - projected_end
    if cash_needed <= 0.0:
        _feedback("No treasury sale needed. Projected turn-end cash already exceeds the $10,000 reserve target.")
        _refresh_status()
        return
    var held_sats := float(player.get("sats", 0.0))
    if held_sats < 1.0:
        _feedback("No BTC treasury is available. Lower the hold policy, seek financing, or cut costs before advancing.")
        return
    var sats_needed: float = float(ceil((cash_needed / maxf(1.0, _btc_price())) * SATS_PER_BTC))
    var sats_to_sell := minf(held_sats, sats_needed)
    var raised := _sell_sats(sats_to_sell)
    var new_end := _projected_end_cash()
    if new_end < 0.0:
        _feedback("Sold all available %d sats for $%d, but projected turn-end cash is still $%d. Financing or cost cuts are still required." % [int(sats_to_sell), int(raised), int(new_end)])
    elif new_end < OPERATING_RESERVE:
        _feedback("Sold all available %d sats for $%d, but projected turn-end cash is only $%d, below the $%d reserve target. Seek financing, cut costs, or improve mining economics before advancing." % [int(sats_to_sell), int(raised), int(new_end), int(OPERATING_RESERVE)])
    else:
        _feedback("Auto-fund sold only %d sats for $%d. Projected turn-end cash is now $%d; the remaining BTC stays in treasury." % [int(sats_to_sell), int(raised), int(new_end)])
    _refresh_status()

func _reset_turn_preview() -> void:
    world.set("live_quarter_confirmation_pending", false)
    var button = world.get("quarter_button")
    if is_instance_valid(button):
        if world.has_method("turn_length_name"):
            button.text = "END %s TURN" % String(world.call("turn_length_name"))
        else:
            button.text = "END QUARTER"
    var phase = world.get("phase_label")
    if is_instance_valid(phase):
        phase.text = "QUARTER PHASE: PLAN • DEAL • BUILD"

func _feedback(message: String) -> void:
    if world.has_method("_feedback"):
        world.call("_feedback", message)

func _refresh_status() -> void:
    if not is_instance_valid(status_label):
        return
    var player := _player()
    var held_sats := float(player.get("sats", 0.0))
    var hold_percent: int = clampi(int(round(float(player.get("treasury_hold", 0.30)) * 100.0)), 0, 100)
    var projected_profit := _projected_turn_profit()
    var projected_end := float(player.get("cash", 0.0)) + projected_profit
    var risk := _projected_risk(projected_profit, projected_end)
    if is_instance_valid(hold_policy_label):
        hold_policy_label.text = "BTC HOLD POLICY: %d / 100" % hold_percent
    status_label.text = "Held: %d sats  •  BTC $%d  •  %s\nProjected turn-end cash: $%d  •  reserve $%d" % [int(held_sats), int(_btc_price()), risk, int(projected_end), int(OPERATING_RESERVE)]

func debug_live_treasury_ready() -> bool:
    return is_instance_valid(hold_policy_slider) and is_instance_valid(sell_button) and is_instance_valid(auto_fund_button)
