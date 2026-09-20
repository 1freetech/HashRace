extends "res://scripts/world_v120.gd"

# Hash Race v0.121 operating-reserve gameplay.
# A mining site should not plan normal operations at 100% of nameplate power.
# Keep a 10% reserve for cooling, auxiliaries, transients, and operational risk.

const V121_OPERATING_RESERVE_REVISION := 1
const V121_RESERVE_PERCENT := 10.0

func site_operating_reserve_plan(load_mw: float, capacity_mw: float, reserve_percent: float = V121_RESERVE_PERCENT) -> Dictionary:
    var hard_plan := site_capacity_action(load_mw, capacity_mw)
    var safe_load := maxf(0.0, float(hard_plan["load_mw"]))
    var safe_capacity := maxf(0.0, float(hard_plan["capacity_mw"]))
    var safe_reserve_percent := clampf(reserve_percent, 0.0, 50.0)
    var reserve_mw := safe_capacity * (safe_reserve_percent / 100.0)
    var operating_limit_mw := maxf(0.0, safe_capacity - reserve_mw)
    var reserve_curtail_mw := maxf(0.0, safe_load - operating_limit_mw)
    var reserve_headroom_mw := maxf(0.0, operating_limit_mw - safe_load)

    var action := String(hard_plan["action"])
    var status := String(hard_plan["status"])
    if status != "NO POWER" and status != "OVER CAPACITY":
        if reserve_curtail_mw > 0.0:
            status = "RESERVE AT RISK"
            action = "CURTAIL %.1f MW FOR RESERVE" % reserve_curtail_mw
        elif reserve_headroom_mw <= maxf(0.25, operating_limit_mw * 0.05):
            status = "RESERVE TIGHT"
            action = "HOLD EXPANSION"

    return {
        "status": status,
        "action": action,
        "load_mw": safe_load,
        "capacity_mw": safe_capacity,
        "reserve_percent": safe_reserve_percent,
        "reserve_mw": reserve_mw,
        "operating_limit_mw": operating_limit_mw,
        "reserve_headroom_mw": reserve_headroom_mw,
        "reserve_curtail_mw": reserve_curtail_mw,
        "hard_curtail_mw": float(hard_plan["curtail_mw"]),
    }

func site_operating_reserve_summary(load_mw: float = -1.0, capacity_mw: float = -1.0) -> String:
    var active_load := load_mw
    if active_load < 0.0:
        active_load = maxf(0.0, _machine_load_kw() / 1000.0)
    var active_capacity := capacity_mw
    if active_capacity < 0.0:
        active_capacity = maxf(0.0, _effective_available_mw())
    var plan := site_operating_reserve_plan(active_load, active_capacity)
    return "%s | safe %.1f/%.1f MW | %.1f MW reserve" % [String(plan["action"]), float(plan["load_mw"]), float(plan["operating_limit_mw"]), float(plan["reserve_mw"])]

func debug_v121_ready() -> bool:
    var healthy := site_operating_reserve_plan(8.0, 10.0)
    var risky := site_operating_reserve_plan(9.5, 10.0)
    var overloaded := site_operating_reserve_plan(12.0, 10.0)
    return V121_OPERATING_RESERVE_REVISION == 1 \
        and is_equal_approx(float(healthy["operating_limit_mw"]), 9.0) \
        and String(healthy["action"]) == "KEEP MINING" \
        and String(risky["status"]) == "RESERVE AT RISK" \
        and is_equal_approx(float(risky["reserve_curtail_mw"]), 0.5) \
        and String(overloaded["action"]) == "CURTAIL 2.0 MW" \
        and debug_v120_ready()
