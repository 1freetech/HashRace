extends "res://scripts/world_v072.gd"

# Hash Race v0.073 high-density character renderer.
# The approved reference direction is recreated procedurally so the live player
# and every company/NPC representative can share the same crisp high-detail
# visual language without depending on a fixed sprite sheet. The renderer uses
# smaller source pixels at the same on-screen footprint, directional front/back/
# side silhouettes, varied body and hair builds, layered armor, headphones,
# neon scanner visors, gloves, boots, chest IDs, and reusable mining/victory
# action poses. Existing company accent colors and wardrobe choices stay live.
#
# Art rule: render at integer positions and let project.godot's nearest-neighbor
# canvas filtering scale the source pixels. This avoids blur while adding more
# source-pixel detail than the older broad-rectangle representative.

const V073_CHARACTER_REVISION: int = 2
const V073_PX: float = 3.0
const V073_BODY_VARIANTS: int = 5
const V073_HAIR_VARIANTS: int = 4
const V073_OUTLINE := Color("07090b")
const V073_OUTLINE_SOFT := Color("201816")
const V073_WHITE := Color("eef3f2")
const V073_WHITE_HI := Color("ffffff")
const V073_STEEL := Color("9aa7ac")
const V073_STEEL_DARK := Color("4c5960")
const V073_GRAPHITE := Color("14191f")
const V073_GRAPHITE_HI := Color("27323b")
const V073_HAIR := Color("101214")
const V073_HAIR_HI := Color("343238")
const V073_VISOR := Color("39ff75")
const V073_VISOR_DARK := Color("0b713f")
const V073_VISOR_HI := Color("baffc7")
const V073_ORANGE := Color("ff8d28")
const V073_GOLD := Color("ffc34d")
const V073_SPARK := Color("ffe06a")

const V073_POSES: Array[String] = [
    "idle_down", "idle_up", "idle_left", "idle_right",
    "walk_down", "walk_up", "walk_left", "walk_right",
    "run_down", "run_up", "run_left", "run_right",
    "mining", "victory"
]

const V073_NPC_SKINS: Array[Color] = [
    Color("3f251b"),
    Color("5b3323"),
    Color("7b4930"),
    Color("9a6444"),
    Color("b57b56"),
    Color("d49a72")
]

var v073_character_action: String = ""
var v073_character_action_until_ms: int = 0

func _ready() -> void:
    super._ready()
    set_meta("hashrace_character_detail_revision", V073_CHARACTER_REVISION)
    set_meta("hashrace_v073_character_revision", V073_CHARACTER_REVISION)
    queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)
    if not v073_character_action.is_empty() and Time.get_ticks_msec() >= v073_character_action_until_ms:
        v073_character_action = ""
        v073_character_action_until_ms = 0
        queue_redraw()

func play_character_action(action: String, duration_seconds: float = 0.9) -> void:
    if action not in ["mining", "victory"]:
        return
    v073_character_action = action
    v073_character_action_until_ms = Time.get_ticks_msec() + int(maxf(0.10, duration_seconds) * 1000.0)
    queue_redraw()

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if is_player:
        var skin_idx: int = int(player.get("skin_tone_idx", CharacterCustomization.DEFAULT_SKIN_TONE))
        var presentation_idx: int = int(player.get("gender_idx", CharacterCustomization.DEFAULT_GENDER))
        var outfit_idx: int = int(player.get("outfit_idx", CharacterCustomization.DEFAULT_OUTFIT))
        var tone: Dictionary = CharacterCustomization.skin_tone(skin_idx)
        var outfit: Dictionary = CharacterCustomization.outfit(outfit_idx)
        var scouter_color_idx: int = int(player.get("scouter_color_idx", CharacterCustomization.DEFAULT_SCOUTER_COLOR))
        var scouter_eye_idx: int = int(player.get("scouter_eye_idx", CharacterCustomization.DEFAULT_SCOUTER_EYE))
        var body_variant: int = (company_idx + presentation_idx + outfit_idx) % V073_BODY_VARIANTS
        var hair_variant: int = (presentation_idx * 2 + outfit_idx) % V073_HAIR_VARIANTS
        _draw_v073_character(
            pos,
            Color(tone["skin"]),
            Color(tone["highlight"]),
            Color(outfit["primary"]),
            Color(outfit["secondary"]),
            CharacterCustomization.scouter_lens_color(scouter_color_idx),
            CharacterCustomization.scouter_scanner_side(scouter_eye_idx),
            rep_facing,
            body_variant,
            hair_variant,
            rep_animation_state,
            v073_character_action,
            true
        )
        return

    var seed: int = _v073_seed(pos, accent)
    var npc_skin: Color = V073_NPC_SKINS[seed % V073_NPC_SKINS.size()]
    var npc_skin_hi: Color = npc_skin.lightened(0.20)
    var npc_facing: String = _v073_npc_facing(pos, seed)
    var npc_body: int = seed % V073_BODY_VARIANTS
    var npc_hair: int = int(seed / V073_BODY_VARIANTS) % V073_HAIR_VARIANTS
    var suit_primary: Color = V073_WHITE if seed % 3 != 1 else Color("d9e1e2")
    _draw_v073_character(
        pos,
        npc_skin,
        npc_skin_hi,
        suit_primary,
        accent.lightened(0.05),
        V073_VISOR,
        scanner,
        npc_facing,
        npc_body,
        npc_hair,
        "%s_idle" % npc_facing,
        "",
        false
    )

