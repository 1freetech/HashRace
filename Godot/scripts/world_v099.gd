extends "res://scripts/world_v098.gd"

# Hash Race v0.099 turn-preview action guidance.
# Keep the readable economics preview from v0.098 and add a short next action
# so risk states teach the player how to recover before committing settlement.

const V099_TURN_ACTION_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v099_turn_action_revision", V099_TURN_ACTION_REVISION)

func _turn_action_hint(power_pct: float, ending_cash: float, power_cost: float) -> String:
    if power_pct < 99.5 and ending_cash < 0.0:
        return "ACTION: add/deploy MW and protect cash before confirming"
    if power_pct < 99.5:
        return "ACTION: open ENERGY/INFRASTRUCTURE and add or deploy MW"
    if ending_cash < 0.0:
        return "ACTION: raise cash, cut costs, or choose a shorter turn"
    if ending_cash < maxf(10000.0, absf(power_cost) * 0.25):
        return "ACTION: preserve a larger cash reserve before confirming"
    return "ACTION: settlement is within current operating limits"

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
        var ending_cash := float(player["cash"]) + float(preview["profit"])
        var power_pct := float(preview.get("power_service_ratio", 1.0)) * 100.0
        var warning := "READY"
        if power_pct < 99.5 and ending_cash < 0.0:
            warning = "POWER + CASH RISK"
        elif power_pct < 99.5:
            warning = "POWER SHORTFALL"
        elif ending_cash < 0.0:
            warning = "NEGATIVE CASH"
        elif ending_cash < maxf(10000.0, absf(float(preview["power_cost"])) * 0.25):
            warning = "LOW CASH BUFFER"
        var action := _turn_action_hint(power_pct, ending_cash, float(preview["power_cost"]))
        _feedback("%s PREVIEW • BTC %.6f • REVENUE $%d • POWER -$%d • OPS -$%d • DEBT -$%d • NET $%d • CASH $%d • SERVICE %.0f%% • %s • %s. Confirm or Esc." % [turn_length_name(), float(preview["mined_btc"]), int(preview["mining_revenue"] + preview["partner_income"]), int(preview["power_cost"]), int(preview["ops_cost"]), int(preview["debt_cost"]), int(preview["profit"]), int(ending_cash), power_pct, warning, action])
        return
    super._end_quarter()

func debug_v099_ready() -> bool:
    return V099_TURN_ACTION_REVISION == 1 and has_method("_scaled_financial_preview") and _turn_action_hint(90.0, 100000.0, 10000.0).contains("MW")
