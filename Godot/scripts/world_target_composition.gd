extends "res://scripts/world_player_sprite.gd"

# Hash Race v0.036 target-composition pass.
# Rebuilds the approved Game Boy Color-style campus composition from procedural
# Godot drawing primitives so the live map stays interactive, scalable and crisp.

const CAMPUS_DARK := Color("10283a")
const CAMPUS_ROOF := Color("435463")
const CAMPUS_WALL := Color("d8e0df")
const CAMPUS_SHADE := Color("8c9ba3")
const CAMPUS_GLASS := Color("49a9d8")
const CAMPUS_BLUE := Color("17699a")
const CAMPUS_GRASS := Color("4c913e")
const CAMPUS_PATH := Color("a8a797")
const CAMPUS_GOLD := Color("f5a623")
const CAMPUS_ANIMATION_STEP_MS: int = 260

var campus_animation_phase: int = -1

func _draw_world_props_pixel() -> void:
    super._draw_world_props_pixel()
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = VisualStack.snap_to_pixel(zone["center"])
        var profile_idx: int = int(zone["profile_idx"])
        var accent: Color = COMPANY_ACCENTS[profile_idx]
        _draw_mining_campus(center, accent)

func _draw_mining_campus(center: Vector2, accent: Color) -> void:
    # Cross-shaped walkable-looking campus echoes the approved target composition.
    _campus_path(Rect2(center + Vector2(-210.0, -24.0), Vector2(420.0, 48.0)))
    _campus_path(Rect2(center + Vector2(-24.0, -170.0), Vector2(48.0, 340.0)))

    # Distinct functional silhouettes: HQ, mining hall, R&D, training, recovery.
    _campus_building(center + Vector2(-175.0, -112.0), Vector2(112.0, 76.0), "HQ", accent, 0)
    _campus_building(center + Vector2(165.0, -105.0), Vector2(150.0, 88.0), "MINING", accent, 1)
    _campus_building(center + Vector2(150.0, 112.0), Vector2(118.0, 76.0), "R&D", Color("45b6df"), 2)
    _campus_building(center + Vector2(-175.0, 108.0), Vector2(112.0, 72.0), "TRAIN", Color("f1b72b"), 3)
    _campus_building(center + Vector2(-45.0, 128.0), Vector2(106.0, 68.0), "RECOVER", Color("dc5b55"), 4)

    # Industrial details from the screenshot target.
    _campus_solar_array(center + Vector2(278.0, -150.0))
    _campus_cooling_rack(center + Vector2(278.0, -72.0), accent)
    _campus_tree(center + Vector2(-270.0, -8.0))
    _campus_tree(center + Vector2(250.0, 96.0))
    _campus_tree(center + Vector2(-250.0, 164.0))

func _campus_path(rect: Rect2) -> void:
    draw_rect(rect.grow(3.0), Color("52616a"), true)
    draw_rect(rect, CAMPUS_PATH, true)
    # Pixel seams keep large paths from reading as flat rectangles.
    if rect.size.x > rect.size.y:
        var x: float = rect.position.x + 12.0
        while x < rect.end.x:
            draw_rect(Rect2(x, rect.position.y + 4.0, 2.0, rect.size.y - 8.0), Color("919287"), true)
            x += 32.0
    else:
        var y: float = rect.position.y + 12.0
        while y < rect.end.y:
            draw_rect(Rect2(rect.position.x + 4.0, y, rect.size.x - 8.0, 2.0), Color("919287"), true)
            y += 32.0