func _draw_v073_character(
    pos: Vector2,
    skin: Color,
    skin_hi: Color,
    suit_primary: Color,
    suit_secondary: Color,
    visor: Color,
    scanner: String,
    facing: String,
    body_variant: int,
    hair_variant: int,
    animation_state: String,
    action_state: String,
    is_player: bool
) -> void:
    var moving: bool = is_player and not animation_state.ends_with("_idle")
    var wave: float = sin(rep_step_phase)
    var stride: int = 0
    if moving:
        stride = 1 if wave >= 0.0 else -1
        if animation_state.begins_with("run_"):
            stride *= 2

    var bob: float = 0.0
    if moving and absf(wave) > 0.55:
        bob = -V073_PX
    if action_state == "victory":
        bob = -V073_PX

    var o: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(0.0, bob))
    var shadow_width: float = 24.0
    if body_variant == 1:
        shadow_width = 20.0
    elif body_variant == 2:
        shadow_width = 31.0
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 44.0)), shadow_width, 7.0)

    match facing:
        "up":
            _draw_v073_back(o, skin, skin_hi, suit_primary, suit_secondary, visor, body_variant, hair_variant, stride, is_player)
        "left":
            _draw_v073_side(o, skin, skin_hi, suit_primary, suit_secondary, visor, scanner, body_variant, hair_variant, stride, -1, is_player)
        "right":
            _draw_v073_side(o, skin, skin_hi, suit_primary, suit_secondary, visor, scanner, body_variant, hair_variant, stride, 1, is_player)
        _:
            _draw_v073_front(o, skin, skin_hi, suit_primary, suit_secondary, visor, scanner, body_variant, hair_variant, stride, is_player)

    if action_state == "mining":
        _draw_v073_mining_pose(o, facing, suit_secondary)
    elif action_state == "victory":
        _draw_v073_victory_pose(o, facing, skin, suit_secondary)

