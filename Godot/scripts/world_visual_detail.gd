extends "res://scripts/world_burnout.gd"

# v0.032 visual-detail pass.
# Corrective goal: make character and environment changes obvious at normal
# screenshot scale instead of only changing anti-aliasing, snapping, or tiny
# accents. The procedural approach is adapted from the MIT-licensed ideas in
# MozeeB/pixel-asset-gen: deterministic micro-texture, bold multi-tier shading,
# thick warm outlines, readable silhouettes, and layered environment props.

const VISUAL_DETAIL_REVISION: int = 2
const VISUAL_DETAIL_SOURCE: String = "MozeeB/pixel-asset-gen"
const WARM_OUTLINE: Color = Color("322319")
const WARM_OUTLINE_LIGHT: Color = Color("503c2d")
const STEEL_DARK: Color = Color("10181d")
const STEEL_BASE: Color = Color("26343b")
const STEEL_LIGHT: Color = Color("60727b")
const HAZARD_YELLOW: Color = Color("f3c84b")
const HAZARD_ORANGE: Color = Color("d9772a")
const WORK_LIGHT: Color = Color("b9f7ff")

func _ready() -> void:
    super._ready()
    set_meta("hashrace_visual_detail_revision", VISUAL_DETAIL_REVISION)
    queue_redraw()

func _detail_seed(cell: Vector2i, salt: int) -> int:
    var value: int = cell.x * 73856093
    value ^= cell.y * 19349663
    value ^= salt * 83492791
    return absi(value)

func _scatter(seed: int, slot: int, extent: int) -> int:
    if extent <= 0:
        return 0
    var value: int = absi(seed * (31 + slot * 2) + slot * 7919 + 104729)
    return value % extent

func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
    super._draw_art_tile(cell, tile_id)
    var p: Vector2 = VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    var seed: int = _detail_seed(cell, tile_id + 11)

    if tile_id == TILE_GRASS or tile_id == TILE_GRASS_DARK:
        _draw_grass_detail(p, seed, tile_id == TILE_GRASS_DARK)
    elif tile_id == TILE_ROAD:
        _draw_road_detail(cell, p, seed)
    elif tile_id == TILE_WATER:
        _draw_water_detail(p, seed)
    elif tile_id == TILE_LOT:
        _draw_lot_detail(p, seed)
    elif tile_id == TILE_PLAZA:
        _draw_plaza_detail(p, seed)

func _draw_grass_detail(p: Vector2, seed: int, dark_variant: bool) -> void:
    var blade_dark: Color = Color("18382c") if not dark_variant else Color("0d281f")
    var blade_mid: Color = Color("2d6848") if not dark_variant else Color("1c4936")
    var blade_high: Color = Color("57a169") if not dark_variant else Color("367853")
    for i in range(8):
        var dx: float = 4.0 + float(_scatter(seed, i, 38))
        var dy: float = 5.0 + float(_scatter(seed + 97, i, 36))
        var tone: Color = blade_mid
        if i % 3 == 0:
            tone = blade_high
        elif i % 3 == 1:
            tone = blade_dark
        draw_rect(Rect2(p + Vector2(dx, dy), Vector2(2.0, 4.0)), tone, true)
        if i % 2 == 0:
            draw_rect(Rect2(p + Vector2(dx + 2.0, dy + 1.0), Vector2(2.0, 2.0)), tone, true)
    # A few tiny stones/flowers stop large grass fields from reading as flat fill.
    if seed % 4 == 0:
        draw_rect(Rect2(p + Vector2(11.0, 31.0), Vector2(3.0, 2.0)), Color("78907c"), true)
    if seed % 7 == 0:
        draw_rect(Rect2(p + Vector2(34.0, 12.0), Vector2(2.0, 2.0)), Color("e8d76d"), true)

func _draw_road_detail(cell: Vector2i, p: Vector2, seed: int) -> void:
    # Asphalt aggregate.
    for i in range(6):
        var dx: float = 5.0 + float(_scatter(seed, i, 38))
        var dy: float = 5.0 + float(_scatter(seed + 211, i, 38))
        var speck: Color = Color("34434b") if i % 2 == 0 else Color("1d292f")
        draw_rect(Rect2(p + Vector2(dx, dy), Vector2(2.0, 2.0)), speck, true)

    # Bright curb pixels appear only where road meets non-road terrain.
    if int(art_cells.get(cell + Vector2i.UP, -1)) != TILE_ROAD:
        _draw_hazard_edge(p + Vector2(0.0, 1.0), true)
    if int(art_cells.get(cell + Vector2i.DOWN, -1)) != TILE_ROAD:
        _draw_hazard_edge(p + Vector2(0.0, 44.0), true)
    if int(art_cells.get(cell + Vector2i.LEFT, -1)) != TILE_ROAD:
        _draw_hazard_edge(p + Vector2(1.0, 0.0), false)
    if int(art_cells.get(cell + Vector2i.RIGHT, -1)) != TILE_ROAD:
        _draw_hazard_edge(p + Vector2(44.0, 0.0), false)

