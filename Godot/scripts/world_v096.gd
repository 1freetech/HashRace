extends "res://scripts/world_v095.gd"

# Hash Race v0.096 visual-cohesion pass.
# Rebuilds the live procedural overworld around the same 48 px gameplay grid,
# but renders it like one authored RPG town instead of a field of unrelated
# rectangles. Roads/lots use neighbor-aware edges, facilities gain a readable
# 3/4 roof/front/side silhouette, frontage paths connect doors to streets, and
# electrical infrastructure uses fenced transformer yards plus orthogonal
# distribution routes instead of loose diagonal wires.

const V096_VISUAL_COHESION_REVISION: int = 1
const V096_BUILDING_PLACER = preload("res://scripts/building_placer.gd")

const V096_GRASS := Color("3f7a58")
const V096_GRASS_DARK := Color("32674b")
const V096_GRASS_LIGHT := Color("5c9368")
const V096_ROAD := Color("515a5b")
const V096_ROAD_DARK := Color("3f484a")
const V096_ROAD_LIGHT := Color("6b7472")
const V096_CURB := Color("b4b3a7")
const V096_CURB_SHADOW := Color("6f716b")
const V096_LOT := Color("747b75")
const V096_LOT_LIGHT := Color("858c84")
const V096_LOT_DARK := Color("545c58")
const V096_PLAZA := Color("a09f91")
const V096_PLAZA_LIGHT := Color("b9b7a5")
const V096_WATER := Color("2f7891")
const V096_WATER_LIGHT := Color("65b9c4")

const V096_INK := Color("11171a")
const V096_WALL := Color("59666a")
const V096_WALL_LIGHT := Color("738085")
const V096_WALL_DARK := Color("354247")
const V096_WINDOW := Color("173744")
const V096_WINDOW_LIGHT := Color("4ea5b4")
const V096_ROOF_EDGE := Color("20292d")
const V096_METAL := Color("7b898b")
const V096_METAL_LIGHT := Color("b9c2c0")
const V096_HAZARD := Color("f4c64f")
const V096_POWER := Color("ffd35a")
const V096_POWER_HI := Color("fff4af")

const V096_FRONTAGE_EDGE := Color("5a5e58")
const V096_FRONTAGE := Color("b6b19d")
const V096_FRONTAGE_HI := Color("d0cbb7")

var v096_power_phase: float = 0.0
var v096_redraw_accum: float = 0.0


func _ready() -> void:
    super._ready()
    set_meta("hashrace_v096_visual_cohesion_revision", V096_VISUAL_COHESION_REVISION)
    set_meta("hashrace_v096_visual_language", "authored-rpg-town")
    queue_redraw()


func _process(delta: float) -> void:
    super._process(delta)
    v096_power_phase = fmod(v096_power_phase + maxf(delta, 0.0), 1000.0)
    v096_redraw_accum += maxf(delta, 0.0)
    if v096_redraw_accum >= 0.18:
        v096_redraw_accum = 0.0
        queue_redraw()


# -----------------------------------------------------------------------------
# Coherent tile rendering.
# The inherited map DATA stays unchanged, so navigation/collision and gameplay
# do not move. Only the paint pass changes. The old per-tile random quadrants are
# removed in favor of continuous surfaces, outer curbs and sparse vegetation.
# -----------------------------------------------------------------------------

func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
    var p := VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    match tile_id:
        TILE_ROAD:
            _draw_v096_road_tile(cell, p)
        TILE_LOT:
            _draw_v096_lot_tile(cell, p)
        TILE_PLAZA:
            _draw_v096_plaza_tile(cell, p)
        TILE_WATER:
            _draw_v096_water_tile(cell, p)
        TILE_GRASS_DARK:
            _draw_v096_grass_tile(cell, p, true)
        _:
            _draw_v096_grass_tile(cell, p, false)


