extends "res://scripts/world_v140.gd"

# Hash Race v0.141 visual declutter pass. Restores v0.091/v0.094/v0.103/v0.114/v0.128 visual contracts without touching simulation state.
const V141_VISUAL_DECLUTTER_REVISION := 1
const V141_ROAD_TILE := Vector2(60.0, 54.0)
const V141_ROAD_SEGMENTS := 7
const V141_PROP_ROAD_GAP := 48.0
const V141_CLUSTER_GAP := 96.0

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v141_visual_declutter", true)
    set_meta("hashrace_v141_single_road_language", true)
    set_meta("hashrace_v141_sparse_four_object_site", true)
    call_deferred("_v141_restore_compact_hud")
    queue_redraw()

# v0.123 reintroduced a persistent full-width HUD after v0.094 removed it.
func _v123_install_hud() -> void:
    _v141_restore_compact_hud()

func _v141_restore_compact_hud() -> void:
    if is_instance_valid(v123_hud): v123_hud.visible = false
    if is_instance_valid(navigation_button): navigation_button.visible = true
    if is_instance_valid(navigation_panel): navigation_panel.visible = false
    if is_instance_valid(mining_ops_restore_button): mining_ops_restore_button.visible = false
    if is_instance_valid(mining_ops_widget) and active_workspace != "ops": mining_ops_widget.visible = false

# One road language only. The v0.125 terrain underlay remains, but no inherited road pass is stacked on top.
func _v123_draw_ground(campus: Rect2) -> void:
    _v125_draw_terrain_underlay(campus)
    var anchor := campus.get_center() + Vector2(-210.0, 45.0)
    _v128_draw_city_road(anchor, company_idx, V141_ROAD_SEGMENTS, V141_ROAD_TILE)
    _v141_draw_road_transition_band(Rect2(anchor, Vector2(V141_ROAD_TILE.x * V141_ROAD_SEGMENTS, V141_ROAD_TILE.y)))

# Extend the v0.103 strip+dither seam language to the procedural campus road.
func _v141_draw_road_transition_band(road: Rect2) -> void:
    var blend := Color(0.45, 0.39, 0.28, 0.24)
    var fringe := Color(0.66, 0.82, 0.42, 0.26)
    draw_rect(Rect2(road.position + Vector2(0.0, -6.0), Vector2(road.size.x, 6.0)), blend, true)
    draw_rect(Rect2(Vector2(road.position.x, road.end.y), Vector2(road.size.x, 6.0)), blend, true)
    var n := 0
    for x in range(int(road.position.x + 8.0), int(road.end.x - 4.0), 24):
        var phase := n % 2
        draw_rect(Rect2(Vector2(float(x), road.position.y - 9.0 - float(phase) * 2.0), Vector2(3.0, 3.0)), fringe, true)
        draw_rect(Rect2(Vector2(float(x + 10), road.end.y + 7.0 + float(phase) * 2.0), Vector2(3.0, 3.0)), fringe, true)
        n += 1

# Four essentials only. Bottom structures move beyond a full 48 px tile from the road edge. Decorative signs/lamps/storage/cabinet clusters are omitted.
func _v115_draw_live_site(origin: Vector2) -> void:
    var capacity_mw := _v114_capacity_mw_for_site(_player_hq_center())
    var accent: Color = COMPANY_ACCENTS[company_idx]
    _v123_draw_ground(Rect2(origin - Vector2(390.0, 260.0), Vector2(780.0, 520.0)))
    _v128_draw_container_sprite(origin + Vector2(-170.0, -112.0), capacity_mw, accent)
    _v141_draw_energy_source(_v114_primary_energy_id(_player_hq_center()), origin + Vector2(225.0, -112.0), capacity_mw, "up")
    _v141_draw_transformer(origin + Vector2(205.0, 205.0), capacity_mw)
    _v128_draw_command_hut(origin + Vector2(-215.0, 205.0), accent)

