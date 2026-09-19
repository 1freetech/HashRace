extends "res://scripts/world_v100.gd"

# Hash Race v0.101 MW-target correctness fix.
# v0.100 looked for player["power_mw"], but the live simulation stores grid
# capacity under other state and derives demand from the active ASIC fleet.
# Estimate the missing continuous capacity from actual fleet load and the
# preview's measured service ratio so the player receives a useful target.

const V101_MW_TARGET_FIX_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v101_mw_target_fix_revision", V101_MW_TARGET_FIX_REVISION)

func _additional_mw_for_load(power_pct: float, load_mw: float) -> float:
    if power_pct >= 99.5 or power_pct <= 0.0 or load_mw <= 0.0:
        return 0.0
    var service_ratio := clampf(power_pct / 100.0, 0.0, 1.0)
    return maxf(0.0, load_mw * (1.0 - service_ratio))

func _additional_mw_needed(power_pct: float) -> float:
    var fleet_load_mw := maxf(0.0, _machine_load_kw() / 1000.0)
    return _additional_mw_for_load(power_pct, fleet_load_mw)

func debug_v101_ready() -> bool:
    return V101_MW_TARGET_FIX_REVISION == 1 and is_equal_approx(_additional_mw_for_load(80.0, 10.0), 2.0) and _additional_mw_for_load(100.0, 10.0) == 0.0