func _draw_v096_grass_tile(cell: Vector2i, p: Vector2, dark_variant: bool) -> void:
    var base := V096_GRASS_DARK if dark_variant else V096_GRASS
    draw_rect(Rect2(p, Vector2(ART_TILE_SIZE + 1.0, ART_TILE_SIZE + 1.0)), base, true)

    # Sparse authored-looking plant clusters. The placement is deterministic,
    # but the motif occupies only selected cells instead of breaking every tile
    # into a noisy checkerboard.
    var motif := posmod(cell.x * 17 + cell.y * 29, 13)
    if motif == 0 or motif == 5:
        var o := p + Vector2(12.0 + float(posmod(cell.y, 3)) * 6.0, 16.0 + float(posmod(cell.x, 2)) * 8.0)
        draw_rect(Rect2(o, Vector2(4.0, 8.0)), V096_GRASS_LIGHT, true)
        draw_rect(Rect2(o + Vector2(7.0, 3.0), Vector2(4.0, 6.0)), V096_GRASS_LIGHT.darkened(0.08), true)
        draw_rect(Rect2(o + Vector2(3.0, 9.0), Vector2(7.0, 3.0)), base.darkened(0.12), true)
    elif motif == 8:
        draw_rect(Rect2(p + Vector2(30.0, 11.0), Vector2(5.0, 5.0)), V096_GRASS_LIGHT.darkened(0.03), true)
        draw_rect(Rect2(p + Vector2(35.0, 16.0), Vector2(4.0, 4.0)), V096_GRASS_LIGHT, true)


func _draw_v096_road_tile(cell: Vector2i, p: Vector2) -> void:
    var rect := Rect2(p, Vector2(ART_TILE_SIZE + 1.0, ART_TILE_SIZE + 1.0))
    draw_rect(rect, V096_ROAD, true)

    # Broad paving bands replace the old tiny repeated quadrant texture.
    if cell.x % 2 == 0:
        draw_rect(Rect2(p + Vector2(0.0, 22.0), Vector2(ART_TILE_SIZE, 2.0)), V096_ROAD_DARK, true)
    if cell.y % 2 == 0:
        draw_rect(Rect2(p + Vector2(23.0, 0.0), Vector2(2.0, ART_TILE_SIZE)), V096_ROAD_LIGHT.darkened(0.13), true)

    # Curbs appear only on the OUTSIDE of the road network. Interior road cells
    # blend into a single street instead of showing a tile border on every cell.
    if not _v096_cell_is_road(cell + Vector2i.UP):
        _v096_draw_horizontal_curb(p, true)
    if not _v096_cell_is_road(cell + Vector2i.DOWN):
        _v096_draw_horizontal_curb(p, false)
    if not _v096_cell_is_road(cell + Vector2i.LEFT):
        _v096_draw_vertical_curb(p, true)
    if not _v096_cell_is_road(cell + Vector2i.RIGHT):
        _v096_draw_vertical_curb(p, false)

    _draw_v096_lane_mark(cell, p)


func _draw_v096_lane_mark(cell: Vector2i, p: Vector2) -> void:
    if posmod(cell.x + cell.y, 2) != 0:
        return
    var tile_center := p + Vector2(ART_TILE_SIZE * 0.5, ART_TILE_SIZE * 0.5)

    # The live road rectangles are the same geometry used by placement checks.
    # Only draw a marking near a route centerline, which reads like a street
    # rather than a grid superimposed on every road tile.
    for road in V096_BUILDING_PLACER.ROAD_RECTS:
        var road_center := road.position + road.size * 0.5
        if road.size.x >= road.size.y:
            if absf(tile_center.y - road_center.y) <= ART_TILE_SIZE * 0.55:
                draw_rect(Rect2(p + Vector2(8.0, 22.0), Vector2(32.0, 3.0)), V096_CURB, true)
                return
        else:
            if absf(tile_center.x - road_center.x) <= ART_TILE_SIZE * 0.55:
                draw_rect(Rect2(p + Vector2(22.0, 8.0), Vector2(3.0, 32.0)), V096_CURB, true)
                return


func _draw_v096_lot_tile(cell: Vector2i, p: Vector2) -> void:
    draw_rect(Rect2(p, Vector2(ART_TILE_SIZE + 1.0, ART_TILE_SIZE + 1.0)), V096_LOT, true)

    # Large slab seams are globally aligned; no random parcel rectangles.
    draw_rect(Rect2(p + Vector2(0.0, 23.0), Vector2(ART_TILE_SIZE, 2.0)), V096_LOT_DARK, true)
    if cell.x % 2 == 0:
        draw_rect(Rect2(p + Vector2(23.0, 0.0), Vector2(2.0, ART_TILE_SIZE)), V096_LOT_LIGHT.darkened(0.16), true)

    _v096_draw_surface_edge(cell, p, TILE_LOT, V096_CURB_SHADOW, V096_CURB)


