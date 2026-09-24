extends RefCounted
class_name HashRaceProceduralBuildingRenderer

# Hash Race v0.055 procedural building renderer.
# Creates crisp 96x128 RGBA facade textures in code. The design adapts the
# supplied create_building_image() approach: masonry courses, pitched/flat
# roofs, foundations, framed windows, doors, vents and per-building accents.

const WIDTH: int = 96
const HEIGHT: int = 128

static func create_building_texture(accent: Color, style: String, seed: int = 0) -> ImageTexture:
    return ImageTexture.create_from_image(create_building_image(accent, style, seed))

static func create_building_image(accent: Color = Color("39ff75"), style: String = "hq", seed: int = 0) -> Image:
    var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
    img.fill(Color(0.0, 0.0, 0.0, 0.0))

    var palette: Dictionary = _palette_for(style, accent)
    _draw_ground_shadow(img)
    _draw_foundation(img, palette["foundation"], palette["foundation_dark"])
    _draw_wall(img, style, palette["wall"], palette["wall_dark"], palette["mortar"])
    _draw_roof(img, style, palette["roof"], palette["roof_high"], accent, seed)
    _draw_door(img, style, palette["door"], palette["frame"], accent)
    _draw_windows_or_intakes(img, style, palette["glass"], palette["frame"], accent, seed)
    _draw_style_details(img, style, accent, palette["frame"], seed)
    return img

static func _palette_for(style: String, accent: Color) -> Dictionary:
    var palette := {
        "wall": Color("8d4e32"),
        "wall_dark": Color("6f3628"),
        "mortar": Color("b8a487"),
        "roof": Color("30383d"),
        "roof_high": Color("59656b"),
        "frame": Color("1c252a"),
        "glass": Color("65bdd2"),
        "foundation": Color("6e777b"),
        "foundation_dark": Color("4e565a"),
        "door": Color("4f3424")
    }
    match style:
        "partner":
            palette["wall"] = accent.darkened(0.50)
            palette["wall_dark"] = accent.darkened(0.68)
            palette["mortar"] = Color("76858b")
            palette["roof"] = Color("263239")
            palette["roof_high"] = Color("5f717a")
            palette["glass"] = Color("7ed6e7")
            palette["door"] = Color("263239")
        "machine":
            palette["wall"] = Color("314047")
            palette["wall_dark"] = Color("1b282e")
            palette["mortar"] = Color("617078")
            palette["roof"] = Color("141f24")
            palette["roof_high"] = Color("4f6068")
            palette["glass"] = Color("39ff75")
            palette["door"] = Color("11191d")
        "power":
            palette["wall"] = Color("59636a")
            palette["wall_dark"] = Color("353f45")
            palette["mortar"] = Color("7f8d93")
            palette["roof"] = Color("202a2f")
            palette["roof_high"] = Color("66757c")
            palette["glass"] = Color("ffd36e")
            palette["door"] = Color("242e33")
        "bank":
            palette["wall"] = Color("8d877d")
            palette["wall_dark"] = Color("68635d")
            palette["mortar"] = Color("b9b1a4")
            palette["roof"] = Color("3a4146")
            palette["roof_high"] = Color("6a7479")
            palette["glass"] = Color("a4d6df")
            palette["door"] = Color("4c3524")
        "land":
            palette["wall"] = Color("7d684c")
            palette["wall_dark"] = Color("5d4b37")
            palette["mortar"] = Color("b6a88d")
            palette["roof"] = Color("314437")
            palette["roof_high"] = Color("5d7d63")
            palette["glass"] = Color("86c7cf")
            palette["door"] = Color("4b3c2c")
        _:
            pass
    return palette

static func _draw_ground_shadow(img: Image) -> void:
    var shadow := Color(0.09, 0.13, 0.15, 0.55)
    for y in range(118, 124):
        var inset: int = (y - 118) * 3
        for x in range(7 + inset, 89 - inset):
            if (x + y) % 2 == 0:
                img.set_pixel(x, y, shadow)

static func _draw_foundation(img: Image, base: Color, dark: Color) -> void:
    for y in range(108, 120):
        for x in range(8, 88):
            img.set_pixel(x, y, base if (x + y) % 3 != 0 else dark)
    for y in range(105, 109):
        for x in range(34, 62):
            img.set_pixel(x, y, base.lightened(0.10))

