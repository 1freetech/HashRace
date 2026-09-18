extends "res://scripts/world_v089.gd"

# Hash Race v0.090 settlement-risk preview.
# Before committing time, the turn preview now shows power coverage and the
# projected cash runway. This turns END TURN into a useful operating decision:
# players can see an overloaded fleet or projected negative cash before the
# simulation irreversibly advances.

const V090_TURN_RISK_REVISION: int = 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v090_turn_risk_revision", V090_TURN_RISK_REVISION)

func _turn_risk_snapshot(days: float) -> Dictionary:
    var preview: Dictionary = _scaled_financial_preview(days)
    var load_kw: float = maxf(0.0, _machine_load_kw())
    var capacity_kw: float = maxf(0.0, float(player.get("mw", 0.0)) * 1000.0)
    var coverage: float = 1.0 if load_kw <= 0.0 else capacity_kw / load_kw
    var cash_after: float = float(player.get("cash", 0.0)) + float(preview["profit"])
    var risk: String = "READY"
    if coverage < 1.0 and cash_after < 0.0:
        risk = "CRITICAL: POWER + CASH"
    elif coverage < 1.0:
        risk = "POWER SHORTFALL"
    elif cash_after < 0.0:
        risk = "NEGATIVE CASH"
    elif cash_after < maxf(10000.0, absf(float(preview["power_cost"])) * 0.25):
        risk = "LOW CASH BUFFER"
    return {
        "coverage": coverage,
        "cash_after": cash_after,
        "risk": risk,
        "preview": preview
    }

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
        _feedback("%s PREVIEW: %.2f days • BTC %.6f • NET $%d • CASH AFTER $%d • POWER %.0f%% • %s. Confirm or Esc." % [turn_length_name(), days, float(p["mined_btc"]), int(p["profit"]), int(snapshot["cash_after"]), float(snapshot["coverage"]) * 100.0, String(snapshot["risk"])])
        return
    super._end_quarter()

func debug_v090_ready() -> bool:
    if V090_TURN_RISK_REVISION != 1 or not has_method("_scaled_financial_preview"):
        return false
    if player.is_empty():
        return true
    var snapshot: Dictionary = _turn_risk_snapshot(30.0)
    return snapshot.has("coverage") and snapshot.has("cash_after") and snapshot.has("risk")
