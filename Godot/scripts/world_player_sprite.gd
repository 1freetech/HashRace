extends "res://scripts/world_visual_upgrade.gd"

# Hash Race v0.046 detailed animated field operator.
# The player is still original procedural art, now drawn on a finer 3px logical
# grid with readable face, hair, visor, straps, cargo pockets, knee pads,
# gloves, boots, backpack, belt hardware and directional head treatment.
const PLAYER_DETAIL_REVISION: int = 2
const PX: float = 3.0
const SKIN := Color("9a5d3c")
const SKIN_SHADOW := Color("6d3f2c")
const SKIN_HI := Color("d08a5b")
const HAIR := Color("11141b")
const HAIR_HI := Color("303244")
const BLACK := Color("070b11")
const ARMOR := Color("101923")
const ARMOR_MID := Color("1b2a32")
const ARMOR_HI := Color("36505a")
const NEON := Color("39ff75")
const NEON_HI := Color("a4ffaf")
const NEON_DARK := Color("0b6e43")
const METAL := Color("d7dfdf")
const METAL_DARK := Color("6c7d82")
const BOOT := Color("05090d")

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if not is_player:
        super._draw_tech_rep(pos, accent, scanner, false)
        return
    _draw_hashrace_player(pos)

func _draw_hashrace_player(pos: Vector2) -> void:
    var moving: bool = not rep_animation_state.ends_with("_idle")
    var wave: float = sin(rep_step_phase)
    var step: int = 0
    var bob: float = 0.0
    if moving:
        step = 1 if wave >= 0.0 else -1
        bob = -2.0 if absf(wave) > 0.55 else 0.0
    var o: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(0.0, bob))
    var left_leg: int = step
    var right_leg: int = -step
    var left_arm: int = -step
    var right_arm: int = step

    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 39.0)), 25.0, 8.0)

    # Backpack and antenna sit behind the body to create depth.
    _part(o, -8, -4, 4, 12, BLACK)
    _part(o, -7, -3, 3, 10, ARMOR_MID)
    _part(o, -7, -2, 1, 7, NEON_DARK)
    _part(o, -8, -8, 1, 5, METAL_DARK)
    _part(o, -8, -9, 1, 2, NEON)

    # Legs: cargo panels, knee pads, ankle bands and steel-toe boots.
    _part(o, -6, 5 + left_leg, 5, 8, BLACK)
    _part(o, 1, 5 + right_leg, 5, 8, BLACK)
    _part(o, -5, 5 + left_leg, 4, 6, ARMOR_MID)
    _part(o, 1, 5 + right_leg, 4, 6, ARMOR_MID)
    _part(o, -5, 6 + left_leg, 2, 3, ARMOR_HI)
    _part(o, 3, 6 + right_leg, 2, 3, ARMOR_HI)
    _part(o, -5, 9 + left_leg, 4, 2, BLACK)
    _part(o, 1, 9 + right_leg, 4, 2, BLACK)
    _part(o, -4, 9 + left_leg, 2, 1, NEON_DARK)
    _part(o, 2, 9 + right_leg, 2, 1, NEON_DARK)
    _part(o, -6, 11 + left_leg, 5, 3, BOOT)
    _part(o, 1, 11 + right_leg, 5, 3, BOOT)
    _part(o, -6, 13 + left_leg, 5, 1, METAL_DARK)
    _part(o, 1, 13 + right_leg, 5, 1, METAL_DARK)

    # Torso silhouette with layered undersuit and hard armor.
    _part(o, -8, -5, 16, 11, BLACK)
    _part(o, -7, -4, 14, 9, ARMOR_MID)
    _part(o, -7, -4, 3, 9, ARMOR)
    _part(o, 4, -4, 3, 9, ARMOR_HI)
    _part(o, -5, -3, 10, 7, BLACK)
    _part(o, -4, -2, 8, 5, ARMOR)
    _part(o, -3, -1, 6, 3, ARMOR_MID)

    # Neon shoulder modules, chest rails and center power/status stripe.
    _part(o, -7, -4, 3, 2, NEON)
    _part(o, 4, -4, 3, 2, NEON)
    _part(o, -5, 2, 10, 2, ARMOR_HI)
    _part(o, -4, 2, 3, 1, NEON_DARK)
    _part(o, 1, 2, 3, 1, NEON_DARK)
    _part(o, -1, -2, 2, 6, BLACK)
    _part(o, -1, -1, 2, 4, NEON)
    _part(o, 0, -1, 1, 2, NEON_HI)

    # Belt, buckle, side pouches and clipped field tool.
    _part(o, -6, 4, 12, 2, BLACK)
    _part(o, -1, 4, 2, 2, NEON)
    _part(o, -5, 5, 3, 2, ARMOR)
    _part(o, 3, 5, 3, 2, ARMOR)
    _part(o, 6, 3, 2, 4, BLACK)
    _part(o, 6, 4, 1, 2, METAL)

    # Arms with elbow plates, wrist devices and gloves.
    _part(o, -10, -3 + left_arm, 3, 8, BLACK)
    _part(o, 7, -3 + right_arm, 3, 8, BLACK)
    _part(o, -9, -2 + left_arm, 2, 5, ARMOR_HI)
    _part(o, 7, -2 + right_arm, 2, 5, ARMOR_HI)
    _part(o, -10, 0 + left_arm, 3, 2, ARMOR)
    _part(o, 7, 0 + right_arm, 3, 2, ARMOR)
    _part(o, -9, 2 + left_arm, 2, 2, NEON_DARK)
    _part(o, 7, 2 + right_arm, 2, 2, NEON_DARK)
    _part(o, -9, 4 + left_arm, 2, 2, SKIN_SHADOW)
    _part(o, 7, 4 + right_arm, 2, 2, SKIN)

    # Neck and head outline.
    _part(o, -2, -8, 4, 3, BLACK)
    _part(o, -1, -8, 3, 3, SKIN_SHADOW)
    _part(o, -6, -16, 12, 9, BLACK)
    _part(o, -5, -15, 10, 7, SKIN)
    _part(o, -5, -14, 2, 6, SKIN_SHADOW)
    _part(o, 3, -14, 2, 5, SKIN_HI)

    if rep_facing == "up":
        _draw_head_back(o)
    elif rep_facing == "left":
        _draw_head_side(o, true)
    elif rep_facing == "right":
        _draw_head_side(o, false)
    else:
        _draw_head_front(o)

    # Spiked/textured hair silhouette, deliberately chunkier than the old cap.
    _part(o, -6, -18, 12, 3, HAIR)
    _part(o, -7, -16, 2, 5, HAIR)
    _part(o, 5, -16, 2, 5, HAIR)
    _part(o, -6, -19, 2, 4, HAIR)
    _part(o, -4, -20, 2, 5, HAIR)
    _part(o, -2, -19, 2, 4, HAIR)
    _part(o, 0, -20, 2, 5, HAIR)
    _part(o, 2, -19, 2, 4, HAIR)
    _part(o, 4, -20, 2, 5, HAIR)
    _part(o, -5, -18, 1, 2, HAIR_HI)
    _part(o, -1, -19, 1, 2, HAIR_HI)
    _part(o, 3, -19, 1, 2, HAIR_HI)

    # Headset band, ear modules and neon one-eye scanner.
    _part(o, -7, -15, 2, 6, BLACK)
    _part(o, 5, -15, 2, 6, BLACK)
    _part(o, -6, -14, 1, 4, METAL)
    _part(o, 5, -14, 1, 4, METAL)
    _part(o, -6, -13, 1, 2, NEON)
    _part(o, 5, -13, 1, 2, NEON)
    _draw_scanner(o)

    # Small forearm tablet visible when idle, tool glow while walking.
    if not moving:
        var tablet_x: int = 9 if rep_facing != "right" else -12
        _part(o, tablet_x, 0, 3, 4, BLACK)
        _part(o, tablet_x + 1, 1, 2, 2, Color("173c48"))
        _part(o, tablet_x + 1, 1, 2, 1, NEON_HI)
    else:
        _part(o, 8, 1 + right_arm, 1, 2, NEON_HI)

