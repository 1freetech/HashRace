extends "res://scripts/world_v162.gd"

# v0.163: replace one generic power-house silhouette with the already proven
# authored solar infrastructure sprite. This is visual-only: entity identity,
# selection, interaction, simulation state and world scale remain unchanged.
const V161Solar = preload("res://scripts/v161_solar_overview_sprite.gd")
const V163_INFRA_REPLACEMENT_REVISION := 1
var v163_solar_texture: Texture2D
var v163_solar_rect := Rect2()
var v163_solar_footprint := Rect2()
var v163_solar_late := false

func _ready() -> void:
    v163_solar_texture = V161Solar.texture()
    super._ready()
    set_meta("hashrace_v163_one_house_replaced_by_infrastructure", V161Solar.valid_texture(v163_solar_texture))
    set_meta("hashrace_v163_replacement_asset", V161Solar.TEXTURE_PATH)
    queue_redraw()

func _draw_world_props_pixel() -> void:
    v163_solar_late = false
    super._draw_world_props_pixel()

# Replace only the dedicated power-building renderer. The underlying entity is
# untouched, so interaction and gameplay continue to address the same building.
func _draw_power_building(entity: Dictionary, idx: int) -> void:
    if not V161Solar.valid_texture(v163_solar_texture):
        super._draw_power_building(entity, idx)
        return
    var center: Vector2 = entity.get("pos", Vector2.ZERO)
    var world_size := WorldScale.size_for_kind(String(entity.get("kind", "power")))
    var tiles := clampi(int(round(maxf(world_size.x, world_size.y) / 48.0)), 2, 8)
    var dest := V161Solar.destination(center, tiles)
    var foot := V161Solar.ground_contact(dest)
    v163_solar_rect = dest
    v163_solar_footprint = foot

    # Keep selection behavior but remove the old house/foundation/door artwork.
    _selection_ring(center, idx, WorldScale.selection_radius(String(entity.get("kind", "power"))))

    # The sprite's authored contact shadow is retained; do not add a second one.
    var player_feet := rep_pos + Vector2(0.0, 43.0)
    var x_overlap := player_feet.x >= dest.position.x - 12.0 and player_feet.x <= dest.end.x + 12.0
    v163_solar_late = x_overlap and player_feet.y >= dest.position.y and player_feet.y < V161Solar.sort_y(dest)
    if not v163_solar_late:
        draw_texture_rect(v163_solar_texture, dest, false)

    # v0.160 will show at most the target plus nearest actionable label.
    _draw_building_name(entity, idx, Color("ffd36e"), world_size.y * 0.43 + 32.0, world_size.x + 28.0)

func _draw_rep() -> void:
    super._draw_rep()
    if v163_solar_late and V161Solar.valid_texture(v163_solar_texture):
        draw_texture_rect(v163_solar_texture, v163_solar_rect, false)

func debug_v163_ready() -> bool:
    return V163_INFRA_REPLACEMENT_REVISION == 1 \
        and V161Solar.valid_texture(v163_solar_texture) \
        and V161Solar.debug_ready() \
        and v163_solar_footprint.size.x > 0.0 \
        and v163_solar_footprint.size.y > 0.0 \
        and debug_v162_ready()
