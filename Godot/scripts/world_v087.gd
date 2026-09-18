extends "res://scripts/world_v086.gd"

# Hash Race v0.087 high-density character finishing pass.
# v0.073 already supplies the directional procedural character silhouette.
# This layer keeps that proven animation/pose system and adds 1-2 px microdetail
# inside the existing 3 px source cells: face catchlights, visor scanlines,
# headset hardware, hair streaks, armor seams/rivets, glove knuckles and boot
# tread. The result reads much closer to a hand-authored hi-res pixel sprite
# without duplicating a sprite sheet for every palette variation.

const V087_CHARACTER_REVISION: int = 1
const V087_SOURCE_CELL: float = 3.0
const V087_MICRO_PIXEL: float = 1.0
const V087_INK := Color("05070a")
const V087_STEEL_DARK := Color("46535b")
const V087_STEEL_HI := Color("f5fbfb")
const V087_EYE := Color("161111")
const V087_EYE_HI := Color("ffffff")
const V087_HAIR_GLOSS := Color("4b4652")

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v087_character_revision", V087_CHARACTER_REVISION)
    set_meta("hashrace_character_render_mode", "procedural_high_density_plus_sprite_rig")
    queue_redraw()

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    super._draw_tech_rep(pos, accent, scanner, is_player)

    var facing: String = "down"
    var animation_state: String = "down_idle"
    var detail_accent: Color = accent
    var visor: Color = Color("39ff75")
    var skin: Color = Color("9a5d3c")
    var hair_tint: Color = V087_HAIR_GLOSS
    var bob: float = 0.0

    if is_player:
        facing = rep_facing
        animation_state = rep_animation_state
        var skin_idx: int = int(player.get("skin_tone_idx", CharacterCustomization.DEFAULT_SKIN_TONE))
        var outfit_idx: int = int(player.get("outfit_idx", CharacterCustomization.DEFAULT_OUTFIT))
        var tone: Dictionary = CharacterCustomization.skin_tone(skin_idx)
        var outfit: Dictionary = CharacterCustomization.outfit(outfit_idx)
        skin = Color(tone["skin"])
        detail_accent = Color(outfit["secondary"])
        visor = Color(outfit["neon"])
        hair_tint = _v087_player_hair_tint(outfit_idx)
        if not animation_state.ends_with("_idle") and absf(sin(rep_step_phase)) > 0.55:
            bob = -V073_PX
        if v073_character_action == "victory":
            bob = -V073_PX
    else:
        var seed: int = _v087_seed(pos, accent)
        facing = _v087_npc_facing(seed)
        skin = V073_NPC_SKINS[seed % V073_NPC_SKINS.size()]
        hair_tint = _v087_npc_hair_tint(seed)

    var o: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(0.0, bob))
    _draw_v087_microdetail(o, facing, scanner, skin, detail_accent, visor, hair_tint, is_player)

func _draw_v087_microdetail(
    o: Vector2,
    facing: String,
    scanner: String,
    skin: Color,
    accent: Color,
    visor: Color,
    hair_tint: Color,
    is_player: bool
) -> void:
    match facing:
        "up":
            _draw_v087_back_detail(o, accent, visor, hair_tint, is_player)
        "left":
            _draw_v087_side_detail(o, -1, skin, accent, visor, hair_tint, is_player)
        "right":
            _draw_v087_side_detail(o, 1, skin, accent, visor, hair_tint, is_player)
        _:
            _draw_v087_front_detail(o, scanner, skin, accent, visor, hair_tint, is_player)

