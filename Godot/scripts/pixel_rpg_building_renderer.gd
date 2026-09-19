extends RefCounted
class_name HashRacePixelRpgBuildingRenderer

# Pure 2D pixel-building generator for Hash Race.
# The source image is intentionally rendered at half world resolution and then
# enlarged with nearest-neighbor filtering. This keeps every roof slope, trim
# line and window on a real pixel grid instead of drawing large vector boxes.
#
# Design references:
# - Pixelorama (MIT): tile/pixel-first authoring and atlas-minded workflow.
# - PokeSharp (MIT): fixed source sprite regions drawn into fixed destination
#   rectangles; Hash Race applies the same source/destination discipline to
#   generated building sprites.
# No third-party art assets are copied.

const TRANSPARENT := Color(0, 0, 0, 0)
const INK := Color("263238")
const DEEP_INK := Color("172027")
const WALL_LIGHT := Color("d8d1b0")
const WALL_MID := Color("b9ad85")
const WALL_DARK := Color("8f835e")
const GLASS_DARK := Color("555b82")
const GLASS_MID := Color("8188c7")
const GLASS_LIGHT := Color("c0c4ef")
const WOOD_DARK := Color("65452f")
const WOOD_MID := Color("8a5b37")
const METAL_DARK := Color("555f61")
const METAL_MID := Color("87918f")
const METAL_LIGHT := Color("cbd0c8")
const GREEN_DARK := Color("2c6838")
const GREEN_MID := Color("4f9846")
const GREEN_LIGHT := Color("86c95d")
const FLOWER_YELLOW := Color("f2d45b")
const FLOWER_PINK := Color("e77a9a")

func create_texture(style: String, accent: Color, source_size: Vector2i) -> ImageTexture:
    var w := maxi(72, source_size.x)
    var h := maxi(64, source_size.y)
    var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
    img.fill(TRANSPARENT)

    var palette := _palette(style, accent)
    _draw_ground_shadow(img, w, h)
    _draw_facade(img, w, h, palette)
    _draw_roof(img, w, h, palette, style)
    _draw_front_gable(img, w, h, palette, style)
    _draw_windows(img, w, h, palette, style)
    _draw_door(img, w, h, palette, style)
    _draw_style_details(img, w, h, palette, style)
    _draw_landscaping(img, w, h, palette, style)
    return ImageTexture.create_from_image(img)

func _palette(style: String, accent: Color) -> Dictionary:
    var roof := accent.darkened(0.18)
    var wall := WALL_MID
    var wall_light := WALL_LIGHT
    var wall_dark := WALL_DARK
    var trim := Color("efe6c6")
    match style:
        "hq":
            wall = Color("b9b58d")
            wall_light = Color("d9d7ad")
            wall_dark = Color("817b59")
        "partner":
            wall = Color("c4b58e")
            wall_light = Color("ddd1ae")
            wall_dark = Color("8d7b58")
        "machines":
            wall = Color("9da8a4")
            wall_light = Color("c5cfca")
            wall_dark = Color("67736f")
            roof = accent.darkened(0.34)
        "power":
            wall = Color("aeb4a5")
            wall_light = Color("d5d9ca")
            wall_dark = Color("727a6e")
            roof = Color("6d786e")
        "bank":
            wall = Color("c6b98d")
            wall_light = Color("e2d8b4")
            wall_dark = Color("8e805a")
            roof = accent.darkened(0.28)
        "land":
            wall = Color("a9ba8c")
            wall_light = Color("d1d9ad")
            wall_dark = Color("71805b")
            roof = Color("4f8754")
        _:
            pass
    return {
        "roof": roof,
        "roof_dark": roof.darkened(0.30),
        "roof_light": roof.lightened(0.16),
        "wall": wall,
        "wall_light": wall_light,
        "wall_dark": wall_dark,
        "trim": trim,
        "accent": accent,
    }

func _draw_ground_shadow(img: Image, w: int, h: int) -> void:
    var y0 := h - 12
    for y in range(y0, h - 4):
        var inset := 6 + absi(y - (y0 + 3))
        _rect(img, inset + 6, y, w - (inset + 6) * 2, 1, Color(0.08, 0.12, 0.12, 0.34))

