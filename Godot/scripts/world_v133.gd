extends "res://scripts/world_v132.gd"

# Hash Race v0.133: make capacity advice actionable with an exact safe batch size.
# The advisor now recommends a conservative ASIC purchase quantity while keeping
# a 10% electrical reserve so normal load variation does not immediately overload the site.

const V133_CAPACITY_BATCH_REVISION := 1
const V133_RESERVE_RATIO := 0.10

func _v133_safe_asic_batch(snapshot: Dictionary) -> int:
    var headroom_mw := maxf(0.0, float(snapshot.get("headroom_mw", 0.0)))
    var overload_mw := maxf(0.0, float(snapshot.get("overload_mw", 0.0)))
    if overload_mw > 0.001:
        return 0
    var usable_kw := headroom_mw * 1000.0 * (1.0 - V133_RESERVE_RATIO)
    return maxi(0, int(floor(usable_kw / V131_REFERENCE_ASIC_KW)))

func _v132_capacity_advice(snapshot: Dictionary) -> String:
    var overload_mw := float(snapshot.get("overload_mw", 0.0))
    var headroom_mw := float(snapshot.get("headroom_mw", 0.0))
    var safe_batch := _v133_safe_asic_batch(snapshot)
    if overload_mw > 0.001:
        return "ACTION: CURTAIL LOAD"
    if headroom_mw < V132_LOW_HEADROOM_MW or safe_batch < 8:
        return "ACTION: EXPAND POWER"
    return "ACTION: BUY UP TO %d ASICs" % safe_batch

func debug_v133_ready() -> bool:
    var safe := {"overload_mw": 0.0, "headroom_mw": 1.0, "reference_asic_count": 285}
    var tight := {"overload_mw": 0.0, "headroom_mw": 0.02, "reference_asic_count": 5}
    var overloaded := {"overload_mw": 0.5, "headroom_mw": 0.0, "reference_asic_count": 0}
    return V133_CAPACITY_BATCH_REVISION == 1 \
        and _v133_safe_asic_batch(safe) == 257 \
        and _v133_safe_asic_batch(overloaded) == 0 \
        and _v132_capacity_advice(safe) == "ACTION: BUY UP TO 257 ASICs" \
        and _v132_capacity_advice(tight) == "ACTION: EXPAND POWER" \
        and _v132_capacity_advice(overloaded) == "ACTION: CURTAIL LOAD" \
        and debug_v132_ready()
