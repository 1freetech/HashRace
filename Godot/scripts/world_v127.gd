extends "res://scripts/world_v126.gd"

const IndustrialRoadCatalog = preload("res://scripts/industrial_road_catalog.gd")
const UtilityPropsCatalog = preload("res://scripts/utility_props_catalog.gd")
const WindTurbineCatalog = preload("res://scripts/wind_turbine_catalog.gd")
const AsicAirCatalog = preload("res://scripts/asic_air_s19j_catalog.gd")
const DefaultPlayerSheet = preload("res://scripts/default_player_sprite_sheet.gd")

const V127_ASSET_BUNDLE_REVISION := 1

var v127_industrial_road_texture: Texture2D
var v127_utility_props_texture: Texture2D
var v127_wind_texture: Texture2D
var v127_asic_texture: Texture2D
var v127_player_texture: Texture2D

func _ready() -> void:
    v127_industrial_road_texture = IndustrialRoadCatalog.load_texture()
    v127_utility_props_texture = UtilityPropsCatalog.load_texture()
    v127_wind_texture = WindTurbineCatalog.load_texture()
    v127_asic_texture = AsicAirCatalog.load_texture()
    v127_player_texture = DefaultPlayerSheet.load_texture()
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    super._ready()
    set_meta("hashrace_v127_asset_bundle_revision", V127_ASSET_BUNDLE_REVISION)
    set_meta("hashrace_industrial_road_live", v127_industrial_road_texture != null)
    set_meta("hashrace_utility_props_live", v127_utility_props_texture != null)
    set_meta("hashrace_wind_turbine_live", v127_wind_texture != null)
    set_meta("hashrace_asic_air_live", v127_asic_texture != null)
    set_meta("hashrace_player_16frame_asset_live", v127_player_texture != null)
    queue_redraw()

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)
    _v127_draw_industrial_road(origin + Vector2(-175.0, 150.0))
    _v127_draw_utility_cluster(origin)
    _v127_draw_directional(v127_wind_texture, WindTurbineCatalog.region("down"),
        origin + Vector2(285.0, -118.0), Vector2(112.0, 112.0), true)
    _v127_draw_directional(v127_asic_texture, AsicAirCatalog.region("up"),
        origin + Vector2(-210.0, -92.0), Vector2(76.0, 76.0), true)

func _v127_draw_industrial_road(anchor: Vector2) -> void:
    if v127_industrial_road_texture == null:
        return
    var tile := Vector2(54.0, 54.0)
    for x in range(5):
        _v127_draw_region(v127_industrial_road_texture,
            IndustrialRoadCatalog.region("straight_h_marked"),
            Rect2(anchor + Vector2(float(x) * tile.x, 0.0), tile))
    _v127_draw_region(v127_industrial_road_texture,
        IndustrialRoadCatalog.region("corner_se"),
        Rect2(anchor + Vector2(4.0 * tile.x, -tile.y), tile))
    _v127_draw_region(v127_industrial_road_texture,
        IndustrialRoadCatalog.region("straight_v_marked"),
        Rect2(anchor + Vector2(4.0 * tile.x, -2.0 * tile.y), tile))

func _v127_draw_utility_cluster(origin: Vector2) -> void:
    if v127_utility_props_texture == null:
        return
    _v127_draw_region(v127_utility_props_texture, UtilityPropsCatalog.region("power_pole_full"),
        Rect2(origin + Vector2(210.0, 18.0), Vector2(62.0, 88.0)))
    _v127_draw_region(v127_utility_props_texture, UtilityPropsCatalog.region("fence"),
        Rect2(origin + Vector2(115.0, 206.0), Vector2(118.0, 52.0)))
    _v127_draw_region(v127_utility_props_texture, UtilityPropsCatalog.region("fence_gate"),
        Rect2(origin + Vector2(231.0, 206.0), Vector2(74.0, 52.0)))
    _v127_draw_region(v127_utility_props_texture, UtilityPropsCatalog.region("electrical_cabinet"),
        Rect2(origin + Vector2(300.0, 178.0), Vector2(48.0, 58.0)))
    _v127_draw_region(v127_utility_props_texture, UtilityPropsCatalog.region("cone_large"),
        Rect2(origin + Vector2(86.0, 196.0), Vector2(28.0, 44.0)))
    _v127_draw_region(v127_utility_props_texture, UtilityPropsCatalog.region("pallet"),
        Rect2(origin + Vector2(16.0, 204.0), Vector2(56.0, 45.0)))

func _v127_draw_directional(texture: Texture2D, source: Rect2i, center: Vector2, size_value: Vector2, shadow: bool) -> void:
    if texture == null:
        return
    if shadow:
        draw_ellipse_shadow(center + Vector2(0.0, size_value.y * 0.34), size_value.x * 0.34, size_value.y * 0.08)
    _v127_draw_region(texture, source, Rect2(center - size_value * 0.5, size_value))

func _v127_draw_region(texture: Texture2D, source: Rect2i, destination: Rect2) -> void:
    if texture == null:
        return
    draw_texture_rect_region(texture, destination, Rect2(source))

func debug_v127_ready() -> bool:
    return V127_ASSET_BUNDLE_REVISION == 1 \
        and v127_industrial_road_texture != null \
        and v127_utility_props_texture != null \
        and v127_wind_texture != null \
        and v127_asic_texture != null \
        and v127_player_texture != null \
        and IndustrialRoadCatalog.debug_ready() \
        and UtilityPropsCatalog.debug_ready() \
        and WindTurbineCatalog.debug_ready() \
        and AsicAirCatalog.debug_ready() \
        and debug_v126_ready()
