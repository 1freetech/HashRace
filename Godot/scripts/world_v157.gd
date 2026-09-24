extends "res://scripts/world_v156.gd"

# Hash Race v0.157: world-scale reset and visual-overlap correction.
# The screenshot gate identified scale drift, stacked infrastructure, permanent
# labels, HUD occlusion and rectangular terrain seams as the dominant problems.
# This live layer fixes those problems without touching simulation state.
const V157_VISUAL_RESET_REVISION := 1
const V157_ROAD_TILE := Vector2(56.0, 48.0)
const V157_ROAD_SEGMENTS := 6
const V157_ROAD_OFFSET := Vector2(-168.0, 14.0)
const V157_SHADOW_OFFSET := Vector2(9.0, 6.0)
const V157_PROP_ROAD_CLEARANCE := 48.0
const V157_CLUSTER_CLEARANCE := 96.0

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v157_visual_reset_revision", V157_VISUAL_RESET_REVISION)
    set_meta("hashrace_v157_single_live_site_renderer", true)
    set_meta("hashrace_v157_permanent_world_labels", false)
    set_meta("hashrace_v157_fullscreen_hud_suppressed", true)
    call_deferred("_v157_apply_hud_contract")
    queue_redraw()

func _v123_install_hud() -> void:
    if is_instance_valid(v123_hud):
        v123_hud.visible = false
        return
    v123_hud = Control.new()
    v123_hud.name = "VisualTargetHUDSuppressed"
    v123_hud.visible = false
    add_child(v123_hud)

func _v157_apply_hud_contract() -> void:
    if not navigation_installed:
        get_tree().process_frame.connect(Callable(self, "_v157_apply_hud_contract"), CONNECT_ONE_SHOT)
        return
    if is_instance_valid(v123_hud):
        v123_hud.visible = false
    if is_instance_valid(menu_button):
        menu_button.visible = false
    if is_instance_valid(compact_prompt):
        compact_prompt.visible = false
    if is_instance_valid(mining_ops_restore_button):
        mining_ops_restore_button.visible = false
    if is_instance_valid(navigation_button):
        navigation_button.visible = true

func _v128_container_size(capacity_mw: float) -> Vector2:
    var tiles := _v114_footprint_tiles(capacity_mw)
    var width := 96.0 + float(tiles) * 16.0
    return Vector2(width, width * V128_CONTAINER_ASPECT)

func _v128_draw_container_sprite(center: Vector2, capacity_mw: float, accent: Color, forced_size: Vector2 = Vector2.ZERO) -> Vector2:
    var size_value := forced_size if forced_size != Vector2.ZERO else _v128_container_size(capacity_mw)
    draw_ellipse_shadow(center + Vector2(0.0, size_value.y * 0.42), size_value.x * 0.40, maxf(8.0, size_value.y * 0.07))
    var dest := Rect2(center - size_value * Vector2(0.5, 0.55), size_value)
    if v128_container_texture != null:
        draw_texture_rect(v128_container_texture, dest, false)
    else:
        draw_rect(dest, Color("c4cbce"), true)
        draw_rect(dest, Color("3b464d"), false, 3.0)
    draw_rect(
        Rect2(Vector2(dest.position.x + 8.0, dest.end.y - 8.0), Vector2(maxf(12.0, dest.size.x - 16.0), 5.0)),
        accent,
        true
    )
    return size_value

func _v115_draw_live_site(origin: Vector2) -> void:
    var capacity_mw := _v114_capacity_mw_for_site(_player_hq_center())
    var accent: Color = COMPANY_ACCENTS[company_idx]
    var container_size := _v128_container_size(capacity_mw)
    _v157_draw_campus_ground(origin)
    var container_pos := origin + Vector2(-170.0, -165.0)
    var energy_pos := origin + Vector2(205.0, -165.0)
    var transformer_pos := origin + Vector2(205.0, 215.0)
    var command_pos := origin + Vector2(-205.0, 215.0)
    _v157_draw_foundation(container_pos, Vector2(container_size.x + 28.0, container_size.y * 0.72))
    _v157_draw_foundation(energy_pos, Vector2(170.0, 106.0))
    _v157_draw_foundation(transformer_pos, Vector2(170.0, 104.0))
    _v157_draw_foundation(command_pos, Vector2(136.0, 92.0))
    _v128_draw_container_sprite(container_pos, capacity_mw, accent)
    _v114_draw_energy_source(_v114_primary_energy_id(_player_hq_center()), energy_pos, capacity_mw, "up")
    _v114_draw_transformer(transformer_pos, capacity_mw)
    _v128_draw_command_hut(command_pos, accent)
    set_meta("hashrace_v157_container_pos", container_pos)
    set_meta("hashrace_v157_energy_pos", energy_pos)
    set_meta("hashrace_v157_transformer_pos", transformer_pos)
    set_meta("hashrace_v157_command_pos", command_pos)

