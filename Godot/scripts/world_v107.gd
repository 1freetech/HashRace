extends "res://scripts/world_v106.gd"

# Hash Race v0.107 intentional-world pixel composition pass.
#
# This is an original implementation derived from visual analysis, not copied
# commercial artwork. The goal is the readable top-down RPG composition shown
# in the supplied references: one strong building silhouette per parcel, broad
# negative space, hard directional shadows, stepped terrain borders, and paths
# that feel embedded in grass instead of stamped on a square grid.

const V107_VISUAL_REVISION := 1
const V107_HQ_PLAYER_SCALE := 1.18
const V107_HQ_RIVAL_SCALE := 1.08
const V107_SERVICE_SCALE := 1.12
const V107_PARTNER_SCALE := 0.88

const V107_SHADOW_NEAR := Color(0.025, 0.040, 0.045, 0.40)
const V107_SHADOW_MID := Color(0.025, 0.040, 0.045, 0.24)
const V107_SHADOW_FAR := Color(0.025, 0.040, 0.045, 0.12)
const V107_PATH_SOIL := Color("927b59")
const V107_PATH_EDGE_LIGHT := Color("dccb9c")
const V107_ROAD_SHOULDER := Color("6c766d")
const V107_WATER_BANK_DARK := Color("6e6548")
const V107_WATER_BANK_LIGHT := Color("b2a77a")

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v107_visual_revision", V107_VISUAL_REVISION)
    queue_redraw()

# Make the gameplay-important buildings read first. Partner offices deliberately
# recede so important mining/power/hardware structures get breathing room.
func _v103_visual_size(pos: Vector2, size_value: Vector2, style: String) -> Vector2:
    var scale := 1.0
    if style == "hq":
        scale = V107_HQ_PLAYER_SCALE if pos.distance_to(_player_hq_center()) <= 8.0 else V107_HQ_RIVAL_SCALE
    elif style in ["machines", "power", "bank", "land"]:
        scale = V107_SERVICE_SCALE
    elif style == "partner":
        scale = V107_PARTNER_SCALE
    return Vector2(round(size_value.x * scale), round(size_value.y * scale))

# Three hard-edged shadow layers create a fixed top-left light source without
# blur. This preserves pixel-art readability while giving buildings more mass.
func _v103_draw_building_shadow(pos: Vector2, size_value: Vector2) -> void:
    var foot_y := pos.y + size_value.y * 0.38
    var half_w := size_value.x * 0.44
    _v107_shadow_quad(pos, foot_y, half_w, Vector2(42.0, 28.0), 30.0, 0.72, V107_SHADOW_FAR)
    _v107_shadow_quad(pos, foot_y, half_w, Vector2(29.0, 19.0), 22.0, 0.78, V107_SHADOW_MID)
    _v107_shadow_quad(pos, foot_y, half_w, Vector2(17.0, 11.0), 15.0, 0.84, V107_SHADOW_NEAR)

func _v107_shadow_quad(pos: Vector2, foot_y: float, half_w: float, offset: Vector2, depth: float, taper: float, color: Color) -> void:
    var poly := PackedVector2Array([
        VisualStack.snap_to_pixel(Vector2(pos.x - half_w, foot_y) + offset),
        VisualStack.snap_to_pixel(Vector2(pos.x + half_w, foot_y) + offset),
        VisualStack.snap_to_pixel(Vector2(pos.x + half_w * taper, foot_y + depth) + offset),
        VisualStack.snap_to_pixel(Vector2(pos.x - half_w * taper, foot_y + depth) + offset),
    ])
    draw_colored_polygon(poly, color)

# Keep the inherited 16x16 source textures, then add a small adjacency-driven
# composition pass. The extra pixels are intentionally sparse: they change the
# shape language of paths/shorelines without turning the ground into noise.
func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
    super._draw_art_tile(cell, tile_id)
    var p := VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    if tile_id == TILE_PLAZA:
        _v107_draw_path_shape(cell, p)
    elif tile_id == TILE_ROAD:
        _v107_draw_road_shoulders(cell, p)
    elif tile_id == TILE_WATER:
        _v107_draw_stepped_bank(cell, p)

func _v107_is_grass(cell: Vector2i) -> bool:
    var tile := int(art_cells.get(cell, -999))
    return tile == TILE_GRASS or tile == TILE_GRASS_DARK

