extends "res://scripts/world_rpg_strategy.gd"

# Flexible season clock for Hash Race. One strategic turn can represent a day,
# week, month, or quarter while all mining and operating economics remain based
# on the same per-day metrics.

const TURN_LENGTHS: Array = [
    {"name": "DAY", "days": 1.0},
    {"name": "WEEK", "days": 7.0},
    {"name": "MONTH", "days": 30.4375},
    {"name": "QUARTER", "days": 91.3125}
]
const DAYS_PER_YEAR: float = 365.25
const HALVING_DAYS: float = 1461.0

var turn_length_idx: int = 2
var elapsed_campaign_days: float = 0.0
var next_halving_day: float = HALVING_DAYS
var turn_scale_button: Button

func _ready() -> void:
    super._ready()
    campaign_turns = int(ceil(float(campaign_years) * DAYS_PER_YEAR / turn_length_days()))
    _install_turn_scale_control()
    _refresh_ui()

func turn_length_days() -> float:
    return float(TURN_LENGTHS[turn_length_idx]["days"])

func turn_length_name() -> String:
    return String(TURN_LENGTHS[turn_length_idx]["name"])

func _install_turn_scale_control() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    layer.name = "TurnScaleLayer"
    layer.layer = 12
    add_child(layer)
    turn_scale_button = Button.new()
    turn_scale_button.position = Vector2(1080.0, 88.0)
    turn_scale_button.size = Vector2(330.0, 42.0)
    turn_scale_button.add_theme_font_size_override("font_size", 12)
    turn_scale_button.pressed.connect(_cycle_turn_length)
    layer.add_child(turn_scale_button)
    _refresh_turn_scale_button()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_C:
            _cycle_turn_length()
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)

func _cycle_turn_length() -> void:
    if live_quarter_confirmation_pending:
        _invalidate_quarter_preview("Turn preview cancelled because the turn length changed.")
    turn_length_idx = (turn_length_idx + 1) % TURN_LENGTHS.size()
    if is_instance_valid(quarter_button):
        quarter_button.text = "END %s TURN" % turn_length_name()
    var remaining_days: float = maxf(0.0, float(campaign_years) * DAYS_PER_YEAR - elapsed_campaign_days)
    campaign_turns = (turn - 1) + int(ceil(remaining_days / turn_length_days()))
    _refresh_turn_scale_button()
    _refresh_ui()
    _feedback("TURN LENGTH: 1 turn = %s (%.2f days). Mining output, power, operations, debt interest, partner income, rivals, and market movement remain scaled to elapsed time." % [turn_length_name(), turn_length_days()])

func _refresh_turn_scale_button() -> void:
    if is_instance_valid(turn_scale_button):
        turn_scale_button.text = "TURN LENGTH: %s  [C]" % turn_length_name()
    if is_instance_valid(quarter_button) and not live_quarter_confirmation_pending and not campaign_complete:
        quarter_button.text = "END %s TURN" % turn_length_name()

func _project_scaled_profit(days: float) -> float:
    var mined_btc: float = _btc_per_day() * days
    var sold_btc: float = mined_btc * (1.0 - float(player["treasury_hold"]))
    var recurring_income: float = float(player["recurring_income"]) * (days / 91.3125)
    var revenue: float = sold_btc * btc_price + recurring_income
    var power_cost: float = _machine_load_kw() * 24.0 * days * _effective_power_cost() * _uptime()
    var ops_cost: float = float(player["machines"]) * 0.38 * days
    var debt_cost: float = float(player["debt"]) * float(player["debt_rate"]) * (days / 365.0)
    return revenue - power_cost - ops_cost - debt_cost