func _draw_v073_front(
    o: Vector2,
    skin: Color,
    skin_hi: Color,
    suit_primary: Color,
    suit_secondary: Color,
    visor: Color,
    scanner: String,
    body_variant: int,
    hair_variant: int,
    stride: int,
    is_player: bool
) -> void:
    var dims: Dictionary = _v073_body_dims(body_variant)
    var torso_half: int = int(dims["torso_half"])
    var shoulder_extra: int = int(dims["shoulder_extra"])
    var arm_w: int = int(dims["arm_w"])
    var boot_w: int = int(dims["boot_w"])
    var left_leg_step: int = stride
    var right_leg_step: int = -stride
    var left_arm_step: int = -stride
    var right_arm_step: int = stride

    var suit_shadow: Color = suit_primary.darkened(0.30)
    var suit_hi: Color = suit_primary.lightened(0.18)
    var trim_shadow: Color = suit_secondary.darkened(0.30)
    var trim_hi: Color = suit_secondary.lightened(0.24)
    var skin_shadow: Color = skin.darkened(0.25)
    var visor_dark: Color = visor.darkened(0.56)
    var visor_hi: Color = visor.lightened(0.42)

    # Boots and segmented legs. Three-pixel source grid creates visibly finer
    # knee, shin and sole detail than the previous four-pixel renderer.
    _v73_part(o, -5, 5 + left_leg_step, boot_w, 7, V073_OUTLINE)
    _v73_part(o, 1, 5 + right_leg_step, boot_w, 7, V073_OUTLINE)
    _v73_part(o, -4, 5 + left_leg_step, boot_w - 1, 5, suit_primary)
    _v73_part(o, 1, 5 + right_leg_step, boot_w - 1, 5, suit_hi)
    _v73_part(o, -4, 7 + left_leg_step, boot_w - 1, 2, suit_secondary)
    _v73_part(o, 1, 7 + right_leg_step, boot_w - 1, 2, trim_hi)
    _v73_part(o, -5, 10 + left_leg_step, boot_w, 3, V073_OUTLINE)
    _v73_part(o, 1, 10 + right_leg_step, boot_w, 3, V073_OUTLINE)
    _v73_part(o, -4, 10 + left_leg_step, boot_w - 1, 2, suit_secondary)
    _v73_part(o, 1, 10 + right_leg_step, boot_w - 1, 2, suit_secondary)
    _v73_part(o, -4, 12 + left_leg_step, boot_w - 1, 1, V073_WHITE_HI)
    _v73_part(o, 1, 12 + right_leg_step, boot_w - 1, 1, V073_WHITE_HI)
    _v73_part(o, -3, 6 + left_leg_step, 1, 2, suit_hi)
    _v73_part(o, 2, 6 + right_leg_step, 1, 2, suit_shadow)

    # Torso shell, abdomen, belt and shoulder armor.
    _v73_part(o, -torso_half - 1, -5, torso_half * 2 + 2, 11, V073_OUTLINE)
    _v73_part(o, -torso_half, -4, torso_half * 2, 9, suit_primary)
    _v73_part(o, -torso_half, -4, 2, 9, suit_shadow)
    _v73_part(o, torso_half - 2, -4, 2, 9, suit_hi)
    _v73_part(o, -torso_half + 1, -3, torso_half * 2 - 2, 2, V073_WHITE_HI)
    _v73_part(o, -torso_half + 1, 2, torso_half * 2 - 2, 2, V073_GRAPHITE)
    _v73_part(o, -torso_half + 2, 4, torso_half * 2 - 4, 2, suit_secondary)
    _v73_part(o, -1, 2, 2, 3, V073_GRAPHITE_HI)

    var left_shoulder_x: int = -torso_half - shoulder_extra - 2
    var right_shoulder_x: int = torso_half
    _v73_part(o, left_shoulder_x, -4 + left_arm_step, shoulder_extra + 2, 4, V073_OUTLINE)
    _v73_part(o, right_shoulder_x, -4 + right_arm_step, shoulder_extra + 2, 4, V073_OUTLINE)
    _v73_part(o, left_shoulder_x + 1, -3 + left_arm_step, shoulder_extra + 1, 2, suit_secondary)
    _v73_part(o, right_shoulder_x, -3 + right_arm_step, shoulder_extra + 1, 2, trim_hi)

    var left_arm_x: int = left_shoulder_x
    var right_arm_x: int = right_shoulder_x + shoulder_extra
    _v73_part(o, left_arm_x, 0 + left_arm_step, arm_w + 1, 7, V073_OUTLINE)
    _v73_part(o, right_arm_x, 0 + right_arm_step, arm_w + 1, 7, V073_OUTLINE)
    _v73_part(o, left_arm_x + 1, 0 + left_arm_step, arm_w, 4, suit_primary)
    _v73_part(o, right_arm_x, 0 + right_arm_step, arm_w, 4, suit_hi)
    _v73_part(o, left_arm_x + 1, 2 + left_arm_step, arm_w, 2, suit_secondary)
    _v73_part(o, right_arm_x, 2 + right_arm_step, arm_w, 2, trim_hi)
    _v73_part(o, left_arm_x + 1, 5 + left_arm_step, arm_w, 2, V073_GRAPHITE)
    _v73_part(o, right_arm_x, 5 + right_arm_step, arm_w, 2, V073_GRAPHITE)

    # Cyber mech-hand variant gets one visibly mechanical forearm/hand.
    if body_variant == 4:
        _v73_part(o, right_arm_x, 1 + right_arm_step, arm_w, 4, V073_STEEL_DARK)
        _v73_part(o, right_arm_x, 2 + right_arm_step, arm_w, 2, suit_secondary)
        _v73_part(o, right_arm_x, 5 + right_arm_step, arm_w + 1, 2, V073_STEEL)
        _v73_part(o, right_arm_x + 1, 5 + right_arm_step, 1, 1, V073_GOLD)

    # Neck, face, hair and headset.
    _v73_part(o, -2, -7, 4, 2, V073_OUTLINE)
    _v73_part(o, -1, -7, 2, 2, skin_shadow)
    _v73_part(o, -6, -15, 12, 9, V073_OUTLINE_SOFT)
    _v73_part(o, -5, -14, 10, 7, skin)
    _v73_part(o, -5, -14, 2, 6, skin_shadow)
    _v73_part(o, 3, -13, 2, 5, skin_hi)
    _v73_part(o, -1, -8, 2, 1, skin_shadow)
    _draw_v073_hair_front(o, hair_variant)

    _v73_part(o, -7, -13, 2, 6, V073_OUTLINE)
    _v73_part(o, 5, -13, 2, 6, V073_OUTLINE)
    _v73_part(o, -6, -12, 1, 4, V073_STEEL)
    _v73_part(o, 5, -12, 1, 4, V073_WHITE_HI)
    _v73_part(o, -6, -10, 1, 2, suit_secondary)
    _v73_part(o, 5, -10, 1, 2, suit_secondary)

    var visor_left: bool = scanner == "left"
    var visor_x: int = -5 if visor_left else 1
    var eye_x: int = 2 if visor_left else -4
    _v73_part(o, eye_x, -11, 3, 1, V073_OUTLINE)
    _v73_part(o, eye_x + 1, -10, 2, 2, V073_WHITE_HI)
    _v73_part(o, eye_x + 2, -10, 1, 2, V073_OUTLINE)
    _v73_part(o, -1, -9, 1, 1, skin_hi)
    _v73_part(o, -2, -7, 4, 1, skin_shadow)
    _v73_part(o, visor_x, -12, 5, 4, V073_OUTLINE)
    _v73_part(o, visor_x + 1, -11, 3, 2, visor_dark)
    _v73_part(o, visor_x + 2, -11, 2, 1, visor)
    _v73_part(o, visor_x + 2, -11, 1, 1, visor_hi)

    # Chest identity badge. Player keeps the B-shaped mark; NPCs use a company
    # color + visor status mark so they share the rig without becoming clones.
    if is_player:
        _v73_part(o, -2, -1, 4, 4, V073_WHITE_HI)
        _v73_part(o, -1, -1, 1, 4, V073_OUTLINE)
        _v73_part(o, 0, -1, 2, 1, V073_OUTLINE)
        _v73_part(o, 0, 0, 2, 1, V073_OUTLINE)
        _v73_part(o, 0, 2, 2, 1, V073_OUTLINE)
        _v73_part(o, 1, 1, 1, 1, V073_OUTLINE)
    else:
        _v73_part(o, -2, -1, 4, 4, V073_OUTLINE)
        _v73_part(o, -1, 0, 2, 2, suit_secondary)
        _v73_part(o, 1, 0, 1, 2, visor)