static func _draw_wall(img: Image, style: String, wall: Color, wall_dark: Color, mortar: Color) -> void:
    var masonry: bool = style in ["hq", "bank", "land"]
    for y in range(40, 110):
        for x in range(12, 84):
            if masonry:
                var row: int = int((y - 40) / 6)
                var offset: int = 4 if row % 2 == 1 else 0
                var is_mortar_y: bool = (y - 40) % 6 == 0
                var is_mortar_x: bool = (x - 12 + offset) % 8 == 0
                if is_mortar_x or is_mortar_y:
                    img.set_pixel(x, y, mortar)
                else:
                    var brick_cell: int = int((x - 12 + offset) / 8) + row
                    img.set_pixel(x, y, wall if brick_cell % 2 == 0 else wall_dark)
            else:
                var panel_line: bool = ((x - 12) % 12 == 0) or ((y - 40) % 10 == 0)
                var fill_color: Color = wall if (x + y) % 5 != 0 else wall_dark
                img.set_pixel(x, y, mortar.darkened(0.30) if panel_line else fill_color)

static func _draw_roof(img: Image, style: String, roof: Color, roof_high: Color, accent: Color, seed: int) -> void:
    if style in ["hq", "bank", "land"]:
        for y in range(10, 43):
            var half_width: int = mini(44, maxi(2, int(float(y - 8) * 1.45)))
            var left: int = maxi(3, 48 - half_width)
            var right: int = mini(92, 48 + half_width)
            for x in range(left, right + 1):
                img.set_pixel(x, y, roof_high if (x + y + seed) % 5 == 0 else roof)
        for x in range(4, 92):
            img.set_pixel(x, 42, roof_high)
            if x % 2 == 0:
                img.set_pixel(x, 43, Color("20292e"))
        if style == "hq":
            for y in range(9, 29):
                for x in range(68, 77):
                    img.set_pixel(x, y, Color("4a5257"))
            for x in range(66, 79):
                img.set_pixel(x, 8, Color("252d31"))
                img.set_pixel(x, 9, Color("252d31"))
    else:
        for y in range(27, 43):
            for x in range(7, 89):
                img.set_pixel(x, y, roof_high if (x + y + seed) % 7 == 0 else roof)
        for x in range(5, 91):
            img.set_pixel(x, 27, Color("151e22"))
            img.set_pixel(x, 42, accent.darkened(0.18))
        for unit in range(3):
            var ux: int = 19 + unit * 24
            for y in range(19, 28):
                for x in range(ux, ux + 12):
                    img.set_pixel(x, y, Color("47565d"))
            for x in range(ux + 2, ux + 10):
                img.set_pixel(x, 20, Color("7d8d94"))

static func _draw_door(img: Image, style: String, door: Color, frame: Color, accent: Color) -> void:
    var left: int = 39
    var right: int = 57
    if style == "machine":
        left = 32
        right = 64
    for y in range(78, 110):
        for x in range(left + 1, right):
            img.set_pixel(x, y, door)
    for y in range(76, 110):
        img.set_pixel(left, y, frame)
        img.set_pixel(right, y, frame)
    for x in range(left, right + 1):
        img.set_pixel(x, 76, frame)
    if style == "machine":
        for y in range(82, 107, 5):
            for x in range(left + 3, right - 2):
                img.set_pixel(x, y, Color("5c6b72"))
        for x in range(left + 4, left + 10):
            img.set_pixel(x, 79, accent)
    else:
        img.set_pixel(right - 4, 94, Color("151a1d"))
        img.set_pixel(right - 3, 94, Color("151a1d"))
        img.set_pixel(right - 4, 95, Color("151a1d"))
        for x in range(left + 3, right - 2):
            img.set_pixel(x, 80, accent.darkened(0.12))