func _draw_v096_plaza_tile(cell: Vector2i, p: Vector2) -> void:
    draw_rect(Rect2(p, Vector2(ART_TILE_SIZE + 1.0, ART_TILE_SIZE + 1.0)), V096_PLAZA, true)
    draw_rect(Rect2(p + Vector2(0.0, 23.0), Vector2(ART_TILE_SIZE, 2.0)), V096_PLAZA_LIGHT.darkened(0.25), true)
    draw_rect(Rect2(p + Vector2(23.0, 0.0), Vector2(2.0, ART_TILE_SIZE)), V096_PLAZA_LIGHT.darkened(0.20), true)
    _v096_draw_surface_edge(cell, p, TILE_PLAZA, V096_CURB_SHADOW, V096_PLAZA_LIGHT)


func _draw_v096_water_tile(cell: Vector2i, p: Vector2) -> void:
    draw_rect(Rect2(p, Vector2(ART_TILE_SIZE + 1.0, ART_TILE_SIZE + 1.0)), V096_WATER, true)
    var offset := float(posmod(cell.x * 11 + cell.y * 7, 3)) * 6.0
    draw_rect(Rect2(p + Vector2(7.0 + offset, 13.0), Vector2(19.0, 3.0)), V096_WATER_LIGHT, true)
    draw_rect(Rect2(p + Vector2(21.0 - offset * 0.5, 32.0), Vector2(20.0, 3.0)), V096_WATER_LIGHT.darkened(0.13), true)


func _v096_cell_is_road(cell: Vector2i) -> bool:
    return int(art_cells.get(cell, -999)) == TILE_ROAD


func _v096_surface_neighbor_matches(cell: Vector2i, tile_id: int) -> bool:
    var neighbor := int(art_cells.get(cell, -999))
    if tile_id == TILE_LOT:
        return neighbor == TILE_LOT or neighbor == TILE_PLAZA
    if tile_id == TILE_PLAZA:
        return neighbor == TILE_PLAZA or neighbor == TILE_LOT
    return neighbor == tile_id


func _v096_draw_surface_edge(cell: Vector2i, p: Vector2, tile_id: int, shadow: Color, top_color: Color) -> void:
    if not _v096_surface_neighbor_matches(cell + Vector2i.UP, tile_id):
        draw_rect(Rect2(p, Vector2(ART_TILE_SIZE, 4.0)), shadow, true)
        draw_rect(Rect2(p + Vector2(0.0, 1.0), Vector2(ART_TILE_SIZE, 2.0)), top_color, true)
    if not _v096_surface_neighbor_matches(cell + Vector2i.DOWN, tile_id):
        draw_rect(Rect2(p + Vector2(0.0, ART_TILE_SIZE - 4.0), Vector2(ART_TILE_SIZE, 4.0)), shadow, true)
        draw_rect(Rect2(p + Vector2(0.0, ART_TILE_SIZE - 3.0), Vector2(ART_TILE_SIZE, 2.0)), top_color, true)
    if not _v096_surface_neighbor_matches(cell + Vector2i.LEFT, tile_id):
        draw_rect(Rect2(p, Vector2(4.0, ART_TILE_SIZE)), shadow, true)
        draw_rect(Rect2(p + Vector2(1.0, 0.0), Vector2(2.0, ART_TILE_SIZE)), top_color, true)
    if not _v096_surface_neighbor_matches(cell + Vector2i.RIGHT, tile_id):
        draw_rect(Rect2(p + Vector2(ART_TILE_SIZE - 4.0, 0.0), Vector2(4.0, ART_TILE_SIZE)), shadow, true)
        draw_rect(Rect2(p + Vector2(ART_TILE_SIZE - 3.0, 0.0), Vector2(2.0, ART_TILE_SIZE)), top_color, true)


func _v096_draw_horizontal_curb(p: Vector2, top_edge: bool) -> void:
    var y := 0.0 if top_edge else ART_TILE_SIZE - 6.0
    draw_rect(Rect2(p + Vector2(0.0, y), Vector2(ART_TILE_SIZE, 6.0)), V096_CURB_SHADOW, true)
    draw_rect(Rect2(p + Vector2(0.0, y + (1.0 if top_edge else 2.0)), Vector2(ART_TILE_SIZE, 3.0)), V096_CURB, true)


