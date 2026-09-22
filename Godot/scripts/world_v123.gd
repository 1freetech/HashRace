extends "res://scripts/world_v122.gd"

# Hash Race v0.123 locked visual-target pass.
# The reference screenshot is a design specification only. This layer redraws
# the live Godot world with original runtime geometry and dynamic HUD data; the
# reference image itself is never used as a gameplay background.
#
# Target language: compact top HUD, neon green/black UI, large intentional
# industrial buildings, strong shadows, clean road/terrain boundaries, sparse
# props, readable storage/fence details, and a green-accented player.

const VisualTargetHUD = preload("res://scripts/visual_target_hud.gd")
const DefaultPlayerSheetV123 = preload("res://scripts/default_player_sprite_sheet.gd")
const V123_VISUAL_TARGET_REVISION := 1
const V123_PLAYER_HEIGHT := 124.0
const V123_PLAYER_ANCHOR_Y := 0.66
const V123_GREEN := Color("64ff71")
const V123_DARK := Color("11181d")
const V123_STEEL := Color("59646b")
const V123_STEEL_HI := Color("919ca2")
const V123_ASPHALT := Color("444a50")
const V123_FENCE := Color("69777a")

var v123_hud_layer: CanvasLayer
var v123_hud: Control
var v123_green_player_texture: Texture2D

func _ready() -> void:
    _v123_build_green_player_texture()
    super._ready()
    set_meta("hashrace_v123_visual_target_revision", V123_VISUAL_TARGET_REVISION)
    call_deferred("_v123_install_hud")
    queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)
    if not is_instance_valid(v123_hud):
        _v123_install_hud()

func _v123_install_hud() -> void:
    if is_instance_valid(v123_hud):
        return
    v123_hud_layer = CanvasLayer.new()
    v123_hud_layer.name = "VisualTargetHUDLayer"
    v123_hud_layer.layer = 55
    add_child(v123_hud_layer)

    v123_hud = VisualTargetHUD.new()
    v123_hud.name = "VisualTargetHUD"
    v123_hud_layer.add_child(v123_hud)
    v123_hud.setup(self)

    # Keep the proven Mining Ops widget alive for its data/API contract, but
    # remove the duplicate always-visible panel. v0.123 owns the top HUD.
    var mining_widget := get_node_or_null("MiningOpsHUD/MiningOpsWidget")
    if is_instance_valid(mining_widget):
        mining_widget.visible = false
    var restore := get_node_or_null("MiningOpsHUD/MiningOpsRestore")
    if is_instance_valid(restore):
        restore.visible = false

func _v123_build_green_player_texture() -> void:
    if v121_player_texture == null:
        v121_player_texture = DefaultPlayerSheetV123.load_texture()
    if v121_player_texture == null:
        return
    var image := v121_player_texture.get_image()
    if image == null or image.is_empty():
        return
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var c := image.get_pixel(x, y)
            if c.a < 0.05:
                continue
            # Recolor only the warm armor/scouter accents. Skin and black armor
            # remain intact, producing the green/black target character at run time.
            if c.r > c.g * 1.18 and c.r > c.b * 1.25 and c.r > 0.30:
                var luminance := clampf((c.r + c.g + c.b) / 3.0, 0.0, 1.0)
                c.r = 0.10 + luminance * 0.18
                c.g = 0.55 + luminance * 0.42
                c.b = 0.18 + luminance * 0.20
                image.set_pixel(x, y, c)
    v123_green_player_texture = ImageTexture.create_from_image(image)

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if not is_player or v123_green_player_texture == null or not v073_character_action.is_empty():
        super._draw_tech_rep(pos, accent, scanner, is_player)
        return
    var moving := not rep_animation_state.ends_with("_idle")
    var frame := _v121_walk_frame(moving)
    var region := DefaultPlayerSheetV123.frame_region(rep_facing, frame)
    var frame_aspect := float(region.size.x) / float(region.size.y)
    var size_value := Vector2(V123_PLAYER_HEIGHT * frame_aspect, V123_PLAYER_HEIGHT)
    var center := VisualStack.snap_to_pixel(pos + Vector2(0.0, -5.0))
    var dest := Rect2(
        center + Vector2(-size_value.x * 0.5, -size_value.y * V123_PLAYER_ANCHOR_Y),
        size_value
    )
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 43.0)), 27.0, 8.0)
    draw_texture_rect_region(v123_green_player_texture, dest, Rect2(region))

