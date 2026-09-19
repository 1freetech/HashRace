extends "res://scripts/world_v095.gd"

# Hash Race v0.096 town-composition + power-clarity pass.
# Goal: replace the noisy checkerboard parcel look with readable RPG-style
# neighborhoods, make campuses read as intentional blocks, and give the power
# building a recognizable substation/transformer silhouette.

const V096_VISUAL_REVISION: int = 1
const V096_PAVER_DARK := Color("70756f")
const V096_PAVER_MID := Color("9b9b8d")
const V096_PAVER_LIGHT := Color("c2bea6")
const V096_LOT_DARK := Color("3e4a4e")
const V096_LOT_MID := Color("5a686c")
const V096_POWER_GOLD := Color("ffd36e")
const V096_POWER_CYAN := Color("52e7ff")
const V096_POWER_INK := Color("101820")
const V096_COPPER := Color("d8843b")
const V096_PORCELAIN := Color("d8e3dc")

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v096_visual_revision", V096_VISUAL_REVISION)
    queue_redraw()

# ---------------------------------------------------------------------------
# TERRAIN COMPOSITION
# ---------------------------------------------------------------------------
# The old plaza texture drew seams every four source pixels. At 3x scale that
# becomes a very dense screen-wide checkerboard. Use larger 8x8 pavers with a
# restrained seam/highlight pattern so paths read as paths instead of noise.
func _paint_walkway_pixels(img: Image, _palette: Array, variant: int) -> void:
    img.fill(V096_PAVER_MID)
    for y in range(MICRO_TILE_SIZE):
        for x in range(MICRO_TILE_SIZE):
            if x == 0 or y == 0:
                img.set_pixel(x, y, V096_PAVER_DARK)
            elif x == 8 or y == 8:
                img.set_pixel(x, y, V096_PAVER_DARK.darkened(0.08))
            elif (x == 7 and y < 8) or (y == 7 and x >= 8):
                img.set_pixel(x, y, V096_PAVER_LIGHT.darkened(0.08))
    # Tiny variation prevents obvious copy/paste without making every tile noisy.
    var chip_x: int = 3 + (variant * 3) % 10
    var chip_y: int = 4 + (variant * 5) % 8
    img.set_pixel(chip_x, chip_y, V096_PAVER_LIGHT)
    if chip_x + 1 < MICRO_TILE_SIZE:
        img.set_pixel(chip_x + 1, chip_y, V096_PAVER_DARK)

# Industrial pads now use broad concrete slabs rather than a 5-pixel mini-grid.
func _paint_lot_pixels(img: Image, _palette: Array, variant: int) -> void:
    img.fill(V096_LOT_MID)
    for i in range(MICRO_TILE_SIZE):
        img.set_pixel(i, 0, V096_LOT_DARK)
        img.set_pixel(0, i, V096_LOT_DARK)
        img.set_pixel(i, 8, V096_LOT_DARK.darkened(0.08))
        img.set_pixel(8, i, V096_LOT_DARK.darkened(0.08))
    img.set_pixel(12 - variant, 3 + variant, V096_LOT_MID.lightened(0.12))
    img.set_pixel(4 + variant, 12 - variant, V096_LOT_DARK.darkened(0.12))

# Recompose every town as a clean neighborhood: grass block, one main avenue,
# one cross street, and four purposeful facility pads. This keeps parcel edges
# predictable and removes the "random gray squares everywhere" look.
func _stamp_campus_walkways() -> void:
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = zone["center"]
        var c: Vector2i = _world_to_art_cell(center)

        # Coherent green neighborhood envelope.
        for y in range(c.y - 5, c.y + 6):
            for x in range(c.x - 6, c.x + 7):
                var cell := Vector2i(x, y)
                if not art_cells.has(cell):
                    continue
                var existing := int(art_cells[cell])
                if existing == TILE_WATER or existing == TILE_ROAD:
                    continue
                art_cells[cell] = TILE_GRASS_DARK if ((x + y) % 9 == 0) else TILE_GRASS

        # Main north/south avenue and east/west pedestrian street.
        for y in range(c.y - 5, c.y + 6):
            _set_v096_walkway(Vector2i(c.x, y))
            _set_v096_walkway(Vector2i(c.x + 1, y))
        for x in range(c.x - 6, c.x + 7):
            _set_v096_walkway(Vector2i(x, c.y))
            _set_v096_walkway(Vector2i(x, c.y + 1))

        # Facility pads live beside the streets, never sprayed across the map.
        _stamp_v096_pad(c + Vector2i(-4, -3), Vector2i(3, 2))
        _stamp_v096_pad(c + Vector2i(2, -3), Vector2i(3, 2))
        _stamp_v096_pad(c + Vector2i(-4, 2), Vector2i(3, 2))
        _stamp_v096_pad(c + Vector2i(2, 2), Vector2i(3, 2))