func _v096_draw_vertical_curb(p: Vector2, left_edge: bool) -> void:
    var x := 0.0 if left_edge else ART_TILE_SIZE - 6.0
    draw_rect(Rect2(p + Vector2(x, 0.0), Vector2(6.0, ART_TILE_SIZE)), V096_CURB_SHADOW, true)
    draw_rect(Rect2(p + Vector2(x + (1.0 if left_edge else 2.0), 0.0), Vector2(3.0, ART_TILE_SIZE)), V096_CURB, true)


# -----------------------------------------------------------------------------
# Frontage paths.
# Every building now has a visual front-door connection to the nearest road.
# This makes lots read as intentional blocks and gives the player obvious routes.
# -----------------------------------------------------------------------------

func _draw_world_props_pixel() -> void:
    super._draw_world_props_pixel()
    _draw_v096_frontage_paths()


func _draw_v096_frontage_paths() -> void:
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        var kind := String(entity.get("kind", ""))
        if not WorldScale.is_building_kind(kind):
            continue
        var pos: Vector2 = entity.get("pos", Vector2.ZERO)
        var door := WorldScale.front_door_world_pos(kind, pos)
        var curb := _v096_nearest_road_point(door)
        var distance := door.distance_to(curb)
        if distance < 10.0 or distance > 300.0:
            continue

        var elbow: Vector2
        if absf(curb.x - door.x) > absf(curb.y - door.y):
            elbow = Vector2(curb.x, door.y)
        else:
            elbow = Vector2(door.x, curb.y)

        var points := PackedVector2Array([
            VisualStack.snap_to_pixel(door),
            VisualStack.snap_to_pixel(elbow),
            VisualStack.snap_to_pixel(curb)
        ])
        draw_polyline(points, V096_FRONTAGE_EDGE, 28.0, false)
        draw_polyline(points, V096_FRONTAGE, 20.0, false)
        draw_polyline(points, V096_FRONTAGE_HI, 2.0, false)


func _v096_nearest_road_point(point: Vector2) -> Vector2:
    var best := point
    var best_distance := INF
    for road in V096_BUILDING_PLACER.ROAD_RECTS:
        var candidate := Vector2(
            clampf(point.x, road.position.x, road.end.x),
            clampf(point.y, road.position.y, road.end.y)
        )
        var distance := point.distance_squared_to(candidate)
        if distance < best_distance:
            best_distance = distance
            best = candidate
    return best


# -----------------------------------------------------------------------------
# Original 3/4 industrial facility renderer.
# The same collision footprint is preserved, but a visible roof plane, facade,
# side wall and rooftop units replace the old flat rectangle.
# -----------------------------------------------------------------------------