func _draw_hazard_edge(origin: Vector2, horizontal: bool) -> void:
    for i in range(6):
        var color: Color = HAZARD_YELLOW.darkened(0.18) if i % 2 == 0 else Color("4a555b")
        if horizontal:
            draw_rect(Rect2(origin + Vector2(float(i) * 8.0, 0.0), Vector2(7.0, 3.0)), color, true)
        else:
            draw_rect(Rect2(origin + Vector2(0.0, float(i) * 8.0), Vector2(3.0, 7.0)), color, true)

func _draw_water_detail(p: Vector2, seed: int) -> void:
    var phase: int = int(Time.get_ticks_msec() / 180) % 8
    for i in range(4):
        var x: float = float((_scatter(seed, i, 30) + phase * (i + 1)) % 30) + 5.0
        var y: float = 7.0 + float(i) * 10.0
        var width: float = 8.0 + float((seed + i * 13) % 8)
        draw_rect(Rect2(p + Vector2(x, y), Vector2(width, 2.0)), Color("49b8c7"), true)
        draw_rect(Rect2(p + Vector2(x + 4.0, y + 3.0), Vector2(maxf(3.0, width - 7.0), 2.0)), Color("1d7184"), true)

func _draw_lot_detail(p: Vector2, seed: int) -> void:
    # Concrete slab seams + rivet/aggregate points.
    draw_rect(Rect2(p + Vector2(23.0, 4.0), Vector2(2.0, 40.0)), Color("303b40"), true)
    draw_rect(Rect2(p + Vector2(4.0, 23.0), Vector2(40.0, 2.0)), Color("303b40"), true)
    for i in range(5):
        var dx: float = 7.0 + float(_scatter(seed, i, 34))
        var dy: float = 7.0 + float(_scatter(seed + 401, i, 34))
        draw_rect(Rect2(p + Vector2(dx, dy), Vector2(2.0, 2.0)), Color("6f7d82"), true)

func _draw_plaza_detail(p: Vector2, seed: int) -> void:
    for gx in range(3):
        for gy in range(3):
            var tile_pos: Vector2 = p + Vector2(8.0 + float(gx) * 11.0, 8.0 + float(gy) * 11.0)
            var shade: Color = Color("59666b") if (gx + gy + seed) % 2 == 0 else Color("465258")
            draw_rect(Rect2(tile_pos, Vector2(9.0, 9.0)), shade, false, 1.0)

func _draw_world_props_pixel() -> void:
    super._draw_world_props_pixel()
    # Give every Bitcoin-mining town a recognizable industrial apron. These are
    # decorative, deliberately outside the building footprint/interact apron.
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = VisualStack.snap_to_pixel(zone["center"])
        var profile_idx: int = int(zone["profile_idx"])
        var accent: Color = COMPANY_ACCENTS[profile_idx]
        _draw_site_container(center + Vector2(-152.0, 22.0), accent)
        _draw_transformer_bank(center + Vector2(143.0, 28.0), accent)
        _draw_site_fence(center, accent)
        _draw_bollards(center + Vector2(0.0, 77.0), accent)

func _draw_site_container(center: Vector2, accent: Color) -> void:
    var rect: Rect2 = Rect2(center + Vector2(-52.0, -28.0), Vector2(104.0, 56.0))
    draw_rect(rect, WARM_OUTLINE, true)
    draw_rect(Rect2(rect.position + Vector2(4.0, 4.0), rect.size - Vector2(8.0, 8.0)), STEEL_BASE, true)
    # Corrugated side wall.
    for x in range(10):
        var wx: float = rect.position.x + 8.0 + float(x) * 9.0
        draw_rect(Rect2(wx, rect.position.y + 6.0, 3.0, rect.size.y - 12.0), STEEL_DARK if x % 2 == 0 else STEEL_LIGHT.darkened(0.34), true)
    # Four cooling fan faces.
    for fan in range(4):
        var fan_center: Vector2 = rect.position + Vector2(17.0 + float(fan) * 23.0, 29.0)
        draw_circle(fan_center, 8.0, Color("0b1115"))
        draw_circle(fan_center, 5.0, accent.darkened(0.42))
        draw_line(fan_center + Vector2(-5.0, 0.0), fan_center + Vector2(5.0, 0.0), accent, 2.0)
        draw_line(fan_center + Vector2(0.0, -5.0), fan_center + Vector2(0.0, 5.0), accent, 2.0)
    draw_rect(Rect2(rect.position + Vector2(6.0, 6.0), Vector2(22.0, 7.0)), accent, true)

