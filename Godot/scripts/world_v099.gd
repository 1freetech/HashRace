extends "res://scripts/world_v098.gd"

# v0.099 turns the settlement preview into a compact decision aid instead of a
# single dense telemetry sentence. Simulation rules remain authoritative below.
const V099_DECISION_REVISION := 1
const V099_LOW_SERVICE_PCT := 99.5

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v099_decision_revision", V099_DECISION_REVISION)

func _v099_money(value: float) -> String:
    var sign := "-" if value < 0.0 else ""
    var n := absf(value)
    if n >= 1000000000.0:
        return "%s$%.1fB" % [sign, n / 1000000000.0]
    if n >= 1000000.0:
        return "%s$%.1fM" % [sign, n / 1000000.0]
    if n >= 1000.0:
        return "%s$%.1fK" % [sign, n / 1000.0]
    return "%s$%d" % [sign, int(round(n))]

func _v099_risk(ending_cash: float, power_pct: float, power_cost: float) -> String:
    if power_pct < V099_LOW_SERVICE_PCT and ending_cash < 0.0:
        return "CRITICAL"
    if ending_cash < 0.0:
        return "NEGATIVE CASH"
    if power_pct < V099_LOW_SERVICE_PCT:
        return "POWER SHORTFALL"
    if ending_cash < maxf(10000.0, absf(power_cost) * 0.25):
        return "LOW RESERVE"
    return "READY"

func _v099_action(risk: String) -> String:
    match risk:
        "CRITICAL": return "Shorten the turn, add power, or raise cash."
        "NEGATIVE CASH": return "Shorten the turn or raise cash before settling."
        "POWER SHORTFALL": return "Add MW capacity or reduce fleet load."
        "LOW RESERVE": return "Preserve cash or choose a shorter turn."
        _: return "Economics are covered; confirm when ready."

func _v099_preview_text(preview: Dictionary, ending_cash: float, power_pct: float) -> String:
    var revenue := float(preview["mining_revenue"]) + float(preview["partner_income"])
    var net := float(preview["profit"])
    var margin := (net / revenue * 100.0) if revenue > 0.0 else 0.0
    var risk := _v099_risk(ending_cash, power_pct, float(preview["power_cost"]))
    return "%s TURN • %s\nBTC %.6f  |  Revenue %s  |  Net %s (%+.0f%%)\nPower %s  |  Ops %s  |  Debt %s\nEnding cash %s  |  Service %.0f%%  |  %s\n%s  Enter/Space: confirm • Esc: cancel" % [turn_length_name(), risk, float(preview["mined_btc"]), _v099_money(revenue), _v099_money(net), margin, _v099_money(-absf(float(preview["power_cost"]))), _v099_money(-absf(float(preview["ops_cost"]))), _v099_money(-absf(float(preview["debt_cost"]))), _v099_money(ending_cash), power_pct, risk, _v099_action(risk)]

func _end_quarter() -> void:
    if campaign_complete:
        return
    var days := minf(turn_length_days(), maxf(0.0, float(campaign_years) * DAYS_PER_YEAR - elapsed_campaign_days))
    if days <= 0.0:
        return
    if not live_quarter_confirmation_pending:
        var preview := _scaled_financial_preview(days)
        var ending_cash := float(player["cash"]) + float(preview["profit"])
        var power_pct := clampf(float(preview.get("power_service_ratio", 1.0)) * 100.0, 0.0, 100.0)
        live_quarter_confirmation_pending = true
        quarter_button.text = "CONFIRM %s TURN" % turn_length_name()
        _feedback(_v099_preview_text(preview, ending_cash, power_pct))
        return
    super._end_quarter()

func debug_v099_ready() -> bool:
    return V099_DECISION_REVISION == 1 and _v099_money(1250000.0) == "$1.2M" and _v099_risk(-1.0, 90.0, 100.0) == "CRITICAL"
