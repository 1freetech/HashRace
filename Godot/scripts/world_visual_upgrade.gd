extends "res://scripts/world_visual_detail.gd"

# Hash Race v0.046 layered overworld upgrade.
# The uploaded Godot-Pokemon project was used as a reference for the general
# idea of vegetation reacting around the player's feet. The uploaded Naev
# project was used as a reference for multi-layer/parallax-style visual depth.
# Hash Race implements both ideas independently with original procedural art;
# no third-party sprites, textures, or source are bundled here.

const VISUAL_UPGRADE_REVISION: int = 1
const SOIL_DARK := Color("243b2b")
const SOIL_MID := Color("5b543b")
const GRASS_DEEP := Color("123b29")
const GRASS_MID := Color("2a7446")
const GRASS_BRIGHT := Color("75bd63")
const LEAF_HI := Color("9ed56f")
const CONCRETE_DARK := Color("303b40")
const CONCRETE_HI := Color("94a3a6")
const ROOF_DARK := Color("16242b")
const ROOF_MID := Color("2e424b")
const WALL_DARK := Color("33474d")
const WALL_MID := Color("586d72")
const WINDOW_DARK := Color("07161d")
const WINDOW_GLOW := Color("7de8ef")
const SHADOW := Color("07101199")

func _ready() -> void:
    super._ready()
    set_meta("hashrace_visual_upgrade_revision", VISUAL_UPGRADE_REVISION)
    set_meta("hashrace_visual_upgrade_sources", "Godot-Pokemon movement/grass concept + Naev layered-depth concept")
    queue_redraw()

func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
    super._draw_art_tile(cell, tile_id)
    var p: Vector2 = VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    var depth: float = VisualStack.layered_terrain_noise(cell, tile_id * 17 + 43)

    if tile_id == TILE_GRASS or tile_id == TILE_GRASS_DARK:
        _draw_ground_clusters(cell, p, depth, tile_id == TILE_GRASS_DARK)
        _draw_grass_edge(cell, p)
    elif tile_id == TILE_ROAD:
        _draw_road_wear(cell, p, depth)
    elif tile_id == TILE_LOT:
        _draw_lot_hardware(cell, p, depth)
    elif tile_id == TILE_PLAZA:
        _draw_plaza_marks(cell, p, depth)
    elif tile_id == TILE_WATER:
        _draw_water_depth(cell, p, depth)

func _draw_ground_clusters(cell: Vector2i, p: Vector2, depth: float, dark_variant: bool) -> void:
    var seed: int = _detail_seed(cell, 941)
    var dark: Color = GRASS_DEEP.darkened(0.12) if dark_variant else GRASS_DEEP
    var mid: Color = GRASS_MID.darkened(0.10) if dark_variant else GRASS_MID
    var bright: Color = GRASS_BRIGHT.darkened(0.14) if dark_variant else GRASS_BRIGHT

    # Large, coherent patches break the previous repeating TV-static look.
    if depth < 0.34:
        var patch_x: float = 5.0 + float(_scatter(seed, 1, 24))
        var patch_y: float = 7.0 + float(_scatter(seed, 2, 23))
        draw_rect(Rect2(p + Vector2(patch_x, patch_y), Vector2(16.0, 7.0)), dark, true)
        draw_rect(Rect2(p + Vector2(patch_x + 4.0, patch_y + 6.0), Vector2(10.0, 4.0)), SOIL_DARK if seed % 3 == 0 else mid.darkened(0.18), true)
    elif depth > 0.68:
        var patch_x2: float = 6.0 + float(_scatter(seed, 3, 22))
        var patch_y2: float = 6.0 + float(_scatter(seed, 4, 22))
        draw_rect(Rect2(p + Vector2(patch_x2, patch_y2), Vector2(14.0, 6.0)), mid.lightened(0.08), true)
        draw_rect(Rect2(p + Vector2(patch_x2 + 3.0, patch_y2 + 2.0), Vector2(7.0, 3.0)), bright, true)

    # Three readable tuft groups, each built from stems instead of random dots.
    for i in range(3):
        var tx: float = 7.0 + float(_scatter(seed + 71, i, 33))
        var ty: float = 9.0 + float(_scatter(seed + 131, i, 29))
        _draw_grass_tuft(p + Vector2(tx, ty), bright if i == 1 else mid, dark, i % 2 == 0)

    # Rare flowers/rocks create landmarks in large green fields.
    if seed % 13 == 0:
        _draw_pixel_flower(p + Vector2(13.0 + float(seed % 16), 13.0), Color("f0c95c"))
    if seed % 17 == 0:
        draw_rect(Rect2(p + Vector2(31.0, 31.0), Vector2(7.0, 4.0)), Color("647a70"), true)
        draw_rect(Rect2(p + Vector2(33.0, 30.0), Vector2(4.0, 2.0)), Color("a1b0a8"), true)

