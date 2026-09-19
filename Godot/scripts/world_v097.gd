extends "res://scripts/world_v096.gd"

# Hash Race v0.097 comprehensive 2D graphics rebuild.
# This pass replaces the old "large dark rectangle + repeated grid" look with a
# sprite-first RPG rendering contract:
# - half-resolution generated building sprites, nearest-neighbor scaled 2x
# - gabled/hipped roofs, siding, windows, trim and fixed top-left lighting
# - soft terrain texture with adjacency-aware edges instead of per-tile boxes
# - grass around buildings, narrow entrance paths and restrained paved areas
# - coherent landscaping around town facilities
#
# Reference implementation ideas:
# Pixelorama (MIT) terrain peering/autotile masks and PokeSharp (MIT) fixed
# source/destination sprite rendering. Tuxemon/CityGenerator were visual/layout
# references only; their GPL code is not copied into Hash Race.

const PixelRpgBuildingRenderer = preload("res://scripts/pixel_rpg_building_renderer.gd")
const V097_GRAPHICS_REVISION: int = 1

const V097_GRASS := Color("69b75b")
const V097_GRASS_DARK := Color("4c9349")
const V097_GRASS_LIGHT := Color("8dcc6c")
const V097_GRASS_HI := Color("b4df83")
const V097_ROAD := Color("a4a89d")
const V097_ROAD_DARK := Color("7f877f")
const V097_ROAD_LIGHT := Color("c4c7b8")
const V097_PATH := Color("c8bd99")
const V097_PATH_DARK := Color("a29472")
const V097_PATH_LIGHT := Color("e2d7ad")
const V097_LOT := Color("8b938d")
const V097_LOT_DARK := Color("68726d")
const V097_WATER := Color("4fa6bc")
const V097_WATER_DARK := Color("317d98")
const V097_WATER_LIGHT := Color("8bd2d6")
const V097_EDGE := Color("59645b")
const V097_FLOWER_PINK := Color("f29ab0")
const V097_FLOWER_YELLOW := Color("f1dc68")

var v097_building_cache: Dictionary = {}

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v097_graphics_revision", V097_GRAPHICS_REVISION)
    queue_redraw()

# ---------------------------------------------------------------------------
# TERRAIN: pixel-first, edge-aware and deliberately low-noise.
# ---------------------------------------------------------------------------

func _build_art_tilemap() -> void:
    super._build_art_tilemap()
    _v097_relandscape_facilities()

func _v097_relandscape_facilities() -> void:
    # The earlier map painter put a 5x5 gray pad under almost every building.
    # Pokémon-like towns generally let buildings sit directly in grass, with a
    # small foundation and a path only at the entrance. Restore that contract.
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        var kind := String(entity.get("kind", ""))
        if not WorldScale.is_building_kind(kind):
            continue
        var c := _world_to_art_cell(Vector2(entity.get("pos", Vector2.ZERO)))

        for y in range(c.y - 3, c.y + 4):
            for x in range(c.x - 3, c.x + 4):
                var cell := Vector2i(x, y)
                if not art_cells.has(cell):
                    continue
                var current := int(art_cells[cell])
                if current == TILE_WATER or current == TILE_ROAD:
                    continue
                art_cells[cell] = TILE_GRASS if (x + y) % 7 != 0 else TILE_GRASS_DARK

        # A small foundation and two-cell front walk ground the entrance.
        for x in range(c.x - 2, c.x + 3):
            _v097_set_if_land(Vector2i(x, c.y + 1), TILE_LOT)
        _v097_set_if_land(Vector2i(c.x, c.y + 2), TILE_PLAZA)
        _v097_set_if_land(Vector2i(c.x, c.y + 3), TILE_PLAZA)

func _stamp_campus_walkways() -> void:
    # Town blocks are mostly grass. Paths are one tile wide and only connect the
    # important approaches; this removes the giant checkerboard plazas.
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var c := _world_to_art_cell(Vector2(zone["center"]))

        for y in range(c.y - 5, c.y + 6):
            for x in range(c.x - 6, c.x + 7):
                var cell := Vector2i(x, y)
                if not art_cells.has(cell):
                    continue
                var current := int(art_cells[cell])
                if current == TILE_WATER or current == TILE_ROAD:
                    continue
                art_cells[cell] = TILE_GRASS_DARK if (x * 3 + y * 5) % 17 == 0 else TILE_GRASS

        for x in range(c.x - 5, c.x + 6):
            _v097_set_if_land(Vector2i(x, c.y + 2), TILE_PLAZA)
        for y in range(c.y - 2, c.y + 5):
            _v097_set_if_land(Vector2i(c.x, y), TILE_PLAZA)

