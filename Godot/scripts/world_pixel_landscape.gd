extends "res://scripts/world_target_composition.gd"

# Hash Race v0.043 pixel-landscape pass.
# Terrain is generated as true 16x16 pixel images in code, then scaled to the
# existing 48px world grid with nearest-neighbor filtering for a crisp 3x look.

const PIXEL_LANDSCAPE_REVISION: int = 1
const MICRO_TILE_SIZE: int = 16
const DISPLAY_TILE_SIZE: float = 48.0

const LAND_GRASS_DARK: Color = Color("1b5635")
const LAND_GRASS: Color = Color("2f8144")
const LAND_GRASS_LIGHT: Color = Color("55aa55")
const LAND_GRASS_HI: Color = Color("82ca62")
const LAND_PATH_DARK: Color = Color("7d755d")
const LAND_PATH: Color = Color("b8aa83")
const LAND_PATH_LIGHT: Color = Color("d3c69b")
const LAND_PATH_HI: Color = Color("e5d8aa")
const LAND_ROAD_DARK: Color = Color("28363d")
const LAND_ROAD: Color = Color("43545b")
const LAND_ROAD_LIGHT: Color = Color("718087")
const LAND_LOT_DARK: Color = Color("4d5a5f")
const LAND_LOT: Color = Color("758187")
const LAND_LOT_LIGHT: Color = Color("a0aaac")
const LAND_WATER_DARK: Color = Color("15566e")
const LAND_WATER: Color = Color("247f9b")
const LAND_WATER_LIGHT: Color = Color("4db4c6")
const LAND_WATER_HI: Color = Color("8edbe0")
const LAND_INK: Color = Color("17252a")

var pixel_landscape_textures: Dictionary = {}

func _ready() -> void:
    super._ready()
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _build_pixel_landscape_textures()
    set_meta("hashrace_pixel_landscape_revision", PIXEL_LANDSCAPE_REVISION)
    queue_redraw()

func _build_art_tilemap() -> void:
    super._build_art_tilemap()
    _stamp_campus_walkways()

func _stamp_campus_walkways() -> void:
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = zone["center"]
        var c: Vector2i = _world_to_art_cell(center)

        # Replace the old broad dark lot with grass so the campus has readable
        # landscaping instead of looking like one giant industrial rectangle.
        for y in range(c.y - 4, c.y + 5):
            for x in range(c.x - 5, c.x + 6):
                var cell: Vector2i = Vector2i(x, y)
                if not art_cells.has(cell):
                    continue
                var existing: int = int(art_cells[cell])
                if existing == TILE_WATER or existing == TILE_ROAD:
                    continue
                if (x + y) % 5 == 0:
                    art_cells[cell] = TILE_GRASS_DARK
                else:
                    art_cells[cell] = TILE_GRASS

        # Beige pedestrian cross plus two facility rows, matching the approved
        # visual target's obvious walkways while staying aligned to gameplay grid.
        for x in range(c.x - 5, c.x + 6):
            _set_walkway_cell(Vector2i(x, c.y))
        for y in range(c.y - 4, c.y + 5):
            _set_walkway_cell(Vector2i(c.x, y))
        for x in range(c.x - 4, c.x + 5):
            _set_walkway_cell(Vector2i(x, c.y - 2))
            _set_walkway_cell(Vector2i(x, c.y + 2))

        _set_lot_cell(c + Vector2i(-4, -2))
        _set_lot_cell(c + Vector2i(3, -2))
        _set_lot_cell(c + Vector2i(-4, 2))
        _set_lot_cell(c + Vector2i(3, 2))

func _set_walkway_cell(cell: Vector2i) -> void:
    if not art_cells.has(cell):
        return
    var existing: int = int(art_cells[cell])
    if existing != TILE_WATER and existing != TILE_ROAD:
        art_cells[cell] = TILE_PLAZA

func _set_lot_cell(cell: Vector2i) -> void:
    if not art_cells.has(cell):
        return
    var existing: int = int(art_cells[cell])
    if existing != TILE_WATER and existing != TILE_ROAD:
        art_cells[cell] = TILE_LOT

func _build_pixel_landscape_textures() -> void:
    pixel_landscape_textures.clear()
    var tile_ids: Array = [TILE_GRASS, TILE_GRASS_DARK, TILE_ROAD, TILE_PLAZA, TILE_WATER, TILE_LOT]
    for raw_tile_id in tile_ids:
        var tile_id: int = int(raw_tile_id)
        for variant in range(4):
            var key: Vector2i = Vector2i(tile_id, variant)
            pixel_landscape_textures[key] = _make_pixel_tile_texture(tile_id, variant)