func _draw_v073_back(
    o: Vector2,
    skin: Color,
    skin_hi: Color,
    suit_primary: Color,
    suit_secondary: Color,
    visor: Color,
    body_variant: int,
    hair_variant: int,
    stride: int,
    is_player: bool
) -> void:
    var dims: Dictionary = _v073_body_dims(body_variant)
    var torso_half: int = int(dims["torso_half"])
    var shoulder_extra: int = int(dims["shoulder_extra"])
    var arm_w: int = int(dims["arm_w"])
    var boot_w: int = int(dims["boot_w"])
    var suit_shadow: Color = suit_primary.darkened(0.31)
    var suit_hi: Color = suit_primary.lightened(0.16)
    var trim_hi: Color = suit_secondary.lightened(0.18)

    _v73_part(o, -5, 5 + stride, boot_w, 7, V073_OUTLINE)
    _v73_part(o, 1, 5 - stride, boot_w, 7, V073_OUTLINE)
    _v73_part(o, -4, 5 + stride, boot_w - 1, 5, suit_shadow)
    _v73_part(o, 1, 5 - stride, boot_w - 1, 5, suit_primary)
    _v73_part(o, -4, 8 + stride, boot_w - 1, 2, suit_secondary)
    _v73_part(o, 1, 8 - stride, boot_w - 1, 2, trim_hi)
    _v73_part(o, -5, 10 + stride, boot_w, 3, V073_OUTLINE)
    _v73_part(o, 1, 10 - stride, boot_w, 3, V073_OUTLINE)
    _v73_part(o, -4, 10 + stride, boot_w - 1, 2, suit_secondary)
    _v73_part(o, 1, 10 - stride, boot_w - 1, 2, suit_secondary)

    _v73_part(o, -torso_half - 1, -5, torso_half * 2 + 2, 11, V073_OUTLINE)
    _v73_part(o, -torso_half, -4, torso_half * 2, 9, suit_primary)
    _v73_part(o, -torso_half, -4, 2, 9, suit_shadow)
    _v73_part(o, torso_half - 2, -4, 2, 9, suit_hi)

    # Rear backpack / cooling pack and circular hash-race identifier.
    _v73_part(o, -4, -3, 8, 7, V073_GRAPHITE)
    _v73_part(o, -3, -2, 6, 5, V073_STEEL_DARK)
    _v73_part(o, -2, -1, 4, 3, V073_OUTLINE)
    _v73_part(o, -1, 0, 2, 1, suit_secondary)
    _v73_part(o, 0, -1, 1, 3, visor)
    _v73_part(o, -4, 3, 8, 1, suit_secondary)

    var left_shoulder_x: int = -torso_half - shoulder_extra - 2
    var right_shoulder_x: int = torso_half
    _v73_part(o, left_shoulder_x, -4 - stride, shoulder_extra + 2, 4, V073_OUTLINE)
    _v73_part(o, right_shoulder_x, -4 + stride, shoulder_extra + 2, 4, V073_OUTLINE)
    _v73_part(o, left_shoulder_x + 1, -3 - stride, shoulder_extra + 1, 2, suit_secondary)
    _v73_part(o, right_shoulder_x, -3 + stride, shoulder_extra + 1, 2, trim_hi)
    _v73_part(o, left_shoulder_x, 0 - stride, arm_w + 1, 7, V073_OUTLINE)
    _v73_part(o, right_shoulder_x + shoulder_extra, 0 + stride, arm_w + 1, 7, V073_OUTLINE)
    _v73_part(o, left_shoulder_x + 1, 0 - stride, arm_w, 4, suit_shadow)
    _v73_part(o, right_shoulder_x + shoulder_extra, 0 + stride, arm_w, 4, suit_primary)
    _v73_part(o, left_shoulder_x + 1, 5 - stride, arm_w, 2, V073_GRAPHITE)
    _v73_part(o, right_shoulder_x + shoulder_extra, 5 + stride, arm_w, 2, V073_GRAPHITE)

    _v73_part(o, -2, -7, 4, 2, V073_OUTLINE)
    _v73_part(o, -1, -7, 2, 2, skin.darkened(0.25))
    _v73_part(o, -6, -15, 12, 9, V073_OUTLINE_SOFT)
    _v73_part(o, -5, -14, 10, 7, skin)
    _v73_part(o, -5, -14, 10, 2, skin_hi.darkened(0.10))
    _draw_v073_hair_back(o, hair_variant)
    _v73_part(o, -7, -13, 2, 6, V073_OUTLINE)
    _v73_part(o, 5, -13, 2, 6, V073_OUTLINE)
    _v73_part(o, -6, -12, 1, 4, V073_STEEL)
    _v73_part(o, 5, -12, 1, 4, V073_WHITE_HI)
    _v73_part(o, -6, -10, 1, 1, visor)
    _v73_part(o, 5, -10, 1, 1, visor)

    if body_variant == 4:
        _v73_part(o, right_shoulder_x + shoulder_extra, 1 + stride, arm_w, 4, V073_STEEL_DARK)
        _v73_part(o, right_shoulder_x + shoulder_extra, 5 + stride, arm_w + 1, 2, V073_STEEL)

