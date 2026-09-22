extends "res://scripts/world_v143.gd"

# v0.144 makes campaign-start skin and suit choices visible on the exact
# approved player sheet. The source PNG stays unchanged; a runtime texture is
# derived from its decoded pixels only when a palette choice changes.

const DefaultPlayerSheetV144 = preload("res://scripts/default_player_sprite_sheet.gd")
const V144_CHARACTER_CUSTOMIZATION_REVISION := 1

var v144_player_texture: Texture2D
var v144_palette_key := Vector3i(-1, -1, -1)

func _ready() -> void:
    super._ready()
    _refresh_v144_player_texture()
    set_meta("hashrace_v144_character_customization_revision", V144_CHARACTER_CUSTOMIZATION_REVISION)
    set_meta("hashrace_character_render_mode", "approved_32frame_runtime_palette")
    queue_redraw()

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if not is_player:
        super._draw_tech_rep(pos, accent, scanner, false)
        return
    _refresh_v144_player_texture()
    if v144_player_texture == null:
        return

    var moving := not rep_animation_state.ends_with("_idle")
    var frame := DefaultPlayerSheetV144.walk_frame(moving, rep_step_phase)
    var region := DefaultPlayerSheetV144.frame_region(rep_facing, frame)
    var foot := VisualStack.snap_to_pixel(pos + Vector2(0.0, 43.0))
    var dest := Rect2(
        VisualStack.snap_to_pixel(foot + (DefaultPlayerSheetV144.frame_offset(region) - Vector2(DefaultPlayerSheetV144.FOOT_ANCHOR)) * PLAYER_PIXEL_SCALE),
        Vector2(region.size) * PLAYER_PIXEL_SCALE
    )
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 42.0)), 28.0, 8.0)
    draw_texture_rect_region(v144_player_texture, dest, Rect2(region))

func _refresh_v144_player_texture() -> void:
    if player.is_empty():
        return
    var skin_idx := int(player.get("skin_tone_idx", CharacterCustomization.DEFAULT_SKIN_TONE))
    var suit_idx := int(player.get("suit_color_idx", CharacterCustomization.DEFAULT_SUIT_COLOR))
    var scouter_idx := int(player.get("scouter_color_idx", CharacterCustomization.DEFAULT_SCOUTER_COLOR))
    var next_key := Vector3i(skin_idx, suit_idx, scouter_idx)
    if v144_player_texture != null and next_key == v144_palette_key:
        return
    var tone: Dictionary = CharacterCustomization.skin_tone(skin_idx)
    var suit: Dictionary = CharacterCustomization.suit_color(suit_idx)
    v144_player_texture = DefaultPlayerSheetV144.build_customized_texture(
        Color(tone["skin"]),
        Color(suit["color"]),
        CharacterCustomization.scouter_lens_color(scouter_idx)
    )
    v144_palette_key = next_key
    set_meta("hashrace_player_custom_palette_live", v144_player_texture != null)

func debug_v144_ready() -> bool:
    return V144_CHARACTER_CUSTOMIZATION_REVISION == 1 \
        and v144_player_texture != null \
        and v144_palette_key.x >= 0 \
        and CharacterCustomization.SUIT_COLORS.size() >= 6 \
        and debug_v143_ready()

func debug_v144_palette_key() -> Vector3i:
    return v144_palette_key
