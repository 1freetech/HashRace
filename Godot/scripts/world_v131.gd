extends "res://scripts/world_v130.gd"

# Hash Race v0.131: live expansion headroom planning.
# Turns existing electrical capacity math into an immediately useful mining
# decision: how much additional load and how many reference ASICs fit before
# the operator must add power. This does not auto-buy hardware or bypass the
# existing curtailment rules; it makes the next expansion decision readable.

const V131_CAPACITY_PLANNER_REVISION := 1
const V131_REFERENCE_ASIC_KW := 3.5

func expansion_headroom_plan(load_mw: float = -1.0, capacity_mw: float = -1.0) -> Dictionary:
    var active_load := maxf(0.0, _machine_load_kw() / 1000.0) if load_mw < 0.0 else maxf(0.0, load_mw)
    var active_capacity := maxf(0.0, _effective_available_mw()) if capacity_mw < 0.0 else maxf(0.0, capacity_mw)
    var action := site_capacity_action(active_load, active_capacity)
    var headroom_mw := maxf(0.0, float(action.get("headroom_mw", 0.0)))
    var reference_miners := int(floor(headroom_mw * 1000.0 / V131_REFERENCE_ASIC_KW))
    return {
        "load_mw": active_load,
        "capacity_mw": active_capacity,
        "headroom_mw": headroom_mw,
        "reference_miners": reference_miners,
        "action": String(action.get("action", "KEEP MINING")),
        "over_capacity": float(action.get("curtail_mw", 0.0)) > 0.0,
    }

func expansion_headroom_summary() -> String:
    var plan := expansion_headroom_plan()
    if bool(plan["over_capacity"]):
        return String(plan["action"])
    return "EXPANSION ROOM %.1f MW | ~%d x 3.5 kW ASICs" % [float(plan["headroom_mw"]), int(plan["reference_miners"])]

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)
    _v131_draw_capacity_board(origin + Vector2(310.0, -176.0))

func _v131_draw_capacity_board(center: Vector2) -> void:
    var plan := expansion_headroom_plan()
    var overloaded := bool(plan["over_capacity"])
    var accent := Color("ff6b6b") if overloaded else Color("39ff75")
    var panel := Rect2(center - Vector2(112.0, 27.0), Vector2(224.0, 54.0))
    draw_rect(panel, Color("071016"), true)
    draw_rect(panel, accent, false, 2.0)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 16.0), "SITE CAPACITY", HORIZONTAL_ALIGNMENT_LEFT, 206.0, 9, accent)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 34.0), expansion_headroom_summary(), HORIZONTAL_ALIGNMENT_LEFT, 206.0, 8, Color("d8edf2"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 48.0), "LOAD %.1f / %.1f MW" % [float(plan["load_mw"]), float(plan["capacity_mw"])], HORIZONTAL_ALIGNMENT_LEFT, 206.0, 7, Color("7896a8"))

func debug_v131_ready() -> bool:
    var healthy := expansion_headroom_plan(5.0, 10.0)
    var overloaded := expansion_headroom_plan(12.0, 10.0)
    return V131_CAPACITY_PLANNER_REVISION == 1 \
        and is_equal_approx(float(healthy["headroom_mw"]), 5.0) \
        and int(healthy["reference_miners"]) == 1428 \
        and not bool(healthy["over_capacity"]) \
        and bool(overloaded["over_capacity"]) \
        and String(overloaded["action"]) == "CURTAIL 2.0 MW" \
        and debug_v130_ready()