func _draw_v087_front_detail(
    o: Vector2,
    scanner: String,
    skin: Color,
    accent: Color,
    visor: Color,
    hair_tint: Color,
    is_player: bool
) -> void:
    var visor_left: bool = scanner == "left"
    var open_eye_x: int = 3 if visor_left else -4
    var visor_x: int = -5 if visor_left else 1
    var skin_shadow: Color = skin.darkened(0.34)
    var accent_hi: Color = accent.lightened(0.38)
    var accent_dark: Color = accent.darkened(0.42)
    var visor_hi: Color = visor.lightened(0.48)

    _v087_micro(o, -4, -17, 0, 0, 2, 1, hair_tint)
    _v087_micro(o, -2, -18, 1, 0, 1, 2, hair_tint.lightened(0.14))
    _v087_micro(o, 0, -19, 0, 0, 2, 1, hair_tint)
    _v087_micro(o, 2, -17, 1, 0, 1, 2, hair_tint.lightened(0.10))
    _v087_micro(o, 4, -17, 0, 1, 2, 1, hair_tint)

    _v087_micro(o, -7, -12, 1, 1, 1, 10, V087_STEEL_DARK)
    _v087_micro(o, -6, -12, 0, 2, 1, 7, V087_STEEL_HI)
    _v087_micro(o, 6, -12, 0, 1, 1, 10, V087_STEEL_DARK)
    _v087_micro(o, 5, -12, 2, 2, 1, 7, V087_STEEL_HI)
    _v087_micro(o, -6, -9, 1, 1, 1, 2, accent_hi)
    _v087_micro(o, 5, -9, 1, 1, 1, 2, accent_hi)

    _v087_micro(o, open_eye_x + 1, -10, 0, 0, 2, 2, V087_EYE)
    _v087_micro(o, open_eye_x + 1, -10, 0, 0, 1, 1, V087_EYE_HI)
    _v087_micro(o, -1, -9, 1, 1, 1, 1, skin.lightened(0.28))
    _v087_micro(o, -1, -7, 0, 1, 4, 1, skin_shadow)

    _v087_micro(o, visor_x, -12, 1, 1, 13, 1, V087_INK)
    _v087_micro(o, visor_x + 1, -11, 0, 1, 8, 1, visor.darkened(0.30))
    _v087_micro(o, visor_x + 1, -10, 1, 0, 6, 1, visor)
    _v087_micro(o, visor_x + 2, -11, 1, 0, 2, 1, visor_hi)
    _v087_micro(o, visor_x + 3, -10, 1, 1, 1, 1, V087_EYE_HI)

    _v087_micro(o, -8, -3, 1, 1, 1, 1, V087_STEEL_HI)
    _v087_micro(o, 7, -3, 1, 1, 1, 1, V087_STEEL_HI)
    _v087_micro(o, -5, -3, 1, 2, 1, 14, accent_dark)
    _v087_micro(o, 4, -3, 1, 2, 1, 14, accent_dark)
    _v087_micro(o, -3, 1, 0, 0, 18, 1, V087_STEEL_DARK)
    _v087_micro(o, -2, 3, 0, 0, 12, 1, accent_hi)

    if is_player:
        _v087_micro(o, -1, -1, 1, 0, 1, 7, V087_INK)
        _v087_micro(o, 0, -1, 0, 1, 4, 1, V087_INK)
        _v087_micro(o, 0, 0, 0, 1, 4, 1, V087_INK)
        _v087_micro(o, 0, 1, 0, 1, 4, 1, V087_INK)

    _v087_micro(o, -8, 5, 1, 1, 4, 1, V087_STEEL_DARK)
    _v087_micro(o, 7, 5, 0, 1, 4, 1, V087_STEEL_DARK)
    _v087_micro(o, -4, 11, 1, 1, 6, 1, V087_STEEL_HI)
    _v087_micro(o, 2, 11, 0, 1, 6, 1, V087_STEEL_HI)
    _v087_micro(o, -4, 12, 1, 1, 1, 1, V087_INK)
    _v087_micro(o, -2, 12, 0, 1, 1, 1, V087_INK)
    _v087_micro(o, 2, 12, 1, 1, 1, 1, V087_INK)
    _v087_micro(o, 4, 12, 0, 1, 1, 1, V087_INK)

func _draw_v087_back_detail(o: Vector2, accent: Color, visor: Color, hair_tint: Color, is_player: bool) -> void:
    var accent_hi: Color = accent.lightened(0.34)
    _v087_micro(o, -4, -17, 0, 0, 2, 1, hair_tint)
    _v087_micro(o, -1, -18, 1, 0, 1, 2, hair_tint.lightened(0.12))
    _v087_micro(o, 2, -17, 1, 0, 1, 2, hair_tint)
    _v087_micro(o, -6, -10, 1, 1, 1, 2, visor.lightened(0.32))
    _v087_micro(o, 5, -10, 1, 1, 1, 2, visor.lightened(0.32))
    _v087_micro(o, -3, -2, 1, 1, 14, 1, V087_STEEL_DARK)
    _v087_micro(o, -3, 0, 1, 1, 14, 1, V087_STEEL_DARK)
    _v087_micro(o, -2, 2, 1, 1, 8, 1, accent_hi)
    _v087_micro(o, -3, -2, 0, 0, 1, 1, V087_STEEL_HI)
    _v087_micro(o, 2, -2, 2, 0, 1, 1, V087_STEEL_HI)
    if is_player:
        _v087_micro(o, -1, 0, 0, 0, 6, 1, visor)
    _v087_micro(o, -4, 11, 1, 1, 6, 1, V087_STEEL_HI)
    _v087_micro(o, 2, 11, 0, 1, 6, 1, V087_STEEL_HI)

