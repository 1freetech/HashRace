extends "res://scripts/world_v162.gd"

# v0.163: promote the already validated directional wind-turbine binary from
# decorative live-site art to the actual wind_farm energy-source renderer.
# One asset only: all other inherited energy renderers remain unchanged.
const V163Wind = preload("res://scripts/wind_turbine_catalog.gd")
const V163_WIND_REVISION := 2
var v163_wind_texture: Texture2D
var v163_wind_drawn := false
var v163_wind_rect := Rect2()
var v163_wind_footprint := Rect2()
var v163_wind_footprint_registered := false

func _ready() -> void:
    # Match the proven v0.161 pattern: the inherited live-site renderer can run
    # during the base ready chain, so load the exact binary first.
    v163_wind_texture = V163Wind.load_texture()
    super._ready()
    set_meta("hashrace_v163_wind_binary_live", v163_wind_texture != null)
    set_meta("hashrace_v163_wind_asset_path", V163Wind.SHEET_PATH)
    queue_redraw()

func _v114_draw_energy_source(asset_id: String, pos: Vector2, capacity_mw: float, orientation: String = "up") -> void:
    if asset_id != "wind_farm" or v163_wind_texture == null:
        super._v114_draw_energy_source(asset_id, pos, capacity_mw, orientation)
        return

    var footprint_tiles := _v114_footprint_tiles(capacity_mw)
    var side := clampf(72.0 + float(footprint_tiles) * 14.0, 100.0, 184.0)
    var size_value := Vector2(side, side)
    var dest := Rect2(VisualStack.snap_to_pixel(pos - size_value * 0.5), size_value)
    var foot := Rect2(
        Vector2(dest.position.x + dest.size.x * 0.27, dest.position.y + dest.size.y * 0.72),
        Vector2(dest.size.x * 0.46, dest.size.y * 0.20)
    )
    v163_wind_rect = dest
    v163_wind_footprint = foot
    v163_wind_drawn = true
    if not v163_wind_footprint_registered and grid_nav != null:
        grid_nav.block_rect(foot)
        v163_wind_footprint_registered = true

    var source := V163Wind.region(orientation)
    _v127_draw_region(v163_wind_texture, source, dest)

func debug_v163_wind_ready() -> bool:
    # Do not call debug_v162_ready() here. Its inherited v0.161 proof requires
    # solar_array to have been drawn in the same frame, which is mutually
    # exclusive with a real wind_farm being the selected primary source. Check
    # the preserved v0.162 cleanup contract directly, then the older independent
    # transformer/runtime chain.
    return V163_WIND_REVISION == 2 \
        and v163_wind_texture != null \
        and V163Wind.debug_ready() \
        and v163_wind_drawn \
        and v163_wind_rect.size.x >= 100.0 \
        and v163_wind_footprint.size.x > 0.0 \
        and v163_wind_footprint_registered \
        and grid_nav != null \
        and not grid_nav.world_is_walkable(v163_wind_footprint.get_center()) \
        and V162_TILEMAP_CLEANUP_REVISION == 1 \
        and bool(get_meta("hashrace_v162_detached_live_site_foundations_removed", false)) \
        and debug_v160_transformer_ready()