func _draw_v073_side(
    o: Vector2,
    skin: Color,
    skin_hi: Color,
    suit_primary: Color,
    suit_secondary: Color,
    visor: Color,
    scanner: String,
    body_variant: int,
    hair_variant: int,
    stride: int,
    flip: int,
    is_player: bool
) -> void:
    var dims: Dictionary = _v073_body_dims(body_variant)
    var torso_half: int = int(dims["torso_half"])
    var suit_shadow: Color = suit_primary.darkened(0.30)
    var suit_hi: Color = suit_primary.lightened(0.18)
    var trim_hi: Color = suit_secondary.lightened(0.22)
    var skin_shadow: Color = skin.darkened(0.25)

    # Far leg and arm first, then torso, then near limbs to preserve readable
    # profile depth when the character walks left/right.
    _v73_mpart(o, -2, 6 - stride, 3, 6, V073_OUTLINE, flip)
    _v73_mpart(o, -1, 6 - stride, 2, 4, suit_shadow, flip)
    _v73_mpart(o, -2, 10 - stride, 4, 3, V073_OUTLINE, flip)
    _v73_mpart(o, -1, 10 - stride, 3, 2, suit_secondary.darkened(0.18), flip)

    _v73_mpart(o, -3, -4, torso_half + 2, 10, V073_OUTLINE, flip)
    _v73_mpart(o, -2, -3, torso_half, 8, suit_primary, flip)
    _v73_mpart(o, -2, -3, 2, 8, suit_shadow, flip)
    _v73_mpart(o, 0, -2, torso_half - 2, 2, suit_hi, flip)
    _v73_mpart(o, -1, 3, torso_half - 1, 2, suit_secondary, flip)

    _v73_mpart(o, -5, -3 - stride, 3, 8, V073_OUTLINE, flip)
    _v73_mpart(o, -4, -2 - stride, 2, 5, suit_primary, flip)
    _v73_mpart(o, -4, 0 - stride, 2, 2, suit_secondary, flip)
    _v73_mpart(o, -4, 3 - stride, 2, 2, V073_GRAPHITE, flip)

    _v73_mpart(o, 1, 0 + stride, 3, 8, V073_OUTLINE, flip)
    if body_variant == 4:
        _v73_mpart(o, 1, 1 + stride, 2, 5, V073_STEEL_DARK, flip)
        _v73_mpart(o, 1, 2 + stride, 2, 2, suit_secondary, flip)
        _v73_mpart(o, 1, 6 + stride, 3, 2, V073_STEEL, flip)
    else:
        _v73_mpart(o, 1, 1 + stride, 2, 5, suit_hi, flip)
        _v73_mpart(o, 1, 3 + stride, 2, 2, trim_hi, flip)
        _v73_mpart(o, 1, 6 + stride, 2, 2, V073_GRAPHITE, flip)

    _v73_mpart(o, 0, 6 + stride, 3, 6, V073_OUTLINE, flip)
    _v73_mpart(o, 0, 6 + stride, 2, 4, suit_primary, flip)
    _v73_mpart(o, 0, 8 + stride, 2, 2, suit_secondary, flip)
    _v73_mpart(o, 0, 10 + stride, 4, 3, V073_OUTLINE, flip)
    _v73_mpart(o, 1, 10 + stride, 3, 2, suit_secondary, flip)
    _v73_mpart(o, 1, 12 + stride, 3, 1, V073_WHITE_HI, flip)

    _v73_mpart(o, -2, -7, 4, 2, V073_OUTLINE, flip)
    _v73_mpart(o, -1, -7, 2, 2, skin_shadow, flip)
    _v73_mpart(o, -4, -15, 9, 9, V073_OUTLINE_SOFT, flip)
    _v73_mpart(o, -3, -14, 7, 7, skin, flip)
    _v73_mpart(o, -3, -14, 2, 6, skin_shadow, flip)
    _v73_mpart(o, 2, -13, 2, 5, skin_hi, flip)
    _draw_v073_hair_side(o, hair_variant, flip)

    _v73_mpart(o, -5, -13, 2, 6, V073_OUTLINE, flip)
    _v73_mpart(o, -4, -12, 1, 4, V073_STEEL, flip)
    _v73_mpart(o, -4, -10, 1, 2, suit_secondary, flip)

    # The profile scanner sits on the forward side of the face regardless of the
    # source character's configured eye; scanner keeps its company color status.
    _v73_mpart(o, 1, -12, 5, 4, V073_OUTLINE, flip)
    _v73_mpart(o, 2, -11, 3, 2, visor.darkened(0.56), flip)
    _v73_mpart(o, 3, -11, 2, 1, visor, flip)
    _v73_mpart(o, 3, -11, 1, 1, visor.lightened(0.42), flip)
    _v73_mpart(o, 0, -7, 3, 1, skin_shadow, flip)

    if is_player:
        _v73_mpart(o, -1, -1, 3, 4, V073_WHITE_HI, flip)
        _v73_mpart(o, 0, 0, 1, 3, V073_OUTLINE, flip)
    else:
        _v73_mpart(o, -1, -1, 3, 4, V073_OUTLINE, flip)
        _v73_mpart(o, 0, 0, 1, 2, suit_secondary, flip)