func _make_pixel_tile_texture(tile_id: int, variant: int):
    var img: Image = Image.create(MICRO_TILE_SIZE, MICRO_TILE_SIZE, false, Image.FORMAT_RGBA8)
    var palette: Array = _palette_for_tile(tile_id)
    var base_color: Color = palette[1]
    img.fill(base_color)

    # Every source pixel is intentionally evaluated so the visible ground uses
    # actual pixel texture density rather than a handful of large screen quads.
    for y in range(MICRO_TILE_SIZE):
        for x in range(MICRO_TILE_SIZE):
            var hash_value: int = absi(x * 37 + y * 61 + variant * 89 + tile_id * 131 + x * y * 7) % 100
            var color: Color = palette[1]
            if hash_value < 12:
                color = palette[0]
            elif hash_value > 87:
                color = palette[2]
            img.set_pixel(x, y, color)

    if tile_id == TILE_GRASS or tile_id == TILE_GRASS_DARK:
        _paint_grass_pixels(img, palette, variant)
    elif tile_id == TILE_PLAZA:
        _paint_walkway_pixels(img, palette, variant)
    elif tile_id == TILE_ROAD:
        _paint_road_pixels(img, palette, variant)
    elif tile_id == TILE_LOT:
        _paint_lot_pixels(img, palette, variant)
    elif tile_id == TILE_WATER:
        _paint_water_pixels(img, palette, variant)

    return ImageTexture.create_from_image(img)

func _palette_for_tile(tile_id: int) -> Array:
    if tile_id == TILE_GRASS_DARK:
        return [LAND_GRASS_DARK.darkened(0.22), LAND_GRASS_DARK, LAND_GRASS]
    if tile_id == TILE_GRASS:
        return [LAND_GRASS_DARK, LAND_GRASS, LAND_GRASS_LIGHT]
    if tile_id == TILE_PLAZA:
        return [LAND_PATH_DARK, LAND_PATH, LAND_PATH_LIGHT]
    if tile_id == TILE_ROAD:
        return [LAND_ROAD_DARK, LAND_ROAD, LAND_ROAD_LIGHT]
    if tile_id == TILE_LOT:
        return [LAND_LOT_DARK, LAND_LOT, LAND_LOT_LIGHT]
    if tile_id == TILE_WATER:
        return [LAND_WATER_DARK, LAND_WATER, LAND_WATER_LIGHT]
    return [LAND_GRASS_DARK, LAND_GRASS, LAND_GRASS_LIGHT]

func _paint_grass_pixels(img: Image, palette: Array, variant: int) -> void:
    for i in range(14):
        var x: int = (i * 5 + variant * 3 + 2) % 15
        var y: int = (i * 9 + variant * 5 + 1) % 15
        img.set_pixel(x, y, palette[2])
        if y + 1 < MICRO_TILE_SIZE and i % 2 == 0:
            img.set_pixel(x, y + 1, palette[0])
    if variant == 1:
        img.set_pixel(12, 4, LAND_GRASS_HI)
        img.set_pixel(13, 4, LAND_GRASS_HI)
    elif variant == 3:
        img.set_pixel(4, 11, Color("e7c85c"))

func _paint_walkway_pixels(img: Image, palette: Array, variant: int) -> void:
    for y in range(MICRO_TILE_SIZE):
        for x in range(MICRO_TILE_SIZE):
            if x % 4 == 0 or y % 4 == 0:
                img.set_pixel(x, y, palette[0])
    img.set_pixel((variant * 3 + 2) % 15, 6, LAND_PATH_HI)
    img.set_pixel((variant * 5 + 8) % 15, 13, LAND_PATH_DARK.darkened(0.12))

func _paint_road_pixels(img: Image, palette: Array, variant: int) -> void:
    for i in range(10):
        var x: int = (i * 7 + variant * 2) % 16
        var y: int = (i * 11 + variant * 3) % 16
        var speck: Color = palette[2]
        if i % 2 == 0:
            speck = palette[0]
        img.set_pixel(x, y, speck)
    for x in range(16):
        img.set_pixel(x, 0, LAND_ROAD_LIGHT)
        img.set_pixel(x, 15, LAND_ROAD_DARK)

func _paint_lot_pixels(img: Image, palette: Array, variant: int) -> void:
    for seam in range(0, 16, 5):
        for x in range(16):
            img.set_pixel(x, seam, palette[0])
        for y in range(16):
            img.set_pixel(seam, y, palette[0])
    img.set_pixel(13 - variant, 13, palette[2])

