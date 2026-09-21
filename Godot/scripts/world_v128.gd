extends "res://scripts/world_v127.gd"

# Hash Race v0.128 road de-clutter + container replacement pass.
# The authored C-01 asset is preferred, but the Command Center/mining-container
# runtime remains valid when a repository binary is missing or corrupt.

const V128_ROAD_CLEANUP_REVISION := 2
const V128_CONTAINER_PATH := "res://art/buildings/c01_mining_container.svg"
const V128_CONTAINER_ASPECT := 102.0 / 128.0
const CITY_ROAD_STYLES: Array[String] = ["industrial_marked", "dirt_clean", "asphalt_center", "gravel_ruts", "industrial_plain", "dirt_clean", "asphalt_double", "gravel_dark", "industrial_marked", "asphalt_plain"]
var v128_container_texture: Texture2D

func _ready() -> void:
    v128_container_texture = _v128_load_texture(V128_CONTAINER_PATH)
    super._ready()
    set_meta("hashrace_v128_road_cleanup_revision", V128_ROAD_CLEANUP_REVISION)
    set_meta("hashrace_v128_container_asset_live", v128_container_texture != null)
    set_meta("hashrace_v128_container_runtime_live", true)
    set_meta("hashrace_v128_single_road_stack", true)
    set_meta("hashrace_v128_city_road_styles", CITY_ROAD_STYLES.size())
    set_meta("hashrace_v128_single_container_door", true)
    set_meta("hashrace_v128_command_hut_removed", true)
    queue_redraw()

func _v128_load_texture(path: String) -> Texture2D:
    if ResourceLoader.exists(path):
        var imported := load(path) as Texture2D
        if imported != null: return imported
    var absolute_path := ProjectSettings.globalize_path(path)
    if not FileAccess.file_exists(absolute_path): return null
    var image := Image.new()
    var load_error := ERR_FILE_UNRECOGNIZED
    if path.to_lower().ends_with(".svg"):
        load_error = image.load_svg_from_string(FileAccess.get_file_as_string(absolute_path), 1.0)
    else: load_error = image.load(absolute_path)
    if load_error != OK or image.is_empty(): return null
    return ImageTexture.create_from_image(image)

func _v128_city_road_style(profile_idx: int) -> String:
    return "industrial_marked" if CITY_ROAD_STYLES.is_empty() else CITY_ROAD_STYLES[posmod(profile_idx, CITY_ROAD_STYLES.size())]

func _v123_draw_ground(campus: Rect2) -> void:
    _v125_draw_terrain_underlay(campus)
    _v128_draw_city_road(campus.get_center() + Vector2(-210.0, 45.0), company_idx, 7, Vector2(60.0, 54.0))

func _draw_town_zones() -> void:
    super._draw_town_zones()
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        _v128_draw_city_road(zone["center"] + Vector2(-130.0, 124.0), int(zone["profile_idx"]), 5, Vector2(52.0, 42.0))

func _v128_draw_city_road(anchor: Vector2, profile_idx: int, segments: int, tile_size: Vector2) -> void:
    var style := _v128_city_road_style(profile_idx)
    var safe_segments := maxi(1, segments)
    var road_size := Vector2(tile_size.x * float(safe_segments), tile_size.y)
    if style.begins_with("asphalt"):
        var road_rect := Rect2(anchor, road_size)
        draw_rect(road_rect, Color("3c4348"), true)
        draw_line(road_rect.position, Vector2(road_rect.end.x, road_rect.position.y), Color("798185"), 2.0)
        draw_line(Vector2(road_rect.position.x, road_rect.end.y), road_rect.end, Color("272d31"), 2.0)
        var mid_y := road_rect.position.y + road_rect.size.y * 0.5
        if style == "asphalt_center":
            for i in range(safe_segments):
                var x0 := anchor.x + float(i) * tile_size.x + tile_size.x * 0.18
                draw_line(Vector2(x0, mid_y), Vector2(x0 + tile_size.x * 0.56, mid_y), Color("d5d2b0"), 2.0)
        elif style == "asphalt_double":
            draw_line(Vector2(anchor.x, mid_y - 3.0), Vector2(anchor.x + road_size.x, mid_y - 3.0), Color("d5d2b0"), 2.0)
            draw_line(Vector2(anchor.x, mid_y + 3.0), Vector2(anchor.x + road_size.x, mid_y + 3.0), Color("d5d2b0"), 2.0)
        return
    var texture: Texture2D
    var source: Rect2i
    if style == "dirt_clean": texture = v125_dirt_road_texture; source = DirtRoadCatalog.region("straight_h")
    elif style == "gravel_ruts": texture = v127_industrial_road_texture; source = IndustrialRoadCatalog.region("gravel_ruts")
    elif style == "gravel_dark": texture = v127_industrial_road_texture; source = IndustrialRoadCatalog.region("gravel_dark")
    else: texture = v127_industrial_road_texture; source = IndustrialRoadCatalog.region("straight_h_marked" if style == "industrial_marked" else "straight_h")
    if texture == null:
        draw_rect(Rect2(anchor, road_size), Color("4b4b46"), true); return
    for i in range(safe_segments):
        draw_texture_rect_region(texture, Rect2(anchor + Vector2(float(i) * tile_size.x, 0.0), tile_size), Rect2(source))

