extends "res://scripts/world_v100.gd"

# Hash Race v0.101 decision-quality pass.
# Keep v0.100 MW targeting, but make the settlement preview compact, bounded,
# comparable between turn lengths, and easier to act on at a glance.

const V101_DECISION_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v101_decision_revision", V101_DECISION_REVISION)

func _compact_money(value: float) -> String:
    var magnitude := absf(value)
    var sign := "-" if value < 0.0 else ""
    if magnitude >= 1000000000.0:
        return "%s$%.2fB" % [sign, magnitude / 1000000000.0]
    if magnitude >= 1000000.0:
        return "%s$%.2fM" % [sign, magnitude / 1000000.0]
    if magnitude >= 1000.0:
        return "%s$%.1fK" % [sign, magnitude / 1000.0]
    return "%s$%d" % [sign, int(round(magnitude))]

func _risk_state(power_pct: float, ending_cash: float, reserve_turns: float) -> String:
    if power_pct < 99.5 and ending_cash < 0.0:
        return "CRITICAL • POWER + CASH"
    if ending_cash < 0.0:
        return "CRITICAL • NEGATIVE CASH"
    if power_pct < 99.5:
        return "WARNING • POWER SHORTFALL"
    if reserve_turns < 1.0:
        return "CAUTION • LOW RESERVE"
    return "READY"

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
        var margin_pct := (profit / revenue * 100.0) if revenue > 0.01 else 0.0
        var reserve_turns := maxf(0.0, ending_cash) / maxf(1.0, total_cost)
        var risk := _risk_state(power_pct, ending_cash, reserve_turns)
        var action := _turn_action_hint(power_pct, ending_cash, power_cost)

        _feedback("%s PREVIEW • BTC %.6f • SERVICE %.0f%% • %s\nREVENUE %s • COSTS %s • NET %s • MARGIN %.1f%%\nCASH AFTER %s • RESERVE %.1fx turn cost\n%s\nEnter/Space: confirm • Esc: cancel" % [turn_length_name(), float(preview["mined_btc"]), power_pct, risk, _compact_money(revenue), _compact_money(total_cost), _compact_money(profit), margin_pct, _compact_money(ending_cash), reserve_turns, action])
        return
    super._end_quarter()

func debug_v101_ready() -> bool:
    return V101_DECISION_REVISION == 1 \
        and _compact_money(1250000.0) == "$1.25M" \
        and _compact_money(-2500.0) == "-$2.5K" \
        and _risk_state(80.0, -1.0, 0.0).begins_with("CRITICAL") \
        and _risk_state(100.0, 50000.0, 2.0) == "READY" \
        and _additional_mw_needed(80.0) >= 0.0