func _v107_draw_path_shape(cell: Vector2i, p: Vector2) -> void:
    var up := _v107_is_grass(cell + Vector2i.UP)
    var down := _v107_is_grass(cell + Vector2i.DOWN)
    var left := _v107_is_grass(cell + Vector2i.LEFT)
    var right := _v107_is_grass(cell + Vector2i.RIGHT)
    var grass := V097_GRASS
    var grass_dark := V097_GRASS_DARK

    if up:
        draw_rect(Rect2(p, Vector2(DISPLAY_TILE_SIZE, 2.0)), V107_PATH_EDGE_LIGHT, true)
        _v107_edge_specks(p, Vector2i.UP, cell, grass_dark)
    if down:
        draw_rect(Rect2(p + Vector2(0.0, DISPLAY_TILE_SIZE - 3.0), Vector2(DISPLAY_TILE_SIZE, 3.0)), V107_PATH_SOIL, true)
        _v107_edge_specks(p, Vector2i.DOWN, cell, grass_dark)
    if left:
        draw_rect(Rect2(p, Vector2(2.0, DISPLAY_TILE_SIZE)), V107_PATH_EDGE_LIGHT, true)
        _v107_edge_specks(p, Vector2i.LEFT, cell, grass_dark)
    if right:
        draw_rect(Rect2(p + Vector2(DISPLAY_TILE_SIZE - 3.0, 0.0), Vector2(3.0, DISPLAY_TILE_SIZE)), V107_PATH_SOIL, true)
        _v107_edge_specks(p, Vector2i.RIGHT, cell, grass_dark)

    # Stepped corner bites break the obvious square-tile silhouette.
    if up and left:
        _v107_corner_bite(p, Vector2(0.0, 0.0), grass, grass_dark)
    if up and right:
        _v107_corner_bite(p, Vector2(DISPLAY_TILE_SIZE - 9.0, 0.0), grass, grass_dark)
    if down and left:
        _v107_corner_bite(p, Vector2(0.0, DISPLAY_TILE_SIZE - 9.0), grass, grass_dark)
    if down and right:
        _v107_corner_bite(p, Vector2(DISPLAY_TILE_SIZE - 9.0, DISPLAY_TILE_SIZE - 9.0), grass, grass_dark)

func _v107_corner_bite(p: Vector2, offset: Vector2, grass: Color, grass_dark: Color) -> void:
    draw_rect(Rect2(p + offset, Vector2(9.0, 9.0)), grass, true)
    draw_rect(Rect2(p + offset + Vector2(3.0, 3.0), Vector2(6.0, 6.0)), grass_dark, true)
    draw_rect(Rect2(p + offset + Vector2(6.0, 6.0), Vector2(3.0, 3.0)), grass, true)

func _v107_edge_specks(p: Vector2, direction: Vector2i, cell: Vector2i, color: Color) -> void:
    var seed := absi(cell.x * 29 + cell.y * 43 + direction.x * 7 + direction.y * 11)
    for i in range(3):
        var along := float((seed + i * 13) % 34 + 7)
        if direction == Vector2i.UP:
            draw_rect(Rect2(p + Vector2(along, 3.0 + float(i % 2) * 3.0), Vector2(3.0, 3.0)), color, true)
        elif direction == Vector2i.DOWN:
            draw_rect(Rect2(p + Vector2(along, DISPLAY_TILE_SIZE - 7.0 - float(i % 2) * 3.0), Vector2(3.0, 3.0)), color, true)
        elif direction == Vector2i.LEFT:
            draw_rect(Rect2(p + Vector2(3.0 + float(i % 2) * 3.0, along), Vector2(3.0, 3.0)), color, true)
        elif direction == Vector2i.RIGHT:
            draw_rect(Rect2(p + Vector2(DISPLAY_TILE_SIZE - 7.0 - float(i % 2) * 3.0, along), Vector2(3.0, 3.0)), color, true)

func _v107_draw_road_shoulders(cell: Vector2i, p: Vector2) -> void:
    if _v107_is_grass(cell + Vector2i.UP):
        draw_rect(Rect2(p, Vector2(DISPLAY_TILE_SIZE, 2.0)), V107_ROAD_SHOULDER, true)
    if _v107_is_grass(cell + Vector2i.DOWN):
        draw_rect(Rect2(p + Vector2(0.0, DISPLAY_TILE_SIZE - 2.0), Vector2(DISPLAY_TILE_SIZE, 2.0)), V107_ROAD_SHOULDER.darkened(0.12), true)
    if _v107_is_grass(cell + Vector2i.LEFT):
        draw_rect(Rect2(p, Vector2(2.0, DISPLAY_TILE_SIZE)), V107_ROAD_SHOULDER, true)
    if _v107_is_grass(cell + Vector2i.RIGHT):
        draw_rect(Rect2(p + Vector2(DISPLAY_TILE_SIZE - 2.0, 0.0), Vector2(2.0, DISPLAY_TILE_SIZE)), V107_ROAD_SHOULDER.darkened(0.12), true)

