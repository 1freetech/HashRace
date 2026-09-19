extends "res://scripts/world_v101.gd"

# Hash Race v0.102: compact, decision-first settlement preview.
# Keeps v0.101's fleet-load MW target while making the confirm step readable,
# numerically safe, and useful for deciding whether to advance time.

const V102_DECISION_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v102_decision_revision", V102_DECISION_REVISION)

func _compact_money(value: float) -> String:
    var sign := "-" if value < 0.0 else ""
    var amount := absf(value)
    if amount >= 1000000000.0:
        return "%s$%.2fB" % [sign, amount / 1000000000.0]
    if amount >= 1000000.0:
        return "%s$%.2fM" % [sign, amount / 1000000.0]
    if amount >= 1000.0:
        return "%s$%.1fK" % [sign, amount / 1000.0]
    return "%s$%d" % [sign, int(round(amount))]

func _risk_state(power_pct: float, ending_cash: float, reserve_turns: float, profit: float) -> String:
    if power_pct < 99.5 and ending_cash < 0.0:
        return "CRITICAL • POWER + CASH"
    if ending_cash < 0.0:
        return "CRITICAL • NEGATIVE CASH"
    if power_pct < 99.5:
        return "WARNING • POWER SHORTFALL"
    if profit < 0.0:
        return "WARNING • OPERATING LOSS"
    if reserve_turns < 1.0:
        return "CAUTION • LOW RUNWAY"
    return "READY"

func _break_even_gap(revenue: float, total_cost: float) -> float:
    return maxf(0.0, total_cost - revenue)

func _end_quarter() -> void:
    if campaign_complete:
        return
    var days := minf(turn_length_days(), maxf(0.0, float(campaign_years) * DAYS_PER_YEAR - elapsed_campaign_days))
    if days <= 0.0:
        return
    if not live_quarter_confirmation_pending:
        var preview := _scaled_financial_preview(days)
        live_quarter_confirmation_pending = true
        quarter_button.text = "CONFIRM %s TURN" % turn_length_name()

        var revenue := float(preview["mining_revenue"]) + float(preview["partner_income"])
        var power_cost := absf(float(preview["power_cost"]))
        var ops_cost := absf(float(preview["ops_cost"]))
        var debt_cost := absf(float(preview["debt_cost"]))
        var total_cost := power_cost + ops_cost + debt_cost
        var profit := float(preview["profit"])
        var ending_cash := float(player["cash"]) + profit
        var power_pct := clampf(float(preview.get("power_service_ratio", 1.0)) * 100.0, 0.0, 100.0)
        var margin_pct := (profit / revenue * 100.0) if revenue > 0.0 else 0.0
        var reserve_turns := maxf(0.0, ending_cash) / maxf(1.0, total_cost)
        var risk := _risk_state(power_pct, ending_cash, reserve_turns, profit)
        var gap := _break_even_gap(revenue, total_cost)
        var action := _turn_action_hint(power_pct, ending_cash, power_cost)
        if gap > 0.0 and power_pct >= 99.5 and ending_cash >= 0.0:
            action = "ACTION: close %s break-even gap before a longer turn" % _compact_money(gap)

        var line1 := "%s TURN • BTC %.6f • SERVICE %.0f%% • %s" % [turn_length_name(), float(preview["mined_btc"]), power_pct, risk]
        var line2 := "REVENUE %s • NET %s • MARGIN %.1f%% • CASH %s" % [_compact_money(revenue), _compact_money(profit), margin_pct, _compact_money(ending_cash)]
        var line3 := "COSTS  POWER %s • OPS %s • DEBT %s • RUNWAY %.1f turns" % [_compact_money(power_cost), _compact_money(ops_cost), _compact_money(debt_cost), reserve_turns]
        var line4 := "%s\nEnter/Space: confirm • Esc: cancel" % action
        _feedback("%s\n%s\n%s\n%s" % [line1, line2, line3, line4])
        return
    super._end_quarter()

func debug_v102_ready() -> bool:
    return V102_DECISION_REVISION == 1 \
        and _compact_money(1250000.0) == "$1.25M" \
        and _compact_money(-12500.0) == "-$12.5K" \
        and _risk_state(80.0, -1.0, 0.0, -1.0).begins_with("CRITICAL") \
        and _risk_state(100.0, 50000.0, 2.0, 1000.0) == "READY" \
        and is_equal_approx(_break_even_gap(800.0, 1000.0), 200.0) \
        and is_equal_approx(_additional_mw_for_load(80.0, 10.0), 2.0)
