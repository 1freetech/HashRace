extends "res://scripts/world_visual_detail.gd"

# Hash Race v0.038 detailed procedural operator.
const PLAYER_PX: float = 4.0
const SKIN_DARK := Color("542f25")
const SKIN := Color("9b5b38")
const SKIN_LIGHT := Color("ca7b48")
const HAIR := Color("090d13")
const HAIR_MID := Color("191e2b")
const HAIR_HI := Color("30364b")
const BLACK := Color("05090d")
const SUIT_BLACK := Color("0a1218")
const SUIT_MID := Color("15242a")
const SUIT_HI := Color("26383d")
const NEON := Color("39ff75")
const NEON_DARK := Color("087c3d")
const NEON_HI := Color("a1ffba")
const METAL := Color("c8d2d0")
const WHITE := Color("f1f5e9")

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if not is_player:
        super._draw_tech_rep(pos, accent, scanner, false)
        return
    _draw_hashrace_player(pos)

func _draw_hashrace_player(pos: Vector2) -> void:
    var moving: bool = not rep_animation_state.ends_with("_idle")
    var phase: float = sin(rep_step_phase)
    var stride: int = 0
    if moving:
        stride = 2 if phase >= 0.0 else -2
    var arm_swing: int = -stride
    var bob: float = -4.0 if moving and absf(phase) > 0.45 else 0.0
    var o: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(0.0, bob))
    var back: bool = rep_facing == "up"
    var side_view: bool = rep_facing == "left" or rep_facing == "right"
    var mirror: int = -1 if rep_facing == "left" else 1
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0,42.0)),26.0,8.0)
    _legs(o,stride)
    _torso(o,arm_swing,back)
    _neck_head(o,back)
    _hair(o,back)
    _face(o,side_view,back,mirror)
    _headset_scouter(o,back,mirror)

func _legs(o: Vector2, s: int) -> void:
    _p(o,-4,5,8,2,SUIT_BLACK)
    _p(o,-3,5,6,1,NEON_DARK)
    for side_index in [-1,1]:
        var x: int = -4 if side_index < 0 else 1
        var dy: int = s if side_index < 0 else -s
        _p(o,x,6+dy,3,3,BLACK)
        _p(o,x+1,6+dy,2,2,SUIT_MID)
        _p(o,x,8+dy,3,2,BLACK)
        _p(o,x+1,8+dy,2,1,NEON)
        _p(o,x,10+dy,3,3,BLACK)
        _p(o,x+1,10+dy,2,2,SUIT_HI)
        _p(o,x,12+dy,4,2,BLACK)
        _p(o,x+1,12+dy,3,1,NEON)
        var toe_x: int = x-1 if side_index < 0 else x
        _p(o,toe_x,13+dy,5,1,BLACK)

func _torso(o: Vector2, swing: int, back: bool) -> void:
    _p(o,-7,-3,14,9,BLACK)
    _p(o,-6,-2,12,7,SUIT_BLACK)
    _p(o,-6,-2,3,3,NEON_DARK)
    _p(o,3,-2,3,3,NEON_DARK)
    _p(o,-5,-2,2,1,NEON)
    _p(o,3,-2,2,1,NEON)
    _p(o,-4,-1,8,5,SUIT_MID)
    _p(o,-3,0,6,3,SUIT_BLACK)
    _p(o,-3,0,6,1,NEON_DARK)
    _p(o,-1,0,2,1,NEON)
    _p(o,-4,4,8,2,BLACK)
    _p(o,-3,4,6,1,SUIT_HI)
    for side_index in [-1,1]:
        var x: int = -8 if side_index < 0 else 6
        var dy: int = swing if side_index < 0 else -swing
        _p(o,x,-1+dy,3,5,BLACK)
        _p(o,x+1,-1+dy,2,3,SUIT_MID)
        _p(o,x+1,0+dy,1,2,NEON)
        _p(o,x,3+dy,3,3,BLACK)
        _p(o,x+1,4+dy,1,1,SKIN)
        var finger_x: int = x if side_index < 0 else x+2
        _p(o,finger_x,4+dy,1,1,SKIN_LIGHT)
    if back:
        _p(o,-3,0,6,3,SUIT_HI)

func _neck_head(o: Vector2, back: bool) -> void:
    _p(o,-2,-5,4,2,BLACK)
    _p(o,-1,-5,2,2,SKIN_DARK)
    _p(o,-5,-12,10,8,BLACK)
    if back:
        _p(o,-4,-11,8,7,HAIR)
        return
    _p(o,-4,-11,8,7,SKIN)
    _p(o,-3,-10,2,2,SKIN_LIGHT)
    _p(o,3,-9,1,3,SKIN_DARK)

func _hair(o: Vector2, back: bool) -> void:
    _p(o,-5,-14,10,4,HAIR)
    _p(o,-6,-12,2,4,HAIR)
    _p(o,4,-12,2,4,HAIR)
    var tufts: Array[Vector2i] = [Vector2i(-5,-15),Vector2i(-3,-16),Vector2i(-1,-15),Vector2i(1,-17),Vector2i(3,-16),Vector2i(5,-14)]
    for i in range(tufts.size()):
        var t: Vector2i = tufts[i]
        _p(o,t.x,t.y,2,4,HAIR)
        _p(o,t.x+1,t.y+1,1,2,HAIR_MID)
        if i % 2 == 0:
            _p(o,t.x+1,t.y+1,1,1,HAIR_HI)
    if back:
        _p(o,-4,-11,8,6,HAIR)

func _face(o: Vector2, side_view: bool, back: bool, mirror: int) -> void:
    if back:
        return
    if side_view:
        var ex: int = -3 if mirror < 0 else 2
        _p(o,ex,-10,2,1,HAIR)
        _p(o,ex,-8,1,1,WHITE)
        var mouth_x: int = -2 if mirror < 0 else 1
        _p(o,mouth_x,-5,2,1,SKIN_DARK)
    else:
        _p(o,-3,-9,2,1,HAIR)
        _p(o,2,-9,2,1,HAIR)
        _p(o,-3,-8,1,1,WHITE)
        _p(o,2,-8,1,1,WHITE)
        _p(o,-3,-8,1,1,BLACK)
        _p(o,2,-8,1,1,BLACK)
        _p(o,-1,-6,2,1,SKIN_DARK)
        _p(o,-1,-5,3,1,BLACK)

func _headset_scouter(o: Vector2, back: bool, mirror: int) -> void:
    _p(o,-6,-10,2,5,BLACK)
    _p(o,5,-10,2,5,BLACK)
    _p(o,-5,-9,1,3,METAL)
    _p(o,5,-9,1,3,METAL)
    _p(o,-5,-8,1,2,NEON)
    _p(o,5,-8,1,2,NEON)
    if back:
        return
    var lx: int = -4 if mirror < 0 else 1
    _p(o,lx,-10,5,4,BLACK)
    _p(o,lx,-9,4,3,NEON_DARK)
    _p(o,lx+1,-9,3,2,NEON)
    _p(o,lx+1,-9,2,1,NEON_HI)
    _p(o,lx+3,-8,1,1,Color("d8ffe0"))

func _p(o: Vector2, x: int, y: int, w: int, h: int, c: Color) -> void:
    draw_rect(Rect2(o + Vector2(float(x)*PLAYER_PX,float(y)*PLAYER_PX),Vector2(float(w)*PLAYER_PX,float(h)*PLAYER_PX)),c,true)

func debug_player_sprite_ready() -> bool:
    return PLAYER_PX == 4.0 and rep_animation_state.length() > 0 and NEON.g > 0.9