static func _draw_windows_or_intakes(img: Image, style: String, glass: Color, frame: Color, accent: Color, seed: int) -> void:
    if style == "power":
        for cabinet in range(3):
            var cx: int = 17 + cabinet * 23
            for y in range(66, 99):
                for x in range(cx, cx + 16):
                    img.set_pixel(x, y, Color("26343a"))
            for x in range(cx, cx + 16):
                img.set_pixel(x, 66, frame)
                img.set_pixel(x, 98, frame)
            for y in range(66, 99):
                img.set_pixel(cx, y, frame)
                img.set_pixel(cx + 15, y, frame)
            for slit in range(4):
                var sy: int = 72 + slit * 5
                for x in range(cx + 3, cx + 13):
                    img.set_pixel(x, sy, Color("10191d"))
            img.set_pixel(cx + 7, 69, accent)
            img.set_pixel(cx + 8, 69, accent)
        return

    if style == "machine":
        for box_x in [17, 65]:
            for y in range(49, 69):
                for x in range(box_x, box_x + 14):
                    img.set_pixel(x, y, frame)
            for y in range(52, 67, 4):
                for x in range(box_x + 2, box_x + 12):
                    img.set_pixel(x, y, Color("46585f"))
            img.set_pixel(box_x + 3, 50, accent)
        return

    var windows: Array[Dictionary] = [
        {"x": 18, "y": 70, "w": 16, "h": 18},
        {"x": 62, "y": 70, "w": 16, "h": 18},
        {"x": 18, "y": 48, "w": 16, "h": 16},
        {"x": 62, "y": 48, "w": 16, "h": 16}
    ]
    if style == "hq":
        windows.append({"x": 41, "y": 29, "w": 14, "h": 10})

    for win in windows:
        var wx: int = int(win["x"])
        var wy: int = int(win["y"])
        var ww: int = int(win["w"])
        var wh: int = int(win["h"])
        for y in range(wy, wy + wh):
            for x in range(wx, wx + ww):
                img.set_pixel(x, y, frame)
        for y in range(wy + 2, wy + wh - 2):
            for x in range(wx + 2, wx + ww - 2):
                img.set_pixel(x, y, glass.lightened(0.20) if (x + y + seed) % 11 == 0 else glass)
        var mid_x: int = wx + int(ww / 2)
        var mid_y: int = wy + int(wh / 2)
        for y in range(wy + 2, wy + wh - 2):
            img.set_pixel(mid_x, y, frame)
        for x in range(wx + 2, wx + ww - 2):
            img.set_pixel(x, mid_y, frame)

static func _draw_style_details(img: Image, style: String, accent: Color, frame: Color, seed: int) -> void:
    match style:
        "hq":
            for box_x in [18, 62]:
                for y in range(88, 92):
                    for x in range(box_x, box_x + 16):
                        img.set_pixel(x, y, Color("5d412a"))
                for i in range(4):
                    img.set_pixel(box_x + 3 + i * 3, 87, accent.darkened(0.35))
                    img.set_pixel(box_x + 4 + i * 3, 86, accent)
        "partner":
            for y in range(47, 105):
                img.set_pixel(16, y, accent)
                img.set_pixel(17, y, accent.darkened(0.22))
            for x in range(22, 74):
                img.set_pixel(x, 47, accent.darkened(0.05))
        "machine":
            for rack in range(4):
                var rx: int = 14 + rack * 19
                for y in range(102, 107):
                    for x in range(rx, rx + 13):
                        img.set_pixel(x, y, Color("10181c"))
                img.set_pixel(rx + 2, 103, accent)
                img.set_pixel(rx + 3, 103, accent)
        "power":
            for x in range(13, 84, 8):
                var stripe_on: bool = (int((x + seed) / 8) % 2) == 0
                img.set_pixel(x, 103, accent if stripe_on else frame)
                img.set_pixel(x + 1, 103, accent if stripe_on else frame)
        "bank":
            for column_x in [19, 31, 65, 77]:
                for y in range(61, 109):
                    img.set_pixel(column_x, y, Color("d0c7b7"))
                    img.set_pixel(column_x + 1, y, Color("908a81"))
            for x in range(14, 83):
                img.set_pixel(x, 58, accent.darkened(0.30))
                img.set_pixel(x, 59, accent.darkened(0.45))
        "land":
            for x in range(14, 83, 7):
                img.set_pixel(x, 104, accent.darkened(0.12))
                if x + 1 < 84:
                    img.set_pixel(x + 1, 103, accent.lightened(0.10))
        _:
            pass