func _draw_head_front(o: Vector2) -> void:
    # Brows, two eyes, nose bridge, cheeks and mouth make the face read as a
    # person rather than a helmet block at normal camera scale.
    _part(o, -4, -14, 3, 1, Color("2a1712"))
    _part(o, 2, -14, 2, 1, Color("2a1712"))
    _part(o, -3, -13, 1, 1, BLACK)
    _part(o, 3, -13, 1, 1, BLACK)
    _part(o, -2, -12, 1, 1, SKIN_HI)
    _part(o, 0, -12, 1, 2, SKIN_HI)
    _part(o, -3, -10, 2, 1, SKIN_SHADOW)
    _part(o, 2, -10, 2, 1, SKIN_SHADOW)
    _part(o, -1, -9, 3, 1, Color("4a281d"))

func _draw_head_side(o: Vector2, facing_left: bool) -> void:
    var eye_x: int = -3 if facing_left else 3
    var nose_x: int = -5 if facing_left else 4
    _part(o, eye_x, -13, 1, 1, BLACK)
    _part(o, eye_x, -14, 2 if facing_left else 1, 1, Color("2a1712"))
    _part(o, nose_x, -11, 1, 2, SKIN_HI)
    _part(o, -1, -9, 2, 1, Color("4a281d"))

func _draw_head_back(o: Vector2) -> void:
    _part(o, -5, -15, 10, 5, HAIR)
    _part(o, -3, -11, 6, 2, SKIN_SHADOW)
    _part(o, -4, -12, 2, 1, HAIR_HI)
    _part(o, 2, -12, 2, 1, HAIR_HI)

func _draw_scanner(o: Vector2) -> void:
    var lens_x: int = -5
    if rep_facing == "left":
        lens_x = -6
    elif rep_facing == "right":
        lens_x = 2
    elif rep_facing == "up":
        lens_x = -2
    _part(o, lens_x, -15, 5, 3, BLACK)
    _part(o, lens_x + 1, -14, 4, 2, NEON_DARK)
    _part(o, lens_x + 2, -14, 2, 1, NEON)
    _part(o, lens_x + 2, -14, 1, 1, NEON_HI)

func _part(o: Vector2, x: int, y: int, w: int, h: int, color: Color) -> void:
    draw_rect(Rect2(o + Vector2(float(x) * PX, float(y) * PX), Vector2(float(w) * PX, float(h) * PX)), color, true)

func debug_player_sprite_ready() -> bool:
    return PLAYER_DETAIL_REVISION >= 2 and PX == 3.0 and NEON.g > 0.9 and rep_animation_state.length() > 0