# Fixed top-left light: one lower-right cast shadow per essential sprite.
func _v128_draw_container_sprite(center: Vector2, capacity_mw: float, accent: Color, forced_size: Vector2 = Vector2.ZERO) -> Vector2:
    var size_value := forced_size if forced_size != Vector2.ZERO else _v128_container_size(capacity_mw)
    _v103_draw_building_shadow(center, size_value)
    var dest := Rect2(center - size_value * Vector2(0.5, 0.55), size_value)
    if v128_container_texture != null:
        draw_rect(dest.grow(4.0), Color("11181d"), true)
        draw_texture_rect(v128_container_texture, dest, false)
    else:
        draw_rect(dest, Color("c4cbce"), true)
        draw_rect(dest, Color("3b464d"), false, 3.0)
        draw_string(ThemeDB.fallback_font, dest.position + Vector2(8.0, 18.0), "MINING CONTAINER", HORIZONTAL_ALIGNMENT_LEFT, dest.size.x - 16.0, 9, Color("17242b"))
    draw_rect(Rect2(Vector2(dest.position.x + 8.0, dest.end.y - 8.0), Vector2(maxf(12.0, dest.size.x - 16.0), 5.0)), accent, true)
    return size_value

func _v128_draw_command_hut(pos: Vector2, accent: Color) -> void:
    var size_value := Vector2(112.0, 72.0)
    _v103_draw_building_shadow(pos, size_value)
    var rect := Rect2(pos - Vector2(56.0, 39.6), size_value)
    draw_rect(rect, Color("17242b"), true)
    draw_rect(Rect2(rect.position + Vector2(12.0, 13.0), Vector2(88.0, 34.0)), Color("071016"), true)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(17.0, 34.0), "COMMAND CENTER", HORIZONTAL_ALIGNMENT_LEFT, 78.0, 8, accent)
    draw_circle(rect.position + Vector2(93.0, 58.0), 3.0, Color("39ff75"))

func _v141_draw_energy_source(asset_id: String, pos: Vector2, capacity_mw: float, orientation: String) -> void:
    if v114_energy_texture == null: return
    var region := EnergyVisualCatalog.source_region(asset_id, orientation)
    if region.size == Vector2.ZERO: return
    var size_value := _v114_sprite_size(capacity_mw, 300.0)
    _v103_draw_building_shadow(pos, size_value)
    draw_texture_rect_region(v114_energy_texture, Rect2(pos - size_value * Vector2(0.5, 0.58), size_value), region)

func _v141_draw_transformer(pos: Vector2, capacity_mw: float) -> void:
    var tiles := _v114_footprint_tiles(capacity_mw)
    var scale := clampf(float(tiles) / 4.0, 0.65, 1.35)
    var body := Vector2(62.0, 58.0) * scale
    _v103_draw_building_shadow(pos, body)
    draw_rect(Rect2(pos - body * Vector2(0.5, 0.55), body), Color("516245"), true)
    draw_rect(Rect2(pos + Vector2(-body.x * 0.40, -body.y * 0.36), Vector2(body.x * 0.80, body.y * 0.52)), Color("64785a"), true)
    for i in range(3):
        var x := pos.x - body.x * 0.28 + float(i) * body.x * 0.28
        draw_line(Vector2(x, pos.y - body.y * 0.48), Vector2(x, pos.y - body.y * 0.76), Color("20272a"), 3.0 * scale)
        draw_circle(Vector2(x, pos.y - body.y * 0.80), 4.0 * scale, Color("20272a"))

# Label budget: active route/selection target plus nearest interactive building only.
func _show_building_name(pos: Vector2, idx: int) -> bool:
    var target_idx := pending_interaction_idx if pending_interaction_idx >= 0 else selected_entity_idx
    if idx == target_idx: return true
    return idx == _nearest_building_idx() and idx != target_idx and rep_pos.distance_to(_entity_interaction_point(idx)) <= V091_BUILDING_LABEL_DISTANCE

# Town banners would create a third nearby label.
func _draw_pixel_town_labels() -> void:
    pass

func debug_v141_ready() -> bool:
    return V141_VISUAL_DECLUTTER_REVISION == 1 and V141_PROP_ROAD_GAP == 48.0 and V141_CLUSTER_GAP == 96.0 and bool(get_meta("hashrace_v141_single_road_language", false)) and bool(get_meta("hashrace_v141_sparse_four_object_site", false)) and debug_v140_ready()