func _v115_draw_live_site(origin: Vector2) -> void:
    # Replace the old gray pad with a sparse, authored-looking facility block.
    # All values still come from the real mining simulation.
    var capacity_mw := _v114_capacity_mw_for_site(_player_hq_center())
    var load_mw := maxf(0.0, _machine_load_kw() / 1000.0)
    var available_mw := maxf(0.0, _effective_available_mw())
    var accent: Color = COMPANY_ACCENTS[company_idx]

    var campus := Rect2(origin - Vector2(390.0, 260.0), Vector2(780.0, 520.0))
    _v123_draw_ground(campus)
    _v123_draw_mining_rigs(origin + Vector2(-225.0, -115.0), accent)
    _v123_draw_transformer_target(origin + Vector2(0.0, -118.0))
    _v123_draw_power_module(origin + Vector2(225.0, -112.0), available_mw)
    _v123_draw_storage_yard(origin + Vector2(205.0, 135.0))
    _v123_draw_site_sign(origin + Vector2(-300.0, 86.0), "SMALL MINERS\nBIG FUTURE", Color("f7931a"))
    _v123_draw_site_sign(origin + Vector2(40.0, 215.0), "BITCOIN POWERS\nPEOPLE", Color("f7931a"))
    _v123_draw_lamps(origin)
    _v123_draw_capacity_meter(origin + Vector2(-180.0, 225.0), load_mw, available_mw, capacity_mw)

func _v123_draw_ground(campus: Rect2) -> void:
    # No giant solid pad: grass remains dominant and structures get purposeful
    # paved aprons so the site reads like the target rather than a gray rectangle.
    var road_y := campus.position.y + campus.size.y * 0.54
    draw_rect(Rect2(Vector2(campus.position.x, road_y), Vector2(campus.size.x, 86.0)), V123_ASPHALT, true)
    draw_rect(Rect2(Vector2(campus.position.x, road_y - 5.0), Vector2(campus.size.x, 5.0)), Color("858b82"), true)
    draw_rect(Rect2(Vector2(campus.position.x, road_y + 86.0), Vector2(campus.size.x, 5.0)), Color("2a3031"), true)
    for x in range(int(campus.position.x + 30.0), int(campus.end.x - 20.0), 82):
        draw_rect(Rect2(Vector2(float(x), road_y + 40.0), Vector2(38.0, 5.0)), Color("c7c8c3"), true)

func _v123_shadow(pos: Vector2, size_value: Vector2) -> void:
    draw_rect(Rect2(pos - size_value * 0.5 + Vector2(10.0, 12.0), size_value), Color(0.0, 0.0, 0.0, 0.28), true)