func _paint_water_pixels(img: Image, palette: Array, variant: int) -> void:
    var wave_rows: Array = [3, 8, 13]
    for raw_y in wave_rows:
        var y: int = int(raw_y)
        for x in range(2 + variant, 13 + variant):
            if x < 16 and (x + y + variant) % 3 != 0:
                var wave_color: Color = palette[2]
                if y == 3:
                    wave_color = LAND_WATER_HI
                img.set_pixel(x, y, wave_color)
    img.set_pixel(1 + variant, 5, palette[0])
    img.set_pixel(10 - variant, 11, palette[0])

func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
    if pixel_landscape_textures.is_empty():
        super._draw_art_tile(cell, tile_id)
        return

    var p: Vector2 = VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    var variant: int = absi(cell.x * 17 + cell.y * 31 + tile_id * 13) % 4
    var key: Vector2i = Vector2i(tile_id, variant)
    var texture = pixel_landscape_textures.get(key, null)
    if texture == null:
        super._draw_art_tile(cell, tile_id)
        return

    draw_texture_rect(texture, Rect2(p, Vector2(DISPLAY_TILE_SIZE + 1.0, DISPLAY_TILE_SIZE + 1.0)), false)

    if tile_id == TILE_ROAD:
        _draw_road_connections(cell, p, Color("d5d4b2"))
        _draw_road_curbs(cell, p)
    elif tile_id == TILE_PLAZA:
        _draw_walkway_edges(cell, p)
    elif tile_id == TILE_WATER:
        _draw_water_bank(cell, p)
    elif tile_id == TILE_LOT:
        draw_rect(Rect2(p + Vector2(3.0, 3.0), Vector2(42.0, 42.0)), LAND_INK, false, 2.0)

func _draw_walkway_edges(cell: Vector2i, p: Vector2) -> void:
    var edge: Color = LAND_PATH_DARK.darkened(0.2)
    if int(art_cells.get(cell + Vector2i.UP, -1)) != TILE_PLAZA:
        draw_rect(Rect2(p, Vector2(48.0, 3.0)), edge, true)
    if int(art_cells.get(cell + Vector2i.DOWN, -1)) != TILE_PLAZA:
        draw_rect(Rect2(p + Vector2(0.0, 45.0), Vector2(48.0, 3.0)), edge, true)
    if int(art_cells.get(cell + Vector2i.LEFT, -1)) != TILE_PLAZA:
        draw_rect(Rect2(p, Vector2(3.0, 48.0)), edge, true)
    if int(art_cells.get(cell + Vector2i.RIGHT, -1)) != TILE_PLAZA:
        draw_rect(Rect2(p + Vector2(45.0, 0.0), Vector2(3.0, 48.0)), edge, true)

func _draw_road_curbs(cell: Vector2i, p: Vector2) -> void:
    var curb: Color = Color("a6afb0")
    if int(art_cells.get(cell + Vector2i.UP, -1)) != TILE_ROAD:
        draw_rect(Rect2(p, Vector2(48.0, 3.0)), curb, true)
    if int(art_cells.get(cell + Vector2i.DOWN, -1)) != TILE_ROAD:
        draw_rect(Rect2(p + Vector2(0.0, 45.0), Vector2(48.0, 3.0)), curb.darkened(0.18), true)
    if int(art_cells.get(cell + Vector2i.LEFT, -1)) != TILE_ROAD:
        draw_rect(Rect2(p, Vector2(3.0, 48.0)), curb, true)
    if int(art_cells.get(cell + Vector2i.RIGHT, -1)) != TILE_ROAD:
        draw_rect(Rect2(p + Vector2(45.0, 0.0), Vector2(3.0, 48.0)), curb.darkened(0.18), true)

func _draw_water_bank(cell: Vector2i, p: Vector2) -> void:
    var bank: Color = Color("8c8660")
    if int(art_cells.get(cell + Vector2i.UP, TILE_WATER)) != TILE_WATER:
        draw_rect(Rect2(p, Vector2(48.0, 4.0)), bank, true)
    if int(art_cells.get(cell + Vector2i.DOWN, TILE_WATER)) != TILE_WATER:
        draw_rect(Rect2(p + Vector2(0.0, 44.0), Vector2(48.0, 4.0)), bank.darkened(0.16), true)
    if int(art_cells.get(cell + Vector2i.LEFT, TILE_WATER)) != TILE_WATER:
        draw_rect(Rect2(p, Vector2(4.0, 48.0)), bank, true)
    if int(art_cells.get(cell + Vector2i.RIGHT, TILE_WATER)) != TILE_WATER:
        draw_rect(Rect2(p + Vector2(44.0, 0.0), Vector2(4.0, 48.0)), bank.darkened(0.16), true)

func debug_pixel_landscape_ready() -> bool:
    return PIXEL_LANDSCAPE_REVISION == 1 and pixel_landscape_textures.size() == 24