func _draw_v073_hair_front(o: Vector2, hair_variant: int) -> void:
    match hair_variant:
        1:
            # Coils / rounded afro.
            _v73_part(o, -6, -19, 12, 5, V073_HAIR)
            _v73_part(o, -7, -17, 3, 5, V073_HAIR)
            _v73_part(o, 4, -17, 3, 5, V073_HAIR)
            _v73_part(o, -5, -20, 3, 3, V073_HAIR)
            _v73_part(o, -1, -21, 3, 4, V073_HAIR)
            _v73_part(o, 3, -20, 3, 3, V073_HAIR)
            _v73_part(o, -4, -18, 1, 2, V073_HAIR_HI)
            _v73_part(o, 0, -19, 1, 2, V073_HAIR_HI)
            _v73_part(o, 4, -18, 1, 2, V073_HAIR_HI)
        2:
            # Short recon cut.
            _v73_part(o, -6, -18, 12, 4, V073_HAIR)
            _v73_part(o, -7, -16, 3, 4, V073_HAIR)
            _v73_part(o, 4, -16, 3, 4, V073_HAIR)
            _v73_part(o, -3, -19, 6, 2, V073_HAIR)
            _v73_part(o, 1, -18, 2, 1, V073_HAIR_HI)
        3:
            # High ponytail / tied rear mass.
            _v73_part(o, -6, -18, 12, 4, V073_HAIR)
            _v73_part(o, -7, -16, 3, 4, V073_HAIR)
            _v73_part(o, 4, -16, 3, 4, V073_HAIR)
            _v73_part(o, 2, -21, 4, 4, V073_HAIR)
            _v73_part(o, 4, -23, 3, 4, V073_HAIR)
            _v73_part(o, 5, -25, 2, 3, V073_HAIR)
            _v73_part(o, 3, -20, 1, 2, V073_HAIR_HI)
        _:
            # Signature multi-spike silhouette.
            _v73_part(o, -6, -18, 12, 4, V073_HAIR)
            _v73_part(o, -7, -16, 3, 5, V073_HAIR)
            _v73_part(o, 4, -16, 3, 5, V073_HAIR)
            _v73_part(o, -6, -21, 2, 6, V073_HAIR)
            _v73_part(o, -4, -22, 2, 7, V073_HAIR)
            _v73_part(o, -2, -20, 2, 5, V073_HAIR)
            _v73_part(o, 0, -23, 2, 8, V073_HAIR)
            _v73_part(o, 2, -20, 2, 5, V073_HAIR)
            _v73_part(o, 4, -22, 2, 7, V073_HAIR)
            _v73_part(o, 6, -20, 2, 5, V073_HAIR)
            _v73_part(o, -4, -19, 1, 2, V073_HAIR_HI)
            _v73_part(o, 0, -21, 1, 3, V073_HAIR_HI)
            _v73_part(o, 4, -19, 1, 2, V073_HAIR_HI)