func _v123_draw_mining_rigs(pos: Vector2, accent: Color) -> void:
    var s := Vector2(245.0, 150.0)
    _v123_shadow(pos, s)
    var r := Rect2(pos - s * 0.5, s)
    draw_rect(r, Color("343c43"), true)
    draw_rect(Rect2(r.position + Vector2(0, 0), Vector2(r.size.x, 34)), Color("252c31"), true)
    draw_rect(Rect2(r.position + Vector2(9, 42), Vector2(150, 74)), Color("171e23"), true)
    draw_rect(Rect2(r.position + Vector2(14, 47), Vector2(140, 9)), V123_GREEN.darkened(0.18), true)
    _v123_label(r.position + Vector2(55, 25), "MINING RIGS", 16, Color("d9e0e2"))
    for i in range(3):
        var c := r.position + Vector2(40.0 + i * 46.0, 84.0)
        draw_rect(Rect2(c - Vector2(18, 18), Vector2(36, 36)), Color("202931"), true)
        draw_circle(c, 14.0, Color("090d10"))
        for a in range(0, 360, 60):
            var rad := deg_to_rad(float(a))
            draw_line(c, c + Vector2(cos(rad), sin(rad)) * 12.0, Color("4d5c63"), 4.0)
        draw_circle(c, 4.0, accent)
    var door := Rect2(r.position + Vector2(169, 60), Vector2(52, 70))
    draw_rect(door, Color("141b20"), true)
    draw_rect(door.grow(-6.0), Color("273238"), true)
    draw_line(door.position + Vector2(18, 42), door.position + Vector2(34, 22), V123_GREEN, 5.0)
    draw_line(door.position + Vector2(22, 21), door.position + Vector2(38, 21), V123_GREEN, 5.0)
    draw_rect(Rect2(r.position + Vector2(225, 78), Vector2(12, 42)), Color("151d21"), true)
    draw_circle(r.position + Vector2(231, 91), 3.0, V123_GREEN)

func _v123_draw_transformer_target(pos: Vector2) -> void:
    var s := Vector2(180.0, 148.0)
    _v123_shadow(pos, s)
    var r := Rect2(pos - s * 0.5, s)
    draw_rect(r, Color("4c555d"), true)
    draw_rect(r.grow(-7.0), Color("707a82"), true)
    draw_rect(Rect2(r.position + Vector2(0, 45), Vector2(r.size.x, 30)), Color("2b3339"), true)
    _v123_label(r.position + Vector2(27, 66), "TRANSFORMER", 14, Color("eef2f3"))
    for ox in [38.0, 90.0, 142.0]:
        draw_rect(Rect2(r.position + Vector2(ox - 7.0, -26.0), Vector2(14.0, 44.0)), Color("171b1f"), true)
        for yy in range(-20, 17, 8):
            draw_rect(Rect2(r.position + Vector2(ox - 12.0, float(yy)), Vector2(24.0, 4.0)), Color("363c40"), true)
    var tri := PackedVector2Array([
        r.position + Vector2(90, 87),
        r.position + Vector2(70, 124),
        r.position + Vector2(110, 124),
    ])
    draw_colored_polygon(tri, Color("f2c94c"))
    draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), Color("171717"), 3.0)
    _v123_label(r.position + Vector2(84, 116), "⚡", 18, Color("171717"))

func _v123_draw_power_module(pos: Vector2, available_mw: float) -> void:
    var s := Vector2(160.0, 138.0)
    _v123_shadow(pos, s)
    var r := Rect2(pos - s * 0.5, s)
    draw_rect(r, Color("323b42"), true)
    draw_rect(r.grow(-7.0), Color("4c565c"), true)
    draw_rect(Rect2(r.position + Vector2(13, 35), Vector2(r.size.x - 26, 34)), Color("1f282d"), true)
    _v123_label(r.position + Vector2(30, 58), "POWER MODULE", 12, Color("e8eeee"))
    var battery := Rect2(r.position + Vector2(46, 83), Vector2(66, 30))
    draw_rect(battery, Color("0b1710"), true)
    draw_rect(battery.grow(-5.0), V123_GREEN.darkened(0.25), true)
    draw_rect(Rect2(battery.position + Vector2(6, 6), Vector2(40, 18)), V123_GREEN, true)
    draw_rect(Rect2(battery.end + Vector2(0, -20), Vector2(6, 10)), V123_GREEN, true)
    _v123_label(r.position + Vector2(49, 131), "%.1f MW" % available_mw, 10, Color("b6c5c9"))

