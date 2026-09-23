extends "res://scripts/world_v160.gd"

# v0.161: one genuine transparent solar sprite replaces the inherited
# procedural solar renderer only. All other energy systems and the existing
# live C-01 and transformer assets remain unchanged until individually proven.
const V161Solar = preload("res://scripts/v161_solar_overview_sprite.gd")
const V161_SOLAR_REVISION := 1
var v161_solar_texture: Texture2D
var v161_solar_drawn := false
var v161_solar_late := false
var v161_solar_rect := Rect2()
var v161_solar_footprint := Rect2()
var v161_solar_footprint_registered := false

func _ready() -> void:
    # Ready-order matters: the dynamic v0.114 renderer is called in inherited
    # world layers. Load the exact PNG before allowing the base ready chain.
    v161_solar_texture = V161Solar.texture()
    super._ready()
    set_meta("hashrace_v161_solar_binary_live", V161Solar.valid_texture(v161_solar_texture))
    set_meta("hashrace_v161_solar_asset_path", V161Solar.TEXTURE_PATH)
    queue_redraw()

func _draw_world_props_pixel() -> void:
    v161_solar_late = false
    super._draw_world_props_pixel()

func _v114_draw_energy_source(asset_id: String, pos: Vector2, capacity_mw: float, orientation: String = "up") -> void:
    if asset_id != "solar_array" or not V161Solar.valid_texture(v161_solar_texture):
        # Preserve every nonempty inherited renderer and its existing behavior.
        super._v114_draw_energy_source(asset_id, pos, capacity_mw, orientation)
        return

    var dest := V161Solar.destination(pos, _v114_footprint_tiles(capacity_mw))
    var foot := V161Solar.ground_contact(dest)
    v161_solar_rect = dest
    v161_solar_footprint = foot
    v161_solar_drawn = true

    # Block only the grounded equipment base, not the tall panel silhouette.
    # A rendered player behind the raised panel is occluded after _draw_rep;
    # the contact shadow is part of the source PNG, never drawn twice.
    if not v161_solar_footprint_registered and grid_nav != null:
        grid_nav.block_rect(foot)
        v161_solar_footprint_registered = true

    var player_feet := rep_pos + Vector2(0.0, 43.0)
    v161_solar_late = player_feet.x >= dest.position.x - 12.0 \
        and player_feet.x <= dest.end.x + 12.0 \
        and player_feet.y >= dest.position.y \
        and player_feet.y < V161Solar.sort_y(dest)
    if not v161_solar_late:
        draw_texture_rect(v161_solar_texture, dest, false)

func _draw_rep() -> void:
    super._draw_rep()
    if v161_solar_late and V161Solar.valid_texture(v161_solar_texture):
        draw_texture_rect(v161_solar_texture, v161_solar_rect, false)

func debug_v161_solar_ready() -> bool:
    return V161_SOLAR_REVISION == 1 \
        and V161Solar.valid_texture(v161_solar_texture) \
        and V161Solar.debug_ready() \
        and v161_solar_drawn \
        and v161_solar_footprint.size.x > 0.0 \
        and v161_solar_footprint.size.y > 0.0 \
        and grid_nav != null \
        and not grid_nav.world_is_walkable(v161_solar_footprint.get_center()) \
        and _v114_footprint_tiles(1.0) == 2 \
        and _v114_footprint_tiles(10.0) == 4 \
        and _v114_footprint_tiles(25.0) == 6 \
        and _v114_footprint_tiles(100.0) == 8 \
        and debug_v160_transformer_ready()