func _draw_transformer_bank(center: Vector2, accent: Color) -> void:
    for i in range(3):
        var p: Vector2 = center + Vector2(float(i) * 30.0 - 30.0, 0.0)
        draw_rect(Rect2(p + Vector2(-11.0, -24.0), Vector2(22.0, 46.0)), WARM_OUTLINE, true)
        draw_rect(Rect2(p + Vector2(-8.0, -21.0), Vector2(16.0, 40.0)), Color("53636b"), true)
        draw_rect(Rect2(p + Vector2(-6.0, -14.0), Vector2(12.0, 5.0)), Color("222e34"), true)
        for slit in range(4):
            draw_rect(Rect2(p + Vector2(-6.0, -3.0 + float(slit) * 5.0), Vector2(12.0, 2.0)), Color("1a252a"), true)
        draw_rect(Rect2(p + Vector2(-3.0, -30.0), Vector2(6.0, 8.0)), accent.darkened(0.1), true)
        draw_rect(Rect2(p + Vector2(-1.0, -34.0), Vector2(2.0, 5.0)), Color("dce9e9"), true)

func _draw_site_fence(center: Vector2, accent: Color) -> void:
    var y: float = center.y - 92.0
    for x in range(-126, 127, 28):
        var px: float = center.x + float(x)
        draw_rect(Rect2(px, y, 3.0, 20.0), Color("718188"), true)
        if x < 112:
            draw_line(Vector2(px + 2.0, y + 4.0), Vector2(px + 30.0, y + 16.0), Color("4b5a60"), 1.0)
            draw_line(Vector2(px + 2.0, y + 16.0), Vector2(px + 30.0, y + 4.0), Color("4b5a60"), 1.0)
    draw_rect(Rect2(center + Vector2(-42.0, -96.0), Vector2(84.0, 5.0)), accent.darkened(0.32), true)

