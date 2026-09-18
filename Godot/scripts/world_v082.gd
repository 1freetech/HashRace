extends "res://scripts/world_v080.gd"

# Hash Race v0.082 Gen-2-style microtile pass.
# Inspired by the supplied MIT-licensed Pokemon-gen-2-style-tilemap tooling:
# use named 8x8 source modules to construct larger 48px terrain cells and
# building surfaces. This keeps detail structured without copying artwork.

const Gen2Micro = preload("res://scripts/gen2_microtile_rules.gd")

const V082_MICROTILE_REVISION: int = 1
const V082_SOURCE: String = "Pokemon-gen-2-style-tilemap (MIT, Niko)"
const V082_MICRO: float = 8.0

func _ready() -> void:
    super._ready()
    set_meta("hashrace_gen2_microtile_revision", V082_MICROTILE_REVISION)
    set_meta("hashrace_microtile_size", V082_MICRO)
    queue_redraw()

func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
    super._draw_art_tile(cell, tile_id)
    var origin := VisualStack.snap_to_pixel(
        Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE)
    )
    var seed: int = _detail_seed(cell, tile_id + 820)
    _draw_v082_microtile_overlay(cell, origin, tile_id, seed)

func _draw_v082_microtile_overlay(cell: Vector2i, origin: Vector2, tile_id: int, seed: int) -> void:
    var mask: int = Gen2Micro.neighbor_mask(art_cells, cell, tile_id)
    match tile_id:
        TILE_GRASS, TILE_GRASS_DARK:
            _draw_v082_grass_microtiles(origin, seed, tile_id == TILE_GRASS_DARK)
        TILE_ROAD:
            _draw_v082_road_microtiles(origin, seed, mask)
        TILE_WATER:
            _draw_v082_water_microtiles(origin, seed, mask)
        TILE_LOT:
            _draw_v082_lot_microtiles(origin, seed)
        TILE_PLAZA:
            _draw_v082_plaza_microtiles(origin, seed)

func _draw_v082_grass_microtiles(origin: Vector2, seed: int, dark_variant: bool) -> void:
    var low := Color("163427") if not dark_variant else Color("0b241b")
    var mid := Color("2d6044") if not dark_variant else Color("1b4632")
    var high := Color("4e8c5e") if not dark_variant else Color("347052")
    var slots: Array[Vector2i] = Gen2Micro.motif_slots(seed, 5)
    for i in range(slots.size()):
        var p: Vector2 = Gen2Micro.micro_origin(origin, slots[i])
        var tone: Color = high if i % 3 == 0 else (mid if i % 3 == 1 else low)
        draw_rect(Rect2(p + Vector2(1.0, 5.0), Vector2(2.0, 2.0)), tone, true)
        draw_rect(Rect2(p + Vector2(4.0, 2.0), Vector2(3.0, 2.0)), tone, true)
        if i % 2 == 0:
            draw_rect(Rect2(p + Vector2(5.0, 4.0), Vector2(2.0, 2.0)), low, true)

func _draw_v082_road_microtiles(origin: Vector2, seed: int, mask: int) -> void:
    var slots: Array[Vector2i] = Gen2Micro.motif_slots(seed, 4)
    for i in range(slots.size()):
        var p: Vector2 = Gen2Micro.micro_origin(origin, slots[i])
        var tone := Color("3a4850") if i % 2 == 0 else Color("202b31")
        draw_rect(Rect2(p + Vector2(2.0, 3.0), Vector2(4.0, 2.0)), tone, true)
        if i % 2 == 0:
            draw_rect(Rect2(p + Vector2(5.0, 6.0), Vector2(2.0, 1.0)), Color("65757c"), true)
    _draw_v082_edge_modules(origin, mask, Color("65767d"), Color("1c282e"))

func _draw_v082_water_microtiles(origin: Vector2, seed: int, mask: int) -> void:
    var phase: int = int(Time.get_ticks_msec() / 240) % Gen2Micro.CELL_MICROTILES
    for row in range(3):
        var cell_x: int = (seed + row * 3 + phase) % Gen2Micro.CELL_MICROTILES
        var p := origin + Vector2(float(cell_x) * V082_MICRO, 6.0 + float(row) * 14.0)
        draw_rect(Rect2(p, Vector2(6.0, 2.0)), Color("5bc7d1"), true)
        draw_rect(Rect2(p + Vector2(3.0, 3.0), Vector2(4.0, 2.0)), Color("1a7487"), true)
    _draw_v082_edge_modules(origin, mask, Color("6bd4d9"), Color("0a3c50"))

