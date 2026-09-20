extends "res://scripts/world_v124.gd"

const DirtRoadCatalog = preload("res://scripts/dirt_road_catalog.gd")
const V125_DIRT_ROAD_REVISION := 1
const V125_DIRT_TILE_SIZE := Vector2(72.0, 72.0)

var v125_dirt_road_texture: Texture2D

func _ready() -> void:
    v125_dirt_road_texture = DirtRoadCatalog.load_texture()
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    super._ready()
    set_meta("hashrace_v125_dirt_road_revision", V125_DIRT_ROAD_REVISION)
    set_meta("hashrace_dirt_road_asset_live", v125_dirt_road_texture != null)
    queue_redraw()

func _v123_draw_ground(campus: Rect2) -> void:
    super._v123_draw_ground(campus)
    _v125_draw_terrain_underlay(campus)
    if v125_dirt_road_texture == null:
        return

    var center := campus.get_center()
    var road_cells: Dictionary = {}
    for x in range(-4, 5):
        road_cells[Vector2i(x, 0)] = true
    road_cells[Vector2i(0, 1)] = true
    road_cells[Vector2i(-3, -1)] = true
    road_cells[Vector2i(-3, 0)] = true
    road_cells[Vector2i(3, -1)] = true
    road_cells[Vector2i(3, 0)] = true
    road_cells[Vector2i(3, 1)] = true
    road_cells[Vector2i(3, 2)] = true

    var grid_origin := center + Vector2(-V125_DIRT_TILE_SIZE.x * 0.5, -55.0)
    _v125_draw_dirt_network(grid_origin, road_cells)

func _v125_draw_terrain_underlay(_campus: Rect2) -> void:
    pass

func _v125_draw_dirt_network(grid_origin: Vector2, road_cells: Dictionary) -> void:
    for raw_cell in road_cells.keys():
        var cell: Vector2i = raw_cell
        var north := road_cells.has(cell + Vector2i(0, -1))
        var east := road_cells.has(cell + Vector2i(1, 0))
        var south := road_cells.has(cell + Vector2i(0, 1))
        var west := road_cells.has(cell + Vector2i(-1, 0))
        var tile_name := DirtRoadCatalog.choose_tile(north, east, south, west)
        _v125_draw_dirt_tile(grid_origin, cell, tile_name)

func _v125_draw_dirt_tile(grid_origin: Vector2, cell: Vector2i, tile_name: String) -> void:
    if v125_dirt_road_texture == null:
        return
    var dest := Rect2(grid_origin + Vector2(cell) * V125_DIRT_TILE_SIZE, V125_DIRT_TILE_SIZE)
    var source: Rect2i = DirtRoadCatalog.region(tile_name)
    draw_texture_rect_region(v125_dirt_road_texture, dest, Rect2(source))

func debug_v125_ready() -> bool:
    return V125_DIRT_ROAD_REVISION == 1 \
        and v125_dirt_road_texture != null \
        and DirtRoadCatalog.debug_ready() \
        and debug_v124_ready()