func _draw_pixel_facility(pos: Vector2, size_value: Vector2, accent: Color, floors: int, badge: String) -> void:
    var snapped := _v096_snap(pos)
    var size_px := _v096_snap_size(size_value)
    var left := _v096_grid(snapped.x - size_px.x * 0.5)
    var top := _v096_grid(snapped.y - size_px.y * 0.62)
    var right := left + size_px.x
    var bottom := top + size_px.y
    var roof_front_y := top + 44.0

    # Ground shadow anchors the building to the parcel.
    draw_rect(
        Rect2(Vector2(left + 16.0, bottom - 4.0) + Vector2(10.0, 10.0), Vector2(size_px.x - 32.0, 14.0)),
        Color("00000055"),
        true
    )

    # Front facade and darker right side wall.
    draw_rect(Rect2(Vector2(left + 8.0, roof_front_y), Vector2(size_px.x - 16.0, bottom - roof_front_y)), V096_INK, true)
    draw_rect(Rect2(Vector2(left + 12.0, roof_front_y + 4.0), Vector2(size_px.x - 44.0, bottom - roof_front_y - 8.0)), V096_WALL, true)
    draw_rect(Rect2(Vector2(right - 32.0, roof_front_y + 8.0), Vector2(20.0, bottom - roof_front_y - 16.0)), V096_WALL_DARK, true)
    draw_rect(Rect2(Vector2(left + 16.0, bottom - 14.0), Vector2(size_px.x - 52.0, 6.0)), accent.darkened(0.38), true)

    # 3/4 roof plane: back edge is higher/narrower, front eave is wider.
    var roof_outer := PackedVector2Array([
        Vector2(left - 4.0, roof_front_y),
        Vector2(left + 28.0, top - 12.0),
        Vector2(right - 28.0, top - 12.0),
        Vector2(right + 4.0, roof_front_y)
    ])
    draw_colored_polygon(roof_outer, V096_ROOF_EDGE)
    var roof_inner := PackedVector2Array([
        Vector2(left + 4.0, roof_front_y - 4.0),
        Vector2(left + 32.0, top - 6.0),
        Vector2(right - 32.0, top - 6.0),
        Vector2(right - 4.0, roof_front_y - 4.0)
    ])
    draw_colored_polygon(roof_inner, accent.darkened(0.43))
    draw_polyline(
        PackedVector2Array([Vector2(left + 4.0, roof_front_y - 5.0), Vector2(right - 4.0, roof_front_y - 5.0)]),
        accent.lightened(0.05),
        5.0,
        false
    )

    # Roof ribs make the top plane legible from the RPG camera.
    for rib in range(1, 5):
        var t := float(rib) / 5.0
        var x0 := lerpf(left + 32.0, right - 32.0, t)
        var x1 := lerpf(left + 7.0, right - 7.0, t)
        draw_line(Vector2(x0, top - 5.0), Vector2(x1, roof_front_y - 8.0), accent.darkened(0.58), 2.0, false)

    # Window rhythm reads as floors without turning the facade into a grid.
    var facade_left := left + 26.0
    var facade_right := right - 52.0
    var usable_width := maxf(48.0, facade_right - facade_left)
    var row_count := clampi(floors, 1, 4)
    for row in range(row_count):
        var wy := roof_front_y + 20.0 + float(row) * 28.0
        if wy > bottom - 50.0:
            break
        for column in range(4):
            var wx := facade_left + float(column) * usable_width / 4.0
            draw_rect(Rect2(Vector2(wx, wy), Vector2(18.0, 12.0)), V096_WINDOW, true)
            draw_rect(Rect2(Vector2(wx + 3.0, wy + 3.0), Vector2(12.0, 3.0)), V096_WINDOW_LIGHT.darkened(0.08), true)

    # Rooftop cooling / ventilation hardware.
    _draw_v096_rooftop_unit(Vector2(left + size_px.x * 0.31, top + 5.0), accent, false)
    _draw_v096_rooftop_unit(Vector2(left + size_px.x * 0.67, top + 5.0), accent, true)

    # Compact building plaque. Keep the world text hierarchy quiet.
    if not badge.is_empty():
        var plaque := Rect2(Vector2(left + 18.0, roof_front_y + 12.0), Vector2(48.0, 20.0))
        draw_rect(plaque, V096_INK, true)
        draw_rect(plaque.grow(-3.0), accent.darkened(0.44), true)
        draw_string(ThemeDB.fallback_font, plaque.position + Vector2(6.0, 15.0), badge.left(6), HORIZONTAL_ALIGNMENT_LEFT, 38.0, 8, accent.lightened(0.22))


func _draw_facility_surface_detail(pos: Vector2, size_value: Vector2, accent: Color, seed: int) -> void:
    var snapped := _v096_snap(pos)
    var size_px := _v096_snap_size(size_value)
    var left := _v096_grid(snapped.x - size_px.x * 0.5)
    var top := _v096_grid(snapped.y - size_px.y * 0.62)
    var bottom := top + size_px.y
    var roof_front_y := top + 44.0

    # One downspout, one service box and restrained wall lights are enough.
    var down_x := left + size_px.x - 44.0
    draw_rect(Rect2(Vector2(down_x, roof_front_y + 8.0), Vector2(5.0, maxf(12.0, bottom - roof_front_y - 18.0))), V096_METAL, true)
    draw_rect(Rect2(Vector2(down_x - 4.0, bottom - 17.0), Vector2(13.0, 5.0)), V096_METAL_LIGHT.darkened(0.18), true)

    var box_x := left + 20.0 + float(posmod(seed * 17, maxi(12, int(size_px.x - 92.0))))
    draw_rect(Rect2(Vector2(box_x, bottom - 38.0), Vector2(22.0, 20.0)), V096_INK, true)
    draw_rect(Rect2(Vector2(box_x + 4.0, bottom - 34.0), Vector2(14.0, 12.0)), V096_WALL_DARK, true)
    draw_rect(Rect2(Vector2(box_x + 7.0, bottom - 31.0), Vector2(8.0, 3.0)), accent, true)

    for light_x in [left + 80.0, left + size_px.x - 88.0]:
        draw_rect(Rect2(Vector2(light_x - 5.0, roof_front_y + 8.0), Vector2(10.0, 5.0)), V096_INK, true)
        draw_rect(Rect2(Vector2(light_x - 3.0, roof_front_y + 9.0), Vector2(6.0, 2.0)), V096_POWER_HI, true)


