extends Control
class_name HashRaceCharacterPreview

const CharacterCustomization = preload("res://scripts/character_customization.gd")

const PX: float = 4.0
const OUTLINE := Color("090b0d")
const METAL := Color("dce3e2")
const HAIR := Color("111315")
const HAIR_HI := Color("34383a")

var skin_idx: int = CharacterCustomization.DEFAULT_SKIN_TONE
var gender_idx: int = CharacterCustomization.DEFAULT_GENDER
var outfit_idx: int = CharacterCustomization.DEFAULT_OUTFIT
var scouter_color_idx: int = CharacterCustomization.DEFAULT_SCOUTER_COLOR
var scouter_eye_idx: int = CharacterCustomization.DEFAULT_SCOUTER_EYE

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(250.0, 270.0)
    queue_redraw()

func set_character(
    new_skin_idx: int,
    new_gender_idx: int,
    new_outfit_idx: int = CharacterCustomization.DEFAULT_OUTFIT,
    new_scouter_color_idx: int = CharacterCustomization.DEFAULT_SCOUTER_COLOR,
    new_scouter_eye_idx: int = CharacterCustomization.DEFAULT_SCOUTER_EYE
) -> void:
    skin_idx = new_skin_idx
    gender_idx = new_gender_idx
    outfit_idx = new_outfit_idx
    scouter_color_idx = new_scouter_color_idx
    scouter_eye_idx = new_scouter_eye_idx
    queue_redraw()

func _draw() -> void:
    var panel := Rect2(Vector2.ZERO, size)
    draw_rect(panel, Color("041017"), true)
    draw_rect(panel, Color("28596b"), false, 2.0)

    for y in range(18, int(size.y) - 18, 24):
        draw_line(Vector2(14.0, float(y)), Vector2(size.x - 14.0, float(y)), Color("0b2028"), 1.0)
    for x in range(14, int(size.x) - 14, 24):
        draw_line(Vector2(float(x), 14.0), Vector2(float(x), size.y - 14.0), Color("0b2028"), 1.0)

    draw_string(
        get_theme_default_font(),
        Vector2(16.0, 24.0),
        "LIVE PLAYER PREVIEW",
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x - 32.0,
        10,
        Color("64ff8c")
    )

    var center := Vector2(size.x * 0.5, size.y * 0.58)
    _draw_character(center)

    draw_string(
        get_theme_default_font(),
        Vector2(16.0, size.y - 18.0),
        "updates as you edit",
        HORIZONTAL_ALIGNMENT_CENTER,
        size.x - 32.0,
        8,
        Color("88aab6")
    )