func _draw_facade(img: Image, w: int, h: int, p: Dictionary) -> void:
    var body_left := 8
    var body_right := w - 9
    var body_top := int(round(float(h) * 0.48))
    var body_bottom := h - 9

    _rect(img, body_left - 2, body_top - 2, body_right - body_left + 5, body_bottom - body_top + 4, INK)
    _rect(img, body_left, body_top, body_right - body_left + 1, body_bottom - body_top + 1, p["wall"])

    # One consistent top-left light source.
    _rect(img, body_left, body_top, 3, body_bottom - body_top + 1, p["wall_light"])
    _rect(img, body_right - 2, body_top, 3, body_bottom - body_top + 1, p["wall_dark"])

    # Horizontal siding is low contrast and regularly spaced, like authored
    # pixel sprites rather than procedural noise.
    for y in range(body_top + 7, body_bottom - 2, 7):
        _rect(img, body_left + 4, y, body_right - body_left - 7, 1, p["wall_dark"].lightened(0.12))
        if y + 1 < body_bottom:
            _rect(img, body_left + 5, y + 1, body_right - body_left - 9, 1, p["wall_light"].darkened(0.10))

    # Foundation strip visually locks the sprite into the terrain.
    _rect(img, body_left, body_bottom - 4, body_right - body_left + 1, 5, p["wall_dark"].darkened(0.18))
    _rect(img, body_left + 3, body_bottom - 4, body_right - body_left - 5, 2, p["wall_light"].darkened(0.18))

func _draw_roof(img: Image, w: int, h: int, p: Dictionary, style: String) -> void:
    var roof_top := 5
    var eave_y := int(round(float(h) * 0.52))
    var cx := int(w / 2)
    var ridge_half := maxi(7, int(round(float(w) * 0.11)))
    var eave_half := int(round(float(w) * 0.49))

    # Hipped/gabled roof: every row expands by integer pixels toward the eave.
    # This is the key 3/4 sprite silhouette missing from the old rectangle roof.
    for y in range(roof_top, eave_y + 1):
        var t := float(y - roof_top) / maxf(1.0, float(eave_y - roof_top))
        var half_w := int(round(lerpf(float(ridge_half), float(eave_half), t)))
        var left := cx - half_w
        var right := cx + half_w
        var roof_color: Color = p["roof"]
        if left < cx - 3:
            roof_color = p["roof_light"] if y % 7 < 4 else p["roof"]
        _rect(img, left, y, right - left + 1, 1, roof_color)
        _safe_pixel(img, left, y, INK)
        _safe_pixel(img, right, y, INK)
        if left + 1 < w:
            _safe_pixel(img, left + 1, y, p["roof_dark"])
        if right - 1 >= 0:
            _safe_pixel(img, right - 1, y, p["roof_dark"])

    # Ridge and chunky roof banding. Hard pixels only.
    _rect(img, cx - ridge_half, roof_top, ridge_half * 2 + 1, 2, INK)
    _rect(img, cx - ridge_half + 2, roof_top + 2, ridge_half * 2 - 3, 2, p["roof_light"])
    for y in range(roof_top + 10, eave_y - 2, 10):
        var t := float(y - roof_top) / maxf(1.0, float(eave_y - roof_top))
        var half_w := int(round(lerpf(float(ridge_half), float(eave_half), t)))
        _rect(img, cx - half_w + 3, y, half_w * 2 - 5, 2, p["roof_dark"].lightened(0.06))

    # Deep eave separates roof from facade.
    _rect(img, 4, eave_y - 1, w - 8, 4, INK)
    _rect(img, 7, eave_y - 1, w - 14, 2, p["roof_dark"])

    # Roof skylights / vents by building type.
    if style in ["hq", "partner", "land"]:
        _roof_window(img, int(w * 0.28), int(h * 0.25))
        _roof_window(img, int(w * 0.64), int(h * 0.25))
    elif style in ["machines", "power"]:
        _roof_vent(img, int(w * 0.30), int(h * 0.25))
        _roof_vent(img, int(w * 0.62), int(h * 0.23))