func _draw_v096_rooftop_unit(center: Vector2, accent: Color, fan: bool) -> void:
    var rect := Rect2(center + Vector2(-18.0, -10.0), Vector2(36.0, 20.0))
    draw_rect(rect, V096_INK, true)
    draw_rect(rect.grow(-3.0), V096_METAL, true)
    if fan:
        draw_circle(center, 6.0, V096_INK)
        draw_line(center + Vector2(-5.0, 0.0), center + Vector2(5.0, 0.0), accent.darkened(0.12), 2.0, false)
        draw_line(center + Vector2(0.0, -5.0), center + Vector2(0.0, 5.0), accent.darkened(0.12), 2.0, false)
    else:
        for slit in range(4):
            draw_rect(Rect2(center + Vector2(-12.0 + float(slit) * 7.0, -4.0), Vector2(4.0, 8.0)), V096_WALL_DARK, true)


func _v096_grid(value: float) -> float:
    return roundf(value / 4.0) * 4.0


func _v096_snap(value: Vector2) -> Vector2:
    return Vector2(_v096_grid(value.x), _v096_grid(value.y))


func _v096_snap_size(value: Vector2) -> Vector2:
    return Vector2(maxf(4.0, _v096_grid(value.x)), maxf(4.0, _v096_grid(value.y)))


# -----------------------------------------------------------------------------
# Power office / transformer yard.
# -----------------------------------------------------------------------------

func _draw_power_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("ffd36e")
    var kind := "power"
    var size_value := WorldScale.SERVICE_SIZE

    _selection_ring(pos, idx, WorldScale.selection_radius(kind))

    # The switch-house sits at the back of the lot; the transformer yard is in
    # front, so the object reads like electrical infrastructure rather than a
    # generic office with three squares pasted on it.
    var switch_pos := pos + Vector2(0.0, -34.0)
    var switch_size := Vector2(size_value.x - 24.0, 118.0)
    _draw_pixel_facility(switch_pos, switch_size, accent, 1, "GRID")
    _draw_facility_surface_detail(switch_pos, switch_size, accent, 963)
    _draw_v096_transformer_yard(pos + Vector2(0.0, 42.0), Vector2(218.0, 88.0), accent)
    _draw_v096_power_gate(kind, pos, accent)

    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 40.0)


func _draw_v096_transformer_yard(center: Vector2, yard_size: Vector2, accent: Color) -> void:
    var yard := Rect2(center - yard_size * 0.5, yard_size)
    draw_rect(Rect2(yard.position + Vector2(5.0, 6.0), yard.size), Color("00000055"), true)
    draw_rect(yard, Color("555c57"), true)

    # Gravel / concrete strips give scale without noisy per-pixel texture.
    for i in range(4):
        draw_rect(Rect2(yard.position + Vector2(8.0, 10.0 + float(i) * 18.0), Vector2(yard.size.x - 16.0, 2.0)), Color("666c64"), true)

    _draw_v096_fence(yard, accent)

    var bus_y := yard.position.y + 17.0
    draw_rect(Rect2(Vector2(yard.position.x + 22.0, bus_y), Vector2(yard.size.x - 44.0, 5.0)), V096_METAL_LIGHT.darkened(0.10), true)
    for i in range(3):
        var tx := yard.position.x + 48.0 + float(i) * ((yard.size.x - 96.0) / 2.0)
        _draw_v096_transformer(Vector2(tx, center.y + 12.0), accent, i)
        draw_line(Vector2(tx, bus_y + 5.0), Vector2(tx, center.y - 16.0), V096_POWER, 3.0, false)

    # Inbound/outbound cable trenches and clear energized nodes.
    draw_rect(Rect2(Vector2(yard.position.x + 6.0, center.y + 27.0), Vector2(40.0, 7.0)), V096_INK, true)
    draw_rect(Rect2(Vector2(yard.position.x + 8.0, center.y + 29.0), Vector2(36.0, 3.0)), V096_POWER, true)
    draw_rect(Rect2(Vector2(yard.end.x - 46.0, center.y + 27.0), Vector2(40.0, 7.0)), V096_INK, true)
    draw_rect(Rect2(Vector2(yard.end.x - 44.0, center.y + 29.0), Vector2(36.0, 3.0)), V096_POWER, true)


