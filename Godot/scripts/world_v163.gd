extends "res://scripts/world_v162.gd"

# v0.163: replace one generic power-house silhouette with the already proven
# authored solar infrastructure sprite. Visual identity changes, but the power
# entity, selection, interaction and simulation state remain the same.
const V163_INFRA_REPLACEMENT_REVISION := 3
var v163_solar_texture: Texture2D
var v163_solar_rect := Rect2()
var v163_solar_footprint := Rect2()
var v163_solar_late := false
var v163_power_center := Vector2.ZERO
var v163_power_footprint_registered := false

func _ready() -> void:
    # V161Solar is inherited from world_v161.gd; do not redeclare it here.
    v163_solar_texture = V161Solar.texture()
    super._ready()
    _v163_register_power_infrastructure_footprint()
    set_meta("hashrace_v163_one_house_replaced_by_infrastructure", V161Solar.valid_texture(v163_solar_texture))
    set_meta("hashrace_v163_replacement_asset", V161Solar.TEXTURE_PATH)
    set_meta("hashrace_v163_power_footprint", v163_solar_footprint)
    set_meta("hashrace_v163_isolated_cable_tray_removed", true)
    queue_redraw()

func _draw_world_props_pixel() -> void:
    v163_solar_late = false
    super._draw_world_props_pixel()

# Fresh exact-head runtime proof showed the inherited decorative cable tray as
# an isolated strip and, in the dedicated solar proof, directly under the
# player's feet. It has no simulation role, so remove the placement rather than
# relocating visual clutter again. The validated PNG remains available in art.
func _v159_draw_cable_tray(_center: Vector2) -> void:
    pass

# Replace only the dedicated Gridline power-building renderer. The underlying
# entity is untouched. Draw at the entity's real world position and preserve the
# validated PNG aspect ratio/contact shadow rather than stretching it to the old
# house rectangle.
func _draw_power_building(entity: Dictionary, idx: int) -> void:
    if not V161Solar.valid_texture(v163_solar_texture):
        super._draw_power_building(entity, idx)
        return
    var center: Vector2 = entity.get("pos", Vector2.ZERO)
    var world_size := WorldScale.size_for_kind(String(entity.get("kind", "power")))
    var tiles := clampi(int(round(maxf(world_size.x, world_size.y) / 48.0)), 2, 8)
    var dest := V161Solar.destination(center, tiles)
    var foot := V161Solar.ground_contact(dest)
    v163_power_center = center
    v163_solar_rect = dest
    v163_solar_footprint = foot

    # Keep selection behavior, but intentionally omit the inherited house body,
    # foundation, door and duplicate cast shadow.
    _selection_ring(center, idx, WorldScale.selection_radius(String(entity.get("kind", "power"))))

    # Sort against the player's feet. The source PNG already owns its contact
    # shadow, so deferred drawing must never create a second ground treatment.
    var player_feet := rep_pos + Vector2(0.0, 43.0)
    var x_overlap := player_feet.x >= dest.position.x - 12.0 and player_feet.x <= dest.end.x + 12.0
    v163_solar_late = x_overlap and player_feet.y >= dest.position.y and player_feet.y < V161Solar.sort_y(dest)
    if not v163_solar_late:
        draw_texture_rect(v163_solar_texture, dest, false)

    # v0.160 already limits permanent world labels to target plus nearest.
    _draw_building_name(entity, idx, Color("ffd36e"), world_size.y * 0.43 + 32.0, world_size.x + 28.0)

func _draw_rep() -> void:
    super._draw_rep()
    if v163_solar_late and V161Solar.valid_texture(v163_solar_texture):
        draw_texture_rect(v163_solar_texture, v163_solar_rect, false)

func _v163_register_power_infrastructure_footprint() -> void:
    if not V161Solar.valid_texture(v163_solar_texture) or grid_nav == null:
        return
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        if String(entity.get("kind", "")) != "power":
            continue
        var center: Vector2 = entity.get("pos", Vector2.ZERO)
        var world_size := WorldScale.size_for_kind("power")
        var tiles := clampi(int(round(maxf(world_size.x, world_size.y) / 48.0)), 2, 8)
        var dest := V161Solar.destination(center, tiles)
        var foot := V161Solar.ground_contact(dest)
        v163_power_center = center
        v163_solar_rect = dest
        v163_solar_footprint = foot
        grid_nav.block_rect(foot)
        v163_power_footprint_registered = true
        break

func debug_v163_ready() -> bool:
    return V163_INFRA_REPLACEMENT_REVISION == 3 \
        and V161Solar.valid_texture(v163_solar_texture) \
        and V161Solar.debug_ready() \
        and v163_power_center != Vector2.ZERO \
        and v163_solar_footprint.size.x > 0.0 \
        and v163_solar_footprint.size.y > 0.0 \
        and v163_power_footprint_registered \
        and bool(get_meta("hashrace_v163_isolated_cable_tray_removed", false)) \
        and grid_nav != null \
        and not grid_nav.world_is_walkable(v163_solar_footprint.get_center()) \
        and debug_v162_ready()
