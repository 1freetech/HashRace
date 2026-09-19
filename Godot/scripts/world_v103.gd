extends "res://scripts/world_v102.gd"

# Hash Race v0.103 composition pass.
# Goal: fewer competing sprites and a stronger intentional-world hierarchy.
# - hero structures read larger while secondary partner buildings recede
# - town blocks keep broad grass buffers instead of decorative cross paths
# - every building gets a directional cast shadow
# - terrain boundaries use layered/dithered transitions instead of a single seam
# - decorative campus props stay sparse and terrain-safe

const V103_COMPOSITION_REVISION := 1
const V103_SHADOW_NEAR := Color(0.035, 0.055, 0.060, 0.34)
const V103_SHADOW_FAR := Color(0.035, 0.055, 0.060, 0.16)
const V103_GRASS_FRINGE := Color(0.19, 0.39, 0.20, 0.34)
const V103_GRASS_HIGHLIGHT := Color(0.66, 0.82, 0.42, 0.26)
const V103_PATH_BLEND := Color(0.45, 0.39, 0.28, 0.24)
const V103_WATER_BLEND := Color(0.15, 0.39, 0.49, 0.34)
const V103_WATER_GLEAM := Color(0.55, 0.83, 0.84, 0.28)

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v103_composition_revision", V103_COMPOSITION_REVISION)
    queue_redraw()

# Remove the inherited town-center cross. Each interactive building already gets
# a narrow road-connected entrance walk from v0.102. Keeping both systems made
# every district look paved and busy instead of giving structures room to read.
func _stamp_campus_walkways() -> void:
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
                art_cells[cell] = TILE_GRASS_DARK if (x * 5 + y * 7) % 23 == 0 else TILE_GRASS

func _build_art_tilemap() -> void:
    super._build_art_tilemap()
    _v103_expand_negative_space()

# Open a four-cell grass buffer around each important structure. Only a compact
# three-tile foundation and a one-tile entrance walk survive.
func _v103_expand_negative_space() -> void:
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        var kind := String(entity.get("kind", ""))
        if not WorldScale.is_building_kind(kind):
            continue
        var c := _world_to_art_cell(Vector2(entity.get("pos", Vector2.ZERO)))

        for y in range(c.y - 4, c.y + 5):
            for x in range(c.x - 4, c.x + 5):
                var cell := Vector2i(x, y)
                if not art_cells.has(cell):
                    continue
                var current := int(art_cells[cell])
                if current == TILE_WATER or current == TILE_ROAD:
                    continue
                if current == TILE_PLAZA or current == TILE_LOT:
                    art_cells[cell] = TILE_GRASS_DARK if (x * 11 + y * 3) % 29 == 0 else TILE_GRASS

        for x in range(c.x - 1, c.x + 2):
            _v102_set_land_tile(Vector2i(x, c.y + 1), TILE_LOT)

        var entrance := Vector2i(c.x, c.y + 2)
        if not _v102_connect_straight_walk(entrance):
            _v102_set_land_tile(entrance, TILE_PLAZA)

# Keep props sparse. Rival campuses get one terrain-safe tree; the player's
# campus gets two. Purchased infrastructure such as the AI rack remains handled
# separately by the inventory-driven v0.102 renderer.
func _draw_mining_campus(center: Vector2, _accent: Color) -> void:
    _v102_tree_if_land(center + Vector2(-272.0, 36.0))
    if center.distance_to(_player_hq_center()) <= 8.0:
        _v102_tree_if_land(center + Vector2(272.0, 92.0))

# Important buildings use more of their collision-safe parcel. Secondary partner
# offices are deliberately smaller so the map has a clear visual hierarchy.
func _v103_visual_size(pos: Vector2, size_value: Vector2, style: String) -> Vector2:
    var scale := 1.0
    if style == "hq":
        scale = 1.10 if pos.distance_to(_player_hq_center()) <= 8.0 else 1.0
    elif style in ["machines", "power", "bank", "land"]:
        scale = 1.08
    elif style == "partner":
        scale = 0.94
    return Vector2(round(size_value.x * scale), round(size_value.y * scale))

func _v097_draw_building(pos: Vector2, size_value: Vector2, accent: Color, style: String) -> void:
    var visual_size := _v103_visual_size(pos, size_value, style)
    _v103_draw_building_shadow(pos, visual_size)

    var texture = _v097_texture(style, accent, visual_size)
    var top_left := VisualStack.snap_to_pixel(pos + Vector2(-visual_size.x * 0.5, -visual_size.y * 0.62))
    draw_texture_rect(texture, Rect2(top_left, visual_size), false)

