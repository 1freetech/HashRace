extends "res://scripts/world_v131.gd"

# Hash Race v0.132: capacity planner now recommends the next concrete action.
# This turns the read-only MW panel into a gameplay decision aid without
# duplicating the underlying power/load simulation.

const V132_CAPACITY_ADVISOR_REVISION := 1
const V132_LOW_HEADROOM_MW := 0.25

func _v132_capacity_advice(snapshot: Dictionary) -> String:
    var overload_mw := float(snapshot.get("overload_mw", 0.0))
    var headroom_mw := float(snapshot.get("headroom_mw", 0.0))
    var asics := int(snapshot.get("reference_asic_count", 0))
    if overload_mw > 0.001:
        return "ACTION: CURTAIL LOAD"
    if headroom_mw < V132_LOW_HEADROOM_MW or asics < 8:
        return "ACTION: EXPAND POWER"
    return "ACTION: ASIC BUY IS SAFE"

func _v131_draw_capacity_planner(center: Vector2) -> void:
    var snapshot := _v131_capacity_snapshot()
    var panel := Rect2(center - Vector2(96.0, 58.0), Vector2(192.0, 116.0))
    draw_rect(panel, Color("071016cc"), true)
    draw_rect(panel, Color("39ff75"), false, 2.0)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 16.0), "SITE CAPACITY", HORIZONTAL_ALIGNMENT_LEFT, 174.0, 11, Color("80ff9b"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 34.0), "LOAD %.2f MW / POWER %.2f MW" % [snapshot.load_mw, snapshot.capacity_mw], HORIZONTAL_ALIGNMENT_LEFT, 174.0, 9, Color("d8edf2"))
    if snapshot.overload_mw > 0.001:
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 54.0), "CURTAIL %.2f MW BEFORE EXPANDING" % snapshot.overload_mw, HORIZONTAL_ALIGNMENT_LEFT, 174.0, 8, Color("ffb36b"))
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 74.0), "NEW ASIC PURCHASES: HOLD", HORIZONTAL_ALIGNMENT_LEFT, 174.0, 9, Color("ffb36b"))
    else:
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 54.0), "HEADROOM %.2f MW" % snapshot.headroom_mw, HORIZONTAL_ALIGNMENT_LEFT, 174.0, 9, Color("d8edf2"))
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 74.0), "~%d x 3.5 kW ASICs FIT" % snapshot.reference_asic_count, HORIZONTAL_ALIGNMENT_LEFT, 174.0, 9, Color("39ff75"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 94.0), _v132_capacity_advice(snapshot), HORIZONTAL_ALIGNMENT_LEFT, 174.0, 9, Color("80ff9b"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 110.0), "PLAN POWER BEFORE HARDWARE", HORIZONTAL_ALIGNMENT_LEFT, 174.0, 8, Color("91a8b0"))

func debug_v132_ready() -> bool:
    var safe := {"overload_mw": 0.0, "headroom_mw": 1.0, "reference_asic_count": 285}
    var tight := {"overload_mw": 0.0, "headroom_mw": 0.02, "reference_asic_count": 5}
    var overloaded := {"overload_mw": 0.5, "headroom_mw": 0.0, "reference_asic_count": 0}
    return V132_CAPACITY_ADVISOR_REVISION == 1 \
        and _v132_capacity_advice(safe) == "ACTION: ASIC BUY IS SAFE" \
        and _v132_capacity_advice(tight) == "ACTION: EXPAND POWER" \
        and _v132_capacity_advice(overloaded) == "ACTION: CURTAIL LOAD" \
        and debug_v131_ready()