func _set_v096_walkway(cell: Vector2i) -> void:
    if not art_cells.has(cell):
        return
    var existing := int(art_cells[cell])
    if existing != TILE_WATER and existing != TILE_ROAD:
        art_cells[cell] = TILE_PLAZA

func _stamp_v096_pad(top_left: Vector2i, size_cells: Vector2i) -> void:
    for oy in range(size_cells.y):
        for ox in range(size_cells.x):
            var cell := top_left + Vector2i(ox, oy)
            if not art_cells.has(cell):
                continue
            var existing := int(art_cells[cell])
            if existing != TILE_WATER and existing != TILE_ROAD:
                art_cells[cell] = TILE_LOT

# Cleaner three-building campus composition inspired by classic 3/4 RPG towns:
# structures sit beside paths, entrances face the walkable center, and empty
# green space separates silhouettes.
func _draw_mining_campus(center: Vector2, accent: Color) -> void:
    _campus_path(Rect2(center + Vector2(-34.0, -172.0), Vector2(68.0, 344.0)))
    _campus_path(Rect2(center + Vector2(-220.0, -28.0), Vector2(440.0, 56.0)))

    _campus_building(center + Vector2(-150.0, -105.0), Vector2(132.0, 86.0), "", accent, 0)
    _campus_building(center + Vector2(150.0, -105.0), Vector2(150.0, 92.0), "", accent, 1)
    _campus_building(center + Vector2(148.0, 116.0), Vector2(134.0, 82.0), "", Color("45b6df"), 2)

    _campus_solar_array(center + Vector2(-170.0, 118.0))
    _campus_cooling_rack(center + Vector2(-160.0, 54.0), accent)
    _campus_tree(center + Vector2(-258.0, -18.0))
    _campus_tree(center + Vector2(252.0, 80.0))
    _campus_tree(center + Vector2(-250.0, 164.0))

# ---------------------------------------------------------------------------
# POWER DISTRIBUTION
# ---------------------------------------------------------------------------
# Draw a subtle, readable distribution route between the utility building and
# the active HQ. It is intentionally narrow and low-contrast so it communicates
# "power path" without becoming another UI overlay.
func _draw_world_props_pixel() -> void:
    super._draw_world_props_pixel()
    var power_pos := _v096_entity_pos("power")
    var hq_pos := _v096_entity_pos("hq")
    if power_pos == Vector2.INF or hq_pos == Vector2.INF:
        return

    var start := power_pos + Vector2(0.0, 128.0)
    var finish := hq_pos + Vector2(0.0, 128.0)
    var bus_y := maxf(start.y, finish.y) + 92.0
    var p1 := Vector2(start.x, bus_y)
    var p2 := Vector2(finish.x, bus_y)

    _v096_power_segment(start, p1)
    _v096_power_segment(p1, p2)
    _v096_power_segment(p2, finish)

    for point in [start, p1, p2, finish]:
        draw_circle(point, 8.0, V096_POWER_INK)
        draw_circle(point, 4.0, V096_POWER_GOLD)

func _v096_power_segment(a: Vector2, b: Vector2) -> void:
    draw_line(a, b, Color("071018cc"), 8.0)
    draw_line(a, b, Color("ffd36eaa"), 3.0)
    var length := a.distance_to(b)
    if length < 40.0:
        return
    var direction := (b - a).normalized()
    var distance := 28.0
    while distance < length - 18.0:
        var p := a + direction * distance
        var side := Vector2(-direction.y, direction.x)
        draw_line(p - direction * 5.0 - side * 4.0, p + side * 4.0, V096_POWER_CYAN, 2.0)
        draw_line(p - direction * 5.0 + side * 4.0, p - side * 4.0, V096_POWER_CYAN, 2.0)
        distance += 58.0

func _v096_entity_pos(kind_name: String) -> Vector2:
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        if String(entity.get("kind", "")) == kind_name:
            return Vector2(entity.get("pos", Vector2.ZERO))
    return Vector2.INF

