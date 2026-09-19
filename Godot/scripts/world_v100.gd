extends "res://scripts/world_v099.gd"

# Hash Race v0.100 settlement-decision polish.
# Keep v0.099 guidance while making the preview compact, bounded, and easier to scan.

const V100_TURN_PREVIEW_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v100_turn_preview_revision", V100_TURN_PREVIEW_REVISION)

func _compact_money(value: float) -> String:
    var magnitude := absf(value)
    var sign := "-" if value < 0.0 else ""
    if magnitude >= 1000000000.0:
        return "%s$%.2fB" % [sign, magnitude / 1000000000.0]
    if magnitude >= 1000000.0:
        return "%s$%.2fM" % [sign, magnitude / 1000000.0]
    if magnitude >= 1000.0:
        return "%s$%.1fK" % [sign, magnitude / 1000.0]
    return "%s$%d" % [sign, int(magnitude)]

func _risk_label(power_pct: float, ending_cash: float, power_cost: float) -> String:
    if power_pct < 99.5 and ending_cash < 0.0:
        return "CRITICAL • POWER + CASH"
    if power_pct < 99.5:
        return "POWER SHORTFALL"
    if ending_cash < 0.0:
        return "NEGATIVE CASH"
    if ending_cash < maxf(10000.0, absf(power_cost) * 0.25):
        return "LOW CASH BUFFER"
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
        var profit := float(preview["profit"])
        var ending_cash := float(player["cash"]) + profit
        var power_cost := absf(float(preview["power_cost"]))
        var ops_cost := absf(float(preview["ops_cost"]))
        var debt_cost := absf(float(preview["debt_cost"]))
        var power_pct := clampf(float(preview.get("power_service_ratio", 1.0)) * 100.0, 0.0, 100.0)
        var margin_pct := 0.0 if revenue <= 0.0 else (profit / revenue) * 100.0
        var warning := _risk_label(power_pct, ending_cash, power_cost)
        var action := _turn_action_hint(power_pct, ending_cash, power_cost)
        _feedback("%s TURN • BTC %.6f • %s\nRevenue %s • Net %s • Margin %.1f%% • Cash %s\nCosts: power %s • ops %s • debt %s • Service %.0f%%\n%s • %s\nEnter/Space: confirm • Esc: cancel" % [turn_length_name(), float(preview["mined_btc"]), warning, _compact_money(revenue), _compact_money(profit), margin_pct, _compact_money(ending_cash), _compact_money(power_cost), _compact_money(ops_cost), _compact_money(debt_cost), power_pct, action, "Review the risk before advancing time."])
        return
    super._end_quarter()

func debug_v100_ready() -> bool:
    return V100_TURN_PREVIEW_REVISION == 1 \
        and _compact_money(1250000.0) == "$1.25M" \
        and _compact_money(-12500.0) == "-$12.5K" \
        and _risk_label(90.0, -1.0, 10000.0).begins_with("CRITICAL") \
        and _risk_label(100.0, 100000.0, 10000.0) == "READY"
