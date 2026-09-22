extends Control
class_name HashRaceCharacterPreview

const CharacterCustomization = preload("res://scripts/character_customization.gd")
const DefaultPlayerSheet = preload("res://scripts/default_player_sprite_sheet.gd")

var skin_idx: int = CharacterCustomization.DEFAULT_SKIN_TONE
var gender_idx: int = CharacterCustomization.DEFAULT_GENDER
var outfit_idx: int = CharacterCustomization.DEFAULT_OUTFIT
var scouter_color_idx: int = CharacterCustomization.DEFAULT_SCOUTER_COLOR
var scouter_eye_idx: int = CharacterCustomization.DEFAULT_SCOUTER_EYE
var suit_color_idx: int = CharacterCustomization.DEFAULT_SUIT_COLOR
var preview_texture: Texture2D
var preview_frame: int = 0
var preview_elapsed: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    custom_minimum_size = Vector2(250.0, 270.0)
    _rebuild_texture()
    set_process(true)
    queue_redraw()

func set_character(
    new_skin_idx: int,
    new_gender_idx: int,
    new_outfit_idx: int = CharacterCustomization.DEFAULT_OUTFIT,
    new_scouter_color_idx: int = CharacterCustomization.DEFAULT_SCOUTER_COLOR,
    new_scouter_eye_idx: int = CharacterCustomization.DEFAULT_SCOUTER_EYE,
    new_suit_color_idx: int = CharacterCustomization.DEFAULT_SUIT_COLOR
) -> void:
    skin_idx = new_skin_idx
    gender_idx = new_gender_idx
    outfit_idx = new_outfit_idx
    scouter_color_idx = new_scouter_color_idx
    scouter_eye_idx = new_scouter_eye_idx
    suit_color_idx = new_suit_color_idx
    _rebuild_texture()
    queue_redraw()

func _process(delta: float) -> void:
    preview_elapsed += delta
    var frame_time := 1.0 / DefaultPlayerSheet.WALK_FPS
    if preview_elapsed >= frame_time:
        preview_elapsed = fposmod(preview_elapsed, frame_time)
        preview_frame = (preview_frame + 1) % 4
        queue_redraw()

func _rebuild_texture() -> void:
    var tone: Dictionary = CharacterCustomization.skin_tone(skin_idx)
    var suit: Dictionary = CharacterCustomization.suit_color(suit_color_idx)
    preview_texture = DefaultPlayerSheet.build_customized_texture(
        Color(tone["skin"]),
        Color(suit["color"]),
        CharacterCustomization.scouter_lens_color(scouter_color_idx)
    )

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("041017"), true)
    draw_rect(Rect2(Vector2.ZERO, size), Color("28596b"), false, 2.0)
    for y in range(18, int(size.y) - 18, 24):
        draw_line(Vector2(14.0, float(y)), Vector2(size.x - 14.0, float(y)), Color("0b2028"), 1.0)
    for x in range(14, int(size.x) - 14, 24):
        draw_line(Vector2(float(x), 14.0), Vector2(float(x), size.y - 14.0), Color("0b2028"), 1.0)
    draw_string(
        get_theme_default_font(), Vector2(16.0, 24.0), "ACTUAL PLAYER PREVIEW",
        HORIZONTAL_ALIGNMENT_CENTER, size.x - 32.0, 10, Color("64ff8c")
    )

    if preview_texture != null:
        var region := DefaultPlayerSheet.frame_region("down", preview_frame)
        var scale := minf(0.88, minf((size.x - 22.0) / float(region.size.x), (size.y - 58.0) / float(region.size.y)))
        var dest_size := Vector2(region.size) * scale
        var dest := Rect2(Vector2((size.x - dest_size.x) * 0.5, 34.0), dest_size)
        draw_texture_rect_region(preview_texture, dest, Rect2(region))

    draw_string(
        get_theme_default_font(), Vector2(16.0, size.y - 10.0), "exact in-game sheet",
        HORIZONTAL_ALIGNMENT_CENTER, size.x - 32.0, 8, Color("88aab6")
    )

func debug_preview_ready() -> bool:
    return preview_texture != null \
        and Vector2i(preview_texture.get_size()) == DefaultPlayerSheet.SHEET_SIZE \
        and CharacterCustomization.SUIT_COLORS.size() >= 6