func _draw_grass_tuft(pos: Vector2, bright: Color, dark: Color, wide: bool) -> void:
    draw_rect(Rect2(pos + Vector2(0.0, 3.0), Vector2(2.0, 7.0)), dark, true)
    draw_rect(Rect2(pos + Vector2(3.0, 1.0), Vector2(2.0, 9.0)), bright, true)
    draw_rect(Rect2(pos + Vector2(6.0, 4.0), Vector2(2.0, 6.0)), dark, true)
    if wide:
        draw_rect(Rect2(pos + Vector2(-3.0, 5.0), Vector2(3.0, 2.0)), bright.darkened(0.12), true)
        draw_rect(Rect2(pos + Vector2(8.0, 6.0), Vector2(3.0, 2.0)), bright.darkened(0.12), true)

func _draw_pixel_flower(pos: Vector2, flower: Color) -> void:
    draw_rect(Rect2(pos + Vector2(2.0, 3.0), Vector2(2.0, 5.0)), Color("315f38"), true)
    draw_rect(Rect2(pos, Vector2(3.0, 3.0)), flower, true)
    draw_rect(Rect2(pos + Vector2(4.0, 0.0), Vector2(3.0, 3.0)), flower.lightened(0.15), true)
    draw_rect(Rect2(pos + Vector2(2.0, -2.0), Vector2(3.0, 3.0)), flower, true)

func _draw_grass_edge(cell: Vector2i, p: Vector2) -> void:
    var edge_color: Color = Color("184f32")
    var bright: Color = Color("5ba858")
    if int(art_cells.get(cell + Vector2i.UP, TILE_GRASS)) in [TILE_ROAD, TILE_PLAZA, TILE_LOT]:
        for x in range(4, 46, 8):
            draw_rect(Rect2(p + Vector2(float(x), 0.0), Vector2(3.0, 6.0)), edge_color, true)
            draw_rect(Rect2(p + Vector2(float(x + 3), 1.0), Vector2(2.0, 3.0)), bright, true)
    if int(art_cells.get(cell + Vector2i.DOWN, TILE_GRASS)) in [TILE_ROAD, TILE_PLAZA, TILE_LOT]:
        for x in range(7, 46, 9):
            draw_rect(Rect2(p + Vector2(float(x), 42.0), Vector2(3.0, 6.0)), edge_color, true)
    if int(art_cells.get(cell + Vector2i.LEFT, TILE_GRASS)) in [TILE_ROAD, TILE_PLAZA, TILE_LOT]:
        for y in range(5, 45, 9):
            draw_rect(Rect2(p + Vector2(0.0, float(y)), Vector2(6.0, 3.0)), edge_color, true)
    if int(art_cells.get(cell + Vector2i.RIGHT, TILE_GRASS)) in [TILE_ROAD, TILE_PLAZA, TILE_LOT]:
        for y in range(7, 45, 9):
            draw_rect(Rect2(p + Vector2(42.0, float(y)), Vector2(6.0, 3.0)), edge_color, true)

func _draw_road_wear(cell: Vector2i, p: Vector2, depth: float) -> void:
    var seed: int = _detail_seed(cell, 119)
    if depth < 0.42:
        var x: float = 8.0 + float(_scatter(seed, 1, 23))
        var y: float = 11.0 + float(_scatter(seed, 2, 22))
        draw_line(p + Vector2(x, y), p + Vector2(x + 8.0, y + 3.0), Color("18252a"), 2.0)
        draw_line(p + Vector2(x + 7.0, y + 3.0), p + Vector2(x + 11.0, y + 8.0), Color("18252a"), 2.0)
    if seed % 9 == 0:
        draw_rect(Rect2(p + Vector2(20.0, 19.0), Vector2(9.0, 9.0)), Color("1b272c"), true)
        draw_rect(Rect2(p + Vector2(22.0, 21.0), Vector2(5.0, 5.0)), Color("58676c"), true)

