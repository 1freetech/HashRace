extends "res://scripts/world_v136.gd"

# Hash Race v0.137: prevent the advisor from recommending ASIC purchases when
# a large site is already operating too close to its electrical ceiling.

const V137_RESERVE_GUARD_REVISION := 1
const V137_MAX_BUY_UTILIZATION := 90.0

func _v132_capacity_advice(snapshot: Dictionary) -> String:
    var overload_mw := float(snapshot.get("overload_mw", 0.0))
    var headroom_mw := float(snapshot.get("headroom_mw", 0.0))
    var utilization := _v136_utilization(snapshot)
    var safe_batch := _v133_safe_asic_batch(snapshot)
    if overload_mw > 0.001:
        return "ACTION: CURTAIL LOAD"
    if utilization >= V137_MAX_BUY_UTILIZATION:
        return "ACTION: EXPAND POWER"
    if headroom_mw < V132_LOW_HEADROOM_MW or safe_batch < 8:
        return "ACTION: EXPAND POWER"
    return "ACTION: BUY UP TO %d ASICs" % safe_batch

func debug_v137_ready() -> bool:
    var large_tight := {"load_mw": 9.2, "capacity_mw": 10.0, "overload_mw": 0.0, "headroom_mw": 0.8, "reference_asic_count": 228}
    var healthy := {"load_mw": 7.0, "capacity_mw": 10.0, "overload_mw": 0.0, "headroom_mw": 3.0, "reference_asic_count": 857}
    return V137_RESERVE_GUARD_REVISION == 1 \
        and _v132_capacity_advice(large_tight) == "ACTION: EXPAND POWER" \
        and _v132_capacity_advice(healthy).begins_with("ACTION: BUY UP TO") \
        and debug_v136_ready()
