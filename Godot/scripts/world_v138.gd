extends "res://scripts/world_v129.gd"

# Hash Race v0.138 recovery baseline.
# v0.129 is the last verified public desktop release. This file deliberately
# collapses the post-v0.129 gameplay work into one live layer instead of
# inheriting through v0.130-v0.137. New releases should build forward from this
# recovery baseline rather than restoring the broken version-per-file chain.

const V138_RECOVERY_REVISION := 1
const V138_REFERENCE_ASIC_KW := 3.5
const V138_RESERVE_RATIO := 0.10
const V138_LOW_HEADROOM_MW := 0.25
const V138_MAX_BUY_UTILIZATION := 90.0
const V138_FAB_SCALE := 1.22
const V138_MINING_COMPANIES := [
    "VantaGrid Mining",
    "NeonForge Mining",
    "ArcShift Mining",
    "IronVector Mining",
    "Meridian Zero Mining",
    "BlueNova Mining",
    "SignalFlux Mining",
    "Parallax Core Mining",
    "LatticeX Mining",
    "Epoch Vector Mining",
]

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v138_recovery_live", true)
    queue_redraw()

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)
    _v138_draw_capacity_planner(origin + Vector2(238.0, -154.0))

func _v138_capacity_snapshot() -> Dictionary:
    var load_mw := maxf(0.0, _machine_load_kw() / 1000.0)
    var capacity_mw := maxf(0.0, _effective_available_mw())
    var headroom_mw := maxf(0.0, capacity_mw - load_mw)
    var overload_mw := maxf(0.0, load_mw - capacity_mw)
    return {
        "load_mw": load_mw,
        "capacity_mw": capacity_mw,
        "headroom_mw": headroom_mw,
        "overload_mw": overload_mw,
        "reference_asic_count": int(floor(headroom_mw * 1000.0 / V138_REFERENCE_ASIC_KW)),
    }

func _v138_utilization(snapshot: Dictionary) -> float:
    var capacity := maxf(0.0, float(snapshot.get("capacity_mw", 0.0)))
    var load := maxf(0.0, float(snapshot.get("load_mw", 0.0)))
    if capacity <= 0.0001:
        return 100.0 if load > 0.0 else 0.0
    return load / capacity * 100.0

func _v138_risk_band(utilization: float) -> String:
    if utilization >= 100.0:
        return "OVERLOAD"
    if utilization >= 90.0:
        return "TIGHT"
    if utilization >= 75.0:
        return "WATCH"
    return "HEALTHY"

func _v138_safe_asic_batch(snapshot: Dictionary) -> int:
    if float(snapshot.get("overload_mw", 0.0)) > 0.001:
        return 0
    var headroom_mw := maxf(0.0, float(snapshot.get("headroom_mw", 0.0)))
    var usable_kw := headroom_mw * 1000.0 * (1.0 - V138_RESERVE_RATIO)
    return maxi(0, int(floor(usable_kw / V138_REFERENCE_ASIC_KW)))

func _v138_capacity_advice(snapshot: Dictionary) -> String:
    if float(snapshot.get("overload_mw", 0.0)) > 0.001:
        return "ACTION: CURTAIL LOAD"
    var utilization := _v138_utilization(snapshot)
    var safe_batch := _v138_safe_asic_batch(snapshot)
    if utilization >= V138_MAX_BUY_UTILIZATION:
        return "ACTION: EXPAND POWER"
    if float(snapshot.get("headroom_mw", 0.0)) < V138_LOW_HEADROOM_MW or safe_batch < 8:
        return "ACTION: EXPAND POWER"
    return "ACTION: BUY UP TO %d ASICs" % safe_batch

func _v138_draw_capacity_planner(center: Vector2) -> void:
    var snapshot := _v138_capacity_snapshot()
    var utilization := _v138_utilization(snapshot)
    var panel := Rect2(center - Vector2(102.0, 66.0), Vector2(204.0, 132.0))
    draw_rect(panel, Color("071016cc"), true)
    draw_rect(panel, Color("39ff75"), false, 2.0)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 16.0), "SITE CAPACITY", HORIZONTAL_ALIGNMENT_LEFT, 186.0, 11, Color("80ff9b"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 34.0), "LOAD %.2f / %.2f MW" % [snapshot.load_mw, snapshot.capacity_mw], HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("d8edf2"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 50.0), "UTILIZATION %.0f%%  %s" % [utilization, _v138_risk_band(utilization)], HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("ffb36b") if utilization >= 90.0 else Color("d8edf2"))
    if snapshot.overload_mw > 0.001:
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 68.0), "CURTAIL %.2f MW" % snapshot.overload_mw, HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("ffb36b"))
    else:
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 68.0), "HEADROOM %.2f MW" % snapshot.headroom_mw, HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("d8edf2"))
        draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 86.0), "~%d x 3.5 kW ASICs FIT" % snapshot.reference_asic_count, HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("39ff75"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 106.0), _v138_capacity_advice(snapshot), HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("80ff9b"))
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(9.0, 123.0), "KEEP ELECTRICAL RESERVE", HORIZONTAL_ALIGNMENT_LEFT, 186.0, 8, Color("91a8b0"))

func _draw_partner_building(entity: Dictionary, idx: int) -> void:
    var partner_idx := int(entity.get("partner_idx", -1))
    if partner_idx != 3 or v116_fab_texture == null:
        super._draw_partner_building(entity, idx)
        return
    var pos: Vector2 = entity["pos"]
    var accent: Color = PARTNER_ACCENTS[partner_idx]
    var size_value := _v103_visual_size(pos, WorldScale.PARTNER_SIZE, "partner") * V138_FAB_SCALE
    _selection_ring(pos, idx, WorldScale.selection_radius("partner") * V138_FAB_SCALE)
    _v103_draw_building_shadow(pos, size_value)
    var cell := Vector2(
        float(v116_fab_texture.get_width()) / float(V116_FAB_GRID.x),
        float(v116_fab_texture.get_height()) / float(V116_FAB_GRID.y)
    )
    var src := Rect2(
        Vector2(float(V116_FAB_DOWN_FRAME.x) * cell.x, float(V116_FAB_DOWN_FRAME.y) * cell.y),
        cell
    )
    var dest := Rect2(
        VisualStack.snap_to_pixel(pos + Vector2(-size_value.x * 0.5, -size_value.y * 0.62)),
        size_value
    )
    draw_texture_rect_region(v116_fab_texture, dest, src)
    _draw_building_name(entity, idx, accent, size_value.y * 0.39 + 34.0, size_value.x + 34.0)

func debug_v138_ready() -> bool:
    var tight := {"load_mw": 9.2, "capacity_mw": 10.0, "overload_mw": 0.0, "headroom_mw": 0.8}
    var healthy := {"load_mw": 7.0, "capacity_mw": 10.0, "overload_mw": 0.0, "headroom_mw": 3.0}
    return V138_RECOVERY_REVISION == 1 \
        and V138_MINING_COMPANIES.size() == 10 \
        and _v138_capacity_advice(tight) == "ACTION: EXPAND POWER" \
        and _v138_capacity_advice(healthy).begins_with("ACTION: BUY UP TO") \
        and debug_v129_ready()