func _draw_front_gable(img: Image, w: int, h: int, p: Dictionary, style: String) -> void:
    if style in ["machines", "power"]:
        return
    var base_y := int(round(float(h) * 0.58))
    var peak_y := int(round(float(h) * 0.37))
    var cx := int(w / 2)
    var half := int(round(float(w) * 0.24))

    # Dark outline then wall triangle.
    _triangle(img, Vector2i(cx, peak_y - 2), Vector2i(cx - half - 2, base_y + 2), Vector2i(cx + half + 2, base_y + 2), INK)
    _triangle(img, Vector2i(cx, peak_y + 1), Vector2i(cx - half, base_y), Vector2i(cx + half, base_y), p["wall"])
    for y in range(peak_y + 7, base_y - 2, 6):
        var t := float(y - peak_y) / maxf(1.0, float(base_y - peak_y))
        var span := int(round(float(half) * t))
        _rect(img, cx - span + 3, y, maxi(1, span * 2 - 5), 1, p["wall_dark"].lightened(0.12))

    var aw := 18
    var ay := peak_y + 9
    _window(img, cx - int(aw / 2), ay, aw, 9, p)

func _draw_windows(img: Image, w: int, h: int, p: Dictionary, style: String) -> void:
    var y := int(round(float(h) * 0.66))
    var ww := maxi(14, int(round(float(w) * 0.14)))
    var wh := maxi(9, int(round(float(h) * 0.10)))

    if style == "machines":
        for i in range(4):
            var x := 14 + i * int((w - 28) / 4.0)
            _window(img, x, y, ww - 2, wh, p)
    else:
        _window(img, 16, y, ww, wh, p)
        _window(img, w - 16 - ww, y, ww, wh, p)

func _draw_door(img: Image, w: int, h: int, p: Dictionary, style: String) -> void:
    var dw := maxi(13, int(round(float(w) * 0.14)))
    var dh := maxi(20, int(round(float(h) * 0.25)))
    var x := int(w / 2) - int(dw / 2)
    var y := h - 9 - dh

    _rect(img, x - 2, y - 2, dw + 4, dh + 3, INK)
    var door_color := WOOD_MID if style in ["hq", "partner", "bank", "land"] else p["roof_dark"]
    _rect(img, x, y, dw, dh, door_color)
    _rect(img, x + 2, y + 2, 3, dh - 4, door_color.lightened(0.18))
    _rect(img, x + dw - 5, y + int(dh * 0.52), 2, 2, p["trim"])

    # Small accent awning gives the entrance a clear gameplay target.
    _rect(img, x - 5, y - 7, dw + 10, 3, INK)
    _rect(img, x - 3, y - 6, dw + 6, 4, p["accent"].darkened(0.18))

func _draw_style_details(img: Image, w: int, h: int, p: Dictionary, style: String) -> void:
    if style == "machines":
        # Rooftop HVAC and front intake rhythm.
        for i in range(3):
            var x := 20 + i * int((w - 40) / 3.0)
            _roof_vent(img, x, int(h * 0.37))
        for i in range(5):
            var x := 10 + i * int((w - 20) / 5.0)
            _rect(img, x, h - 30, 12, 5, INK)
            _rect(img, x + 2, h - 28, 8, 2, p["accent"].darkened(0.15))
    elif style == "power":
        # Compact substation cue: transformer cans and insulators on the roof.
        for i in range(3):
            var x := int(w * (0.27 + 0.23 * i))
            _rect(img, x - 5, int(h * 0.36), 10, 10, METAL_DARK)
            _rect(img, x - 3, int(h * 0.36) + 2, 6, 6, METAL_MID)
            _rect(img, x - 1, int(h * 0.36) - 8, 3, 8, Color("d9ddd0"))
            _rect(img, x - 3, int(h * 0.36) - 6, 7, 2, INK)
    elif style == "bank":
        for i in range(4):
            var x := 15 + i * int((w - 30) / 4.0)
            _rect(img, x, h - 37, 5, 25, p["wall_dark"])
            _rect(img, x + 1, h - 36, 2, 23, p["wall_light"])
    elif style == "land":
        # Greenhouse-style side bay.
        _rect(img, w - 34, h - 43, 22, 25, INK)
        _rect(img, w - 32, h - 41, 18, 21, Color("77aab2"))
        for i in range(1, 3):
            _rect(img, w - 32 + i * 6, h - 40, 1, 19, Color("c9e1d7"))
    else:
        # Small chimney / service stack.
        _rect(img, 18, int(h * 0.27), 9, 23, INK)
        _rect(img, 20, int(h * 0.27) + 2, 5, 19, WOOD_DARK)
        _rect(img, 17, int(h * 0.27) - 2, 11, 4, INK)
        _rect(img, 19, int(h * 0.27) - 1, 7, 2, WOOD_MID)