func _v157_draw_campus_ground(origin: Vector2) -> void:
    var anchor := origin + V157_ROAD_OFFSET
    _v128_draw_city_road(anchor, company_idx, V157_ROAD_SEGMENTS, V157_ROAD_TILE)
    _v157_draw_road_transition(Rect2(anchor, Vector2(V157_ROAD_TILE.x * float(V157_ROAD_SEGMENTS), V157_ROAD_TILE.y)))

func _v157_draw_road_transition(road: Rect2) -> void:
    var fringe := Color(0.24, 0.44, 0.24, 0.42)
    var highlight := Color(0.62, 0.78, 0.42, 0.34)
    draw_rect(Rect2(road.position + Vector2(0.0, -6.0), Vector2(road.size.x, 6.0)), fringe, true)
    draw_rect(Rect2(Vector2(road.position.x, road.end.y), Vector2(road.size.x, 6.0)), fringe, true)
    for x in range(0, int(road.size.x), 24):
        var fx := road.position.x + float(x)
        var jitter := float((x / 24) % 3) * 2.0
        draw_rect(Rect2(Vector2(fx + 5.0, road.position.y - 10.0 - jitter), Vector2(3.0, 3.0)), highlight, true)
        draw_rect(Rect2(Vector2(fx + 13.0, road.end.y + 6.0 + jitter), Vector2(3.0, 3.0)), highlight, true)

func _v157_draw_foundation(center: Vector2, size_value: Vector2) -> void:
    var rect := Rect2(center - size_value * 0.5, size_value)
    draw_rect(rect, Color(0.10, 0.13, 0.14, 0.30), true)
    draw_rect(rect, Color(0.33, 0.39, 0.39, 0.48), false, 2.0)
    for i in range(4):
        var px := rect.position.x + 14.0 + float(i) * maxf(18.0, (rect.size.x - 28.0) / 4.0)
        draw_rect(Rect2(Vector2(px, rect.position.y - 4.0 - float(i % 2) * 2.0), Vector2(3.0, 3.0)), Color(0.30, 0.48, 0.27, 0.42), true)

func _v138_draw_capacity_planner(_center: Vector2) -> void:
    pass

func _draw_town_zones() -> void:
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = zone["center"]
        var anchor := center + Vector2(-112.0, 118.0)
        var tile := Vector2(50.0, 40.0)
        _v128_draw_city_road(anchor, int(zone["profile_idx"]), 4, tile)
        _v157_draw_road_transition(Rect2(anchor, Vector2(tile.x * 4.0, tile.y)))

func _v157_nearest_building_idx() -> int:
    var best_idx := -1
    var best_distance := 1.0e20
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind := String(entity.get("kind", ""))
        if not WorldScale.is_building_kind(kind):
            continue
        var distance := rep_pos.distance_to(Vector2(entity.get("pos", Vector2.ZERO)))
        if distance < best_distance:
            best_distance = distance
            best_idx = i
    return best_idx

func _show_building_name(pos: Vector2, idx: int) -> bool:
    if idx == selected_entity_idx:
        return true
    var nearest_idx := _v157_nearest_building_idx()
    return idx == nearest_idx and rep_pos.distance_to(pos) <= BUILDING_LABEL_DISTANCE

func _draw_pixel_town_labels() -> void:
    pass

func _draw_neon_character_name(_pos: Vector2, _character_name: String) -> void:
    pass