# Make the utility destination look like a real compact substation rather than
# three generic boxes: transformer tank, cooling fins, bushings, insulators,
# bus bars, warning plate, service conduits and a visible energized path.
func _draw_power_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var kind := "power"
    var size_value := WorldScale.SERVICE_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))
    _draw_pixel_facility(pos, size_value, V096_POWER_GOLD, 3, "")
    _draw_facility_surface_detail(pos, size_value, V096_POWER_GOLD, 963)

    # Transformer oil tank.
    var tank := Rect2(pos + Vector2(-76.0, -24.0), Vector2(152.0, 64.0))
    draw_rect(tank.grow(4.0), V096_POWER_INK, true)
    draw_rect(tank, Color("52636a"), true)
    draw_rect(Rect2(tank.position + Vector2(4.0, 4.0), Vector2(tank.size.x - 8.0, 7.0)), Color("7f9196"), true)
    draw_rect(Rect2(tank.position + Vector2(6.0, tank.size.y - 11.0), Vector2(tank.size.x - 12.0, 5.0)), Color("34434a"), true)

    # Radiator cooling fins.
    for i in range(9):
        var fx := tank.position.x + 10.0 + float(i) * 15.0
        draw_rect(Rect2(Vector2(fx, tank.position.y + 15.0), Vector2(7.0, 37.0)), Color("34434a"), true)
        draw_rect(Rect2(Vector2(fx + 2.0, tank.position.y + 17.0), Vector2(2.0, 33.0)), Color("6f8085"), true)

    # Three HV bushings/insulators and copper bus.
    var bushing_xs := [-48.0, 0.0, 48.0]
    for raw_x in bushing_xs:
        var bx := pos.x + float(raw_x)
        draw_line(Vector2(bx, pos.y - 28.0), Vector2(bx, pos.y - 70.0), V096_COPPER, 4.0)
        for ring in range(4):
            var ry := pos.y - 40.0 - float(ring) * 8.0
            draw_rect(Rect2(Vector2(bx - 8.0, ry - 3.0), Vector2(16.0, 5.0)), V096_POWER_INK, true)
            draw_rect(Rect2(Vector2(bx - 6.0, ry - 2.0), Vector2(12.0, 3.0)), V096_PORCELAIN, true)
        draw_circle(Vector2(bx, pos.y - 73.0), 5.0, V096_POWER_GOLD)
    draw_line(pos + Vector2(-58.0, -78.0), pos + Vector2(58.0, -78.0), V096_COPPER, 4.0)

    # Breaker/control cabinet.
    var cabinet := Rect2(pos + Vector2(90.0, -10.0), Vector2(42.0, 58.0))
    draw_rect(cabinet.grow(3.0), V096_POWER_INK, true)
    draw_rect(cabinet, Color("7c8582"), true)
    draw_rect(Rect2(cabinet.position + Vector2(7.0, 8.0), Vector2(28.0, 18.0)), Color("26363b"), true)
    draw_circle(cabinet.position + Vector2(14.0, 38.0), 4.0, Color("64ff8c"))
    draw_circle(cabinet.position + Vector2(27.0, 38.0), 4.0, Color("ffbd66"))

    # Ground-level cable/conduit exits visually connect to the distribution line.
    for xoff in [-30.0, 0.0, 30.0]:
        var a := pos + Vector2(xoff, 43.0)
        var b := pos + Vector2(xoff, 96.0)
        draw_line(a, b, V096_POWER_INK, 7.0)
        draw_line(a, b, V096_POWER_CYAN.darkened(0.18), 3.0)

    # Tiny hazard plate keeps the object recognizable without adding big text.
    var hazard := Rect2(pos + Vector2(-12.0, 6.0), Vector2(24.0, 18.0))
    draw_rect(hazard, Color("111a1f"), true)
    draw_colored_polygon(PackedVector2Array([
        hazard.position + Vector2(12.0, 2.0),
        hazard.position + Vector2(21.0, 16.0),
        hazard.position + Vector2(3.0, 16.0)
    ]), V096_POWER_GOLD)

    _draw_v088_entry_cue(kind, pos, size_value, V096_POWER_GOLD)
    _draw_building_name(entity, idx, V096_POWER_GOLD, size_value.y * 0.38 + 34.0, size_value.x + 40.0)

func debug_v096_ready() -> bool:
    return (
        V096_VISUAL_REVISION == 1
        and debug_v095_ready()
        and _v096_entity_pos("power") != Vector2.INF
        and _v096_entity_pos("hq") != Vector2.INF
    )