func _end_quarter() -> void:
    if campaign_complete:
        _feedback("Campaign complete. Start a new campaign from the setup menu.")
        return
    var days: float = minf(turn_length_days(), maxf(0.0, float(campaign_years) * DAYS_PER_YEAR - elapsed_campaign_days))
    if days <= 0.0:
        campaign_complete = true
        return
    if not live_quarter_confirmation_pending:
        live_quarter_confirmation_pending = true
        var projected_profit: float = _project_scaled_profit(days)
        var projected_cash: float = float(player["cash"]) + projected_profit
        var risk: String = _quarter_preview_risk(projected_profit, projected_cash)
        quarter_button.text = "CONFIRM %s TURN" % turn_length_name()
        if is_instance_valid(phase_label):
            phase_label.text = "%s PREVIEW: %s" % [turn_length_name(), risk]
        _feedback("%s PREVIEW [%s]: %.2f days • projected cash result $%d • projected ending cash $%d. Confirm to settle, or press Esc to cancel." % [turn_length_name(), risk, days, int(projected_profit), int(projected_cash)])
        return

    live_quarter_confirmation_pending = false
    quarter_button.text = "END %s TURN" % turn_length_name()
    if is_instance_valid(phase_label):
        phase_label.text = "QUARTER PHASE: PLAN • DEAL • BUILD"
    var mined_btc: float = _btc_per_day() * days
    var mined_sats: float = mined_btc * SATS_PER_BTC
    var held_sats: float = mined_sats * float(player["treasury_hold"])
    var sold_btc: float = mined_btc * (1.0 - float(player["treasury_hold"]))
    var recurring_income: float = float(player["recurring_income"]) * (days / 91.3125)
    var revenue: float = sold_btc * btc_price + recurring_income
    var power_cost: float = _machine_load_kw() * 24.0 * days * _effective_power_cost() * _uptime()
    var ops_cost: float = float(player["machines"]) * 0.38 * days
    var debt_cost: float = float(player["debt"]) * float(player["debt_rate"]) * (days / 365.0)
    var profit: float = revenue - power_cost - ops_cost - debt_cost
    player["sats"] = float(player["sats"]) + held_sats
    player["cash"] = float(player["cash"]) + profit
    player["last_profit"] = profit

    _simulate_rivals_scaled(days)
    elapsed_campaign_days += days
    var halving_happened: bool = false
    while elapsed_campaign_days >= next_halving_day:
        block_subsidy_btc *= 0.5
        next_halving_day += HALVING_DAYS
        halving_happened = true
    var market_note: String = _advance_market_scaled(days, halving_happened)
    var settled_turn: int = turn

    if elapsed_campaign_days >= float(campaign_years) * DAYS_PER_YEAR - 0.01:
        campaign_complete = true
        quarter_button.disabled = true
        quarter_button.text = "CAMPAIGN COMPLETE"
        _open_message("CAMPAIGN COMPLETE", "Finished %d years in %d turns. Final assets $%d • cash $%d • machines %d • %.2f MW • %.1f acres. %s" % [campaign_years, settled_turn, int(_asset_value()), int(player["cash"]), int(player["machines"]), float(player["mw"]), float(player["acres"]), market_note])
        _refresh_ui()
        return

    turn += 1
    var remaining_days: float = maxf(0.0, float(campaign_years) * DAYS_PER_YEAR - elapsed_campaign_days)
    campaign_turns = (turn - 1) + int(ceil(remaining_days / turn_length_days()))
    var note: String = "%s TURN %d closed: %.2f days • mined %d sats • held %d • cash result $%d. %s" % [turn_length_name(), settled_turn, days, int(mined_sats), int(held_sats), int(profit), market_note]
    if halving_happened:
        note += " HALVING: subsidy is now %.4f BTC." % block_subsidy_btc
    _open_message("%s SETTLEMENT" % turn_length_name(), note)
    _refresh_ui()
    queue_redraw()

func _cancel_live_quarter_confirmation() -> void:
    if not live_quarter_confirmation_pending:
        return
    live_quarter_confirmation_pending = false
    if is_instance_valid(quarter_button) and not campaign_complete:
        quarter_button.text = "END %s TURN" % turn_length_name()
    if is_instance_valid(phase_label):
        phase_label.text = "QUARTER PHASE: PLAN • DEAL • BUILD"
    _feedback("Turn settlement cancelled. Keep planning, dealing, or building before advancing time.")

