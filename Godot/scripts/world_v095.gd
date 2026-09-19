extends "res://scripts/world_v094.gd"

# Hash Race v0.095 roadside-world + live scouter customization pass.
# All interactive facilities are validated against the same road/water geometry
# used by the pixel tilemap. The player's one-eye scouter now uses the color and
# eye-side choices from campaign setup and the in-game Wardrobe at render time.

const V095_ROADSIDE_REVISION: int = 1
const V095_BUILDING_PLACER = preload("res://scripts/building_placer.gd")

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v095_roadside_revision", V095_ROADSIDE_REVISION)
    set_meta("hashrace_v095_building_road_overlaps", V095_BUILDING_PLACER.road_overlap_count(entities))
    set_meta("hashrace_v095_building_water_overlaps", V095_BUILDING_PLACER.water_overlap_count(entities))
    queue_redraw()

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if not is_player:
        super._draw_tech_rep(pos, accent, scanner, false)
        return

    var skin_idx: int = int(player.get("skin_tone_idx", CharacterCustomization.DEFAULT_SKIN_TONE))
    var presentation_idx: int = int(player.get("gender_idx", CharacterCustomization.DEFAULT_GENDER))
    var outfit_idx: int = int(player.get("outfit_idx", CharacterCustomization.DEFAULT_OUTFIT))
    var scouter_color_idx: int = int(player.get("scouter_color_idx", CharacterCustomization.DEFAULT_SCOUTER_COLOR))
    var scouter_eye_idx: int = int(player.get("scouter_eye_idx", CharacterCustomization.DEFAULT_SCOUTER_EYE))
    var tone: Dictionary = CharacterCustomization.skin_tone(skin_idx)
    var outfit: Dictionary = CharacterCustomization.outfit(outfit_idx)
    var visor: Color = CharacterCustomization.scouter_lens_color(scouter_color_idx)
    var active_scanner: String = CharacterCustomization.scouter_scanner_side(scouter_eye_idx)
    var body_variant: int = (company_idx + presentation_idx + outfit_idx) % V073_BODY_VARIANTS
    var hair_variant: int = (presentation_idx * 2 + outfit_idx) % V073_HAIR_VARIANTS

    _draw_v073_character(
        pos,
        Color(tone["skin"]),
        Color(tone["highlight"]),
        Color(outfit["primary"]),
        Color(outfit["secondary"]),
        visor,
        active_scanner,
        rep_facing,
        body_variant,
        hair_variant,
        rep_animation_state,
        v073_character_action,
        true
    )

    var bob: float = 0.0
    if not rep_animation_state.ends_with("_idle") and absf(sin(rep_step_phase)) > 0.55:
        bob = -V073_PX
    if v073_character_action == "victory":
        bob = -V073_PX
    var origin: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(0.0, bob))
    _draw_v087_microdetail(
        origin,
        rep_facing,
        active_scanner,
        Color(tone["skin"]),
        Color(outfit["secondary"]),
        visor,
        _v087_player_hair_tint(outfit_idx),
        true
    )

func debug_v095_ready() -> bool:
    return (
        V095_ROADSIDE_REVISION == 1
        and debug_v094_navigation_ready()
        and V095_BUILDING_PLACER.all_buildings_clear_of_roads(entities)
        and V095_BUILDING_PLACER.all_buildings_clear_of_water(entities)
        and CharacterCustomization.SCOUTER_COLORS.size() >= 8
        and CharacterCustomization.SCOUTER_EYES.size() == 2
    )

func debug_building_road_overlap_count() -> int:
    return V095_BUILDING_PLACER.road_overlap_count(entities)

func debug_building_water_overlap_count() -> int:
    return V095_BUILDING_PLACER.water_overlap_count(entities)

func debug_live_scouter_color() -> Color:
    return CharacterCustomization.scouter_lens_color(
        int(player.get("scouter_color_idx", CharacterCustomization.DEFAULT_SCOUTER_COLOR))
    )

func debug_live_scouter_side() -> String:
    return CharacterCustomization.scouter_scanner_side(
        int(player.get("scouter_eye_idx", CharacterCustomization.DEFAULT_SCOUTER_EYE))
    )
