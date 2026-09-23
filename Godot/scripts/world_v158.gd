extends "res://scripts/world_v157.gd"

# Hash Race v0.158: runtime-proof cleanup after inspecting the actual v0.157
# gameplay screenshot. The screenshot still showed oversized road bands, the
# blurry semiconductor JPG, repeated per-town mining infrastructure, tiled grass
# and crowded representatives. This layer fixes those rendered problems while
# preserving simulation state and the approved v0.144 character sheet contract.
const V158_RUNTIME_CLEANUP_REVISION := 1
const V158_ROAD_WIDTH_CELLS := 1
const V158_REP_BUILDING_GAP := 86.0
const V158_SHORE_MIN := 9.0
const V158_SHORE_MAX := 17.0

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v158_runtime_cleanup_revision", V158_RUNTIME_CLEANUP_REVISION)
    set_meta("hashrace_v158_single_tile_intercity_roads", true)
    set_meta("hashrace_v158_legacy_campus_props_suppressed", true)
    set_meta("hashrace_v158_semiconductor_jpg_suppressed", true)
    set_meta("hashrace_v158_canonical_facilities", true)
    queue_redraw()

# The original art map painted routes 3-6 tiles wide. Keep the same connected
# road graph, but collapse every route to a single 48 px road cell so pavement
# no longer owns most of the screen.
func _build_art_tilemap() -> void:
    super._build_art_tilemap()

    # Strip the old 3-6-cell roads and all orphan lot/plaza checker patches.
    # Canonical facilities draw their own small foundations below.
    for raw_cell in art_cells.keys():
        var cell: Vector2i = raw_cell
        var value := int(art_cells.get(cell, TILE_GRASS))
        if value == TILE_ROAD or value == TILE_LOT or value == TILE_PLAZA:
            art_cells[cell] = TILE_GRASS_DARK if (cell.x * 5 + cell.y * 7) % 19 == 0 else TILE_GRASS

    GBPaint.paint_line(art_cells, Vector2i(2, 19), Vector2i(60, 19), V158_ROAD_WIDTH_CELLS, TILE_ROAD, art_columns, art_rows)
    GBPaint.paint_line(art_cells, Vector2i(29, 7), Vector2i(29, 35), V158_ROAD_WIDTH_CELLS, TILE_ROAD, art_columns, art_rows)
    GBPaint.paint_line(art_cells, Vector2i(7, 9), Vector2i(52, 9), V158_ROAD_WIDTH_CELLS, TILE_ROAD, art_columns, art_rows)
    GBPaint.paint_line(art_cells, Vector2i(7, 29), Vector2i(52, 29), V158_ROAD_WIDTH_CELLS, TILE_ROAD, art_columns, art_rows)

    set_meta("hashrace_v158_visual_road_tiles", debug_gbc_road_tiles())

func _draw_world_props_pixel() -> void:
    if player.is_empty() or town_zones.is_empty():
        return
    var origin := _energy_campus_origin()
    # The player site is a destination, not permanent wallpaper behind the town.
    # It appears once the player walks into its campus parcel.
    if rep_pos.distance_to(origin) <= 520.0:
        _v115_draw_live_site(origin)

func _draw_mining_campus(_center: Vector2, _accent: Color) -> void:
    pass

