extends "res://scripts/world_v099.gd"

# Hash Race v0.100 turn-preview efficiency guidance.
# The preview now translates service shortfall into an approximate additional MW
# requirement so the player can make a concrete infrastructure decision.

const V100_TURN_EFFICIENCY_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v100_turn_efficiency_revision", V100_TURN_EFFICIENCY_REVISION)

func _required_extra_mw(power_pct: float) -> float:
    if power_pct >= 99.5 or power_pct <= 0.0:
        return 0.0
    var deployed_mw := float(player.get("power_mw", 0.0))
    if deployed_mw <= 0.0:
        return 0.0
    var service_ratio := clampf(power_pct / 100.0, 0.01, 1.0)
    var estimated_demand_mw := deployed_mw / service_ratio
    return maxf(0.0, estimated_demand_mw - deployed_mw)

func _turn_action_hint(power_pct: float, ending_cash: float, power_cost: float) -> String:
    if power_pct < 99.5:
        var extra_mw := _required_extra_mw(power_pct)
        var mw_hint := "add/deploy MW"
        if extra_mw > 0.05:
            mw_hint = "add/deploy about %.1f MW" % extra_mw
        if ending_cash < 0.0:
            return "ACTION: %s and protect cash before confirming" % mw_hint
        return "ACTION: open ENERGY/INFRASTRUCTURE and %s" % mw_hint
    return super._turn_action_hint(power_pct, ending_cash, power_cost)

func debug_v100_ready() -> bool:
    return V100_TURN_EFFICIENCY_REVISION == 1 and _required_extra_mw(100.0) == 0.0 and has_method("_scaled_financial_preview")
