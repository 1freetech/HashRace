extends "res://scripts/world_v118.gd"

# Hash Race v0.119 zero-capacity safety fix.
# A powered-down mining site with deployed load must never look READY simply
# because utilization cannot be divided by zero.

const V119_ZERO_CAPACITY_REVISION := 1

func _v118_site_utilization_state(load_mw: float, capacity_mw: float) -> Dictionary:
    var safe_load := maxf(0.0, load_mw)
    var safe_capacity := maxf(0.0, capacity_mw)
    var ratio := 0.0
    if safe_capacity > 0.0:
        ratio = safe_load / safe_capacity
    elif safe_load > 0.0:
        ratio = INF

    var status := "READY"
    if safe_load > 0.0 and safe_capacity <= 0.0:
        status = "NO POWER"
    elif ratio >= 1.0:
        status = "OVER CAPACITY"
    elif ratio >= 0.90:
        status = "EXPAND NOW"
    elif ratio >= 0.75:
        status = "PLAN EXPANSION"

    return {
        "load_mw": safe_load,
        "capacity_mw": safe_capacity,
        "ratio": ratio,
        "headroom_mw": maxf(0.0, safe_capacity - safe_load),
        "overload_mw": maxf(0.0, safe_load - safe_capacity),
        "status": status,
    }

func debug_v119_ready() -> bool:
    var idle := _v118_site_utilization_state(0.0, 0.0)
    var powerless := _v118_site_utilization_state(5.0, 0.0)
    var normal := _v118_site_utilization_state(5.0, 10.0)
    return V119_ZERO_CAPACITY_REVISION == 1 \
        and String(idle["status"]) == "READY" \
        and String(powerless["status"]) == "NO POWER" \
        and is_inf(float(powerless["ratio"])) \
        and is_equal_approx(float(powerless["overload_mw"]), 5.0) \
        and String(normal["status"]) == "READY" \
        and debug_v118_ready()
