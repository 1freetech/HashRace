extends "res://scripts/world_v104.gd"

# Hash Race v0.105 blackout-capacity guidance fix.
# A 0% service preview is the most severe shortage, but the inherited helper
# returned 0 MW because it treated zero service as an invalid ratio. Use the
# fleet's full electrical load as the recovery target when service is zero.

const V105_BLACKOUT_TARGET_REVISION := 1

func _additional_mw_for_load(power_pct: float, load_mw: float) -> float:
    if power_pct >= 99.5 or load_mw <= 0.0:
        return 0.0
    if power_pct <= 0.0:
        return load_mw
    var service_ratio := clampf(power_pct / 100.0, 0.0, 1.0)
    return maxf(0.0, load_mw * (1.0 - service_ratio))

func debug_v105_ready() -> bool:
    return (
        V105_BLACKOUT_TARGET_REVISION == 1
        and debug_v104_ready()
        and is_equal_approx(_additional_mw_for_load(0.0, 10.0), 10.0)
        and is_equal_approx(_additional_mw_for_load(80.0, 10.0), 2.0)
        and _additional_mw_for_load(100.0, 10.0) == 0.0
    )
