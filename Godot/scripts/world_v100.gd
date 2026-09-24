extends "res://scripts/world_v099.gd"

# Hash Race v0.100 power-capacity target guidance.
# Convert an existing service shortfall into an approximate MW target so the
# player knows how much infrastructure to add before confirming settlement.

const V100_MW_TARGET_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v100_mw_target_revision", V100_MW_TARGET_REVISION)

func _additional_mw_needed(power_pct: float) -> float:
    if power_pct >= 99.5 or power_pct <= 0.0:
        return 0.0
    var deployed_mw := maxf(0.0, float(player.get("power_mw", 0.0)))
    if deployed_mw <= 0.0:
        return 0.0
    var service_ratio := clampf(power_pct / 100.0, 0.01, 1.0)
    var required_mw := deployed_mw / service_ratio
    return maxf(0.0, required_mw - deployed_mw)

func _turn_action_hint(power_pct: float, ending_cash: float, power_cost: float) -> String:
    if power_pct < 99.5:
        var extra_mw := _additional_mw_needed(power_pct)
        var target := ""
        if extra_mw > 0.0:
            target = " (~%.1f MW more)" % extra_mw
        if ending_cash < 0.0:
            return "ACTION: add/deploy MW%s and protect cash before confirming" % target
        return "ACTION: open ENERGY/INFRASTRUCTURE and add or deploy MW%s" % target
    return super._turn_action_hint(power_pct, ending_cash, power_cost)

func debug_v100_ready() -> bool:
    return V100_MW_TARGET_REVISION == 1 and _additional_mw_needed(80.0) >= 0.0 and _turn_action_hint(90.0, 100000.0, 10000.0).contains("MW")