func _draw_character(o: Vector2) -> void:
    var tone: Dictionary = CharacterCustomization.skin_tone(skin_idx)
    var outfit: Dictionary = CharacterCustomization.outfit(outfit_idx)
    var skin: Color = tone["skin"]
    var skin_hi: Color = tone["highlight"]
    var primary: Color = outfit["primary"]
    var secondary: Color = outfit["secondary"]
    var neon: Color = CharacterCustomization.scouter_lens_color(scouter_color_idx)
    var shadow := primary.darkened(0.32)
    var hi := primary.lightened(0.18)
    var secondary_hi := secondary.lightened(0.20)
    var skin_shadow := skin.darkened(0.28)

    draw_ellipse_shadow(o + Vector2(0.0, 52.0), 31.0, 9.0)

    # Legs / boots
    _part(o, -5, 5, 4, 7, OUTLINE)
    _part(o, 1, 5, 4, 7, OUTLINE)
    _part(o, -4, 5, 3, 5, primary)
    _part(o, 1, 5, 3, 5, hi)
    _part(o, -4, 8, 3, 2, secondary)
    _part(o, 1, 8, 3, 2, secondary_hi)
    _part(o, -5, 10, 4, 2, OUTLINE)
    _part(o, 1, 10, 4, 2, OUTLINE)
    _part(o, -4, 10, 3, 1, secondary)
    _part(o, 1, 10, 3, 1, secondary)

    # Torso / armor
    _part(o, -7, -4, 14, 10, OUTLINE)
    _part(o, -6, -3, 12, 8, primary)
    _part(o, -6, -3, 2, 8, shadow)
    _part(o, 4, -3, 2, 8, hi)
    _part(o, -5, 3, 10, 2, shadow)
    _part(o, -4, 4, 8, 1, secondary)
    _part(o, -5, -2, 2, 2, secondary)
    _part(o, 3, -2, 2, 2, secondary_hi)

    # Arms
    _part(o, -9, -3, 3, 9, OUTLINE)
    _part(o, 6, -3, 3, 9, OUTLINE)
    _part(o, -8, -2, 2, 6, primary)
    _part(o, 6, -2, 2, 6, hi)
    _part(o, -8, -2, 2, 2, secondary)
    _part(o, 6, -2, 2, 2, secondary_hi)
    _part(o, -8, 4, 2, 2, OUTLINE)
    _part(o, 6, 4, 2, 2, OUTLINE)

    # Neck / face
    _part(o, -2, -6, 4, 2, OUTLINE)
    _part(o, -1, -6, 2, 2, skin_shadow)
    _part(o, -5, -13, 10, 8, OUTLINE)
    _part(o, -4, -12, 8, 6, skin)
    _part(o, -4, -12, 2, 5, skin_shadow)
    _part(o, 2, -11, 2, 4, skin_hi)

    # Hair variants mirror the live presentation choices.
    if gender_idx == 1:
        _part(o, -6, -18, 12, 5, HAIR)
        _part(o, -7, -16, 2, 10, HAIR)
        _part(o, 5, -16, 2, 10, HAIR)
        _part(o, -4, -19, 2, 4, HAIR)
        _part(o, 2, -19, 2, 4, HAIR)
        _part(o, -4, -17, 1, 3, HAIR_HI)
        _part(o, 3, -17, 1, 3, HAIR_HI)
    elif gender_idx == 2:
        _part(o, -6, -16, 12, 4, HAIR)
        _part(o, -7, -14, 3, 3, HAIR)
        _part(o, 4, -14, 3, 3, HAIR)
        _part(o, -3, -17, 2, 3, HAIR)
        _part(o, 1, -17, 2, 3, HAIR)
        _part(o, -1, -16, 2, 1, HAIR_HI)
    else:
        _part(o, -6, -16, 12, 4, HAIR)
        _part(o, -7, -15, 3, 4, HAIR)
        _part(o, 4, -15, 3, 4, HAIR)
        _part(o, -6, -18, 2, 5, HAIR)
        _part(o, -4, -19, 2, 6, HAIR)
        _part(o, 0, -20, 2, 7, HAIR)
        _part(o, 4, -19, 2, 6, HAIR)
        _part(o, 0, -18, 1, 3, HAIR_HI)

    # Ear protection / headset
    _part(o, -7, -12, 2, 6, OUTLINE)
    _part(o, 5, -12, 2, 6, OUTLINE)
    _part(o, -6, -11, 1, 4, METAL)
    _part(o, 5, -11, 1, 4, METAL)

    # One-eye scouter / uncovered eye
    var scanner := CharacterCustomization.scouter_scanner_side(scouter_eye_idx)
    var visor_left := scanner == "left"
    var visor_x: int = -5 if visor_left else 1
    var eye_x: int = 2 if visor_left else -3
    _part(o, eye_x, -9, 2, 2, METAL)
    _part(o, eye_x + 1, -9, 1, 2, OUTLINE)
    _part(o, visor_x, -11, 5, 4, OUTLINE)
    _part(o, visor_x + 1, -10, 3, 2, neon.darkened(0.55))
    _part(o, visor_x + 2, -10, 2, 1, neon)
    _part(o, visor_x + 2, -10, 1, 1, neon.lightened(0.38))

    # Chest badge
    _part(o, -2, 0, 4, 4, METAL)
    _part(o, -1, 0, 1, 4, OUTLINE)
    _part(o, 0, 0, 2, 1, OUTLINE)
    _part(o, 0, 2, 2, 1, OUTLINE)

func _part(o: Vector2, x: int, y: int, w: int, h: int, color: Color) -> void:
    draw_rect(
        Rect2(o + Vector2(float(x) * PX, float(y) * PX), Vector2(float(w) * PX, float(h) * PX)),
        color,
        true
    )

func draw_ellipse_shadow(center: Vector2, rx: float, ry: float) -> void:
    var points := PackedVector2Array()
    for i in range(24):
        var angle := TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
    draw_colored_polygon(points, Color("00000066"))

func debug_preview_ready() -> bool:
    return size.x >= 200.0 and CharacterCustomization.SKIN_TONES.size() >= 6
