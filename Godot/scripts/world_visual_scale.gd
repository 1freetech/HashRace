extends "res://scripts/world_visual_detail.gd"

# v0.034 visual scale + conversation pass.
# Camera-area math is adapted from the MIT-licensed codenamecpp/carnage3d
# GameCamera::ComputeViewBounds2 pattern: visible bounds are derived from camera
# position plus/minus a half-span. In Godot 2D the half-span is viewport / zoom.
# This keeps player/map proportions deterministic instead of eyeballing sprite size.

const TalkPortrait = preload("res://scripts/talk_portrait.gd")
const VISUAL_SCALE_REVISION: int = 4
const CARNAGE3D_SOURCE: String = "codenamecpp/carnage3d/src/GameCamera.cpp"
const NORMAL_MAP_ZOOM: float = 0.72
const REP_ART_HEIGHT_PX: float = 145.0
const REP_HEIGHT_IN_TILES: float = 1.34
const EXTRA_DETAIL_REVISION: int = 3

var overview_active: bool = false
var talk_portrait: Control
var overview_banner: Label
var _camera_tween: Tween
var _visible_map_min: Vector2 = Vector2.ZERO
var _visible_map_max: Vector2 = Vector2.ZERO

func _ready() -> void:
    super._ready()
    set_meta("hashrace_visual_scale_revision", VISUAL_SCALE_REVISION)
    set_meta("hashrace_visual_scale_source", CARNAGE3D_SOURCE)
    if is_instance_valid(camera):
        camera.zoom = Vector2(NORMAL_MAP_ZOOM, NORMAL_MAP_ZOOM)
        camera.position_smoothing_enabled = true
        camera.position_smoothing_speed = 7.0
    _build_visual_mode_ui()
    _refresh_talk_portrait("COMPANY REPRESENTATIVE")
    _update_visible_map_bounds()
    queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)
    if is_instance_valid(camera):
        if overview_active:
            camera.position = WORLD_SIZE * 0.5
        _update_visible_map_bounds()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_M:
            _toggle_map_overview()
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)

func _open_message(title_text: String, body_text: String) -> void:
    super._open_message(title_text, body_text)
    _refresh_talk_portrait(title_text)

func _build_visual_mode_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "VisualScaleHUD"
    layer.layer = 35
    add_child(layer)

    talk_portrait = TalkPortrait.new()
    talk_portrait.name = "TalkPortrait"
    talk_portrait.position = Vector2(1038.0, 632.0)
    talk_portrait.size = Vector2(390.0, 256.0)
    layer.add_child(talk_portrait)

    overview_banner = Label.new()
    overview_banner.position = Vector2(34.0, 98.0)
    overview_banner.size = Vector2(540.0, 42.0)
    overview_banner.text = "MAP OVERVIEW // M: RETURN TO FIELD VIEW"
    overview_banner.add_theme_font_size_override("font_size", 17)
    overview_banner.add_theme_color_override("font_color", Color("dff8d8"))
    overview_banner.add_theme_color_override("font_shadow_color", Color("061015"))
    overview_banner.add_theme_constant_override("shadow_offset_x", 2)
    overview_banner.add_theme_constant_override("shadow_offset_y", 2)
    overview_banner.visible = false
    layer.add_child(overview_banner)

