extends "res://scripts/world_v090.gd"

# Hash Race v0.091 turns the settlement warning into an actionable decision.
# The preview still shows the measured cash/power risk from v0.090, but now
# adds one short corrective suggestion so a player knows what to do before
# confirming an overloaded or underfunded turn.

const V091_TURN_GUIDANCE_REVISION: int = 1

func _turn_risk_guidance(snapshot: Dictionary) -> String:
    var risk: String = String(snapshot.get("risk", "READY"))
    match risk:
        "CRITICAL: POWER + CASH":
            return "Fix power capacity and raise cash before advancing."
        "POWER SHORTFALL":
            return "Deploy or buy more power capacity before advancing."
        "NEGATIVE CASH":
            return "Raise cash, cut costs, or shorten the turn before advancing."
        "LOW CASH BUFFER":
            return "Consider a shorter turn or keep more cash in reserve."
        _:
            return "Capacity and cash are ready for this turn."

func _end_quarter() -> void:
    if campaign_complete:
        return
    var days: float = minf(turn_length_days(), maxf(0.0, float(campaign_years) * DAYS_PER_YEAR - elapsed_campaign_days))
    if days <= 0.0:
        return
    if not live_quarter_confirmation_pending:
        live_quarter_confirmation_pending = true
        var snapshot: Dictionary = _turn_risk_snapshot(days)
        var p: Dictionary = snapshot["preview"]
        quarter_button.text = "CONFIRM %s TURN" % turn_length_name()
        _feedback("%s PREVIEW: %.2f days • BTC %.6f • NET $%d • CASH AFTER $%d • POWER %.0f%% • %s — %s Confirm or Esc." % [turn_length_name(), days, float(p["mined_btc"]), int(p["profit"]), int(snapshot["cash_after"]), float(snapshot["coverage"]) * 100.0, String(snapshot["risk"]), _turn_risk_guidance(snapshot)])
        return
    super._end_quarter()

func debug_v091_ready() -> bool:
    if V091_TURN_GUIDANCE_REVISION != 1 or not has_method("_turn_risk_snapshot"):
        return false
    return (
        _turn_risk_guidance({"risk":"POWER SHORTFALL"}).contains("power")
        and _turn_risk_guidance({"risk":"NEGATIVE CASH"}).contains("cash")
        and _turn_risk_guidance({"risk":"READY"}).contains("ready")
    )