# Pick one clear parcel near the player's HQ for the four-object live site.
# Candidate scoring is visual-only and does not modify simulation placement.
func _energy_campus_origin() -> Vector2:
    var hq := _player_hq_center()
    var candidates: Array[Vector2] = [
        hq + Vector2(650.0, 0.0),
        hq + Vector2(-650.0, 0.0),
        hq + Vector2(0.0, 540.0),
        hq + Vector2(0.0, -540.0),
        hq + Vector2(560.0, 410.0),
        hq + Vector2(-560.0, 410.0),
        hq + Vector2(560.0, -410.0),
        hq + Vector2(-560.0, -410.0)
    ]
    var site_half := Vector2(305.0, 295.0)
    var best := hq + Vector2(650.0, 0.0)
    var best_score := -1.0e20

    for raw_candidate in candidates:
        var candidate: Vector2 = raw_candidate
        candidate.x = clampf(candidate.x, site_half.x + 40.0, WORLD_SIZE.x - site_half.x - 40.0)
        candidate.y = clampf(candidate.y, site_half.y + 40.0, WORLD_SIZE.y - site_half.y - 40.0)

        var water_penalty := 0.0
        var samples: Array[Vector2] = [
            candidate,
            candidate + Vector2(site_half.x * 0.78, site_half.y * 0.78),
            candidate + Vector2(-site_half.x * 0.78, site_half.y * 0.78),
            candidate + Vector2(site_half.x * 0.78, -site_half.y * 0.78),
            candidate + Vector2(-site_half.x * 0.78, -site_half.y * 0.78)
        ]
        for sample in samples:
            if int(art_cells.get(_world_to_art_cell(sample), TILE_GRASS)) == TILE_WATER:
                water_penalty += 2400.0

        var overlap_penalty := 0.0
        var nearest_edge := 99999.0
        for raw_entity in entities:
            var entity: Dictionary = raw_entity
            var kind := String(entity.get("kind", ""))
            if not WorldScale.is_building_kind(kind):
                continue
            var building_pos := Vector2(entity.get("pos", Vector2.ZERO))
            var building_half := WorldScale.size_for_kind(kind) * 0.5 + Vector2(54.0, 54.0)
            var dx := absf(candidate.x - building_pos.x) - (site_half.x + building_half.x)
            var dy := absf(candidate.y - building_pos.y) - (site_half.y + building_half.y)
            if dx < 0.0 and dy < 0.0:
                overlap_penalty += (absf(dx) + absf(dy) + 1.0) * 60.0
            else:
                nearest_edge = minf(nearest_edge, maxf(dx, dy))

        var center_tile := int(art_cells.get(_world_to_art_cell(candidate), TILE_GRASS))
        var road_penalty := 500.0 if center_tile == TILE_ROAD else 0.0
        var score := nearest_edge - overlap_penalty - water_penalty - road_penalty
        if score > best_score:
            best_score = score
            best = candidate

    return VisualStack.snap_to_pixel(best)

func _build_entities() -> void:
    super._build_entities()
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind := String(entity.get("kind", ""))
        if kind == "partner_rep":
            var partner_idx := int(entity.get("partner_idx", -1))
            var owner := _entity_position_for("partner", "partner_idx", partner_idx)
            var side := 1.0 if partner_idx % 2 == 0 else -1.0
            var owner_size := WorldScale.PARTNER_SIZE
            var pos := owner + Vector2(side * (owner_size.x * 0.5 + V158_REP_BUILDING_GAP), owner_size.y * 0.42 + 54.0)
            pos.x = clampf(pos.x, 72.0, WORLD_SIZE.x - 72.0)
            pos.y = clampf(pos.y, 90.0, WORLD_SIZE.y - 72.0)
            entity["pos"] = pos
            entities[i] = entity
        elif kind == "rival_rep":
            var rival_idx := int(entity.get("rival_idx", -1))
            var profile_idx := int(entity.get("profile_idx", 0))
            var owner := _entity_position_for("rival", "rival_idx", rival_idx)
            var side := 1.0 if profile_idx % 2 == 0 else -1.0
            var owner_size := WorldScale.HQ_SIZE
            var pos := owner + Vector2(side * (owner_size.x * 0.5 + V158_REP_BUILDING_GAP), owner_size.y * 0.42 + 54.0)
            pos.x = clampf(pos.x, 72.0, WORLD_SIZE.x - 72.0)
            pos.y = clampf(pos.y, 90.0, WORLD_SIZE.y - 72.0)
            entity["pos"] = pos
            entities[i] = entity