func _draw_v082_lot_microtiles(origin: Vector2, seed: int) -> void:
    for i in range(1, Gen2Micro.CELL_MICROTILES):
        if (i + seed) % 2 == 0:
            var offset: float = float(i) * V082_MICRO
            draw_rect(Rect2(origin + Vector2(offset, 4.0), Vector2(1.0, 40.0)), Color("38454a"), true)
            draw_rect(Rect2(origin + Vector2(4.0, offset), Vector2(40.0, 1.0)), Color("38454a"), true)
    for slot in Gen2Micro.motif_slots(seed + 31, 3):
        var p: Vector2 = Gen2Micro.micro_origin(origin, slot)
        draw_rect(Rect2(p + Vector2(3.0, 3.0), Vector2(2.0, 2.0)), Color("7c8a8f"), true)

func _draw_v082_plaza_microtiles(origin: Vector2, seed: int) -> void:
    for y in range(0, Gen2Micro.CELL_MICROTILES, 2):
        for x in range((int(y / 2) + seed) % 2, Gen2Micro.CELL_MICROTILES, 2):
            var p := origin + Vector2(float(x) * V082_MICRO, float(y) * V082_MICRO)
            draw_rect(Rect2(p + Vector2(1.0, 1.0), Vector2(6.0, 6.0)), Color("617076"), false, 1.0)

func _draw_v082_edge_modules(origin: Vector2, mask: int, light: Color, dark: Color) -> void:
    if not Gen2Micro.has_neighbor(mask, Gen2Micro.NORTH):
        for x in range(Gen2Micro.CELL_MICROTILES):
            var tone: Color = light if x % 2 == 0 else dark
            draw_rect(Rect2(origin + Vector2(float(x) * V082_MICRO, 0.0), Vector2(7.0, 2.0)), tone, true)
    if not Gen2Micro.has_neighbor(mask, Gen2Micro.SOUTH):
        for x in range(Gen2Micro.CELL_MICROTILES):
            var tone: Color = dark if x % 2 == 0 else light
            draw_rect(Rect2(origin + Vector2(float(x) * V082_MICRO, 46.0), Vector2(7.0, 2.0)), tone, true)
    if not Gen2Micro.has_neighbor(mask, Gen2Micro.WEST):
        for y in range(Gen2Micro.CELL_MICROTILES):
            var tone: Color = light if y % 2 == 0 else dark
            draw_rect(Rect2(origin + Vector2(0.0, float(y) * V082_MICRO), Vector2(2.0, 7.0)), tone, true)
    if not Gen2Micro.has_neighbor(mask, Gen2Micro.EAST):
        for y in range(Gen2Micro.CELL_MICROTILES):
            var tone: Color = dark if y % 2 == 0 else light
            draw_rect(Rect2(origin + Vector2(46.0, float(y) * V082_MICRO), Vector2(2.0, 7.0)), tone, true)

func _draw_facility_surface_detail(pos: Vector2, size_value: Vector2, accent: Color, seed: int) -> void:
    super._draw_facility_surface_detail(pos, size_value, accent, seed)
    var snapped_pos: Vector2 = _v080_snap(pos)
    var size_px: Vector2 = _v080_snap_size(size_value)
    var left: float = Gen2Micro.snap_to_micro(snapped_pos.x - size_px.x * 0.5)
    var top: float = Gen2Micro.snap_to_micro(snapped_pos.y - size_px.y * 0.62)
    var panel_dark: Color = Color("0d171c")
    var panel_mid: Color = Color("26363d")
    var panel_hi: Color = accent.darkened(0.18)

    var columns: int = maxi(1, int(floor((size_px.x - 32.0) / 16.0)))
    var rows: int = maxi(1, mini(4, int(floor((size_px.y - 52.0) / 16.0))))
    for row in range(rows):
        for col in range(columns):
            if (col + row + seed) % 3 != 0:
                continue
            var px: float = left + 16.0 + float(col) * 16.0
            var py: float = top + 36.0 + float(row) * 16.0
            draw_rect(Rect2(px, py, 8.0, 4.0), panel_dark, true)
            draw_rect(Rect2(px + 8.0, py, 4.0, 4.0), panel_mid, true)
            if (col + seed) % 4 == 0:
                draw_rect(Rect2(px + 4.0, py + 6.0, 8.0, 2.0), panel_hi, true)

func debug_v082_ready() -> bool:
    return (
        debug_v080_ready()
        and V082_MICROTILE_REVISION >= 1
        and is_equal_approx(V082_MICRO, 8.0)
        and is_equal_approx(ART_TILE_SIZE, Gen2Micro.CELL_SIZE)
        and Gen2Micro.source_contract_ready()
    )