func _v107_draw_stepped_bank(cell: Vector2i, p: Vector2) -> void:
    if int(art_cells.get(cell + Vector2i.UP, TILE_WATER)) != TILE_WATER:
        draw_rect(Rect2(p, Vector2(DISPLAY_TILE_SIZE, 3.0)), V107_WATER_BANK_LIGHT, true)
        draw_rect(Rect2(p + Vector2(6.0, 3.0), Vector2(DISPLAY_TILE_SIZE - 12.0, 2.0)), V107_WATER_BANK_DARK, true)
    if int(art_cells.get(cell + Vector2i.DOWN, TILE_WATER)) != TILE_WATER:
        draw_rect(Rect2(p + Vector2(0.0, DISPLAY_TILE_SIZE - 4.0), Vector2(DISPLAY_TILE_SIZE, 4.0)), V107_WATER_BANK_DARK, true)
        draw_rect(Rect2(p + Vector2(9.0, DISPLAY_TILE_SIZE - 6.0), Vector2(DISPLAY_TILE_SIZE - 18.0, 2.0)), V107_WATER_BANK_LIGHT, true)
    if int(art_cells.get(cell + Vector2i.LEFT, TILE_WATER)) != TILE_WATER:
        draw_rect(Rect2(p, Vector2(3.0, DISPLAY_TILE_SIZE)), V107_WATER_BANK_LIGHT, true)
    if int(art_cells.get(cell + Vector2i.RIGHT, TILE_WATER)) != TILE_WATER:
        draw_rect(Rect2(p + Vector2(DISPLAY_TILE_SIZE - 4.0, 0.0), Vector2(4.0, DISPLAY_TILE_SIZE)), V107_WATER_BANK_DARK, true)

# One detailed terrain-safe accent per mining campus instead of repeated arrays
# of decorative structures. The player campus gets one extra compact site sign.
func _draw_mining_campus(center: Vector2, accent: Color) -> void:
    _v102_tree_if_land(center + Vector2(-286.0, 52.0))
    if center.distance_to(_player_hq_center()) <= 8.0:
        _v107_draw_site_marker(center + Vector2(274.0, 98.0), accent)

func _v107_draw_site_marker(pos: Vector2, accent: Color) -> void:
    var cell := _world_to_art_cell(pos)
    var tile := int(art_cells.get(cell, TILE_WATER))
    if tile == TILE_WATER or tile == TILE_ROAD:
        return
    var p := VisualStack.snap_to_pixel(pos)
    draw_rect(Rect2(p + Vector2(-12.0, 19.0), Vector2(24.0, 5.0)), Color(0.02, 0.03, 0.03, 0.32), true)
    draw_rect(Rect2(p + Vector2(-3.0, -8.0), Vector2(6.0, 29.0)), Color("5f6b64"), true)
    draw_rect(Rect2(p + Vector2(-17.0, -18.0), Vector2(34.0, 16.0)), Color("172027"), true)
    draw_rect(Rect2(p + Vector2(-14.0, -15.0), Vector2(28.0, 10.0)), accent.darkened(0.18), true)
    draw_rect(Rect2(p + Vector2(-10.0, -12.0), Vector2(20.0, 3.0)), accent.lightened(0.18), true)

func debug_v107_ready() -> bool:
    var player_hq := _v103_visual_size(_player_hq_center(), WorldScale.HQ_SIZE, "hq")
    var partner := _v103_visual_size(Vector2.ZERO, WorldScale.PARTNER_SIZE, "partner")
    return (
        V107_VISUAL_REVISION == 1
        and debug_v106_ready()
        and player_hq.x >= round(WorldScale.HQ_SIZE.x * 1.17)
        and partner.x <= round(WorldScale.PARTNER_SIZE.x * 0.90)
        and V107_SERVICE_SCALE > 1.0
        and V107_SHADOW_NEAR.a > V107_SHADOW_MID.a
        and V107_SHADOW_MID.a > V107_SHADOW_FAR.a
    )