func _draw_v096_transformer(center: Vector2, accent: Color, variant: int) -> void:
    var body := Rect2(center + Vector2(-16.0, -19.0), Vector2(32.0, 42.0))
    draw_rect(Rect2(body.position + Vector2(3.0, 5.0), body.size), Color("00000055"), true)
    draw_rect(body, V096_INK, true)
    draw_rect(body.grow(-3.0), Color("66716e"), true)
    draw_rect(Rect2(body.position + Vector2(5.0, 6.0), Vector2(22.0, 7.0)), Color("384448"), true)

    # Cooling fins.
    for fin in range(5):
        draw_rect(Rect2(body.position + Vector2(5.0 + float(fin) * 5.0, 17.0), Vector2(3.0, 14.0)), V096_WALL_DARK, true)

    # Ceramic bushings and energized caps.
    for bushing in [-8.0, 0.0, 8.0]:
        draw_rect(Rect2(center + Vector2(bushing - 2.0, -28.0), Vector2(4.0, 9.0)), V096_METAL_LIGHT, true)
        draw_rect(Rect2(center + Vector2(bushing - 4.0, -30.0), Vector2(8.0, 3.0)), V096_POWER_HI, true)

    # Warning band and operating LED.
    for stripe in range(5):
        var stripe_color := V096_HAZARD if stripe % 2 == 0 else V096_INK
        draw_rect(Rect2(body.position + Vector2(4.0 + float(stripe) * 5.0, 34.0), Vector2(5.0, 4.0)), stripe_color, true)
    var led := Color("5dff76") if variant != 1 else Color("ffae55")
    draw_rect(Rect2(body.position + Vector2(24.0, 8.0), Vector2(3.0, 3.0)), led, true)
    draw_rect(Rect2(body.position + Vector2(5.0, 8.0), Vector2(10.0, 3.0)), accent.darkened(0.20), true)


func _draw_v096_fence(rect: Rect2, accent: Color) -> void:
    draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3.0)), V096_METAL, true)
    draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - 3.0), Vector2(rect.size.x, 3.0)), V096_METAL, true)
    draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), V096_METAL, true)
    draw_rect(Rect2(Vector2(rect.end.x - 3.0, rect.position.y), Vector2(3.0, rect.size.y)), V096_METAL, true)
    for x in range(int(rect.position.x) + 8, int(rect.end.x) - 4, 18):
        draw_rect(Rect2(Vector2(float(x), rect.position.y - 3.0), Vector2(3.0, 8.0)), V096_METAL_LIGHT.darkened(0.12), true)
        draw_rect(Rect2(Vector2(float(x), rect.end.y - 5.0), Vector2(3.0, 8.0)), V096_METAL_LIGHT.darkened(0.12), true)
    draw_rect(Rect2(Vector2(rect.position.x + 6.0, rect.position.y + 6.0), Vector2(18.0, 6.0)), accent.darkened(0.35), true)


func _draw_v096_power_gate(kind: String, pos: Vector2, accent: Color) -> void:
    var target := WorldScale.front_door_world_pos(kind, pos)
    var yard_bottom := pos.y + 86.0
    draw_line(Vector2(pos.x, yard_bottom), target, V096_FRONTAGE_EDGE, 20.0, false)
    draw_line(Vector2(pos.x, yard_bottom), target, V096_FRONTAGE, 14.0, false)
    draw_rect(Rect2(target + Vector2(-18.0, -7.0), Vector2(36.0, 14.0)), V096_INK, true)
    draw_rect(Rect2(target + Vector2(-14.0, -4.0), Vector2(28.0, 8.0)), accent.darkened(0.34), true)
    if rep_pos.distance_to(target) <= INTERACT_DISTANCE + 36.0:
        var alpha := 0.45 + 0.45 * absf(sin(v096_power_phase * 4.0))
        draw_circle(target, 13.0, Color(accent.r, accent.g, accent.b, alpha), false, 3.0)


