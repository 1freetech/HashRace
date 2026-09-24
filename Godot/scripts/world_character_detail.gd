extends "res://scripts/world_customization.gd"

# Hash Race v0.053 character-detail layer.
# The playable operator and every world representative now share one detailed
# procedural pixel build inspired by the approved 64x96 character reference:
# spiky hair, headphones, one-eye scanner visor, layered face shading, armored
# suit panels, shoulder/knee guards, gloves, boots and a readable chest badge.
# No sprite sheet is required, so wardrobe colors and NPC company accents remain
# live data while nearest-neighbor pixel edges stay crisp at every camera zoom.

const CHARACTER_DETAIL_REVISION: int = 1
const DETAIL_OUTLINE := Color("090b0d")
const DETAIL_OUTLINE_SOFT := Color("241b18")
const DETAIL_METAL_DARK := Color("737c80")
const DETAIL_METAL := Color("dce3e2")
const DETAIL_METAL_HI := Color("f8fbf8")
const DETAIL_HAIR := Color("111315")
const DETAIL_HAIR_HI := Color("2d3030")
const DETAIL_VISOR_GREEN := Color("39ff75")
const DETAIL_VISOR_DARK := Color("0b6e43")
const DETAIL_VISOR_HI := Color("baffbd")
const DETAIL_NPC_SUIT := Color("e7ecea")

func _ready() -> void:
    super._ready()
    set_meta("hashrace_character_detail_revision", CHARACTER_DETAIL_REVISION)
    queue_redraw()

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if is_player:
        _draw_hashrace_player(pos)
        return

    # NPC representatives use the same construction and detail density as the
    # player. Company/partner accent color replaces the orange reference trim.
    var npc_skin := Color("8b553b")
    var npc_skin_hi := Color("c17f59")
    _draw_detailed_character(
        pos,
        npc_skin,
        npc_skin_hi,
        DETAIL_NPC_SUIT,
        accent.lightened(0.08),
        DETAIL_VISOR_GREEN,
        scanner,
        0,
        false
    )

func _draw_hashrace_player(pos: Vector2) -> void:
    var skin_idx: int = int(player.get("skin_tone_idx", CharacterCustomization.DEFAULT_SKIN_TONE))
    var gender_idx: int = int(player.get("gender_idx", CharacterCustomization.DEFAULT_GENDER))
    var outfit_idx: int = int(player.get("outfit_idx", CharacterCustomization.DEFAULT_OUTFIT))
    var tone: Dictionary = CharacterCustomization.skin_tone(skin_idx)
    var outfit: Dictionary = CharacterCustomization.outfit(outfit_idx)
    var rep: Dictionary = COMPANY_REPS[company_idx]

    _draw_detailed_character(
        pos,
        tone["skin"],
        tone["highlight"],
        outfit["primary"],
        outfit["secondary"],
        outfit["neon"],
        String(rep.get("scanner", "right")),
        gender_idx,
        true
    )

