extends "res://scripts/world_v130.gd"

# Hash Race v0.131: mining-site capacity planning.
# Converts the existing power/load simulation into a readable expansion decision
# before the player buys another batch of ASICs.

const V131_CAPACITY_PLANNER_REVISION := 2
const V131_REFERENCE_ASIC_KW := 3.5

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v131_capacity_planner_revision", V131_CAPACITY_PLANNER_REVISION)
    set_meta("hashrace_v131_capacity_planner_live", true)
    queue_redraw()

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)
    _v131_draw_capacity_planner(origin + Vector2(238.0, -154.0))

func _v131_capacity_snapshot() -> Dictionary:
    var load_mw := maxf(0.0, _machine_load_kw() / 1000.0)
    var capacity_mw := maxf(0.0, _effective_available_mw())
    var headroom_mw := maxf(0.0, capacity_mw - load_mw)
    var overload_mw := maxf(0.0, load_mw - capacity_mw)
    var reference_asic_count := int(floor(headroom_mw * 1000.0 / V131_REFERENCE_ASIC_KW))
    return {
        "load_mw": load_mw,
        "capacity_mw": capacity_mw,
        "headroom_mw": headroom_mw,
        "overload_mw": overload_mw,
        "reference_asic_count": reference_asic_count,
    }

func _v131_draw_capacity_planner(center: Vector2) -> void:
    var snapshot := _v131_capacity_snapshot()
    var panel := Rect2(center - Vector2(96.0, 50.0), Vector2(192.0, 100.0))
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
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 92.0), "PLAN POWER BEFORE HARDWARE", HORIZONTAL_ALIGNMENT_LEFT, 174.0, 8, Color("91a8b0"))

func debug_v131_ready() -> bool:
    var snapshot := _v131_capacity_snapshot()
    return V131_CAPACITY_PLANNER_REVISION == 2 \
        and V131_REFERENCE_ASIC_KW > 0.0 \
        and snapshot.has("headroom_mw") \
        and snapshot.has("reference_asic_count") \
        and debug_v130_ready()