func _draw_bollards(center: Vector2, accent: Color) -> void:
    for x in [-48.0, -24.0, 24.0, 48.0]:
        draw_rect(Rect2(center + Vector2(x - 3.0, -10.0), Vector2(6.0, 20.0)), WARM_OUTLINE, true)
        draw_rect(Rect2(center + Vector2(x - 2.0, -8.0), Vector2(4.0, 16.0)), HAZARD_YELLOW if int(x) % 48 == 0 else accent.lightened(0.12), true)

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    # Larger 16x24-ish industrial worker silhouette. The old sprite used broad
    # rectangles with very few facial/clothing pixels; this version adds a hard
    # hat, vest, scanner, gloves, pockets, tablet, backpack, boots and three-tier
    # skin/clothing shading so the change remains visible in a full-frame render.
    var cycle: float = fmod(float(Time.get_ticks_msec()), 720.0)
    var mirrored: float = cycle if cycle <= 360.0 else 720.0 - cycle
    var pose_mix: float = VisualStack.mix_alpha(mirrored, 360.0)
    var bob: float = round(VisualStack.lerp_number(0.0, -2.0, pose_mix))
    var step: int = int(round(VisualStack.lerp_number(0.0, 1.0, pose_mix)))
    var draw_pos: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(0.0, bob))
    var px: float = 5.0

    var skin_shadow: Color = Color("704431")
    var skin_base: Color = Color("a96f50")
    var skin_high: Color = Color("d9a07a")
    var suit_shadow: Color = Color("111c23")
    var suit_base: Color = Color("243641")
    var suit_high: Color = Color("425d68")
    var safety: Color = accent
    var safety_high: Color = accent.lightened(0.34)
    var boot: Color = Color("0b1014")

    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 47.0)), 28.0, 9.0)

    # Backpack silhouette behind the torso.
    _draw_px(draw_pos, -7, -3, 3, 9, px, WARM_OUTLINE)
    _draw_px(draw_pos, -6, -2, 2, 7, px, suit_shadow)
    _draw_px(draw_pos, -6, 0, 1, 4, px, safety.darkened(0.35))

    # Legs and steel-toe boots, each with shadow/base separation.
    _draw_px(draw_pos, -5, 5, 4, 7, px, WARM_OUTLINE)
    _draw_px(draw_pos, 1, 5, 4, 7, px, WARM_OUTLINE)
    _draw_px(draw_pos, -4, 5, 3, 5, px, suit_shadow)
    _draw_px(draw_pos, 1, 5, 3, 5, px, suit_base)
    _draw_px(draw_pos, -4, 9 + step, 3, 3, px, boot)
    _draw_px(draw_pos, 1, 10 - step, 4, 2, px, boot)
    _draw_px(draw_pos, -3, 9 + step, 2, 1, px, Color("4f6067"))
    _draw_px(draw_pos, 2, 10 - step, 2, 1, px, Color("4f6067"))

    # Torso + arms with thick warm outline.
    _draw_px(draw_pos, -7, -4, 14, 10, px, WARM_OUTLINE)
    _draw_px(draw_pos, -6, -3, 12, 8, px, suit_base)
    _draw_px(draw_pos, -6, -3, 3, 8, px, suit_shadow)
    _draw_px(draw_pos, 3, -3, 3, 8, px, suit_high)
    _draw_px(draw_pos, -9, -2 + step, 3, 8, px, WARM_OUTLINE)
    _draw_px(draw_pos, 6, -1 - step, 3, 8, px, WARM_OUTLINE)
    _draw_px(draw_pos, -8, -1 + step, 2, 6, px, suit_base)
    _draw_px(draw_pos, 6, 0 - step, 2, 6, px, suit_high)
    _draw_px(draw_pos, -8, 4 + step, 2, 2, px, Color("39484e"))
    _draw_px(draw_pos, 6, 5 - step, 2, 2, px, Color("39484e"))

    # High-visibility vest, reflective stripes, zipper and pockets.
    _draw_px(draw_pos, -5, -2, 2, 6, px, safety.darkened(0.24))
    _draw_px(draw_pos, 3, -2, 2, 6, px, safety.darkened(0.24))
    _draw_px(draw_pos, -3, -1, 6, 1, px, safety_high)
    _draw_px(draw_pos, -3, 2, 6, 1, px, safety_high)
    _draw_px(draw_pos, 0, -2, 1, 6, px, Color("0a1115"))
    _draw_px(draw_pos, -4, 3, 2, 2, px, suit_shadow)
    _draw_px(draw_pos, 2, 3, 2, 2, px, suit_shadow)
    _draw_px(draw_pos, -5, 5, 10, 1, px, Color("10171b"))
    _draw_px(draw_pos, -1, 5, 2, 1, px, safety)

    # Neck and head with three-tone skin shading.
    _draw_px(draw_pos, -2, -6, 4, 2, px, WARM_OUTLINE)
    _draw_px(draw_pos, -1, -6, 3, 2, px, skin_shadow)
    _draw_px(draw_pos, -5, -12, 10, 7, px, WARM_OUTLINE)
    _draw_px(draw_pos, -4, -11, 8, 5, px, skin_base)
    _draw_px(draw_pos, -4, -11, 2, 5, px, skin_shadow)
    _draw_px(draw_pos, 2, -10, 2, 3, px, skin_high)

    # Hard hat with brim and top highlight.
    _draw_px(draw_pos, -6, -14, 12, 3, px, WARM_OUTLINE)
    _draw_px(draw_pos, -5, -14, 10, 2, px, safety)
    _draw_px(draw_pos, -3, -15, 6, 1, px, safety_high)
    _draw_px(draw_pos, -7, -12, 14, 1, px, WARM_OUTLINE)
    _draw_px(draw_pos, -6, -12, 12, 1, px, safety.darkened(0.12))

    # Eyes, brow, nose/mouth and the single-eye scanner visor.
    _draw_px(draw_pos, -3, -9, 2, 1, px, Color("251b17"))
    _draw_px(draw_pos, 2, -9, 1, 1, px, Color("251b17"))
    _draw_px(draw_pos, 0, -8, 1, 2, px, skin_high)
    _draw_px(draw_pos, 1, -7, 2, 1, px, skin_shadow)
    var lens_x: int = -4 if scanner == "left" else 1
    _draw_px(draw_pos, lens_x, -10, 3, 2, px, Color("071018"))
    _draw_px(draw_pos, lens_x + 1, -10, 2, 1, px, safety_high)
    _draw_px(draw_pos, -5 if scanner == "left" else 4, -11, 1, 4, px, safety.darkened(0.35))

    # Field tablet and antenna make the mining-tech role obvious.
    var tablet_x: int = 7 if scanner == "left" else -10
    _draw_px(draw_pos, tablet_x, 1, 3, 4, px, WARM_OUTLINE)
    _draw_px(draw_pos, tablet_x + 1, 2, 2, 2, px, Color("163b48"))
    _draw_px(draw_pos, tablet_x + 1, 2, 2, 1, px, WORK_LIGHT)
    _draw_px(draw_pos, -6, -5, 1, 3, px, safety)
    _draw_px(draw_pos, -6, -7, 1, 2, px, WORK_LIGHT)

    if is_player:
        var player_rect := Rect2(draw_pos + Vector2(-55.0, -82.0), Vector2(110.0, 145.0))
        _draw_layered_stroke_rect(player_rect, Color(0.0, 0.0, 0.0, 0.0), Color(accent.r, accent.g, accent.b, 0.72), Color(accent.r, accent.g, accent.b, 0.30), 2.0)