func _draw_v073_hair_back(o: Vector2, hair_variant: int) -> void:
    _draw_v073_hair_front(o, hair_variant)
    _v73_part(o, -5, -14, 10, 3, V073_HAIR)
    if hair_variant == 3:
        _v73_part(o, 4, -18, 3, 7, V073_HAIR)
        _v73_part(o, 5, -13, 2, 5, V073_HAIR)

func _draw_v073_hair_side(o: Vector2, hair_variant: int, flip: int) -> void:
    match hair_variant:
        1:
            _v73_mpart(o, -5, -20, 10, 5, V073_HAIR, flip)
            _v73_mpart(o, -6, -18, 4, 6, V073_HAIR, flip)
            _v73_mpart(o, 2, -18, 4, 5, V073_HAIR, flip)
            _v73_mpart(o, 0, -20, 1, 2, V073_HAIR_HI, flip)
        2:
            _v73_mpart(o, -5, -18, 10, 4, V073_HAIR, flip)
            _v73_mpart(o, -6, -16, 3, 4, V073_HAIR, flip)
            _v73_mpart(o, 2, -16, 3, 3, V073_HAIR, flip)
        3:
            _v73_mpart(o, -5, -18, 10, 4, V073_HAIR, flip)
            _v73_mpart(o, -6, -16, 3, 4, V073_HAIR, flip)
            _v73_mpart(o, -7, -21, 4, 4, V073_HAIR, flip)
            _v73_mpart(o, -8, -23, 3, 4, V073_HAIR, flip)
        _:
            _v73_mpart(o, -5, -18, 10, 4, V073_HAIR, flip)
            _v73_mpart(o, -6, -16, 3, 5, V073_HAIR, flip)
            _v73_mpart(o, -5, -21, 2, 6, V073_HAIR, flip)
            _v73_mpart(o, -3, -22, 2, 7, V073_HAIR, flip)
            _v73_mpart(o, -1, -20, 2, 5, V073_HAIR, flip)
            _v73_mpart(o, 1, -22, 2, 7, V073_HAIR, flip)
            _v73_mpart(o, 3, -20, 2, 5, V073_HAIR, flip)