func _draw_detailed_character(
    pos: Vector2,
    skin: Color,
    skin_hi: Color,
    suit_primary: Color,
    suit_secondary: Color,
    visor: Color,
    scanner: String,
    presentation: int,
    is_player: bool
) -> void:
    var step: int = 0
    var bob: float = 0.0
    if is_player:
        var moving: bool = not rep_animation_state.ends_with("_idle")
        if moving:
            var wave: float = sin(rep_step_phase)
            step = 1 if wave >= 0.0 else -1
            bob = -2.0 if absf(wave) > 0.55 else 0.0
    else:
        # One-pixel idle lift adds life without making stationary NPCs look like
        # they are walking or shifting their interaction position.
        var idle_wave: float = sin(float(Time.get_ticks_msec()) / 310.0 + pos.x * 0.009)
        bob = -1.0 if idle_wave > 0.80 else 0.0

    var o: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(0.0, bob))
    var left_leg: int = step
    var right_leg: int = -step
    var left_arm: int = -step
    var right_arm: int = step
    var suit_shadow: Color = suit_primary.darkened(0.32)
    var suit_hi: Color = suit_primary.lightened(0.18)
    var trim_shadow: Color = suit_secondary.darkened(0.28)
    var trim_hi: Color = suit_secondary.lightened(0.22)
    var skin_shadow: Color = skin.darkened(0.28)
    var visor_dark: Color = visor.darkened(0.55)
    var visor_hi: Color = visor.lightened(0.42)

    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 48.0)), 29.0, 9.0)

    # Legs and chunky boots. Separate outline, shell, guards and sole pixels keep
    # the lower body readable even when the camera is zoomed out.
    _part(o, -5, 5 + left_leg, 4, 7, DETAIL_OUTLINE)
    _part(o, 1, 5 + right_leg, 4, 7, DETAIL_OUTLINE)
    _part(o, -4, 5 + left_leg, 3, 5, suit_primary)
    _part(o, 1, 5 + right_leg, 3, 5, suit_hi)
    _part(o, -4, 7 + left_leg, 3, 2, suit_secondary)
    _part(o, 1, 7 + right_leg, 3, 2, trim_hi)
    _part(o, -5, 9 + left_leg, 4, 3, DETAIL_OUTLINE)
    _part(o, 1, 9 + right_leg, 4, 3, DETAIL_OUTLINE)
    _part(o, -4, 9 + left_leg, 3, 2, suit_secondary)
    _part(o, 1, 9 + right_leg, 3, 2, suit_secondary)
    _part(o, -5, 11 + left_leg, 4, 1, DETAIL_METAL_HI)
    _part(o, 1, 11 + right_leg, 4, 1, DETAIL_METAL_HI)

    # Torso armor and waist. The outer black silhouette is intentionally one
    # source-pixel thick, matching the high-contrast reference character.
    _part(o, -7, -4, 14, 10, DETAIL_OUTLINE)
    _part(o, -6, -3, 12, 8, suit_primary)
    _part(o, -6, -3, 2, 8, suit_shadow)
    _part(o, 4, -3, 2, 8, suit_hi)
    _part(o, -5, 3, 10, 2, suit_shadow)
    _part(o, -4, 4, 8, 1, suit_secondary)
    _part(o, -5, -2, 2, 2, suit_secondary)
    _part(o, 3, -2, 2, 2, trim_hi)
    _part(o, -4, -1, 8, 1, DETAIL_METAL_HI)

    # Shoulder armor, articulated arms and gloves.
    _part(o, -9, -3 + left_arm, 3, 9, DETAIL_OUTLINE)
    _part(o, 6, -3 + right_arm, 3, 9, DETAIL_OUTLINE)
    _part(o, -8, -2 + left_arm, 2, 3, suit_secondary)
    _part(o, 6, -2 + right_arm, 2, 3, trim_hi)
    _part(o, -8, 1 + left_arm, 2, 3, suit_primary)
    _part(o, 6, 1 + right_arm, 2, 3, suit_hi)
    _part(o, -8, 3 + left_arm, 2, 1, DETAIL_METAL)
    _part(o, 6, 3 + right_arm, 2, 1, DETAIL_METAL)
    _part(o, -8, 4 + left_arm, 2, 2, DETAIL_OUTLINE)
    _part(o, 6, 4 + right_arm, 2, 2, DETAIL_OUTLINE)
    _part(o, -7, 4 + left_arm, 1, 1, trim_shadow)
    _part(o, 6, 4 + right_arm, 1, 1, trim_shadow)

    # Neck and face use three skin values instead of one flat rectangle.
    _part(o, -2, -6, 4, 2, DETAIL_OUTLINE)
    _part(o, -1, -6, 2, 2, skin_shadow)
    _part(o, -5, -13, 10, 8, DETAIL_OUTLINE_SOFT)
    _part(o, -4, -12, 8, 6, skin)
    _part(o, -4, -12, 2, 5, skin_shadow)
    _part(o, 2, -11, 2, 4, skin_hi)
    _part(o, -1, -7, 2, 1, skin_shadow)

    # Hair silhouette. Neutral/default presentation is the large spiky style in
    # the supplied reference; alternate presentations keep the same detail level.
    if presentation == 1:
        _part(o, -6, -18, 12, 5, DETAIL_HAIR)
        _part(o, -7, -16, 2, 10, DETAIL_HAIR)
        _part(o, 5, -16, 2, 10, DETAIL_HAIR)
        _part(o, -4, -19, 2, 4, DETAIL_HAIR)
        _part(o, 2, -19, 2, 4, DETAIL_HAIR)
        _part(o, -5, -17, 1, 3, DETAIL_HAIR_HI)
        _part(o, 4, -17, 1, 3, DETAIL_HAIR_HI)
    elif presentation == 2:
        _part(o, -6, -16, 12, 4, DETAIL_HAIR)
        _part(o, -7, -14, 3, 3, DETAIL_HAIR)
        _part(o, 4, -14, 3, 3, DETAIL_HAIR)
        _part(o, -3, -17, 2, 3, DETAIL_HAIR)
        _part(o, 1, -17, 2, 3, DETAIL_HAIR)
        _part(o, -1, -16, 2, 1, DETAIL_HAIR_HI)
    else:
        _part(o, -6, -16, 12, 4, DETAIL_HAIR)
        _part(o, -7, -15, 3, 4, DETAIL_HAIR)
        _part(o, 4, -15, 3, 4, DETAIL_HAIR)
        _part(o, -6, -18, 2, 5, DETAIL_HAIR)
        _part(o, -4, -19, 2, 6, DETAIL_HAIR)
        _part(o, -2, -18, 2, 4, DETAIL_HAIR)
        _part(o, 0, -20, 2, 7, DETAIL_HAIR)
        _part(o, 2, -18, 2, 5, DETAIL_HAIR)
        _part(o, 4, -19, 2, 6, DETAIL_HAIR)
        _part(o, 6, -17, 2, 5, DETAIL_HAIR)
        _part(o, -4, -17, 1, 2, DETAIL_HAIR_HI)
        _part(o, 0, -18, 1, 3, DETAIL_HAIR_HI)
        _part(o, 4, -17, 1, 2, DETAIL_HAIR_HI)

    # Headphones/ear protection echo the white circular earpieces in the source.
    _part(o, -7, -12, 2, 6, DETAIL_OUTLINE)
    _part(o, 5, -12, 2, 6, DETAIL_OUTLINE)
    _part(o, -6, -11, 1, 4, DETAIL_METAL)
    _part(o, 5, -11, 1, 4, DETAIL_METAL_HI)
    _part(o, -6, -9, 1, 2, DETAIL_METAL_DARK)
    _part(o, 5, -9, 1, 2, DETAIL_METAL_DARK)

    # Brow, uncovered eye, mouth and scanner visor. Scanner side still follows
    # each representative's data while the display retains the neon lens look.
    var visor_left: bool = scanner == "left"
    var visor_x: int = -5 if visor_left else 1
    var eye_x: int = 2 if visor_left else -3
    _part(o, eye_x - 1, -10, 3, 1, DETAIL_OUTLINE)
    _part(o, eye_x, -9, 2, 2, DETAIL_METAL_HI)
    _part(o, eye_x + 1, -9, 1, 2, DETAIL_OUTLINE)
    _part(o, -1, -8, 1, 1, skin_hi)
    _part(o, -1, -6, 3, 1, skin_shadow)
    _part(o, visor_x, -11, 5, 4, DETAIL_OUTLINE)
    _part(o, visor_x + 1, -10, 3, 2, visor_dark)
    _part(o, visor_x + 2, -10, 2, 1, visor)
    _part(o, visor_x + 2, -10, 1, 1, visor_hi)
    _part(o, -6 if visor_left else 5, -12, 1, 5, trim_shadow)

    # Chest badge: the player gets a tiny B/hash-race mark; NPCs get a compact
    # company-colored field ID so they share the build without looking cloned.
    if is_player:
        _part(o, -2, 0, 4, 4, DETAIL_METAL_HI)
        _part(o, -1, 0, 1, 4, DETAIL_OUTLINE)
        _part(o, 0, 0, 2, 1, DETAIL_OUTLINE)
        _part(o, 0, 1, 2, 1, DETAIL_OUTLINE)
        _part(o, 0, 3, 2, 1, DETAIL_OUTLINE)
        _part(o, 1, 2, 1, 1, DETAIL_OUTLINE)
    else:
        _part(o, -2, 0, 4, 4, DETAIL_OUTLINE)
        _part(o, -1, 1, 2, 2, suit_secondary)
        _part(o, 1, 1, 1, 2, visor)

func debug_character_detail_ready() -> bool:
    return CHARACTER_DETAIL_REVISION >= 1 and DETAIL_VISOR_GREEN.g > 0.9 and not player.is_empty()