func _draw_pixel_facility(pos: Vector2, size_value: Vector2, accent: Color, floors: int, badge: String) -> void:
    super._draw_pixel_facility(pos, size_value, accent, floors, badge)
    var snapped: Vector2 = VisualStack.snap_to_pixel(pos)
    var left: float = snapped.x - size_value.x * 0.5
    var top: float = snapped.y - size_value.y * 0.62

    # Wall panel seams and bolt heads create readable industrial texture.
    for col in range(1, 6):
        var x: float = left + float(col) * size_value.x / 6.0
        draw_rect(Rect2(x, top + 38.0, 2.0, size_value.y - 48.0), Color("14232b"), true)
    for col in range(5):
        var bolt_x: float = left + 17.0 + float(col) * ((size_value.x - 34.0) / 4.0)
        draw_rect(Rect2(bolt_x, top + size_value.y - 12.0, 3.0, 3.0), STEEL_LIGHT, true)

    # Rooftop cooling units with visible fans.
    for unit in range(3):
        var ux: float = left + 55.0 + float(unit) * ((size_value.x - 110.0) / 2.0)
        var uy: float = top - 3.0
        draw_rect(Rect2(ux - 18.0, uy - 12.0, 36.0, 18.0), WARM_OUTLINE, true)
        draw_rect(Rect2(ux - 15.0, uy - 9.0, 30.0, 12.0), Color("3b4b52"), true)
        draw_circle(Vector2(ux, uy - 3.0), 6.0, Color("0b1115"))
        draw_line(Vector2(ux - 5.0, uy - 3.0), Vector2(ux + 5.0, uy - 3.0), accent, 2.0)
        draw_line(Vector2(ux, uy - 8.0), Vector2(ux, uy + 2.0), accent, 2.0)

    # Side louvers, conduit and hazard marks around the main entrance.
    var louver_x: float = left + size_value.x - 30.0
    for slit in range(5):
        draw_rect(Rect2(louver_x, top + 42.0 + float(slit) * 7.0, 18.0, 3.0), Color("081116"), true)
    draw_rect(Rect2(left + 7.0, top + 40.0, 5.0, size_value.y - 48.0), accent.darkened(0.42), true)
    draw_rect(Rect2(left + 10.0, top + 44.0, 10.0, 4.0), accent, true)
    for stripe in range(4):
        var sx: float = snapped.x - 22.0 + float(stripe) * 11.0
        draw_rect(Rect2(sx, top + size_value.y - 10.0, 7.0, 5.0), HAZARD_YELLOW if stripe % 2 == 0 else HAZARD_ORANGE, true)

    # Small work lights across the facade.
    for lamp in range(3):
        var lx: float = left + 35.0 + float(lamp) * ((size_value.x - 70.0) / 2.0)
        draw_rect(Rect2(lx - 4.0, top + 27.0, 8.0, 4.0), Color("091014"), true)
        draw_rect(Rect2(lx - 2.0, top + 28.0, 4.0, 2.0), WORK_LIGHT, true)

func debug_visual_detail_ready() -> bool:
    return VISUAL_DETAIL_REVISION >= 2 and VISUAL_DETAIL_SOURCE == "MozeeB/pixel-asset-gen"
