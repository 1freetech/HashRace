extends "res://scripts/world_v135.gd"

# Hash Race v0.136: make site-capacity risk readable at a glance.
# Adds utilization percentage and a risk band to the existing MW planner.

const V136_UTILIZATION_REVISION := 1

func _v136_utilization(snapshot: Dictionary) -> float:
    var capacity := maxf(0.0, float(snapshot.get("capacity_mw", 0.0)))
    var load := maxf(0.0, float(snapshot.get("load_mw", 0.0)))
    if capacity <= 0.0001:
        return 100.0 if load > 0.0 else 0.0
    return load / capacity * 100.0

func _v136_risk_band(utilization: float) -> String:
    if utilization >= 100.0:
        return "OVERLOAD"
    if utilization >= 90.0:
        return "TIGHT"
    if utilization >= 75.0:
        return "WATCH"
    return "HEALTHY"

func _v131_draw_capacity_planner(center: Vector2) -> void:
    var snapshot := _v131_capacity_snapshot()
    var utilization := _v136_utilization(snapshot)
    var panel := Rect2(center - Vector2(102.0, 66.0), Vector2(204.0, 132.0))
    draw_rect(panel, Color("071016cc"), true)
    draw_rect(panel, Color("39ff75"), false, 2.0)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 16.0), "SITE CAPACITY", HORIZONTAL_ALIGNMENT_LEFT, 186.0, 11, Color("80ff9b"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 34.0), "LOAD %.2f / %.2f MW" % [snapshot.load_mw, snapshot.capacity_mw], HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("d8edf2"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 50.0), "UTILIZATION %.0f%%  %s" % [utilization, _v136_risk_band(utilization)], HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("ffb36b") if utilization >= 90.0 else Color("d8edf2"))
    if snapshot.overload_mw > 0.001:
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 68.0), "CURTAIL %.2f MW" % snapshot.overload_mw, HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("ffb36b"))
    else:
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 68.0), "HEADROOM %.2f MW" % snapshot.headroom_mw, HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("d8edf2"))
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 86.0), "~%d x 3.5 kW ASICs FIT" % snapshot.reference_asic_count, HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("39ff75"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 106.0), _v132_capacity_advice(snapshot), HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("80ff9b"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 123.0), "KEEP ELECTRICAL RESERVE", HORIZONTAL_ALIGNMENT_LEFT, 186.0, 8, Color("91a8b0"))

func debug_v136_ready() -> bool:
    return V136_UTILIZATION_REVISION == 1 \
        and is_equal_approx(_v136_utilization({"load_mw": 0.75, "capacity_mw": 1.0}), 75.0) \
        and _v136_risk_band(74.9) == "HEALTHY" \
        and _v136_risk_band(90.0) == "TIGHT" \
        and _v136_risk_band(100.0) == "OVERLOAD" \
        and debug_v135_ready()
