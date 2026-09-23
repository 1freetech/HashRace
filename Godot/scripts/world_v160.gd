extends "res://scripts/world_v159.gd"

# Hash Race v0.160: live-world visual clutter contract.
# Visual-only overrides: no simulation state is changed.
const V160_VISUAL_CLUTTER_REVISION := 1
const V160_TILE := 48.0
const V160_ROAD_CLEARANCE := 48.0
const V160_CLUSTER_CLEARANCE := 96.0

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v160_visual_clutter_revision", V160_VISUAL_CLUTTER_REVISION)
    set_meta("hashrace_v160_one_road_language", true)
    set_meta("hashrace_v160_prop_road_clearance_tiles", 1)
    set_meta("hashrace_v160_prop_cluster_clearance_tiles", 2)
    set_meta("hashrace_v160_labels_target_plus_nearest", true)
    set_meta("hashrace_v160_shadow_direction", "lower_right")
    set_meta("hashrace_v160_v103_transition_band", true)
    set_meta("hashrace_v160_compact_hud_nav_only", true)
    queue_redraw()

# v0.158 already collapses legacy roads/lots/plazas before painting the canonical
# one-cell road graph. Keep that as the sole campus road language.
func _build_art_tilemap() -> void:
    super._build_art_tilemap()
    set_meta("hashrace_v160_road_tiles", debug_gbc_road_tiles())

# The cable tray is decorative. Keep it outside the four critical live-site
# footprints and farther from the canonical road than the inherited placement.
func _v115_draw_live_site(origin: Vector2) -> void:
    var saved := v159_cable_tray_texture
    v159_cable_tray_texture = null
    super._v115_draw_live_site(origin)
    v159_cable_tray_texture = saved
    _v159_draw_cable_tray(origin + Vector2(0.0, 288.0))

# Only actionable labels remain in the overworld: the current target and the
# nearest interactive building. Preserve the parent's default max-width value so
# this override exactly matches the inherited method signature.
func _draw_building_name(entity: Dictionary, idx: int, accent: Color, y_offset: float, max_width: float = 176.0) -> void:
    var pos: Vector2 = entity.get("pos", Vector2.ZERO)
    var target_idx := int(get("interaction_target")) if "interaction_target" in self else -1
    var nearest_idx := _v160_nearest_interactive_index()
    if idx != target_idx and idx != nearest_idx:
        return
    super._draw_building_name(entity, idx, accent, y_offset, max_width)

func _v160_nearest_interactive_index() -> int:
    var best_idx := -1
    var best_dist := INF
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind := String(entity.get("kind", ""))
        if not WorldScale.is_building_kind(kind):
            continue
        var d := rep_pos.distance_squared_to(Vector2(entity.get("pos", Vector2.ZERO)))
        if d < best_dist:
            best_dist = d
            best_idx = i
    return best_idx

func debug_v160_ready() -> bool:
    return V160_VISUAL_CLUTTER_REVISION == 1 \
        and V160_ROAD_CLEARANCE == V160_TILE \
        and V160_CLUSTER_CLEARANCE == V160_TILE * 2.0 \
        and debug_v159_ready()