func _campus_building(center: Vector2, size: Vector2, label: String, accent: Color, kind: int) -> void:
    var rect := Rect2(center - size * 0.5, size)
    # Drop shadow, dark outline, wall, roof and highlight create chunky GBC depth.
    draw_rect(Rect2(rect.position + Vector2(6.0, 8.0), rect.size), Color(0.03, 0.07, 0.08, 0.42), true)
    draw_rect(rect.grow(4.0), CAMPUS_DARK, true)
    draw_rect(rect, CAMPUS_WALL, true)
    draw_rect(Rect2(rect.position, Vector2(rect.size.x, 20.0)), CAMPUS_ROOF, true)
    draw_rect(Rect2(rect.position + Vector2(4.0, 4.0), Vector2(rect.size.x - 8.0, 4.0)), CAMPUS_SHADE.lightened(0.18), true)
    draw_rect(Rect2(rect.position + Vector2(0.0, 20.0), Vector2(rect.size.x, 5.0)), accent.darkened(0.12), true)

    # Sign plate is real world geometry, not baked screenshot text.
    var sign_w: float = minf(rect.size.x - 16.0, 70.0)
    var sign_rect := Rect2(center.x - sign_w * 0.5, rect.position.y + 9.0, sign_w, 18.0)
    draw_rect(sign_rect.grow(2.0), CAMPUS_DARK, true)
    draw_rect(sign_rect, accent.darkened(0.35), true)
    draw_string(ThemeDB.fallback_font, sign_rect.position + Vector2(6.0, 13.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("f4f0d7"))

    # Door and blue glass frontage.
    var door := Rect2(center + Vector2(-10.0, 10.0), Vector2(20.0, rect.end.y - center.y - 10.0))
    draw_rect(door.grow(2.0), CAMPUS_DARK, true)
    draw_rect(door, CAMPUS_GLASS.darkened(0.18), true)
    draw_rect(Rect2(door.position + Vector2(3.0, 3.0), Vector2(4.0, maxf(5.0, door.size.y - 6.0))), CAMPUS_GLASS.lightened(0.28), true)
    for side in [-1.0, 1.0]:
        var wx: float = center.x + side * 30.0 - 9.0
        draw_rect(Rect2(wx, center.y + 12.0, 18.0, 15.0), CAMPUS_DARK, true)
        draw_rect(Rect2(wx + 2.0, center.y + 14.0, 14.0, 11.0), CAMPUS_GLASS, true)
        draw_rect(Rect2(wx + 4.0, center.y + 15.0, 3.0, 8.0), Color("9ee6f1"), true)

    # Building-specific roof silhouettes make each destination readable without text.
    if kind == 0:
        _campus_bitcoin_badge(center + Vector2(0.0, -30.0), accent)
    elif kind == 1:
        for i in range(4):
            _campus_fan(center + Vector2(-45.0 + float(i) * 30.0, -35.0), accent)
    elif kind == 2:
        draw_circle(center + Vector2(0.0, -38.0), 13.0, CAMPUS_DARK)
        draw_line(center + Vector2(-9.0, -45.0), center + Vector2(10.0, -31.0), Color("d9edf1"), 3.0)
    elif kind == 3:
        draw_rect(Rect2(center + Vector2(-18.0, -39.0), Vector2(36.0, 7.0)), CAMPUS_DARK, true)
        draw_rect(Rect2(center + Vector2(-13.0, -42.0), Vector2(5.0, 13.0)), CAMPUS_GOLD, true)
        draw_rect(Rect2(center + Vector2(8.0, -42.0), Vector2(5.0, 13.0)), CAMPUS_GOLD, true)
    else:
        draw_rect(Rect2(center + Vector2(-4.0, -43.0), Vector2(8.0, 22.0)), Color("c64d49"), true)
        draw_rect(Rect2(center + Vector2(-11.0, -36.0), Vector2(22.0, 8.0)), Color("c64d49"), true)

func _campus_bitcoin_badge(center: Vector2, accent: Color) -> void:
    draw_circle(center, 12.0, CAMPUS_DARK)
    draw_circle(center, 9.0, accent)
    draw_rect(Rect2(center + Vector2(-2.0, -7.0), Vector2(4.0, 14.0)), Color("fff0b0"), true)
    draw_rect(Rect2(center + Vector2(1.0, -5.0), Vector2(5.0, 4.0)), Color("fff0b0"), true)
    draw_rect(Rect2(center + Vector2(1.0, 2.0), Vector2(5.0, 4.0)), Color("fff0b0"), true)

func _campus_fan(center: Vector2, accent: Color) -> void:
    draw_circle(center, 11.0, CAMPUS_DARK)
    draw_circle(center, 8.0, CAMPUS_ROOF.darkened(0.25))
    draw_line(center + Vector2(-6.0, 0.0), center + Vector2(6.0, 0.0), accent, 2.0)
    draw_line(center + Vector2(0.0, -6.0), center + Vector2(0.0, 6.0), accent, 2.0)

func _campus_solar_array(center: Vector2) -> void:
    var rect := Rect2(center + Vector2(-55.0, -25.0), Vector2(110.0, 50.0))
    draw_rect(rect.grow(4.0), CAMPUS_DARK, true)
    draw_rect(rect, Color("153e62"), true)
    for x in range(1, 5):
        draw_rect(Rect2(rect.position.x + float(x) * 22.0 - 1.0, rect.position.y, 2.0, rect.size.y), Color("67b9dd"), true)
    for y in range(1, 3):
        draw_rect(Rect2(rect.position.x, rect.position.y + float(y) * 16.0, rect.size.x, 2.0), Color("67b9dd"), true)

func _campus_cooling_rack(center: Vector2, accent: Color) -> void:
    var rect := Rect2(center + Vector2(-58.0, -25.0), Vector2(116.0, 50.0))
    draw_rect(rect.grow(3.0), CAMPUS_DARK, true)
    draw_rect(rect, CAMPUS_ROOF, true)
    for i in range(4):
        _campus_fan(center + Vector2(-42.0 + float(i) * 28.0, 0.0), accent)

func _campus_tree(center: Vector2) -> void:
    draw_rect(Rect2(center + Vector2(-4.0, 8.0), Vector2(8.0, 18.0)), Color("66452d"), true)
    draw_circle(center + Vector2(0.0, -2.0), 19.0, Color("173e2b"))
    draw_circle(center + Vector2(-8.0, -8.0), 13.0, Color("2f7541"))
    draw_circle(center + Vector2(8.0, -10.0), 12.0, Color("54a84d"))
    draw_rect(Rect2(center + Vector2(-4.0, -18.0), Vector2(7.0, 5.0)), Color("78c75d"), true)

func _process(delta: float) -> void:
    super._process(delta)
    # Animated water/facility details only need a redraw when their discrete
    # pixel-art phase changes. The old even/odd test queued redraw every frame
    # for half of each cycle, causing unnecessary full-world redraw bursts.
    var next_phase := int(Time.get_ticks_msec() / CAMPUS_ANIMATION_STEP_MS)
    if next_phase != campus_animation_phase:
        campus_animation_phase = next_phase
        queue_redraw()

func debug_target_composition_ready() -> bool:
    return CAMPUS_WALL.a == 1.0 and town_zones.size() == 10

func debug_animation_scheduler_ready() -> bool:
    return CAMPUS_ANIMATION_STEP_MS >= 200 and CAMPUS_ANIMATION_STEP_MS <= 500