# Fixed top-left lighting means every building throws the same lower-right cast
# shadow. Two hard-pixel layers create depth without blurry vector effects.
func _v103_draw_building_shadow(pos: Vector2, size_value: Vector2) -> void:
    var foot_y := pos.y + size_value.y * 0.38
    var half_w := size_value.x * 0.43
    var near_offset := Vector2(22.0, 14.0)
    var far_offset := Vector2(36.0, 24.0)

    var far_poly := PackedVector2Array([
        VisualStack.snap_to_pixel(Vector2(pos.x - half_w, foot_y) + far_offset),
        VisualStack.snap_to_pixel(Vector2(pos.x + half_w, foot_y) + far_offset),
        VisualStack.snap_to_pixel(Vector2(pos.x + half_w * 0.78, foot_y + 24.0) + far_offset),
        VisualStack.snap_to_pixel(Vector2(pos.x - half_w * 0.78, foot_y + 24.0) + far_offset),
    ])
    draw_colored_polygon(far_poly, V103_SHADOW_FAR)

    var near_poly := PackedVector2Array([
        VisualStack.snap_to_pixel(Vector2(pos.x - half_w, foot_y) + near_offset),
        VisualStack.snap_to_pixel(Vector2(pos.x + half_w, foot_y) + near_offset),
        VisualStack.snap_to_pixel(Vector2(pos.x + half_w * 0.82, foot_y + 17.0) + near_offset),
        VisualStack.snap_to_pixel(Vector2(pos.x - half_w * 0.82, foot_y + 17.0) + near_offset),
    ])
    draw_colored_polygon(near_poly, V103_SHADOW_NEAR)

func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
    super._draw_art_tile(cell, tile_id)
    _v103_draw_terrain_transitions(cell, tile_id)

func _v103_draw_terrain_transitions(cell: Vector2i, tile_id: int) -> void:
    var p := VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

    for direction in directions:
        var neighbor := int(art_cells.get(cell + direction, tile_id))
        if neighbor == tile_id:
            continue

        if tile_id == TILE_GRASS or tile_id == TILE_GRASS_DARK:
            _v103_transition_strip(p, direction, 6.0, V103_GRASS_FRINGE)
            _v103_transition_dither(p, cell, direction, V103_GRASS_HIGHLIGHT)
        elif tile_id == TILE_PLAZA or tile_id == TILE_LOT:
            if neighbor == TILE_GRASS or neighbor == TILE_GRASS_DARK:
                _v103_transition_strip(p, direction, 4.0, V103_PATH_BLEND)
        elif tile_id == TILE_WATER:
            if neighbor != TILE_WATER:
                _v103_transition_strip(p, direction, 6.0, V103_WATER_BLEND)
                _v103_transition_strip(p, direction, 2.0, V103_WATER_GLEAM)

func _v103_transition_strip(p: Vector2, direction: Vector2i, width: float, color: Color) -> void:
    if direction == Vector2i.UP:
        draw_rect(Rect2(p, Vector2(DISPLAY_TILE_SIZE, width)), color, true)
    elif direction == Vector2i.DOWN:
        draw_rect(Rect2(p + Vector2(0.0, DISPLAY_TILE_SIZE - width), Vector2(DISPLAY_TILE_SIZE, width)), color, true)
    elif direction == Vector2i.LEFT:
        draw_rect(Rect2(p, Vector2(width, DISPLAY_TILE_SIZE)), color, true)
    elif direction == Vector2i.RIGHT:
        draw_rect(Rect2(p + Vector2(DISPLAY_TILE_SIZE - width, 0.0), Vector2(width, DISPLAY_TILE_SIZE)), color, true)

func _v103_transition_dither(p: Vector2, cell: Vector2i, direction: Vector2i, color: Color) -> void:
    var seed := absi(cell.x * 17 + cell.y * 31 + direction.x * 7 + direction.y * 13)
    for i in range(4):
        var along := float((seed + i * 11) % 38 + 5)
        if direction == Vector2i.UP:
            draw_rect(Rect2(p + Vector2(along, 6.0 + float(i % 2) * 3.0), Vector2(2.0, 2.0)), color, true)
        elif direction == Vector2i.DOWN:
            draw_rect(Rect2(p + Vector2(along, DISPLAY_TILE_SIZE - 10.0 - float(i % 2) * 3.0), Vector2(2.0, 2.0)), color, true)
        elif direction == Vector2i.LEFT:
            draw_rect(Rect2(p + Vector2(6.0 + float(i % 2) * 3.0, along), Vector2(2.0, 2.0)), color, true)
        elif direction == Vector2i.RIGHT:
            draw_rect(Rect2(p + Vector2(DISPLAY_TILE_SIZE - 10.0 - float(i % 2) * 3.0, along), Vector2(2.0, 2.0)), color, true)

func debug_v103_ready() -> bool:
    return (
        V103_COMPOSITION_REVISION == 1
        and debug_v102_ready()
        and _v103_visual_size(_player_hq_center(), WorldScale.HQ_SIZE, "hq").x > WorldScale.HQ_SIZE.x
        and _v103_visual_size(Vector2.ZERO, WorldScale.PARTNER_SIZE, "partner").x < WorldScale.PARTNER_SIZE.x
    )
