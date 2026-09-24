extends "res://scripts/world_v125.gd"

const GrassTerrainCatalog = preload("res://scripts/grass_terrain_catalog.gd")
const V126_GRASS_TERRAIN_REVISION := 1
const V126_GRASS_TILE_SIZE := Vector2(72.0, 72.0)

var v126_grass_texture: Texture2D

func _ready() -> void:
    v126_grass_texture = GrassTerrainCatalog.load_texture()
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    super._ready()
    set_meta("hashrace_v126_grass_terrain_revision", V126_GRASS_TERRAIN_REVISION)
    set_meta("hashrace_grass_terrain_asset_live", v126_grass_texture != null)
    queue_redraw()

func _v125_draw_terrain_underlay(campus: Rect2) -> void:
    if v126_grass_texture == null:
        return

    var cols: int = maxi(1, int(ceil(campus.size.x / V126_GRASS_TILE_SIZE.x)))
    var rows: int = maxi(1, int(ceil(campus.size.y / V126_GRASS_TILE_SIZE.y)))
    var start := campus.position

    for y in range(rows):
        for x in range(cols):
            var cell := Vector2i(x, y)
            var tile_name := GrassTerrainCatalog.variant_for_cell(cell)
            if ((x * 5 + y * 3) % 7) != 0 and tile_name not in ["grass_plain", "grass_light", "grass_dark"]:
                tile_name = "grass_plain"
            _v126_draw_grass_tile(start, cell, tile_name)

    var edge_y: int = maxi(0, rows - 1)
    for x in range(cols):
        var edge_name := "edge_bottom"
        if x == 0:
            edge_name = "corner_bottom_left"
        elif x == cols - 1:
            edge_name = "corner_bottom_right"
        _v126_draw_grass_tile(start, Vector2i(x, edge_y), edge_name)

func _v126_draw_grass_tile(origin: Vector2, cell: Vector2i, tile_name: String) -> void:
    if v126_grass_texture == null:
        return
    var dest := Rect2(origin + Vector2(cell) * V126_GRASS_TILE_SIZE, V126_GRASS_TILE_SIZE)
    var source: Rect2i = GrassTerrainCatalog.region(tile_name)
    draw_texture_rect_region(v126_grass_texture, dest, Rect2(source))

func debug_v126_ready() -> bool:
    return V126_GRASS_TERRAIN_REVISION == 1 \
        and v126_grass_texture != null \
        and GrassTerrainCatalog.debug_ready() \
        and debug_v125_ready()
