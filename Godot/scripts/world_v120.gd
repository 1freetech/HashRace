extends "res://scripts/world_v119.gd"

# Hash Race v0.120 actionable capacity response.
# Site warnings now tell the Bitcoin-mining operator exactly how much deployed
# load can remain online and how much must be curtailed before the next turn.

const V120_CURTAILMENT_REVISION := 1

func site_capacity_action(load_mw: float, capacity_mw: float) -> Dictionary:
    var state := _v118_site_utilization_state(load_mw, capacity_mw)
    var safe_load := float(state["load_mw"])
    var safe_capacity := float(state["capacity_mw"])
    var curtail_mw := maxf(0.0, safe_load - safe_capacity)
    var online_mw := minf(safe_load, safe_capacity)
    var curtail_percent := 0.0
    if safe_load > 0.0:
        curtail_percent = (curtail_mw / safe_load) * 100.0

    var action := "KEEP MINING"
    var status := String(state["status"])
    if status == "NO POWER":
        action = "CURTAIL ALL MINERS"
    elif status == "OVER CAPACITY":
        action = "CURTAIL %.1f MW" % curtail_mw
    elif status == "EXPAND NOW":
        action = "ADD POWER BEFORE NEXT EXPANSION"
    elif status == "PLAN EXPANSION":
        action = "PLAN NEXT POWER BLOCK"

    return {
        "status": status,
        "action": action,
        "load_mw": safe_load,
        "capacity_mw": safe_capacity,
        "online_mw": online_mw,
        "curtail_mw": curtail_mw,
        "curtail_percent": curtail_percent,
        "headroom_mw": float(state["headroom_mw"]),
    }

func site_capacity_action_summary(load_mw: float = -1.0, capacity_mw: float = -1.0) -> String:
    var active_load := load_mw
    if active_load < 0.0:
        active_load = maxf(0.0, _machine_load_kw() / 1000.0)
    var active_capacity := capacity_mw
    if active_capacity < 0.0:
        active_capacity = _v118_effective_site_capacity_mw()
    var plan := site_capacity_action(active_load, active_capacity)
    if float(plan["curtail_mw"]) > 0.0:
        return "%s | %.1f MW online | %.1f MW curtailed (%.0f%%)" % [String(plan["action"]), float(plan["online_mw"]), float(plan["curtail_mw"]), float(plan["curtail_percent"])]
    return "%s | %.1f MW headroom" % [String(plan["action"]), float(plan["headroom_mw"])]

func debug_v120_ready() -> bool:
    var overloaded := site_capacity_action(12.0, 10.0)
    var powerless := site_capacity_action(5.0, 0.0)
    var healthy := site_capacity_action(5.0, 10.0)
    return V120_CURTAILMENT_REVISION == 1 \
        and String(overloaded["action"]) == "CURTAIL 2.0 MW" \
        and is_equal_approx(float(overloaded["online_mw"]), 10.0) \
        and is_equal_approx(float(overloaded["curtail_percent"]), 16.6666667) \
        and String(powerless["action"]) == "CURTAIL ALL MINERS" \
        and is_equal_approx(float(powerless["curtail_mw"]), 5.0) \
        and String(healthy["action"]) == "KEEP MINING" \
        and debug_v119_ready()