func _v097_set_if_land(cell: Vector2i, tile_id: int) -> void:
    if not art_cells.has(cell):
        return
    var current := int(art_cells[cell])
    if current != TILE_WATER and current != TILE_ROAD:
        art_cells[cell] = tile_id

func _make_pixel_tile_texture(tile_id: int, variant: int):
    var img := Image.create(MICRO_TILE_SIZE, MICRO_TILE_SIZE, false, Image.FORMAT_RGBA8)
    match tile_id:
        TILE_GRASS, TILE_GRASS_DARK:
            _v097_paint_grass(img, variant, tile_id == TILE_GRASS_DARK)
        TILE_ROAD:
            _v097_paint_road(img, variant)
        TILE_PLAZA:
            _v097_paint_path(img, variant)
        TILE_LOT:
            _v097_paint_lot(img, variant)
        TILE_WATER:
            _v097_paint_water(img, variant)
        _:
            img.fill(V097_GRASS)
    return ImageTexture.create_from_image(img)

func _v097_paint_grass(img: Image, variant: int, dark: bool) -> void:
    var base := V097_GRASS_DARK if dark else V097_GRASS
    img.fill(base)
    # Sparse 1-2 pixel grass clusters; no tile border and no 4px checker.
    for i in range(8):
        var x := (i * 7 + variant * 3 + 2) % 15
        var y := (i * 11 + variant * 5 + 1) % 15
        var c := V097_GRASS_LIGHT if i % 3 != 0 else V097_GRASS_DARK
        img.set_pixel(x, y, c)
        if i % 2 == 0 and y + 1 < 16:
            img.set_pixel(x, y + 1, V097_GRASS_DARK)
    for i in range(2):
        var tx := (variant * 5 + i * 8 + 3) % 14
        var ty := (variant * 7 + i * 6 + 4) % 14
        img.set_pixel(tx, ty, V097_GRASS_HI)
        img.set_pixel(tx + 1, ty + 1, V097_GRASS_DARK)

func _v097_paint_road(img: Image, variant: int) -> void:
    img.fill(V097_ROAD)
    # Large staggered stone courses read as a continuous road when repeated.
    for y in [0, 8]:
        for x in range(16):
            img.set_pixel(x, y, V097_ROAD_DARK)
    var offset := 0 if variant % 2 == 0 else 4
    for x in [offset, offset + 8]:
        if x >= 0 and x < 16:
            for y in range(0, 8):
                img.set_pixel(x, y, V097_ROAD_DARK.darkened(0.03))
    for x in [4 - offset, 12 - offset]:
        if x >= 0 and x < 16:
            for y in range(9, 16):
                img.set_pixel(x, y, V097_ROAD_DARK.darkened(0.03))
    img.set_pixel((variant * 5 + 3) % 15, 4, V097_ROAD_LIGHT)
    img.set_pixel((variant * 7 + 9) % 15, 12, V097_ROAD_DARK)

func _v097_paint_path(img: Image, variant: int) -> void:
    img.fill(V097_PATH)
    # Warm paving with low-contrast 8px stones, closer to the references than
    # the old dense gray engineering grid.
    for x in range(16):
        img.set_pixel(x, 8, V097_PATH_DARK)
    for y in range(0, 8):
        img.set_pixel(8, y, V097_PATH_DARK)
    for y in range(9, 16):
        img.set_pixel(4, y, V097_PATH_DARK)
        img.set_pixel(12, y, V097_PATH_DARK)
    img.set_pixel(2 + variant * 3, 3, V097_PATH_LIGHT)
    img.set_pixel(13 - variant * 2, 12, V097_PATH_DARK.darkened(0.08))

func _v097_paint_lot(img: Image, variant: int) -> void:
    img.fill(V097_LOT)
    # Foundation concrete has broad slabs, not a repeated micro-grid.
    for x in range(16):
        img.set_pixel(x, 8, V097_LOT_DARK)
    img.set_pixel(4 + variant, 4, V097_LOT.lightened(0.12))
    img.set_pixel(11 - variant, 12, V097_LOT_DARK.darkened(0.08))

func _v097_paint_water(img: Image, variant: int) -> void:
    img.fill(V097_WATER)
    for y in [3, 9, 14]:
        for x in range((variant + y) % 4, 16, 4):
            img.set_pixel(x, y, V097_WATER_LIGHT)
            if x + 1 < 16:
                img.set_pixel(x + 1, y, V097_WATER_LIGHT)
    img.set_pixel(2 + variant, 6, V097_WATER_DARK)
    img.set_pixel(10 - variant, 12, V097_WATER_DARK)

