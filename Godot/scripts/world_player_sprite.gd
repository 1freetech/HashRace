extends "res://scripts/world_visual_detail.gd"

# Hash Race v0.037 procedural operator.
# The approved sprite-sheet target is translated into reusable GDScript shapes:
# brown skin, textured black hair, white/graphite suit, orange trim and green
# one-eye scanner. Movement already owned by the RPG world drives the animation.

const PLAYER_PX: float = 4.0
const PLAYER_SKIN_DARK := Color("5b3428")
const PLAYER_SKIN := Color("9a5d3c")
const PLAYER_SKIN_LIGHT := Color("c47b4c")
const PLAYER_HAIR := Color("11141b")
const PLAYER_HAIR_LIGHT := Color("292b3c")
const PLAYER_SUIT_DARK := Color("101923")
const PLAYER_SUIT := Color("e6edf2")
const PLAYER_SUIT_SHADE := Color("8796a6")
const PLAYER_ORANGE := Color("f59b23")
const PLAYER_GOLD := Color("ffd24a")
const PLAYER_SCOUTER := Color("37e46f")
const PLAYER_SCOUTER_DARK := Color("0b6e43")
const PLAYER_OUTLINE := Color("070b11")

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if not is_player:
        super._draw_tech_rep(pos, accent, scanner, false)
        return
    _draw_hashrace_player(pos, accent)

func _draw_hashrace_player(pos: Vector2, accent: Color = PLAYER_ORANGE) -> void:
    var moving: bool = not rep_animation_state.ends_with("_idle")
    var run_mode: bool = rep_animation_state.contains("run")
    var stride: int = 0
    if moving:
        stride = 2 if sin(rep_step_phase) >= 0.0 else -2
        if run_mode: stride *= 2
    var bob: float = -4.0 if moving and absf(sin(rep_step_phase)) > 0.45 else 0.0
    var origin: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(0.0, bob))
    var side: bool = rep_facing == "left" or rep_facing == "right"
    var back: bool = rep_facing == "up"
    var mirror: int = -1 if rep_facing == "left" else 1

    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 39.0)), 25.0, 8.0)
    _draw_operator_legs(origin, stride)
    _draw_operator_body(origin, stride, back)
    _draw_operator_head(origin, side, back, mirror)
    _draw_operator_hair(origin, side, back, mirror)
    _draw_operator_scouter(origin, back, mirror)
    _draw_operator_badge(origin, back)

func _draw_operator_legs(o: Vector2, stride: int) -> void:
    _pspx(o,-5,5+stride,4,5,PLAYER_PX,PLAYER_OUTLINE)
    _pspx(o,1,5-stride,4,5,PLAYER_PX,PLAYER_OUTLINE)
    _pspx(o,-4,5+stride,3,4,PLAYER_PX,PLAYER_SUIT_DARK)
    _pspx(o,1,5-stride,3,4,PLAYER_PX,PLAYER_SUIT_DARK)
    _pspx(o,-5,8+stride,4,2,PLAYER_PX,PLAYER_SUIT)
    _pspx(o,1,8-stride,4,2,PLAYER_PX,PLAYER_SUIT)
    _pspx(o,-5,9+stride,4,1,PLAYER_PX,PLAYER_ORANGE)
    _pspx(o,1,9-stride,4,1,PLAYER_PX,PLAYER_ORANGE)

func _draw_operator_body(o: Vector2, stride: int, back: bool) -> void:
    _pspx(o,-7,-3,14,9,PLAYER_PX,PLAYER_OUTLINE)
    _pspx(o,-6,-2,12,7,PLAYER_PX,PLAYER_SUIT)
    _pspx(o,-5,2,10,3,PLAYER_PX,PLAYER_SUIT_SHADE)
    _pspx(o,-4,-1,8,5,PLAYER_PX,PLAYER_SUIT_DARK)
    _pspx(o,-3,0,6,3,PLAYER_PX,PLAYER_SUIT)
    _pspx(o,-7,-1+stride,2,5,PLAYER_PX,PLAYER_OUTLINE)
    _pspx(o,5,-1-stride,2,5,PLAYER_PX,PLAYER_OUTLINE)
    _pspx(o,-6,-1+stride,1,4,PLAYER_PX,PLAYER_SUIT)
    _pspx(o,5,-1-stride,1,4,PLAYER_PX,PLAYER_SUIT)
    _pspx(o,-6,0+stride,1,2,PLAYER_PX,PLAYER_ORANGE)
    _pspx(o,5,0-stride,1,2,PLAYER_PX,PLAYER_ORANGE)
    if back:
        _pspx(o,-3,0,6,3,PLAYER_PX,PLAYER_SUIT_SHADE)

