extends Node

# Live treasury controls for the shipped RPG strategy world.
# Keeps emergency liquidity inside the actual playable world instead of only
# in the older campaign prototype layer.

const SATS_PER_BTC: float = 100000000.0
const OPERATING_RESERVE: float = 10000.0

var world: Node
var sell_button: Button
var auto_fund_button: Button
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
    panel.position = Vector2(1038.0, 632.0)
    panel.size = Vector2(390.0, 256.0)
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
    status_label.position = Vector2(16.0, 44.0)
    status_label.size = Vector2(355.0, 72.0)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status_label.add_theme_font_size_override("font_size", 11)
    status_label.add_theme_color_override("font_color", Color("d7eef3"))
    panel.add_child(status_label)

    sell_button = Button.new()
    sell_button.position = Vector2(16.0, 124.0)
    sell_button.size = Vector2(355.0, 46.0)
    sell_button.text = "SELL 25% BTC TREASURY"
    sell_button.tooltip_text = "Sell one quarter of held sats at the current simulated Bitcoin price."
    sell_button.pressed.connect(sell_quarter_treasury)
    panel.add_child(sell_button)

    auto_fund_button = Button.new()
    auto_fund_button.position = Vector2(16.0, 180.0)
    auto_fund_button.size = Vector2(355.0, 46.0)
    auto_fund_button.text = "AUTO-FUND SAFE QUARTER"
    auto_fund_button.tooltip_text = "Sell only enough held Bitcoin to target $10,000 cash after the projected quarter."
    auto_fund_button.pressed.connect(auto_fund_safe_quarter)
    panel.add_child(auto_fund_button)
    _refresh_status()

func _player() -> Dictionary:
    return world.get("player") as Dictionary

func _btc_price() -> float:
    return float(world.get("btc_price"))

func _projected_end_cash() -> float:
    var player := _player()
    return float(player.get("cash", 0.0)) + float(world.call("_project_live_quarter_profit"))

func _sell_sats(sats_to_sell: float) -> float:
    var player := _player()
    var held_sats := float(player.get("sats", 0.0))
    sats_to_sell = clampf(floor(sats_to_sell), 0.0, held_sats)
    if sats_to_sell < 1.0:
        return 0.0
    var cash_raised := (sats_to_sell / SATS_PER_BTC) * _btc_price()
    player["sats"] = held_sats - sats_to_sell
    player["cash"] = float(player.get("cash", 0.0)) + cash_raised
    _reset_quarter_preview()
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
        _feedback("No treasury sale needed. Projected quarter-end cash already exceeds the $10,000 reserve target.")
        _refresh_status()
        return
    var held_sats := float(player.get("sats", 0.0))
    if held_sats < 1.0:
        _feedback("No BTC treasury is available. Lower the HQ hold policy, seek financing, or cut costs before advancing.")
        return
    var sats_needed := ceil((cash_needed / maxf(1.0, _btc_price())) * SATS_PER_BTC)
    var sats_to_sell := minf(held_sats, sats_needed)
    var raised := _sell_sats(sats_to_sell)
    var new_end := _projected_end_cash()
    if new_end < 0.0:
        _feedback("Sold all available %d sats for $%d, but projected quarter-end cash is still $%d. Financing or cost cuts are still required." % [int(sats_to_sell), int(raised), int(new_end)])
    else:
        _feedback("Auto-fund sold only %d sats for $%d. Projected quarter-end cash is now $%d; the remaining BTC stays in treasury." % [int(sats_to_sell), int(raised), int(new_end)])
    _refresh_status()

func _reset_quarter_preview() -> void:
    world.set("live_quarter_confirmation_pending", false)
    var button = world.get("quarter_button")
    if is_instance_valid(button):
        button.text = "END QUARTER"

func _feedback(message: String) -> void:
    if world.has_method("_feedback"):
        world.call("_feedback", message)

func _refresh_status() -> void:
    if not is_instance_valid(status_label):
        return
    var player := _player()
    var held_sats := float(player.get("sats", 0.0))
    status_label.text = "Held: %d sats  •  BTC $%d\nProjected quarter-end cash: $%d  •  reserve target $%d" % [int(held_sats), int(_btc_price()), int(_projected_end_cash()), int(OPERATING_RESERVE)]

func debug_live_treasury_ready() -> bool:
    return is_instance_valid(sell_button) and is_instance_valid(auto_fund_button)