# One facility grammar for every interactive building. Sizes come from the same
# WorldScale contract used by collision/selection, so doors, people and building
# bodies no longer imply different physical scales.
func _v158_draw_facility(entity: Dictionary, idx: int, accent: Color) -> void:
    var pos: Vector2 = entity["pos"]
    var kind := String(entity.get("kind", "partner"))
    var size_value := WorldScale.size_for_kind(kind)
    var rect := Rect2(pos - size_value * Vector2(0.5, 0.62), size_value)
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))

    # One intentional concrete foundation and one narrow front walk replace the
    # orphan lot/plaza tile checker. They sit behind the building silhouette.
    var foundation := Rect2(
        rect.position + Vector2(-8.0, rect.size.y * 0.42),
        Vector2(rect.size.x + 16.0, rect.size.y * 0.58 + 12.0)
    )
    draw_rect(foundation, Color(0.28, 0.32, 0.28, 0.62), true)
    draw_rect(foundation, Color(0.42, 0.48, 0.40, 0.50), false, 2.0)
    var front_walk := Rect2(Vector2(pos.x - 20.0, rect.end.y - 4.0), Vector2(40.0, 44.0))
    draw_rect(front_walk, Color(0.38, 0.42, 0.36, 0.78), true)
    for i in range(5):
        draw_rect(Rect2(front_walk.position + Vector2(5.0 + float(i) * 7.0, 7.0 + float(i % 2) * 18.0), Vector2(2.0, 2.0)), Color(0.54, 0.60, 0.48, 0.65), true)

    _v103_draw_building_shadow(pos, size_value)
    draw_rect(rect, Color("111b21"), true)
    draw_rect(rect, Color("071016"), false, 4.0)
    draw_rect(Rect2(rect.position + Vector2(4.0, 4.0), Vector2(rect.size.x - 8.0, 18.0)), accent.darkened(0.30), true)
    draw_rect(Rect2(rect.position + Vector2(8.0, 26.0), Vector2(rect.size.x - 16.0, 8.0)), Color("26363d"), true)

    var vent_count := maxi(3, int(floor((rect.size.x - 36.0) / 58.0)))
    var vent_span := (rect.size.x - 44.0) / float(vent_count)
    for i in range(vent_count):
        var vx := rect.position.x + 22.0 + float(i) * vent_span
        var vent := Rect2(Vector2(vx, rect.position.y + 44.0), Vector2(32.0, 18.0))
        draw_rect(vent, Color("050b0e"), true)
        draw_rect(vent.grow(-4.0), Color("31454e"), false, 2.0)
        draw_line(vent.position + Vector2(5.0, 6.0), vent.end - Vector2(5.0, 12.0), accent.darkened(0.40), 2.0)

    var door_h := minf(WorldScale.DOOR_VISUAL_HEIGHT, rect.size.y * 0.58)
    var door_w := minf(WorldScale.DOOR_VISUAL_WIDTH, rect.size.x * 0.20)
    var door_bottom := rect.end.y - 4.0
    var door := Rect2(Vector2(pos.x - door_w * 0.5, door_bottom - door_h), Vector2(door_w, door_h))
    draw_rect(door, Color("061016"), true)
    draw_rect(door.grow(-4.0), accent.darkened(0.55), true)
    draw_rect(Rect2(door.position + Vector2(7.0, 9.0), Vector2(maxf(6.0, door.size.x - 14.0), 7.0)), accent.darkened(0.18), true)
    draw_circle(Vector2(door.end.x - 8.0, door.position.y + door.size.y * 0.56), 2.0, Color("c9d5d7"))

    draw_rect(Rect2(Vector2(rect.position.x + 10.0, rect.end.y - 12.0), Vector2(rect.size.x - 20.0, 5.0)), accent, true)
    _draw_building_name(entity, idx, accent, size_value.y * 0.43 + 32.0, size_value.x + 28.0)

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    var profile_idx := int(entity.get("profile_idx", company_idx))
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    if String(entity.get("kind", "")) == "rival" and bool(rivals[int(entity["rival_idx"])]["merged"]):
        accent = Color("657078")
    _v158_draw_facility(entity, idx, accent)

# The v0.116/v0.138 semiconductor JPG is valid data but is visibly a blurry
# rectangular concept sheet in the gameplay frame. Keep it in the repository and
# dedicated proof history, but do not use it as a live world sprite.
func _draw_partner_building(entity: Dictionary, idx: int) -> void:
    var partner_idx := int(entity.get("partner_idx", 0))
    _v158_draw_facility(entity, idx, PARTNER_ACCENTS[partner_idx])

func _draw_machine_market(entity: Dictionary, idx: int) -> void:
    _v158_draw_facility(entity, idx, Color("bd8cff"))

func _draw_power_building(entity: Dictionary, idx: int) -> void:
    _v158_draw_facility(entity, idx, Color("ffd36e"))

func _draw_bank_building(entity: Dictionary, idx: int) -> void:
    _v158_draw_facility(entity, idx, ORANGE)