func _simulate_rivals_scaled(days: float) -> void:
    var scale: float = days / 91.3125
    for i in range(rivals.size()):
        var rival: Dictionary = rivals[i]
        if bool(rival["merged"]):
            continue
        var cash_return: float = randf_range(-0.04, 0.08) * sqrt(scale)
        rival["cash"] = float(rival["cash"]) * maxf(0.85, 1.0 + cash_return)
        if randf() < minf(1.0, 0.55 * scale):
            rival["machines"] = int(rival["machines"]) + max(1, int(round(float(randi_range(5, 25)) * minf(1.0, scale))))
        if randf() < minf(1.0, 0.25 * scale):
            rival["mw"] = float(rival["mw"]) + 0.25
        if randf() < minf(1.0, 0.16 * scale):
            rival["acres"] = float(rival["acres"]) + 5.0
        rivals[i] = rival

func _advance_market_scaled(days: float, halving_happened: bool) -> String:
    var volatility_scale: float = sqrt(days / 91.3125)
    var rate_move: float = randf_range(-0.0035, 0.0035) * volatility_scale
    if randf() < 0.12 * minf(1.0, days / 91.3125):
        rate_move += randf_range(-0.005, 0.005) * volatility_scale
    federal_rate = clampf(federal_rate + rate_move, 0.005, 0.085)
    var rate_headwind: float = maxf(-0.02, federal_rate - 0.04)
    var btc_return: float = randf_range(-0.12, 0.18) * volatility_scale - rate_headwind * 0.90 * (days / 91.3125)
    var land_return: float = randf_range(-0.025, 0.040) * volatility_scale - rate_headwind * 0.35 * (days / 91.3125)
    btc_price = maxf(8000.0, btc_price * maxf(0.72, 1.0 + btc_return))
    land_price_per_acre = maxf(1800.0, land_price_per_acre * maxf(0.80, 1.0 + land_return))
    energy_market_index = clampf(energy_market_index * (1.0 + randf_range(-0.06, 0.07) * volatility_scale), 0.72, 1.45)
    network_hashrate_th *= maxf(0.90, 1.0 + randf_range(-0.015, 0.075) * volatility_scale)
    average_fees_btc = clampf(average_fees_btc * maxf(0.50, 1.0 + randf_range(-0.28, 0.38) * volatility_scale), 0.04, 0.85)
    var note: String = "Fed %.2f%% • BTC $%d • land $%d/acre." % [federal_rate * 100.0, int(btc_price), int(land_price_per_acre)]
    last_market_event = "Normal market"
    if halving_happened:
        halvings_since_crash += 1
        var crash_due: bool = halvings_since_crash >= 3 or (halvings_since_crash >= 2 and randf() < 0.55)
        if crash_due:
            note += " " + _trigger_rare_crash()
            halvings_since_crash = 0
    return note

func _refresh_ui() -> void:
    super._refresh_ui()
    if not is_instance_valid(top_stats) or player.is_empty():
        return
    var year: int = mini(campaign_years, int(elapsed_campaign_days / DAYS_PER_YEAR) + 1)
    var day_of_year: int = int(fmod(elapsed_campaign_days, DAYS_PER_YEAR)) + 1
    var quarter: int = clampi(int((day_of_year - 1) / (DAYS_PER_YEAR / 4.0)) + 1, 1, 4)
    top_stats.text = "%s  |  Y%d Q%d DAY %d  |  TURN %d  |  %s  |  Cash $%d  |  SATS %d" % [String(player["name"]), year, quarter, day_of_year, turn, turn_length_name(), int(player["cash"]), int(player["sats"])]
    var days_to_halving: int = maxi(0, int(ceil(next_halving_day - elapsed_campaign_days)))
    market_label.text += "  •  Halving ~%d days  •  1 turn=%s" % [days_to_halving, turn_length_name()]