# The energy campus uses the same detailed transformer language as the power
# office, keeping infrastructure visually consistent across the world.
func _draw_substation(pos: Vector2) -> void:
    _draw_v096_transformer_yard(pos, Vector2(112.0, 82.0), V096_POWER)


# -----------------------------------------------------------------------------
# Clear electrical distribution.
# The old diagonal line looked like a loose cable thrown across the map. Power
# now follows an orthogonal utility route, with dark trench, bright conductor,
# energized endpoints and multiple animated pulses.
# -----------------------------------------------------------------------------

func _draw_energy_power_flow(from: Vector2, to: Vector2) -> void:
    var start := VisualStack.snap_to_pixel(from)
    var finish := VisualStack.snap_to_pixel(to)
    var points := PackedVector2Array()

    # Use one clean right-angle route. This reads as a buried/overhead utility
    # corridor and aligns to the same world grid as roads and parcels.
    if absf(finish.x - start.x) >= absf(finish.y - start.y):
        var mid_x := _v096_grid((start.x + finish.x) * 0.5)
        points = PackedVector2Array([
            start,
            Vector2(mid_x, start.y),
            Vector2(mid_x, finish.y),
            finish
        ])
    else:
        var mid_y := _v096_grid((start.y + finish.y) * 0.5)
        points = PackedVector2Array([
            start,
            Vector2(start.x, mid_y),
            Vector2(finish.x, mid_y),
            finish
        ])

    draw_polyline(points, V096_INK, 10.0, false)
    draw_polyline(points, Color("8b6c2b"), 6.0, false)
    draw_polyline(points, V096_POWER, 3.0, false)

    _draw_v096_power_terminal(start, true)
    _draw_v096_power_terminal(finish, false)

    for pulse_index in range(3):
        var t := fmod(v096_power_phase * 0.28 + float(pulse_index) / 3.0, 1.0)
        var pulse_pos := _v096_point_on_polyline(points, t)
        draw_circle(pulse_pos, 5.0, V096_INK)
        draw_circle(pulse_pos, 3.0, V096_POWER_HI)


func _draw_v096_power_terminal(pos: Vector2, source: bool) -> void:
    var box := Rect2(pos + Vector2(-8.0, -8.0), Vector2(16.0, 16.0))
    draw_rect(box, V096_INK, true)
    draw_rect(box.grow(-3.0), V096_POWER if source else Color("66e4b5"), true)
    draw_rect(Rect2(pos + Vector2(-2.0, -5.0), Vector2(4.0, 4.0)), V096_POWER_HI, true)
    draw_rect(Rect2(pos + Vector2(-4.0, -1.0), Vector2(5.0, 3.0)), V096_POWER_HI, true)
    draw_rect(Rect2(pos + Vector2(-1.0, 2.0), Vector2(4.0, 4.0)), V096_POWER_HI, true)


func _v096_point_on_polyline(points: PackedVector2Array, t: float) -> Vector2:
    if points.size() == 0:
        return Vector2.ZERO
    if points.size() == 1:
        return points[0]

    var lengths: Array[float] = []
    var total := 0.0
    for i in range(points.size() - 1):
        var segment := points[i].distance_to(points[i + 1])
        lengths.append(segment)
        total += segment
    if total <= 0.001:
        return points[0]

    var target := clampf(t, 0.0, 1.0) * total
    var walked := 0.0
    for i in range(lengths.size()):
        var segment_length := lengths[i]
        if target <= walked + segment_length or i == lengths.size() - 1:
            var local_t := 0.0 if segment_length <= 0.001 else (target - walked) / segment_length
            return points[i].lerp(points[i + 1], clampf(local_t, 0.0, 1.0))
        walked += segment_length
    return points[points.size() - 1]


func debug_v096_visual_ready() -> bool:
    return (
        V096_VISUAL_COHESION_REVISION == 1
        and V096_BUILDING_PLACER.all_buildings_clear_of_roads(entities)
        and V096_BUILDING_PLACER.all_buildings_clear_of_water(entities)
        and ART_TILE_SIZE == WorldScale.WORLD_TILE
        and has_method("_draw_v096_frontage_paths")
        and has_method("_draw_v096_transformer_yard")
        and has_method("_v096_point_on_polyline")
    )