func _draw_v087_side_detail(
    o: Vector2,
    flip: int,
    skin: Color,
    accent: Color,
    visor: Color,
    hair_tint: Color,
    is_player: bool
) -> void:
    var accent_hi: Color = accent.lightened(0.36)
    var skin_shadow: Color = skin.darkened(0.34)
    _v087_side_micro(o, -3, -17, 1, 0, 4, 1, hair_tint, flip)
    _v087_side_micro(o, -1, -18, 1, 0, 3, 1, hair_tint.lightened(0.13), flip)
    _v087_side_micro(o, 1, -16, 0, 1, 4, 1, hair_tint, flip)
    _v087_side_micro(o, -5, -12, 1, 1, 1, 10, V087_STEEL_DARK, flip)
    _v087_side_micro(o, -4, -12, 0, 2, 1, 7, V087_STEEL_HI, flip)
    _v087_side_micro(o, -4, -9, 1, 1, 1, 2, accent_hi, flip)
    _v087_side_micro(o, 1, -10, 1, 0, 2, 2, V087_EYE, flip)
    _v087_side_micro(o, 1, -10, 1, 0, 1, 1, V087_EYE_HI, flip)
    _v087_side_micro(o, 2, -11, 0, 1, 7, 1, visor.darkened(0.28), flip)
    _v087_side_micro(o, 2, -10, 1, 0, 4, 1, visor, flip)
    _v087_side_micro(o, 3, -11, 0, 0, 1, 1, visor.lightened(0.48), flip)
    _v087_side_micro(o, 1, -7, 1, 1, 3, 1, skin_shadow, flip)
    _v087_side_micro(o, -2, -2, 1, 1, 1, 15, accent.darkened(0.42), flip)
    _v087_side_micro(o, 1, 3, 0, 1, 5, 1, accent_hi, flip)
    _v087_side_micro(o, 1, 11, 1, 1, 6, 1, V087_STEEL_HI, flip)
    _v087_side_micro(o, 2, 12, 0, 1, 1, 1, V087_INK, flip)
    if is_player:
        _v087_side_micro(o, -1, 0, 1, 0, 3, 1, visor, flip)

func _v087_micro(
    o: Vector2,
    cell_x: int,
    cell_y: int,
    px_x: int,
    px_y: int,
    width: int,
    height: int,
    color: Color
) -> void:
    var p := o + Vector2(
        float(cell_x) * V087_SOURCE_CELL + float(px_x),
        float(cell_y) * V087_SOURCE_CELL + float(px_y)
    )
    draw_rect(Rect2(VisualStack.snap_to_pixel(p), Vector2(float(width), float(height))), color, true)

func _v087_side_micro(
    o: Vector2,
    cell_x: int,
    cell_y: int,
    px_x: int,
    px_y: int,
    width: int,
    height: int,
    color: Color,
    flip: int
) -> void:
    var source_x: float = float(cell_x) * V087_SOURCE_CELL + float(px_x)
    if flip < 0:
        source_x = -source_x - float(width)
    var p := o + Vector2(source_x, float(cell_y) * V087_SOURCE_CELL + float(px_y))
    draw_rect(Rect2(VisualStack.snap_to_pixel(p), Vector2(float(width), float(height))), color, true)

func _v087_seed(pos: Vector2, accent: Color) -> int:
    return abs(int(pos.x * 17.0 + pos.y * 31.0 + accent.r * 255.0 * 13.0 + accent.g * 255.0 * 7.0 + accent.b * 255.0 * 3.0))

func _v087_npc_facing(seed: int) -> String:
    var facings: Array[String] = ["down", "down", "left", "right", "up"]
    return facings[seed % facings.size()]

func _v087_player_hair_tint(outfit_idx: int) -> Color:
    var palette: Array[Color] = [
        Color("35323e"), Color("25324b"), Color("5b315f"),
        Color("2d4b50"), Color("5c4829"), Color("4b304f")
    ]
    return palette[outfit_idx % palette.size()]

func _v087_npc_hair_tint(seed: int) -> Color:
    var palette: Array[Color] = [
        Color("34323b"), Color("243552"), Color("5a3e31"),
        Color("60656d"), Color("4b2f51"), Color("70402d")
    ]
    return palette[seed % palette.size()]

func debug_v087_ready() -> bool:
    return V087_CHARACTER_REVISION == 1 and V087_MICRO_PIXEL == 1.0 and has_method("_draw_v073_front")
