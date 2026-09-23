extends "res://scripts/world_v159.gd"

# Hash Race v0.160: live-world visual clutter contract.
# Visual-only overrides: no simulation state is changed.
const V160_VISUAL_CLUTTER_REVISION := 1
const V160_TILE := 48.0
const V160_ROAD_CLEARANCE := 48.0
const V160_CLUSTER_CLEARANCE := 96.0
const V160SubstationSprite = preload("res://scripts/substation_transformer_sprite.gd")

var v160_transformer_texture: Texture2D
var v160_late_transformer_rect: Rect2 = Rect2()
var v160_transformer_late: bool = false

func _ready() -> void:
    # Load before inherited _ready: image decoding must precede the world draw.
    v160_transformer_texture = V160SubstationSprite.texture()
    super._ready()
    _v160_register_transformer_footprint()
    set_meta("hashrace_v160_real_transformer_sprite_live", V160SubstationSprite.valid_texture(v160_transformer_texture))
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


# Replace the inherited v0.114 procedural transformer, not its simulation or
# the v0.114 capacity-tier mapping. One 80x72 transparent PNG comes from the
# actual HashRace Library electrical-substation rear elevation.
func _v114_draw_transformer(pos: Vector2, capacity_mw: float) -> void:
    if not V160SubstationSprite.valid_texture(v160_transformer_texture):
        push_error("HASH RACE TRANSFORMER SPRITE FAIL: missing/invalid authored PNG")
        return
    var destination := V160SubstationSprite.destination(pos, _v114_footprint_tiles(capacity_mw))
    var foot := V160SubstationSprite.ground_contact(destination)
    # Top-left light -> one lower-right ground shadow. Draw it only here,
    # regardless of whether the visible sprite is deferred for character sorting.
    draw_ellipse_shadow(foot.get_center() + Vector2(0.0, 3.0), foot.size.x * 0.49, maxf(5.0, foot.size.y * 0.34))
    var player_foot_y := rep_pos.y + 43.0
    var x_overlap := rep_pos.x >= destination.position.x - 24.0 and rep_pos.x <= destination.end.x + 24.0
    var y_overlap := player_foot_y >= destination.position.y and player_foot_y < V160SubstationSprite.sort_y(destination)
    v160_transformer_late = x_overlap and y_overlap
    if v160_transformer_late:
        v160_late_transformer_rect = destination
    else:
        draw_texture_rect(v160_transformer_texture, destination, false)

func _draw_world_props_pixel() -> void:
    # Reset each world render. The inherited v0.158 draw only visits the mining
    # campus when the camera/player approaches its reserved open parcel.
    v160_transformer_late = false
    super._draw_world_props_pixel()

func _draw_rep() -> void:
    super._draw_rep()
    if v160_transformer_late and V160SubstationSprite.valid_texture(v160_transformer_texture):
        # Player is behind the infrastructure footprint in world Y; present
        # the transformer in front of that player without a second shadow.
        draw_texture_rect(v160_transformer_texture, v160_late_transformer_rect, false)

func _v160_register_transformer_footprint() -> void:
    # Navigation collision covers just the base, not the full tall sprite.
    # The core mining simulation and capacity-tier contract remain unchanged.
    var site_origin := _energy_campus_origin()
    var capacity_mw := _v114_capacity_mw_for_site(_player_hq_center())
    var destination := V160SubstationSprite.destination(site_origin + Vector2(205.0, 215.0), _v114_footprint_tiles(capacity_mw))
    var foot := V160SubstationSprite.ground_contact(destination)
    set_meta("hashrace_v160_transformer_footprint", foot)
    set_meta("hashrace_v160_transformer_sort_y", V160SubstationSprite.sort_y(destination))
    if grid_nav != null:
        grid_nav.block_rect(foot)

func debug_v160_transformer_ready() -> bool:
    var foot: Rect2 = get_meta("hashrace_v160_transformer_footprint", Rect2())
    return V160SubstationSprite.valid_texture(v160_transformer_texture) \
        and V160SubstationSprite.debug_ready() \
        and foot.size.x > 0.0 and foot.size.y > 0.0 \
        and grid_nav != null and not grid_nav.world_is_walkable(foot.get_center()) \
        and _v114_footprint_tiles(1.0) == 2 \
        and _v114_footprint_tiles(10.0) == 4 \
        and _v114_footprint_tiles(25.0) == 6 \
        and _v114_footprint_tiles(100.0) == 8