func _draw_tech_rep(pos: Vector2, accent: Color, _scanner: String, is_player: bool) -> void:
    _refresh_v144_player_texture()
    if v144_player_texture == null:
        return
    var facing := rep_facing if is_player else _v073_npc_facing(pos, _v073_seed(pos, accent))
    var moving := is_player and not rep_animation_state.ends_with("_idle")
    var frame := DefaultPlayerSheetV144.walk_frame(moving, rep_step_phase if is_player else 0.0)
    var region := DefaultPlayerSheetV144.frame_region(facing, frame)
    var scale_value := PLAYER_PIXEL_SCALE if is_player else PLAYER_PIXEL_SCALE * 0.88
    var foot := VisualStack.snap_to_pixel(pos + Vector2(0.0, 43.0))
    var dest := Rect2(
        VisualStack.snap_to_pixel(foot + (DefaultPlayerSheetV144.frame_offset(region) - Vector2(DefaultPlayerSheetV144.FOOT_ANCHOR)) * scale_value),
        Vector2(region.size) * scale_value
    )
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 42.0)), 28.0 * (1.0 if is_player else 0.88), 8.0 * (1.0 if is_player else 0.88))
    draw_texture_rect_region(v144_player_texture, dest, Rect2(region))
    if not is_player:
        draw_rect(Rect2(foot + Vector2(-6.0, -52.0) * 0.88, Vector2(12.0, 4.0)), accent, true)

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var profile_idx: int = int(entity.get("profile_idx", company_idx))
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    if String(entity.get("kind", "")) == "rival" and bool(rivals[int(entity["rival_idx"])]["merged"]):
        accent = Color("657078")
    var capacity_mw := _v114_capacity_mw_for_site(pos)
    var display_size := _v128_container_size(capacity_mw)
    _selection_ring(pos, idx, WorldScale.selection_radius("hq"))
    _v128_draw_container_sprite(pos + Vector2(0.0, -8.0), capacity_mw, accent, display_size)
    _draw_v088_entry_cue(String(entity.get("kind", "hq")), pos, display_size, accent)
    _draw_building_name(entity, idx, accent, display_size.y * 0.48 + 30.0, display_size.x + 24.0)

func draw_ellipse_shadow(center: Vector2, radius_x: float, radius_y: float) -> void:
    var shifted := VisualStack.snap_to_pixel(center + V157_SHADOW_OFFSET)
    var points := PackedVector2Array()
    for i in range(20):
        var angle := TAU * float(i) / 20.0
        points.append(shifted + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
    draw_colored_polygon(points, Color(0.02, 0.03, 0.035, 0.28))

func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
    super._draw_art_tile(cell, tile_id)
    if tile_id != TILE_WATER:
        return
    var p := VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    var dirs: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
    for direction in dirs:
        var neighbor := int(art_cells.get(cell + direction, tile_id))
        if neighbor == TILE_WATER:
            continue
        var seed := absi(cell.x * 19 + cell.y * 37 + direction.x * 11 + direction.y * 13)
        for i in range(3):
            var along := float((seed + i * 17) % 34 + 7)
            var rock := Color("65705f") if i % 2 == 0 else Color("405946")
            if direction == Vector2i.UP:
                draw_rect(Rect2(p + Vector2(along, float(i * 3)), Vector2(6.0, 4.0)), rock, true)
            elif direction == Vector2i.DOWN:
                draw_rect(Rect2(p + Vector2(along, DISPLAY_TILE_SIZE - 4.0 - float(i * 3)), Vector2(6.0, 4.0)), rock, true)
            elif direction == Vector2i.LEFT:
                draw_rect(Rect2(p + Vector2(float(i * 3), along), Vector2(4.0, 6.0)), rock, true)
            elif direction == Vector2i.RIGHT:
                draw_rect(Rect2(p + Vector2(DISPLAY_TILE_SIZE - 4.0 - float(i * 3), along), Vector2(4.0, 6.0)), rock, true)

func debug_v157_ready() -> bool:
    return V157_VISUAL_RESET_REVISION == 1 \
        and bool(get_meta("hashrace_v157_single_live_site_renderer", false)) \
        and _v114_footprint_tiles(1.0) == 2 \
        and _v114_footprint_tiles(10.0) == 4 \
        and _v114_footprint_tiles(25.0) == 6 \
        and _v114_footprint_tiles(100.0) == 8 \
        and _v128_container_size(1.0).x < _v128_container_size(10.0).x \
        and _v128_container_size(10.0).x < _v128_container_size(25.0).x \
        and _v128_container_size(25.0).x < _v128_container_size(100.0).x \
        and debug_v156_ready()