func _draw_operator_head(o: Vector2, side: bool, back: bool, mirror: int) -> void:
    _pspx(o,-5,-11,10,7,PLAYER_PX,PLAYER_OUTLINE)
    if back:
        _pspx(o,-4,-10,8,6,PLAYER_PX,PLAYER_HAIR)
        return
    _pspx(o,-4,-10,8,6,PLAYER_PX,PLAYER_SKIN)
    _pspx(o,-3,-9,2,1,PLAYER_PX,PLAYER_SKIN_LIGHT)
    if side:
        var eye_x: int = -3 if mirror < 0 else 2
        _pspx(o,eye_x,-7,1,1,PLAYER_PX,PLAYER_OUTLINE)
        _pspx(o,-4 if mirror < 0 else 3,-8,1,3,PLAYER_PX,PLAYER_SKIN_DARK)
    else:
        _pspx(o,-3,-7,1,1,PLAYER_PX,PLAYER_OUTLINE)
        _pspx(o,2,-7,1,1,PLAYER_PX,PLAYER_OUTLINE)
        _pspx(o,-1,-5,2,1,PLAYER_PX,PLAYER_SKIN_DARK)

func _draw_operator_hair(o: Vector2, side: bool, back: bool, mirror: int) -> void:
    _pspx(o,-5,-13,10,3,PLAYER_PX,PLAYER_HAIR)
    _pspx(o,-6,-11,2,3,PLAYER_PX,PLAYER_HAIR)
    _pspx(o,4,-11,2,3,PLAYER_PX,PLAYER_HAIR)
    # Dense irregular clusters approximate the sprite-sheet's textured silhouette.
    var tufts := [Vector2i(-5,-14),Vector2i(-3,-15),Vector2i(-1,-14),Vector2i(1,-16),Vector2i(3,-14),Vector2i(4,-13)]
    for t in tufts:
        _pspx(o,t.x,t.y,2,3,PLAYER_PX,PLAYER_HAIR)
        _pspx(o,t.x+1,t.y+1,1,1,PLAYER_PX,PLAYER_HAIR_LIGHT)
    if back:
        _pspx(o,-4,-10,8,4,PLAYER_PX,PLAYER_HAIR)

func _draw_operator_scouter(o: Vector2, back: bool, mirror: int) -> void:
    if back:
        _pspx(o,-5,-8,1,3,PLAYER_PX,PLAYER_SUIT)
        _pspx(o,4,-8,1,3,PLAYER_PX,PLAYER_SUIT)
        _pspx(o,-5,-7,1,1,PLAYER_PX,PLAYER_ORANGE)
        _pspx(o,4,-7,1,1,PLAYER_PX,PLAYER_ORANGE)
        return
    var lens_x: int = -4 if mirror < 0 else 1
    _pspx(o,lens_x,-9,4,3,PLAYER_PX,PLAYER_OUTLINE)
    _pspx(o,lens_x,-8,4,2,PLAYER_PX,PLAYER_SCOUTER_DARK)
    _pspx(o,lens_x+1,-8,2,1,PLAYER_PX,PLAYER_SCOUTER)
    _pspx(o,lens_x+1,-8,1,1,PLAYER_PX,Color("a4ffaf"))
    var ear_x: int = 4 if mirror < 0 else -5
    _pspx(o,ear_x,-9,2,4,PLAYER_PX,PLAYER_OUTLINE)
    _pspx(o,ear_x,-8,2,2,PLAYER_PX,PLAYER_SUIT)
    _pspx(o,ear_x+1,-8,1,2,PLAYER_PX,PLAYER_ORANGE)

func _draw_operator_badge(o: Vector2, back: bool) -> void:
    _pspx(o,-2,0,4,3,PLAYER_PX,PLAYER_OUTLINE)
    _pspx(o,-1,0,2,3,PLAYER_PX,PLAYER_ORANGE)
    _pspx(o,0,0,1,3,PLAYER_PX,PLAYER_GOLD)
    if not back:
        _pspx(o,1,1,1,1,PLAYER_PX,PLAYER_GOLD)

func _pspx(origin: Vector2, gx: int, gy: int, gw: int, gh: int, px: float, color: Color) -> void:
    draw_rect(Rect2(origin + Vector2(float(gx)*px,float(gy)*px),Vector2(float(gw)*px,float(gh)*px)),color,true)

func debug_player_sprite_ready() -> bool:
    return PLAYER_PX == 4.0 and rep_animation_state.length() > 0 and PLAYER_SCOUTER.g > 0.8