func _draw_lot_hardware(cell: Vector2i, p: Vector2, depth: float) -> void:
    var seed: int = _detail_seed(cell, 313)
    if depth > 0.58:
        draw_rect(Rect2(p + Vector2(8.0, 33.0), Vector2(14.0, 6.0)), Color("263238"), true)
        for slit in range(3):
            draw_rect(Rect2(p + Vector2(10.0 + float(slit) * 4.0, 34.0), Vector2(2.0, 4.0)), CONCRETE_HI.darkened(0.25), true)
    if seed % 5 == 0:
        draw_rect(Rect2(p + Vector2(31.0, 8.0), Vector2(8.0, 8.0)), Color("5b4d37"), true)
        draw_rect(Rect2(p + Vector2(33.0, 10.0), Vector2(4.0, 4.0)), Color("2f3434"), true)

func _draw_plaza_marks(cell: Vector2i, p: Vector2, depth: float) -> void:
    if depth < 0.31:
        draw_rect(Rect2(p + Vector2(7.0, 7.0), Vector2(4.0, 4.0)), Color("c8b98f"), true)
        draw_rect(Rect2(p + Vector2(37.0, 35.0), Vector2(3.0, 3.0)), Color("80755b"), true)
    if _detail_seed(cell, 507) % 11 == 0:
        _draw_planter(p + Vector2(32.0, 14.0))

func _draw_planter(pos: Vector2) -> void:
    draw_rect(Rect2(pos + Vector2(-8.0, 4.0), Vector2(16.0, 8.0)), WARM_OUTLINE, true)
    draw_rect(Rect2(pos + Vector2(-6.0, 5.0), Vector2(12.0, 5.0)), Color("695642"), true)
    draw_rect(Rect2(pos + Vector2(-4.0, -2.0), Vector2(8.0, 8.0)), GRASS_DEEP, true)
    draw_rect(Rect2(pos + Vector2(-7.0, 0.0), Vector2(5.0, 5.0)), GRASS_MID, true)
    draw_rect(Rect2(pos + Vector2(2.0, -4.0), Vector2(5.0, 6.0)), GRASS_BRIGHT, true)

func _draw_water_depth(cell: Vector2i, p: Vector2, depth: float) -> void:
    var seed: int = _detail_seed(cell, 721)
    if depth > 0.55:
        var y: float = 9.0 + float(_scatter(seed, 1, 24))
        draw_rect(Rect2(p + Vector2(5.0, y), Vector2(20.0, 2.0)), Color("8fe2df"), true)
        draw_rect(Rect2(p + Vector2(18.0, y + 4.0), Vector2(16.0, 2.0)), Color("3d9eaa"), true)

func _draw_world_props_pixel() -> void:
    super._draw_world_props_pixel()
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = VisualStack.snap_to_pixel(zone["center"])
        var profile_idx: int = int(zone["profile_idx"])
        var accent: Color = COMPANY_ACCENTS[profile_idx]
        _draw_mining_hall(center + Vector2(-122.0, -148.0), accent, profile_idx)
        _draw_service_hub(center + Vector2(118.0, -142.0), accent)
        _draw_campus_power_lane(center + Vector2(0.0, 130.0), accent)
        _draw_landscape_cluster(center + Vector2(-205.0, -38.0), profile_idx)
        _draw_landscape_cluster(center + Vector2(205.0, 42.0), profile_idx + 3)

