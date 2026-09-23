extends "res://scripts/world_v163.gd"

# v0.164: integrate exactly one existing validated binary into the actual
# wind_farm energy renderer while preserving the proven v0.163 solar building.
const V164Wind = preload("res://scripts/wind_turbine_catalog.gd")
const V164_WIND_REVISION := 1
var v164_wind_texture: Texture2D
var v164_wind_drawn := false
var v164_wind_rect := Rect2()
var v164_wind_footprint := Rect2()
var v164_wind_footprint_registered := false

func _ready() -> void:
    # Load before inherited ready because live-site drawing can occur there.
    v164_wind_texture = V164Wind.load_texture()
    super._ready()
    set_meta("hashrace_v164_wind_binary_live", v164_wind_texture != null)
    set_meta("hashrace_v164_wind_asset_path", V164Wind.SHEET_PATH)
    queue_redraw()

func _v114_draw_energy_source(asset_id: String, pos: Vector2, capacity_mw: float, orientation: String = "up") -> void:
    if asset_id != "wind_farm" or v164_wind_texture == null:
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
    v164_wind_rect = dest
    v164_wind_footprint = foot
    v164_wind_drawn = true
    if not v164_wind_footprint_registered and grid_nav != null:
        grid_nav.block_rect(foot)
        v164_wind_footprint_registered = true
    _v127_draw_region(v164_wind_texture, V164Wind.region(orientation), dest)

func debug_v164_wind_ready() -> bool:
    return V164_WIND_REVISION == 1 \
        and v164_wind_texture != null \
        and V164Wind.debug_ready() \
        and v164_wind_drawn \
        and v164_wind_rect.size.x >= 100.0 \
        and v164_wind_footprint.size.x > 0.0 \
        and v164_wind_footprint_registered \
        and grid_nav != null \
        and not grid_nav.world_is_walkable(v164_wind_footprint.get_center()) \
        and debug_v160_transformer_ready()
