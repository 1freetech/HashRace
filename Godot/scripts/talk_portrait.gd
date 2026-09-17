extends Control
class_name HashRaceTalkPortrait

# Large procedural 16-bit-style conversation portrait.
# The map representative stays physically small; this dedicated portrait gives
# conversations the readable face/gear detail that would be lost on the map.

var subject_name: String = "COMPANY REPRESENTATIVE"
var subject_role: String = "BITCOIN MINING OPERATOR"
var accent: Color = Color("64ff8c")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func set_subject(name_text: String, accent_color: Color, role_text: String = "BITCOIN MINING OPERATOR") -> void:
    subject_name = name_text
    subject_role = role_text
    accent = accent_color
    queue_redraw()

func _draw() -> void:
    var outer := Rect2(Vector2.ZERO, size)
    draw_rect(outer, Color("071018f7"), true)
    draw_rect(outer.grow(-2.0), Color("31434b"), false, 2.0)
    draw_rect(Rect2(8.0, 8.0, size.x - 16.0, size.y - 16.0), Color("0d1b23"), true)

    # Industrial backdrop: wall seams, status lamps, and equipment silhouettes.
    for x in range(18, int(size.x) - 18, 24):
        draw_rect(Rect2(float(x), 14.0, 2.0, size.y - 62.0), Color("152b35"), true)
    draw_rect(Rect2(12.0, size.y - 48.0, size.x - 24.0, 3.0), accent.darkened(0.45), true)
    for lamp in range(4):
        var lx := 22.0 + float(lamp) * 28.0
        draw_rect(Rect2(lx, 21.0, 12.0, 5.0), Color("102831"), true)
        draw_rect(Rect2(lx + 3.0, 22.0, 6.0, 3.0), accent.lightened(0.28), true)

    var c := Vector2(size.x * 0.52, 126.0)
    var p := 5.0
    var outline := Color("171419")
    var skin_shadow := Color("6c3f2d")
    var skin_base := Color("a96848")
    var skin_high := Color("d79a72")
    var suit_shadow := Color("101923")
    var suit_base := Color("21354d")
    var suit_mid := Color("34577c")
    var suit_high := Color("5f82aa")
    var metal := Color("92a8b7")

    # Drop shadow and broad shoulder silhouette.
    draw_circle(c + Vector2(0.0, 70.0), 63.0, Color(0.0, 0.0, 0.0, 0.28))
    _px(c, -15, 2, 30, 16, p, outline)
    _px(c, -13, 3, 26, 14, p, suit_base)
    _px(c, -13, 4, 7, 12, p, suit_shadow)
    _px(c, 7, 4, 6, 12, p, suit_mid)

    # Armored shoulder caps and orange/company piping.
    _px(c, -17, 3, 6, 7, p, outline)
    _px(c, 11, 3, 6, 7, p, outline)
    _px(c, -16, 4, 5, 5, p, suit_mid)
    _px(c, 11, 4, 5, 5, p, suit_high)
    _px(c, -16, 8, 5, 1, p, accent)
    _px(c, 11, 8, 5, 1, p, accent)

    # Chest plates, center seam, collar, and utility modules.
    _px(c, -9, 5, 18, 11, p, suit_mid)
    _px(c, -8, 6, 7, 9, p, suit_base)
    _px(c, 2, 6, 6, 9, p, suit_high.darkened(0.15))
    _px(c, -1, 5, 2, 11, p, outline)
    _px(c, -8, 9, 16, 1, p, metal.darkened(0.25))
    _px(c, -8, 14, 16, 1, p, accent.darkened(0.12))
    _px(c, -12, 12, 4, 4, p, outline)
    _px(c, -11, 13, 2, 2, p, accent)

    # Neck and head with a stronger readable facial silhouette.
    _px(c, -4, -1, 8, 5, p, outline)
    _px(c, -3, 0, 6, 4, p, skin_shadow)
    _px(c, -7, -12, 14, 13, p, outline)
    _px(c, -6, -11, 12, 11, p, skin_base)
    _px(c, -6, -10, 3, 9, p, skin_shadow)
    _px(c, 3, -9, 3, 6, p, skin_high)

    # Hair mass with stepped 16-bit clusters.
    _px(c, -7, -15, 13, 4, p, outline)
    _px(c, -6, -16, 3, 3, p, Color("0c1118"))
    _px(c, -3, -17, 3, 4, p, Color("0a0f15"))
    _px(c, 0, -17, 3, 4, p, Color("111824"))
    _px(c, 3, -16, 3, 4, p, Color("0a0f15"))

    # Face detail: brow, eye, nose, mouth.
    _px(c, -4, -8, 2, 1, p, Color("23191a"))
    _px(c, 2, -8, 2, 1, p, Color("23191a"))
    _px(c, 0, -7, 1, 3, p, skin_high)
    _px(c, -1, -3, 4, 1, p, skin_shadow)

    # Scanner visor + headset inspired by the conversation reference image.
    _px(c, 1, -10, 7, 4, p, outline)
    _px(c, 2, -9, 5, 2, p, Color("173c35"))
    _px(c, 3, -9, 3, 1, p, accent.lightened(0.42))
    _px(c, 7, -9, 2, 3, p, metal)
    _px(c, 8, -7, 2, 8, p, outline)
    _px(c, 9, -6, 2, 6, p, accent.darkened(0.15))
    _px(c, 9, -5, 1, 4, p, metal)
    _px(c, 6, -14, 2, 6, p, metal.darkened(0.2))

    # Forearm computer / wearable control panel.
    _px(c, -17, 10, 5, 7, p, outline)
    _px(c, -16, 11, 3, 5, p, metal.darkened(0.2))
    _px(c, -15, 12, 2, 3, p, Color("12384a"))
    _px(c, -15, 12, 1, 1, p, accent.lightened(0.35))

    draw_string(ThemeDB.fallback_font, Vector2(18.0, size.y - 25.0), subject_name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, 14, Color("e7f7fa"))
    draw_string(ThemeDB.fallback_font, Vector2(18.0, size.y - 8.0), subject_role, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36.0, 10, accent.lightened(0.2))

func _px(base: Vector2, ox: int, oy: int, w: int, h: int, unit: float, color: Color) -> void:
    draw_rect(Rect2(base + Vector2(float(ox) * unit, float(oy) * unit), Vector2(float(w) * unit, float(h) * unit)), color, true)