func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
    var p := VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    var variant := absi(cell.x * 17 + cell.y * 31 + tile_id * 13) % 4
    var texture = pixel_landscape_textures.get(Vector2i(tile_id, variant), null)
    if texture == null:
        super._draw_art_tile(cell, tile_id)
        return

    draw_texture_rect(texture, Rect2(p, Vector2(DISPLAY_TILE_SIZE + 1.0, DISPLAY_TILE_SIZE + 1.0)), false)

    if tile_id == TILE_ROAD:
        _v097_draw_edges(cell, p, TILE_ROAD, V097_ROAD_LIGHT, V097_ROAD_DARK)
    elif tile_id == TILE_PLAZA:
        _v097_draw_edges(cell, p, TILE_PLAZA, V097_PATH_LIGHT, V097_PATH_DARK, 2.0)
    elif tile_id == TILE_LOT:
        _v097_draw_edges(cell, p, TILE_LOT, V097_LOT.lightened(0.12), V097_LOT_DARK, 2.0)
    elif tile_id == TILE_WATER:
        _v097_draw_edges(cell, p, TILE_WATER, V097_WATER_LIGHT, V097_WATER_DARK, 3.0)

func _v097_draw_edges(cell: Vector2i, p: Vector2, tile_id: int, light: Color, dark: Color, width: float = 3.0) -> void:
    # Pixelorama-style terrain peering: only draw an edge when the neighboring
    # terrain differs. Interior tile boundaries disappear completely.
    if int(art_cells.get(cell + Vector2i.UP, -999)) != tile_id:
        draw_rect(Rect2(p, Vector2(48.0, width)), light, true)
    if int(art_cells.get(cell + Vector2i.DOWN, -999)) != tile_id:
        draw_rect(Rect2(p + Vector2(0.0, 48.0 - width), Vector2(48.0, width)), dark, true)
    if int(art_cells.get(cell + Vector2i.LEFT, -999)) != tile_id:
        draw_rect(Rect2(p, Vector2(width, 48.0)), light.darkened(0.06), true)
    if int(art_cells.get(cell + Vector2i.RIGHT, -999)) != tile_id:
        draw_rect(Rect2(p + Vector2(48.0 - width, 0.0), Vector2(width, 48.0)), dark, true)

# ---------------------------------------------------------------------------
# BUILDINGS: generated source sprites instead of large vector rectangles.
# ---------------------------------------------------------------------------

func _v097_texture(style: String, accent: Color, size_value: Vector2):
    var src := Vector2i(maxi(72, int(round(size_value.x * 0.5))), maxi(64, int(round(size_value.y * 0.5))))
    var key := "%s|%s|%dx%d" % [style, accent.to_html(false), src.x, src.y]
    if not v097_building_cache.has(key):
        v097_building_cache[key] = PixelRpgBuildingRenderer.create_texture(style, accent, src)
    return v097_building_cache[key]

func _v097_draw_building(pos: Vector2, size_value: Vector2, accent: Color, style: String) -> void:
    var texture = _v097_texture(style, accent, size_value)
    var top_left := VisualStack.snap_to_pixel(pos + Vector2(-size_value.x * 0.5, -size_value.y * 0.62))
    draw_texture_rect(texture, Rect2(top_left, size_value), false)

func _draw_pixel_facility(pos: Vector2, size_value: Vector2, accent: Color, _floors: int, _badge: String) -> void:
    _v097_draw_building(pos, size_value, accent, "partner")

func _draw_facility_surface_detail(_pos: Vector2, _size_value: Vector2, _accent: Color, _seed: int) -> void:
    # Surface detail is baked into the source sprite. Avoid overlaying the old
    # wall seams, rooftop boxes and hazard stripes on top of the new art.
    pass

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var kind := String(entity.get("kind", "hq"))
    var profile_idx := int(entity.get("profile_idx", company_idx))
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    if kind == "rival" and bool(rivals[int(entity["rival_idx"])]["merged"]):
        accent = Color("657078")
    var size_value := WorldScale.size_for_kind(kind)
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))
    _v097_draw_building(pos, size_value, accent, "hq")
    _draw_v088_entry_cue(kind, pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 44.0)

func _draw_partner_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent: Color = PARTNER_ACCENTS[int(entity["partner_idx"])]
    var size_value := WorldScale.PARTNER_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius("partner"))
    _v097_draw_building(pos, size_value, accent, "partner")
    _draw_v088_entry_cue("partner", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 42.0)

func _draw_machine_market(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("bd8cff")
    var size_value := WorldScale.SERVICE_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius("machines"))
    _v097_draw_building(pos, size_value, accent, "machines")
    _draw_v088_entry_cue("machines", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 40.0)