func _toggle_map_overview() -> void:
    if not is_instance_valid(camera):
        return
    overview_active = not overview_active
    if _camera_tween != null and _camera_tween.is_valid():
        _camera_tween.kill()
    _camera_tween = create_tween()
    _camera_tween.set_parallel(true)

    if overview_active:
        var fit_zoom := _calculate_overview_zoom()
        _camera_tween.tween_property(camera, "zoom", Vector2(fit_zoom, fit_zoom), 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        _camera_tween.tween_property(camera, "position", WORLD_SIZE * 0.5, 0.32).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        if is_instance_valid(overview_banner):
            overview_banner.visible = true
        if is_instance_valid(talk_portrait):
            talk_portrait.visible = false
    else:
        _camera_tween.tween_property(camera, "zoom", Vector2(NORMAL_MAP_ZOOM, NORMAL_MAP_ZOOM), 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        _camera_tween.tween_property(camera, "position", rep_pos, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
        if is_instance_valid(overview_banner):
            overview_banner.visible = false
        if is_instance_valid(talk_portrait):
            talk_portrait.visible = true
    queue_redraw()

func _calculate_overview_zoom() -> float:
    # Fit the 3000x1900 world into the usable play area while leaving room for UI.
    var viewport_size := get_viewport_rect().size
    var usable := Vector2(maxf(720.0, viewport_size.x - 360.0), maxf(520.0, viewport_size.y - 150.0))
    var fit_x := usable.x / WORLD_SIZE.x
    var fit_y := usable.y / WORLD_SIZE.y
    return clampf(minf(fit_x, fit_y), 0.32, 0.52)

func _update_visible_map_bounds() -> void:
    if not is_instance_valid(camera):
        return
    # Carnage3D equivalent:
    # areaBounds.min = camera.position - half_span
    # areaBounds.max = camera.position + half_span
    var safe_zoom := Vector2(maxf(camera.zoom.x, 0.001), maxf(camera.zoom.y, 0.001))
    var half_span := (get_viewport_rect().size * 0.5) / safe_zoom
    _visible_map_min = camera.position - half_span
    _visible_map_max = camera.position + half_span

func debug_visible_map_bounds() -> Rect2:
    return Rect2(_visible_map_min, _visible_map_max - _visible_map_min)

func debug_rep_world_height_px() -> float:
    return ART_TILE_SIZE * REP_HEIGHT_IN_TILES

func _representative_world_scale() -> float:
    var desired_height := ART_TILE_SIZE * REP_HEIGHT_IN_TILES
    return clampf(desired_height / REP_ART_HEIGHT_PX, 0.38, 0.56)

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    # Render the detailed v0.032 representative at a mathematically derived map
    # scale. The source art is ~145 px tall; the live map target is 1.34 tiles.
    # This makes people read as people inside the town rather than giant icons.
    var scale_value := _representative_world_scale()
    draw_set_transform(VisualStack.snap_to_pixel(pos), 0.0, Vector2(scale_value, scale_value))
    super._draw_tech_rep(Vector2.ZERO, accent, scanner, is_player)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_grass_detail(p: Vector2, seed: int, dark_variant: bool) -> void:
    super._draw_grass_detail(p, seed, dark_variant)
    var blade_mid := Color("2d6848") if not dark_variant else Color("1c4936")
    var blade_high := Color("57a169") if not dark_variant else Color("367853")
    var phase := int(Time.get_ticks_msec() / 220.0) % 6
    for i in range(4):
        var dx := 4.0 + float(_scatter(seed + 701, i, 38))
        var dy := 5.0 + float(_scatter(seed + 809, i, 36))
        var sway := float((i + phase) % 3) - 1.0
        var tone := blade_high if i % 2 == 0 else blade_mid
        draw_rect(Rect2(p + Vector2(dx + sway, dy), Vector2(2.0, 5.0)), tone, true)
    if seed % 11 == 0:
        draw_rect(Rect2(p + Vector2(22.0, 8.0), Vector2(2.0, 2.0)), Color("c45c3a"), true)

func _draw_road_detail(cell: Vector2i, p: Vector2, seed: int) -> void:
    super._draw_road_detail(cell, p, seed)
    for i in range(4):
        var dx := 6.0 + float(_scatter(seed + 991, i, 34))
        var dy := 6.0 + float(_scatter(seed + 1091, i, 34))
        draw_rect(Rect2(p + Vector2(dx, dy), Vector2(2.0, 2.0)), Color("202c31"), true)
    if seed % 6 == 0:
        draw_rect(Rect2(p + Vector2(10.0, 18.0), Vector2(18.0, 2.0)), Color("141b1f"), true)

func _draw_site_container(center: Vector2, accent: Color) -> void:
    super._draw_site_container(center, accent)
    # Additional animated fan blades from the supplied visual-upgrade prototype.
    var angle := float(Time.get_ticks_msec() % 4000) / 4000.0 * TAU
    var rect_pos := center + Vector2(-52.0, -28.0)
    for fan in range(4):
        var fc := rect_pos + Vector2(17.0 + float(fan) * 23.0, 29.0)
        var axis := Vector2(cos(angle + float(fan) * 0.55), sin(angle + float(fan) * 0.55)) * 5.0
        var cross_axis := Vector2(-axis.y, axis.x)
        draw_line(fc - axis, fc + axis, accent.lightened(0.18), 2.0)
        draw_line(fc - cross_axis, fc + cross_axis, accent.darkened(0.08), 2.0)

func _draw_transformer_bank(center: Vector2, accent: Color) -> void:
    super._draw_transformer_bank(center, accent)
    var tick := int(Time.get_ticks_msec() / 120)
    if (tick + int(center.x + center.y)) % 19 == 0:
        var spark_origin := VisualStack.snap_to_pixel(center + Vector2(2.0, -32.0))
        draw_line(spark_origin, spark_origin + Vector2(5.0, -6.0), Color("88efff"), 2.0)
        draw_line(spark_origin + Vector2(5.0, -6.0), spark_origin + Vector2(9.0, -2.0), Color("ffffff"), 1.0)

func _refresh_talk_portrait(title_text: String) -> void:
    if not is_instance_valid(talk_portrait):
        return
    var portrait_name := String(player.get("name", "COMPANY REPRESENTATIVE"))
    var portrait_role := "BITCOIN MINING OPERATOR"
    var portrait_accent: Color = COMPANY_ACCENTS[company_idx]

    if selected_entity_idx >= 0 and selected_entity_idx < entities.size():
        var entity: Dictionary = entities[selected_entity_idx]
        portrait_name = String(entity.get("name", portrait_name))
        var kind := String(entity.get("kind", ""))
        if kind == "rival":
            portrait_role = "RIVAL MINING REPRESENTATIVE"
            var rival_idx := int(entity.get("rival_idx", -1))
            if rival_idx >= 0 and rival_idx < rivals.size():
                portrait_accent = COMPANY_ACCENTS[int(rivals[rival_idx].get("profile_idx", company_idx))]
        elif kind == "partner":
            portrait_role = String(entity.get("subtitle", "INDUSTRY PARTNER"))
        elif kind == "hq":
            portrait_role = "COMPANY REPRESENTATIVE"
        else:
            portrait_role = String(entity.get("subtitle", "TECH DISTRICT CONTACT"))
    elif not title_text.is_empty():
        portrait_name = title_text.left(34)

    talk_portrait.call("set_subject", portrait_name, portrait_accent, portrait_role)

func debug_visual_scale_state() -> Dictionary:
    return {
        "revision": VISUAL_SCALE_REVISION,
        "detail_revision": EXTRA_DETAIL_REVISION,
        "source": CARNAGE3D_SOURCE,
        "rep_scale": _representative_world_scale(),
        "rep_height_px": debug_rep_world_height_px(),
        "overview_active": overview_active,
        "visible_bounds": debug_visible_map_bounds(),
        "portrait_ready": is_instance_valid(talk_portrait)
    }