func _draw_mining_hall(center: Vector2, accent: Color, variant: int) -> void:
    var width: float = 184.0
    var roof_h: float = 70.0
    var left: float = center.x - width * 0.5
    var top: float = center.y - roof_h * 0.5

    draw_rect(Rect2(left + 7.0, top + 13.0, width, 91.0), SHADOW, true)
    draw_rect(Rect2(left - 4.0, top - 4.0, width + 8.0, roof_h + 8.0), WARM_OUTLINE, true)
    draw_rect(Rect2(left, top, width, roof_h), ROOF_MID, true)

    # Roof-panel rhythm, skylights, vents and three cooling units.
    for col in range(6):
        var x: float = left + 8.0 + float(col) * 29.0
        var panel: Color = ROOF_DARK if col % 2 == 0 else ROOF_MID.lightened(0.08)
        draw_rect(Rect2(x, top + 7.0, 24.0, 54.0), panel, true)
        draw_rect(Rect2(x + 2.0, top + 9.0, 20.0, 2.0), Color("566970"), true)
    for skylight in range(3):
        var sx: float = left + 25.0 + float(skylight) * 58.0
        draw_rect(Rect2(sx, top + 18.0, 28.0, 10.0), WINDOW_DARK, true)
        draw_rect(Rect2(sx + 3.0, top + 20.0, 22.0, 3.0), WINDOW_GLOW.darkened(0.18), true)
    for fan in range(3):
        var fx: float = left + 37.0 + float(fan) * 55.0
        var fy: float = top + 48.0
        draw_rect(Rect2(fx - 12.0, fy - 10.0, 24.0, 20.0), WARM_OUTLINE, true)
        draw_rect(Rect2(fx - 10.0, fy - 8.0, 20.0, 16.0), Color("42565d"), true)
        draw_circle(Vector2(fx, fy), 6.0, Color("0b1317"))
        draw_line(Vector2(fx - 5.0, fy), Vector2(fx + 5.0, fy), accent, 2.0)
        draw_line(Vector2(fx, fy - 5.0), Vector2(fx, fy + 5.0), accent, 2.0)

    # Front wall gives the building thickness and a readable entrance.
    var wall_top: float = top + roof_h
    draw_rect(Rect2(left - 4.0, wall_top - 1.0, width + 8.0, 35.0), WARM_OUTLINE, true)
    draw_rect(Rect2(left, wall_top, width, 30.0), WALL_MID, true)
    draw_rect(Rect2(left, wall_top, width, 5.0), accent.darkened(0.16), true)
    for bay in range(4):
        var bx: float = left + 13.0 + float(bay) * 42.0
        draw_rect(Rect2(bx, wall_top + 9.0, 28.0, 15.0), WINDOW_DARK, true)
        for slit in range(3):
            draw_rect(Rect2(bx + 4.0, wall_top + 11.0 + float(slit) * 4.0, 20.0, 2.0), Color("47636a"), true)
    var door_x: float = left + width * 0.5 - 16.0
    draw_rect(Rect2(door_x - 2.0, wall_top + 6.0, 36.0, 24.0), WARM_OUTLINE, true)
    draw_rect(Rect2(door_x, wall_top + 8.0, 32.0, 22.0), Color("17272e"), true)
    draw_rect(Rect2(door_x + 4.0, wall_top + 10.0, 24.0, 4.0), accent, true)
    draw_rect(Rect2(door_x + 14.0, wall_top + 17.0, 4.0, 8.0), Color("9dd7d8"), true)

    # Small company-number roof mark keeps each campus visually distinct.
    draw_rect(Rect2(left + 8.0, top + 7.0, 28.0, 8.0), accent, true)
    draw_string(ThemeDB.fallback_font, Vector2(left + 13.0, top + 14.0), "%02d" % (variant + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("081014"))

func _draw_service_hub(center: Vector2, accent: Color) -> void:
    draw_rect(Rect2(center + Vector2(-47.0, -32.0), Vector2(100.0, 74.0)), SHADOW, true)
    draw_rect(Rect2(center + Vector2(-50.0, -36.0), Vector2(100.0, 66.0)), WARM_OUTLINE, true)
    draw_rect(Rect2(center + Vector2(-46.0, -32.0), Vector2(92.0, 58.0)), ROOF_DARK, true)
    draw_rect(Rect2(center + Vector2(-40.0, -26.0), Vector2(80.0, 8.0)), accent.darkened(0.25), true)
    for unit in range(2):
        var x: float = center.x - 22.0 + float(unit) * 44.0
        draw_rect(Rect2(x - 14.0, center.y - 12.0, 28.0, 24.0), Color("465a61"), true)
        draw_circle(Vector2(x, center.y), 8.0, WINDOW_DARK)
        draw_line(Vector2(x - 6.0, center.y), Vector2(x + 6.0, center.y), accent, 2.0)
        draw_line(Vector2(x, center.y - 6.0), Vector2(x, center.y + 6.0), accent, 2.0)
    draw_rect(Rect2(center + Vector2(-46.0, 27.0), Vector2(92.0, 20.0)), WALL_DARK, true)
    for vent in range(5):
        draw_rect(Rect2(center + Vector2(-38.0 + float(vent) * 16.0, 31.0), Vector2(10.0, 3.0)), Color("0e1a1f"), true)

func _draw_campus_power_lane(center: Vector2, accent: Color) -> void:
    draw_rect(Rect2(center + Vector2(-118.0, -5.0), Vector2(236.0, 10.0)), Color("26343a"), true)
    for post in range(7):
        var x: float = center.x - 102.0 + float(post) * 34.0
        draw_rect(Rect2(x - 3.0, center.y - 18.0, 6.0, 36.0), WARM_OUTLINE, true)
        draw_rect(Rect2(x - 1.0, center.y - 15.0, 2.0, 30.0), Color("8b9a9d"), true)
        draw_rect(Rect2(x - 9.0, center.y - 19.0, 18.0, 4.0), accent.darkened(0.28), true)
        draw_rect(Rect2(x - 6.0, center.y - 23.0, 4.0, 5.0), Color("c4d1d1"), true)
        draw_rect(Rect2(x + 2.0, center.y - 23.0, 4.0, 5.0), Color("c4d1d1"), true)

func _draw_landscape_cluster(center: Vector2, seed: int) -> void:
    var spread: Array[Vector2] = [Vector2(-14.0, 6.0), Vector2(0.0, -4.0), Vector2(16.0, 7.0), Vector2(6.0, 15.0)]
    for i in range(spread.size()):
        var offset: Vector2 = spread[i]
        var tone: Color = GRASS_MID if (seed + i) % 2 == 0 else GRASS_DEEP
        draw_rect(Rect2(center + offset + Vector2(-9.0, -7.0), Vector2(18.0, 14.0)), tone, true)
        draw_rect(Rect2(center + offset + Vector2(-4.0, -10.0), Vector2(9.0, 8.0)), GRASS_BRIGHT, true)
        if (seed + i) % 3 == 0:
            draw_rect(Rect2(center + offset + Vector2(1.0, -9.0), Vector2(4.0, 4.0)), LEAF_HI, true)

func _draw() -> void:
    super._draw()
    _draw_player_ground_interaction()

func _draw_player_ground_interaction() -> void:
    var player_cell: Vector2i = _world_to_art_cell(rep_pos)
    var tile_id: int = int(art_cells.get(player_cell, -1))
    if tile_id != TILE_GRASS and tile_id != TILE_GRASS_DARK:
        return

    # A foreground grass overlay reacts to walking, adapting the useful idea in
    # the uploaded Godot-Pokemon sample without copying its sprites or code.
    var moving: bool = not rep_animation_state.ends_with("_idle")
    var swing: float = sin(rep_step_phase) if moving else 0.0
    var spread: float = 4.0 + absf(swing) * 5.0
    var foot_y: float = rep_pos.y + 35.0
    var base: Color = GRASS_MID if tile_id == TILE_GRASS else GRASS_DEEP
    var hi: Color = GRASS_BRIGHT if tile_id == TILE_GRASS else GRASS_MID

    _draw_grass_tuft(Vector2(rep_pos.x - 18.0 - spread, foot_y - 8.0), hi, base, true)
    _draw_grass_tuft(Vector2(rep_pos.x + 10.0 + spread, foot_y - 7.0), hi, base, true)
    _draw_grass_tuft(Vector2(rep_pos.x - 3.0, foot_y - 2.0), hi.lightened(0.08), base, false)

    if moving:
        var leaf_x: float = rep_pos.x + swing * 15.0
        draw_rect(Rect2(Vector2(leaf_x - 2.0, foot_y - 16.0), Vector2(4.0, 2.0)), LEAF_HI, true)
        draw_rect(Rect2(Vector2(rep_pos.x - swing * 11.0, foot_y - 11.0), Vector2(3.0, 2.0)), hi, true)

func debug_visual_upgrade_ready() -> bool:
    return VISUAL_UPGRADE_REVISION == 1 \
        and VisualStack.SOURCE_COUNT >= 11 \
        and VisualStack.layered_terrain_noise(Vector2i(4, 7), 3) >= 0.0 \
        and VisualStack.layered_terrain_noise(Vector2i(4, 7), 3) <= 1.0