func _v123_draw_storage_yard(pos: Vector2) -> void:
    var yard := Rect2(pos - Vector2(160, 72), Vector2(320, 144))
    draw_rect(yard, Color("3b4144"), true)
    _v123_draw_fence(Rect2(yard.position - Vector2(8, 8), yard.size + Vector2(16, 16)))
    var building := Rect2(yard.position + Vector2(182, 18), Vector2(116, 102))
    draw_rect(building, Color("2b3338"), true)
    draw_rect(Rect2(building.position + Vector2(13, 47), Vector2(90, 56)), Color("151b1e"), true)
    _v123_label(building.position + Vector2(22, 30), "STORAGE", 13, Color("d8e0e2"))
    draw_rect(Rect2(yard.position + Vector2(22, 48), Vector2(78, 63)), Color("26343a"), true)
    draw_rect(Rect2(yard.position + Vector2(104, 76), Vector2(48, 34)), Color("a6793e"), true)
    draw_rect(Rect2(yard.position + Vector2(122, 52), Vector2(42, 28)), Color("b38548"), true)
    # Forklift silhouette + restrained safety cones.
    draw_rect(Rect2(yard.position + Vector2(151, 88), Vector2(35, 22)), Color("d69b20"), true)
    draw_circle(yard.position + Vector2(158, 113), 7.0, Color("151515"))
    draw_circle(yard.position + Vector2(181, 113), 7.0, Color("151515"))
    draw_line(yard.position + Vector2(185, 89), yard.position + Vector2(185, 62), Color("1f2528"), 5.0)
    for x in [116.0, 205.0]:
        var c := yard.position + Vector2(x, 124)
        var cone := PackedVector2Array([c, c + Vector2(-7, 14), c + Vector2(7, 14)])
        draw_colored_polygon(cone, Color("ff7a2d"))

func _v123_draw_fence(r: Rect2) -> void:
    draw_rect(r, V123_FENCE, false, 3.0)
    for x in range(int(r.position.x + 10), int(r.end.x), 24):
        draw_line(Vector2(float(x), r.position.y), Vector2(float(x), r.end.y), Color("485559"), 1.0)
        draw_line(Vector2(float(x), r.position.y), Vector2(float(x + 18), r.end.y), Color("566367"), 1.0)

func _v123_draw_site_sign(pos: Vector2, text_value: String, accent: Color) -> void:
    var r := Rect2(pos - Vector2(62, 32), Vector2(124, 64))
    draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.24), true)
    draw_rect(r, Color("182026"), true)
    draw_rect(r, Color("59676b"), false, 2.0)
    _v123_label(r.position + Vector2(10, 24), text_value, 10, Color("e4e8e6"))
    draw_circle(r.position + Vector2(r.size.x - 18, 19), 8.0, accent)

func _v123_draw_lamps(origin: Vector2) -> void:
    for xoff in [-305.0, 305.0]:
        var p := origin + Vector2(xoff, 62.0)
        draw_rect(Rect2(p + Vector2(-3, -5), Vector2(6, 100)), Color("20292d"), true)
        draw_rect(Rect2(p + Vector2(-12, -11), Vector2(24, 10)), Color("252e32"), true)
        draw_rect(Rect2(p + Vector2(-8, -8), Vector2(16, 5)), Color("ffe69a"), true)

func _v123_draw_capacity_meter(pos: Vector2, load_mw: float, available_mw: float, capacity_mw: float) -> void:
    var max_mw := maxf(0.001, maxf(available_mw, capacity_mw))
    var ratio := clampf(load_mw / max_mw, 0.0, 1.0)
    var r := Rect2(pos, Vector2(330, 42))
    draw_rect(r, Color(0.02, 0.05, 0.07, 0.90), true)
    draw_rect(r, Color("40545e"), false, 1.0)
    var bar := Rect2(r.position + Vector2(12, 25), Vector2(r.size.x - 24, 8))
    draw_rect(bar, Color("172126"), true)
    draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), V123_GREEN, true)
    _v123_label(r.position + Vector2(12, 17), "MINING LOAD %.1f / %.1f MW" % [load_mw, max_mw], 10, Color("d7e1e3"))

func _v123_label(pos: Vector2, value: String, font_size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func debug_v123_ready() -> bool:
    return V123_VISUAL_TARGET_REVISION == 1 \
        and VisualTargetHUD != null \
        and V123_PLAYER_HEIGHT > 88.0 \
        and debug_v122_ready()