func _draw_bank_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent: Color = ORANGE
    var size_value := WorldScale.SERVICE_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius("bank"))
    _v097_draw_building(pos, size_value, accent, "bank")
    _draw_v088_entry_cue("bank", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 40.0)

func _draw_land_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("8ed06c")
    var size_value := WorldScale.SERVICE_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius("land"))
    _v097_draw_building(pos, size_value, accent, "land")
    _draw_v088_entry_cue("land", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 40.0)

func _draw_power_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("ffd36e")
    var size_value := WorldScale.SERVICE_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius("power"))
    _v097_draw_building(pos, size_value, accent, "power")

    # Readable outdoor transformer details at the front-right edge.
    var yard := Rect2(pos + Vector2(62.0, 42.0), Vector2(72.0, 50.0))
    draw_rect(yard.grow(3.0), Color("35423f"), true)
    draw_rect(yard, Color("8f998d"), true)
    for i in range(3):
        var cx := yard.position.x + 14.0 + float(i) * 22.0
        draw_rect(Rect2(Vector2(cx - 6.0, yard.position.y + 17.0), Vector2(12.0, 21.0)), Color("59645e"), true)
        draw_rect(Rect2(Vector2(cx - 4.0, yard.position.y + 19.0), Vector2(8.0, 17.0)), Color("858f86"), true)
        draw_line(Vector2(cx, yard.position.y + 17.0), Vector2(cx, yard.position.y + 7.0), Color("d8dfd3"), 3.0)
        draw_rect(Rect2(Vector2(cx - 5.0, yard.position.y + 8.0), Vector2(10.0, 3.0)), Color("2d3734"), true)

    _draw_v088_entry_cue("power", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 40.0)

# ---------------------------------------------------------------------------
# TOWN COMPOSITION: consistent secondary sprites + landscaping.
# ---------------------------------------------------------------------------

func _draw_mining_campus(center: Vector2, accent: Color) -> void:
    # Small warm path, not a screen-filling cross.
    _campus_path(Rect2(center + Vector2(-28.0, -158.0), Vector2(56.0, 300.0)))
    _campus_path(Rect2(center + Vector2(-180.0, 82.0), Vector2(360.0, 48.0)))

    # Two support buildings behind the interactive HQ use the same sprite system
    # so the scene no longer mixes incompatible rectangle/vector styles.
    var support_size := Vector2(126.0, 92.0)
    _v097_draw_building(center + Vector2(-178.0, -112.0), support_size, accent.lightened(0.10), "partner")
    _v097_draw_building(center + Vector2(178.0, -112.0), support_size, Color("45b6df"), "partner")

    _campus_solar_array(center + Vector2(-188.0, 118.0))
    _campus_tree(center + Vector2(-270.0, -14.0))
    _campus_tree(center + Vector2(260.0, 75.0))
    _v097_hedge(center + Vector2(-205.0, 42.0), 5)
    _v097_hedge(center + Vector2(120.0, 42.0), 4)
    _v097_flower_bed(center + Vector2(-95.0, 142.0), 7)

func _v097_hedge(start: Vector2, count: int) -> void:
    for i in range(count):
        var p := start + Vector2(float(i) * 24.0, 0.0)
        draw_rect(Rect2(p + Vector2(2.0, 8.0), Vector2(20.0, 12.0)), Color("2f713b"), true)
        draw_rect(Rect2(p + Vector2(4.0, 3.0), Vector2(16.0, 12.0)), Color("55a04b"), true)
        draw_rect(Rect2(p + Vector2(7.0, 3.0), Vector2(7.0, 4.0)), Color("86c95d"), true)

func _v097_flower_bed(start: Vector2, count: int) -> void:
    draw_rect(Rect2(start + Vector2(-6.0, 5.0), Vector2(float(count) * 15.0 + 12.0, 18.0)), Color("7c5c3e"), true)
    for i in range(count):
        var p := start + Vector2(float(i) * 15.0, 0.0)
        draw_rect(Rect2(p + Vector2(5.0, 9.0), Vector2(3.0, 9.0)), Color("3e7d3e"), true)
        draw_rect(Rect2(p + Vector2(2.0, 3.0), Vector2(9.0, 7.0)), V097_FLOWER_PINK if i % 2 == 0 else V097_FLOWER_YELLOW, true)

func debug_v097_ready() -> bool:
    return (
        V097_GRAPHICS_REVISION == 1
        and debug_v096_ready()
        and PixelRpgBuildingRenderer != null
        and pixel_landscape_textures.size() == 24
    )
