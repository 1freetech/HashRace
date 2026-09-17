extends "res://scripts/world_visual_detail.gd"

# Hash Race v0.035 player-character presentation.
# Original procedural Game Boy Color-style operator inspired by the approved
# Hash Race concept art: brown skin, futuristic field suit and green scanner.
# Drawing it from GDScript keeps the character crisp at any camera zoom and lets
# the existing RPG movement state drive real directional animation.

const PLAYER_PX: float = 4.0
const PLAYER_SKIN_DARK := Color("5b3428")
const PLAYER_SKIN := Color("9a5d3c")
const PLAYER_SKIN_LIGHT := Color("c47b4c")
const PLAYER_HAIR := Color("11141b")
const PLAYER_SUIT_DARK := Color("101923")
const PLAYER_SUIT := Color("e6edf2")
const PLAYER_SUIT_SHADE := Color("8796a6")
const PLAYER_ORANGE := Color("f59b23")
const PLAYER_SCOUTER := Color("37e46f")
const PLAYER_SCOUTER_DARK := Color("0b6e43")

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if not is_player:
        super._draw_tech_rep(pos, accent, scanner, false)
        return
    _draw_hashrace_player(pos, accent)

func _draw_hashrace_player(pos: Vector2, accent: Color) -> void:
    var moving: bool = not rep_animation_state.ends_with("_idle")
    var stride: int = 0
    if moving:
        stride = 1 if sin(rep_step_phase) >= 0.0 else -1
    var bob: float = -4.0 if moving and absf(sin(rep_step_phase)) > 0.55 else 0.0
    var origin: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(0.0, bob))
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 35.0)), 23.0, 8.0)
    var side: bool = rep_facing == "left" or rep_facing == "right"
    var back: bool = rep_facing == "up"
    var mirror: int = -1 if rep_facing == "left" else 1

    _pspx(origin, -4, 5 + stride, 3, 5, PLAYER_PX, PLAYER_SUIT_DARK)
    _pspx(origin, 1, 5 - stride, 3, 5, PLAYER_PX, PLAYER_SUIT_DARK)
    _pspx(origin, -5, 9 + stride, 4, 2, PLAYER_PX, PLAYER_SUIT_SHADE)
    _pspx(origin, 1, 9 - stride, 4, 2, PLAYER_PX, PLAYER_SUIT_SHADE)
    _pspx(origin, -4, 9 + stride, 3, 1, PLAYER_PX, PLAYER_ORANGE)
    _pspx(origin, 1, 9 - stride, 3, 1, PLAYER_PX, PLAYER_ORANGE)

    _pspx(origin, -6, -2, 12, 8, PLAYER_PX, PLAYER_SUIT_DARK)
    _pspx(origin, -5, -2, 10, 7, PLAYER_PX, PLAYER_SUIT)
    _pspx(origin, -5, 2, 10, 3, PLAYER_PX, PLAYER_SUIT_SHADE)
    _pspx(origin, -3, -1, 6, 5, PLAYER_PX, PLAYER_SUIT_DARK)
    _pspx(origin, -2, 0, 4, 3, PLAYER_PX, PLAYER_SUIT)
    _pspx(origin, -1, 1, 2, 1, PLAYER_PX, PLAYER_ORANGE)
    _pspx(origin, -6, -1 + stride, 2, 5, PLAYER_PX, PLAYER_SUIT_SHADE)
    _pspx(origin, 4, -1 - stride, 2, 5, PLAYER_PX, PLAYER_SUIT_SHADE)
    _pspx(origin, -6, 0 + stride, 1, 3, PLAYER_PX, PLAYER_ORANGE)
    _pspx(origin, 5, 0 - stride, 1, 3, PLAYER_PX, PLAYER_ORANGE)

    _pspx(origin, -2, -5, 4, 3, PLAYER_PX, PLAYER_SKIN_DARK)
    _pspx(origin, -4, -10, 8, 6, PLAYER_PX, PLAYER_SKIN)
    if side:
        _pspx(origin, -4 if mirror < 0 else 3, -9, 2, 4, PLAYER_PX, PLAYER_SKIN_DARK)
        _pspx(origin, -2 if mirror < 0 else 1, -7, 1, 1, PLAYER_PX, PLAYER_SKIN_LIGHT)
    elif not back:
        _pspx(origin, -3, -7, 1, 1, PLAYER_PX, PLAYER_SKIN_LIGHT)
        _pspx(origin, 2, -7, 1, 1, PLAYER_PX, PLAYER_SKIN_LIGHT)
        _pspx(origin, -1, -5, 2, 1, PLAYER_PX, PLAYER_SKIN_DARK)

    _pspx(origin, -4, -11, 8, 2, PLAYER_PX, PLAYER_HAIR)
    _pspx(origin, -5, -10, 2, 2, PLAYER_PX, PLAYER_HAIR)
    _pspx(origin, 3, -10, 2, 2, PLAYER_PX, PLAYER_HAIR)
    _pspx(origin, -3, -12, 2, 2, PLAYER_PX, PLAYER_HAIR)
    _pspx(origin, 0, -13, 2, 3, PLAYER_PX, PLAYER_HAIR)
    _pspx(origin, 2, -12, 2, 2, PLAYER_PX, PLAYER_HAIR)

    if not back:
        var lens_x: int = -4 if rep_facing != "right" else 1
        _pspx(origin, lens_x, -8, 4, 2, PLAYER_PX, PLAYER_SCOUTER_DARK)
        _pspx(origin, lens_x + 1, -8, 3, 1, PLAYER_PX, PLAYER_SCOUTER)
        _pspx(origin, lens_x + 3, -9, 1, 3, PLAYER_PX, PLAYER_SUIT)
        _pspx(origin, -1, 1, 2, 2, PLAYER_PX, PLAYER_ORANGE)
        _pspx(origin, 0, 1, 1, 2, PLAYER_PX, Color("fff0b0"))
    else:
        _pspx(origin, -3, -1, 6, 4, PLAYER_PX, PLAYER_SUIT_SHADE)
        _pspx(origin, -1, 0, 2, 2, PLAYER_PX, PLAYER_ORANGE)

    var player_rect := Rect2(origin + Vector2(-30.0, -55.0), Vector2(60.0, 101.0))
    _draw_layered_stroke_rect(player_rect, Color(0.0, 0.0, 0.0, 0.0), Color(accent.r, accent.g, accent.b, 0.72), Color(accent.r, accent.g, accent.b, 0.24), 2.0)

func _pspx(origin: Vector2, gx: int, gy: int, gw: int, gh: int, px: float, color: Color) -> void:
    draw_rect(Rect2(origin + Vector2(float(gx) * px, float(gy) * px), Vector2(float(gw) * px, float(gh) * px)), color, true)

func debug_player_sprite_ready() -> bool:
    return PLAYER_PX == 4.0 and rep_animation_state.length() > 0