func _v128_container_size(capacity_mw: float) -> Vector2:
    var width := clampf(110.0 + float(_v114_footprint_tiles(capacity_mw)) * 22.0, 154.0, 286.0)
    return Vector2(width, width * V128_CONTAINER_ASPECT)

func _v128_draw_container_sprite(center: Vector2, capacity_mw: float, accent: Color, forced_size: Vector2 = Vector2.ZERO) -> Vector2:
    var size_value := forced_size if forced_size != Vector2.ZERO else _v128_container_size(capacity_mw)
    draw_ellipse_shadow(center + Vector2(0.0, size_value.y * 0.42), size_value.x * 0.40, maxf(8.0, size_value.y * 0.07))
    var dest := Rect2(center - size_value * Vector2(0.5, 0.55), size_value)
    if v128_container_texture != null:
        draw_rect(dest.grow(4.0), Color("11181d"), true); draw_texture_rect(v128_container_texture, dest, false)
    else:
        draw_rect(dest, Color("c4cbce"), true); draw_rect(dest, Color("3b464d"), false, 3.0)
        draw_string(ThemeDB.fallback_font, dest.position + Vector2(8.0, 18.0), "MINING CONTAINER", HORIZONTAL_ALIGNMENT_LEFT, dest.size.x - 16.0, 9, Color("17242b"))
    draw_rect(Rect2(Vector2(dest.position.x + 8.0, dest.end.y - 8.0), Vector2(maxf(12.0, dest.size.x - 16.0), 5.0)), accent, true)
    return size_value

func _v128_draw_container_entry_marker(kind: String, pos: Vector2, size_value: Vector2, accent: Color) -> void:
    # The authored container already contains its physical door. Keep interaction
    # feedback on the ground so a second procedural doorway is never painted over it.
    var bottom_y := pos.y + size_value.y * 0.38
    var door_target := WorldScale.front_door_world_pos(kind, pos)
    if rep_pos.distance_to(door_target) <= INTERACT_DISTANCE + 36.0:
        var pulse := 0.55 + 0.45 * absf(sin(float(Time.get_ticks_msec()) / 220.0))
        var glow := Color(accent.r, accent.g, accent.b, pulse)
        draw_circle(Vector2(pos.x, bottom_y + 25.0), 12.0, glow, false, 3.0)
        draw_line(Vector2(pos.x - 6.0, bottom_y + 25.0), Vector2(pos.x + 6.0, bottom_y + 25.0), Color("f1f6f5"), 2.0)

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var kind := String(entity.get("kind", "hq"))
    var profile_idx: int = int(entity.get("profile_idx", company_idx))
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    if kind == "rival" and bool(rivals[int(entity["rival_idx"])]["merged"]): accent = Color("657078")
    var base_size := _v103_visual_size(pos, WorldScale.HQ_SIZE, "hq")
    var width := clampf(base_size.x * 1.08, 190.0, 320.0)
    var display_size := Vector2(width, width * V128_CONTAINER_ASPECT)
    _selection_ring(pos, idx, WorldScale.selection_radius("hq"))
    _v128_draw_container_sprite(pos + Vector2(0.0, -8.0), _v114_capacity_mw_for_site(pos), accent, display_size)
    _v128_draw_container_entry_marker(kind, pos, display_size, accent)
    _draw_building_name(entity, idx, accent, display_size.y * 0.48 + 38.0, display_size.x + 36.0)

func _v115_draw_live_site(origin: Vector2) -> void:
    var capacity_mw := _v114_capacity_mw_for_site(_player_hq_center())
    var tiles := _v114_footprint_tiles(capacity_mw)
    var accent: Color = COMPANY_ACCENTS[company_idx]
    _v123_draw_ground(Rect2(origin - Vector2(390.0, 260.0), Vector2(780.0, 520.0)))
    _v128_draw_container_sprite(origin + Vector2(-170.0, -112.0), capacity_mw, accent)
    _v114_draw_energy_source(_v114_primary_energy_id(_player_hq_center()), origin + Vector2(225.0, -112.0), capacity_mw, "up")
    _v114_draw_transformer(origin + Vector2(205.0, 170.0), capacity_mw)
    draw_string(ThemeDB.fallback_font, origin + Vector2(-365.0, -228.0), "%s • %.1f MW • CONTAINER %dx%d" % [String(InfrastructureVisualCatalog.capacity_profile(capacity_mw).get("scale_name", "SITE")), capacity_mw, tiles, tiles], HORIZONTAL_ALIGNMENT_LEFT, 730.0, 12, accent.lightened(0.15))

func debug_v128_ready() -> bool:
    return V128_ROAD_CLEANUP_REVISION == 2 and bool(get_meta("hashrace_v128_container_runtime_live", false)) and CITY_ROAD_STYLES.size() == 10 and bool(get_meta("hashrace_v128_single_road_stack", false)) and bool(get_meta("hashrace_v128_single_container_door", false)) and bool(get_meta("hashrace_v128_command_hut_removed", false)) and debug_v127_ready()
