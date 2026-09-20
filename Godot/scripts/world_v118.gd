extends "res://scripts/world_v117.gd"

# Hash Race v0.118 mining-site utilization feedback.
# The physical site now tells the player how much of its electrical capacity is
# actually occupied by deployed mining load, turning visual growth into a useful
# expansion signal instead of decoration only.

const V118_SITE_UTILIZATION_REVISION := 1

func _v118_site_utilization_state(load_mw: float, capacity_mw: float) -> Dictionary:
    var safe_load := maxf(0.0, load_mw)
    var safe_capacity := maxf(0.0, capacity_mw)
    var ratio := 0.0
    if safe_capacity > 0.0:
        ratio = safe_load / safe_capacity
    var status := "READY"
    if ratio >= 1.0:
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

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)

    var load_mw := maxf(0.0, _machine_load_kw() / 1000.0)
    var capacity_mw := maxf(0.0, _effective_available_mw())
    var state := _v118_site_utilization_state(load_mw, capacity_mw)
    var ratio := float(state["ratio"])
    var fill_ratio := clampf(ratio, 0.0, 1.0)

    # One compact world-space meter beneath the site. It is intentionally much
    # smaller than the site pad and replaces no navigation or Mining Ops UI.
    var panel_size := Vector2(360.0, 48.0)
    var panel_pos := origin + Vector2(-panel_size.x * 0.5, 238.0)
    var panel := Rect2(panel_pos, panel_size)
    draw_rect(panel, Color(0.03, 0.06, 0.08, 0.92), true)
    draw_rect(panel, Color("52636a"), false, 1.0)

    var bar := Rect2(panel.position + Vector2(12.0, 27.0), Vector2(panel.size.x - 24.0, 9.0))
    draw_rect(bar, Color("172126"), true)
    var status := String(state["status"])
    var meter_color := Color("39ff75")
    if status == "PLAN EXPANSION":
        meter_color = Color("f0c94a")
    elif status == "EXPAND NOW":
        meter_color = Color("ff8a3d")
    elif status == "OVER CAPACITY":
        meter_color = Color("ff4f5e")
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * fill_ratio, bar.size.y)), meter_color, true)

    var detail := "HEADROOM %.1f MW" % float(state["headroom_mw"])
    if float(state["overload_mw"]) > 0.0:
        detail = "OVERLOAD %.1f MW" % float(state["overload_mw"])
    draw_string(
        ThemeDB.fallback_font,
        panel.position + Vector2(12.0, 18.0),
        "MINING LOAD %.1f / %.1f MW • %.0f%% • %s • %s" % [
            load_mw,
            capacity_mw,
            ratio * 100.0,
            status,
            detail,
        ],
        HORIZONTAL_ALIGNMENT_LEFT,
        panel.size.x - 24.0,
        10,
        Color("d7e1e3")
    )

func debug_v118_ready() -> bool:
    var ready := _v118_site_utilization_state(5.0, 10.0)
    var planning := _v118_site_utilization_state(8.0, 10.0)
    var urgent := _v118_site_utilization_state(9.5, 10.0)
    var overloaded := _v118_site_utilization_state(12.0, 10.0)
    return V118_SITE_UTILIZATION_REVISION == 1 \
        and String(ready["status"]) == "READY" \
        and String(planning["status"]) == "PLAN EXPANSION" \
        and String(urgent["status"]) == "EXPAND NOW" \
        and String(overloaded["status"]) == "OVER CAPACITY" \
        and is_equal_approx(float(overloaded["overload_mw"]), 2.0) \
        and debug_v117_ready()