func _draw_v073_mining_pose(o: Vector2, facing: String, accent: Color) -> void:
    var side: float = -1.0 if facing == "left" else 1.0
    if facing == "up":
        side = 1.0
    var hand_a: Vector2 = o + Vector2(5.0 * side * V073_PX, -1.0 * V073_PX)
    var hand_b: Vector2 = o + Vector2(2.0 * side * V073_PX, 3.0 * V073_PX)
    var tool_top: Vector2 = o + Vector2(11.0 * side * V073_PX, -12.0 * V073_PX)
    var tool_tip: Vector2 = o + Vector2(14.0 * side * V073_PX, -8.0 * V073_PX)
    draw_line(hand_b, tool_top, V073_OUTLINE, 5.0)
    draw_line(hand_b, tool_top, Color("7f5a37"), 2.0)
    draw_line(tool_top + Vector2(-5.0 * side, -2.0), tool_tip, V073_STEEL, 4.0)
    draw_line(tool_top, tool_top + Vector2(7.0 * side, 4.0), V073_WHITE_HI, 2.0)
    draw_circle(hand_a, 4.0, accent.darkened(0.12))

func _draw_v073_victory_pose(o: Vector2, facing: String, skin: Color, accent: Color) -> void:
    var side: int = -1 if facing == "left" else 1
    var arm_x: int = 5 if side > 0 else -7
    _v73_part(o, arm_x, -8, 3, 9, V073_OUTLINE)
    _v73_part(o, arm_x + (0 if side > 0 else 1), -7, 2, 6, accent)
    _v73_part(o, arm_x + (0 if side > 0 else 1), -10, 2, 3, V073_GRAPHITE)
    _v73_part(o, arm_x + (0 if side > 0 else 1), -11, 2, 2, skin)
    _draw_v073_spark(o + Vector2(12.0 * V073_PX, -18.0 * V073_PX))
    _draw_v073_spark(o + Vector2(-11.0 * V073_PX, -14.0 * V073_PX))
    _draw_v073_spark(o + Vector2(9.0 * V073_PX, -25.0 * V073_PX))

func _draw_v073_spark(center: Vector2) -> void:
    draw_rect(Rect2(center + Vector2(-1.0, -6.0), Vector2(3.0, 13.0)), V073_SPARK, true)
    draw_rect(Rect2(center + Vector2(-6.0, -1.0), Vector2(13.0, 3.0)), V073_SPARK, true)

func _v073_body_dims(body_variant: int) -> Dictionary:
    match body_variant:
        1:
            return {"torso_half": 4, "shoulder_extra": 1, "arm_w": 2, "boot_w": 4}
        2:
            return {"torso_half": 7, "shoulder_extra": 2, "arm_w": 3, "boot_w": 5}
        3:
            return {"torso_half": 4, "shoulder_extra": 2, "arm_w": 2, "boot_w": 4}
        4:
            return {"torso_half": 5, "shoulder_extra": 2, "arm_w": 2, "boot_w": 4}
        _:
            return {"torso_half": 5, "shoulder_extra": 2, "arm_w": 2, "boot_w": 4}

func _v073_seed(pos: Vector2, accent: Color) -> int:
    var spatial: int = int(roundf(pos.x * 0.31 + pos.y * 0.67))
    return absi(spatial + accent.to_html(false).hash())

func _v073_npc_facing(pos: Vector2, seed: int) -> String:
    if pos.distance_to(rep_pos) <= 250.0:
        return _v073_direction_to(pos, rep_pos)
    var directions: Array[String] = ["down", "left", "right", "down"]
    return directions[seed % directions.size()]

func _v073_direction_to(origin: Vector2, target: Vector2) -> String:
    var delta: Vector2 = target - origin
    if absf(delta.x) > absf(delta.y):
        return "right" if delta.x > 0.0 else "left"
    return "down" if delta.y > 0.0 else "up"

func _v73_part(o: Vector2, x: int, y: int, w: int, h: int, color: Color) -> void:
    if w <= 0 or h <= 0:
        return
    draw_rect(
        Rect2(
            o + Vector2(float(x) * V073_PX, float(y) * V073_PX),
            Vector2(float(w) * V073_PX, float(h) * V073_PX)
        ),
        color,
        true
    )

func _v73_mpart(o: Vector2, x: int, y: int, w: int, h: int, color: Color, flip: int) -> void:
    var draw_x: int = x
    if flip < 0:
        draw_x = -x - w
    _v73_part(o, draw_x, y, w, h, color)

func debug_character_detail_ready() -> bool:
    return (
        V073_CHARACTER_REVISION >= 2
        and V073_PX < 4.0
        and V073_BODY_VARIANTS >= 5
        and V073_HAIR_VARIANTS >= 4
        and V073_POSES.size() >= 14
        and not player.is_empty()
    )

func debug_character_pose_library() -> Array[String]:
    return V073_POSES.duplicate()

func debug_character_body_variant_count() -> int:
    return V073_BODY_VARIANTS

func debug_v073_ready() -> bool:
    return debug_v072_ready() and debug_character_detail_ready()
