extends "res://scripts/world_v097.gd"

# Hash Race v0.098 turn-preview clarity.
# Keep the existing two-step END TURN flow, but expose the operating costs that
# drive the result so a player can make a useful decision before settlement.

const V098_TURN_PREVIEW_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v098_turn_preview_revision", V098_TURN_PREVIEW_REVISION)

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
        _feedback("%s PREVIEW • BTC %.6f • REVENUE $%d • POWER -$%d • OPS -$%d • DEBT -$%d • NET $%d • CASH $%d • SERVICE %.0f%% • %s. Confirm or Esc." % [turn_length_name(), float(preview["mined_btc"]), int(preview["mining_revenue"] + preview["partner_income"]), int(preview["power_cost"]), int(preview["ops_cost"]), int(preview["debt_cost"]), int(preview["profit"]), int(ending_cash), power_pct, warning])
        return
    super._end_quarter()

func debug_v098_ready() -> bool:
    return V098_TURN_PREVIEW_REVISION == 1 and has_method("_scaled_financial_preview")