func _draw_landscaping(img: Image, w: int, h: int, p: Dictionary, style: String) -> void:
    if style in ["machines", "power"]:
        return
    var y := h - 16
    # Two small bushes and flower pixels soften the building-ground seam.
    _bush(img, 8, y - 4)
    _bush(img, w - 18, y - 4)
    if style in ["hq", "partner", "land"]:
        for i in range(4):
            var x := 20 + i * 6
            _safe_pixel(img, x, h - 13, FLOWER_PINK if i % 2 == 0 else FLOWER_YELLOW)
            _safe_pixel(img, x, h - 12, GREEN_DARK)

func _roof_window(img: Image, x: int, y: int) -> void:
    _rect(img, x - 8, y - 5, 18, 12, INK)
    _rect(img, x - 6, y - 3, 14, 8, GLASS_MID)
    _rect(img, x - 4, y - 2, 4, 3, GLASS_LIGHT)
    _rect(img, x + 1, y - 2, 5, 3, GLASS_DARK)

func _roof_vent(img: Image, x: int, y: int) -> void:
    _rect(img, x - 7, y - 5, 16, 12, INK)
    _rect(img, x - 5, y - 3, 12, 8, METAL_MID)
    _rect(img, x - 3, y - 1, 8, 2, METAL_LIGHT)
    _rect(img, x - 3, y + 2, 8, 2, METAL_DARK)

func _window(img: Image, x: int, y: int, w: int, h: int, p: Dictionary) -> void:
    _rect(img, x - 2, y - 2, w + 4, h + 4, INK)
    _rect(img, x, y, w, h, GLASS_MID)
    _rect(img, x + 2, y + 2, maxi(2, int(w * 0.35)), maxi(2, int(h * 0.28)), GLASS_LIGHT)
    _rect(img, x + int(w / 2), y, 1, h, GLASS_DARK)
    _rect(img, x, y + int(h / 2), w, 1, GLASS_DARK)
    _rect(img, x - 1, y + h + 1, w + 2, 2, p["trim"].darkened(0.12))

func _bush(img: Image, x: int, y: int) -> void:
    _rect(img, x + 3, y + 8, 8, 4, GREEN_DARK)
    _rect(img, x + 1, y + 4, 12, 6, GREEN_MID)
    _rect(img, x + 4, y + 1, 7, 6, GREEN_LIGHT)
    _safe_pixel(img, x + 5, y + 2, Color("b0e27b"))

func _triangle(img: Image, a: Vector2i, b: Vector2i, c: Vector2i, color: Color) -> void:
    var min_y := maxi(0, mini(a.y, mini(b.y, c.y)))
    var max_y := mini(img.get_height() - 1, maxi(a.y, maxi(b.y, c.y)))
    for y in range(min_y, max_y + 1):
        var xs: Array[float] = []
        _edge_intersection_y(a, b, y, xs)
        _edge_intersection_y(b, c, y, xs)
        _edge_intersection_y(c, a, y, xs)
        if xs.size() < 2:
            continue
        xs.sort()
        var left := maxi(0, int(ceil(xs[0])))
        var right := mini(img.get_width() - 1, int(floor(xs[xs.size() - 1])))
        for x in range(left, right + 1):
            img.set_pixel(x, y, color)

func _edge_intersection_y(a: Vector2i, b: Vector2i, y: int, xs: Array[float]) -> void:
    if a.y == b.y:
        if y == a.y:
            xs.append(float(a.x))
            xs.append(float(b.x))
        return
    var ymin := mini(a.y, b.y)
    var ymax := maxi(a.y, b.y)
    if y < ymin or y > ymax:
        return
    var t := float(y - a.y) / float(b.y - a.y)
    xs.append(lerpf(float(a.x), float(b.x), t))

func _rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
    if w <= 0 or h <= 0:
        return
    var x0 := maxi(0, x)
    var y0 := maxi(0, y)
    var x1 := mini(img.get_width(), x + w)
    var y1 := mini(img.get_height(), y + h)
    for py in range(y0, y1):
        for px in range(x0, x1):
            img.set_pixel(px, py, color)

func _safe_pixel(img: Image, x: int, y: int, color: Color) -> void:
    if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
        img.set_pixel(x, y, color)