func _draw_land_building(entity: Dictionary, idx: int) -> void:
    _v158_draw_facility(entity, idx, Color("8ed06c"))

# Ground grass is rendered as a continuous fine-grain field instead of 12x12
# checker blocks. v0.103 transition dithering still runs on every grass tile.
func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
    if tile_id == TILE_GRASS or tile_id == TILE_GRASS_DARK:
        var p := VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
        var base := Color("5a9a46") if tile_id == TILE_GRASS else Color("508d40")
        var dark := base.darkened(0.12)
        var light := base.lightened(0.10)
        draw_rect(Rect2(p, Vector2(ART_TILE_SIZE + 1.0, ART_TILE_SIZE + 1.0)), base, true)
        var seed := absi(cell.x * 131 + cell.y * 197 + 17)
        for i in range(9):
            var sx := float((seed + i * 17) % 44 + 2)
            var sy := float((seed * 3 + i * 23) % 44 + 2)
            var speck := light if i % 3 == 0 else dark
            draw_rect(Rect2(p + Vector2(sx, sy), Vector2(2.0, 2.0)), speck, true)
        _v103_draw_terrain_transitions(cell, tile_id)
        return

    super._draw_art_tile(cell, tile_id)
    if tile_id == TILE_WATER:
        _v158_draw_shoreline(cell)

# Keep logical water cells unchanged for navigation, but visually mask their
# straight tile edge with a variable rocky shoreline band.
func _v158_draw_shoreline(cell: Vector2i) -> void:
    var p := VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
    for direction in directions:
        var neighbor := int(art_cells.get(cell + direction, TILE_WATER))
        if neighbor == TILE_WATER:
            continue
        var seed := absi(cell.x * 41 + cell.y * 67 + direction.x * 13 + direction.y * 29)
        var depth := lerpf(V158_SHORE_MIN, V158_SHORE_MAX, float(seed % 7) / 6.0)
        var shore := Color("687354")
        var shore_dark := Color("46513d")
        if direction == Vector2i.LEFT:
            draw_rect(Rect2(p, Vector2(depth, ART_TILE_SIZE)), shore, true)
            for i in range(4):
                draw_rect(Rect2(p + Vector2(float((seed + i * 9) % int(maxf(4.0, depth))), float(6 + i * 10)), Vector2(5.0, 4.0)), shore_dark, true)
        elif direction == Vector2i.RIGHT:
            draw_rect(Rect2(p + Vector2(ART_TILE_SIZE - depth, 0.0), Vector2(depth, ART_TILE_SIZE)), shore, true)
            for i in range(4):
                draw_rect(Rect2(p + Vector2(ART_TILE_SIZE - depth + float((seed + i * 7) % int(maxf(4.0, depth))), float(5 + i * 10)), Vector2(5.0, 4.0)), shore_dark, true)
        elif direction == Vector2i.UP:
            draw_rect(Rect2(p, Vector2(ART_TILE_SIZE, depth)), shore, true)
            for i in range(4):
                draw_rect(Rect2(p + Vector2(float(6 + i * 10), float((seed + i * 7) % int(maxf(4.0, depth)))), Vector2(4.0, 5.0)), shore_dark, true)
        elif direction == Vector2i.DOWN:
            draw_rect(Rect2(p + Vector2(0.0, ART_TILE_SIZE - depth), Vector2(ART_TILE_SIZE, depth)), shore, true)
            for i in range(4):
                draw_rect(Rect2(p + Vector2(float(5 + i * 10), ART_TILE_SIZE - depth + float((seed + i * 9) % int(maxf(4.0, depth)))), Vector2(4.0, 5.0)), shore_dark, true)

func debug_v158_ready() -> bool:
    return V158_RUNTIME_CLEANUP_REVISION == 1 \
        and bool(get_meta("hashrace_v158_single_tile_intercity_roads", false)) \
        and bool(get_meta("hashrace_v158_legacy_campus_props_suppressed", false)) \
        and bool(get_meta("hashrace_v158_semiconductor_jpg_suppressed", false)) \
        and _v114_footprint_tiles(1.0) == 2 \
        and _v114_footprint_tiles(10.0) == 4 \
        and _v114_footprint_tiles(25.0) == 6 \
        and _v114_footprint_tiles(100.0) == 8 \
        and debug_v157_ready()
