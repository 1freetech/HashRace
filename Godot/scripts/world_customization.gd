extends "res://scripts/world_texture_spacing.gd"

# Hash Race v0.052 character customization.
# Identity choices are free. Cosmetic outfit skins are bought with the same
# in-game company cash used by the mining simulation, then can be equipped at
# any time from the compact Wardrobe panel.

const CharacterCustomization = preload("res://scripts/character_customization.gd")
const CHARACTER_CUSTOMIZATION_REVISION: int = 1

var wardrobe_installed: bool = false
var wardrobe_layer: CanvasLayer
var wardrobe_panel: Panel
var wardrobe_summary: Label
var wardrobe_feedback: Label
var skin_tone_button: Button
var gender_button: Button
var scouter_color_button: Button
var scouter_eye_button: Button
var outfit_buttons: Array[Button] = []

func _initialize_player() -> void:
    super._initialize_player()
    var skin_idx: int = CharacterCustomization.DEFAULT_SKIN_TONE
    var gender_idx: int = CharacterCustomization.DEFAULT_GENDER
    var outfit_idx: int = CharacterCustomization.DEFAULT_OUTFIT
    var scouter_color_idx: int = CharacterCustomization.DEFAULT_SCOUTER_COLOR
    var scouter_eye_idx: int = CharacterCustomization.DEFAULT_SCOUTER_EYE
    var suit_color_idx: int = CharacterCustomization.DEFAULT_SUIT_COLOR
    if get_tree().has_meta("hashrace_character_skin_tone"):
        skin_idx = clampi(int(get_tree().get_meta("hashrace_character_skin_tone")), 0, CharacterCustomization.SKIN_TONES.size() - 1)
    if get_tree().has_meta("hashrace_character_gender"):
        gender_idx = clampi(int(get_tree().get_meta("hashrace_character_gender")), 0, CharacterCustomization.GENDERS.size() - 1)
    if get_tree().has_meta("hashrace_character_outfit"):
        outfit_idx = clampi(int(get_tree().get_meta("hashrace_character_outfit")), 0, CharacterCustomization.OUTFITS.size() - 1)
    if get_tree().has_meta("hashrace_character_scouter_color"):
        scouter_color_idx = clampi(int(get_tree().get_meta("hashrace_character_scouter_color")), 0, CharacterCustomization.SCOUTER_COLORS.size() - 1)
    if get_tree().has_meta("hashrace_character_scouter_eye"):
        scouter_eye_idx = clampi(int(get_tree().get_meta("hashrace_character_scouter_eye")), 0, CharacterCustomization.SCOUTER_EYES.size() - 1)
    if get_tree().has_meta("hashrace_character_suit_color"):
        suit_color_idx = clampi(int(get_tree().get_meta("hashrace_character_suit_color")), 0, CharacterCustomization.SUIT_COLORS.size() - 1)

    player["skin_tone_idx"] = skin_idx
    player["gender_idx"] = gender_idx
    player["outfit_idx"] = outfit_idx
    player["scouter_color_idx"] = scouter_color_idx
    player["scouter_eye_idx"] = scouter_eye_idx
    player["suit_color_idx"] = suit_color_idx
    var owned: Dictionary = {CharacterCustomization.DEFAULT_OUTFIT: true}
    if outfit_idx == CharacterCustomization.DEFAULT_OUTFIT:
        owned[outfit_idx] = true
    player["owned_outfits"] = owned

func _ready() -> void:
    super._ready()
    set_meta("hashrace_character_customization_revision", CHARACTER_CUSTOMIZATION_REVISION)
    call_deferred("_try_install_wardrobe")
    queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)
    if not wardrobe_installed:
        _try_install_wardrobe()
    elif is_instance_valid(wardrobe_panel) and wardrobe_panel.visible:
        _refresh_wardrobe()

func _try_install_wardrobe() -> void:
    if wardrobe_installed or not compact_ui_installed or not is_instance_valid(drawer_panel):
        return

    # Make one extra compact-menu slot without adding another always-visible HUD.
    drawer_panel.size.y = 544.0
    for child in drawer_panel.get_children():
        if child is Button and String((child as Button).text) == "CLEAR PANELS":
            (child as Button).position.y = 494.0
    _add_menu_button("WARDROBE", 450.0, Callable(self, "_show_wardrobe"))

    wardrobe_layer = CanvasLayer.new()
    wardrobe_layer.name = "WardrobeLayer"
    wardrobe_layer.layer = 31
    add_child(wardrobe_layer)

    wardrobe_panel = Panel.new()
    wardrobe_panel.position = Vector2(900.0, 138.0)
    wardrobe_panel.size = Vector2(516.0, 680.0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("06141df5")
    style.border_width_left = 3
    style.border_width_top = 3
    style.border_width_right = 3
    style.border_width_bottom = 3
    style.border_color = Color("39ff75")
    style.corner_radius_top_left = 7
    style.corner_radius_top_right = 7
    style.corner_radius_bottom_left = 7
    style.corner_radius_bottom_right = 7
    wardrobe_panel.add_theme_stylebox_override("panel", style)
    wardrobe_layer.add_child(wardrobe_panel)

    var title := Label.new()
    title.position = Vector2(18.0, 14.0)
    title.size = Vector2(480.0, 30.0)
    title.text = "CHARACTER WARDROBE"
    title.add_theme_font_size_override("font_size", 19)
    title.add_theme_color_override("font_color", Color("39ff75"))
    wardrobe_panel.add_child(title)

    wardrobe_summary = Label.new()
    wardrobe_summary.position = Vector2(18.0, 48.0)
    wardrobe_summary.size = Vector2(480.0, 50.0)
    wardrobe_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    wardrobe_summary.add_theme_font_size_override("font_size", 11)
    wardrobe_summary.add_theme_color_override("font_color", Color("c5e7ed"))
    wardrobe_panel.add_child(wardrobe_summary)

    skin_tone_button = _wardrobe_button(18.0, 108.0, 232.0, "", Callable(self, "_cycle_skin_tone"))
    gender_button = _wardrobe_button(266.0, 108.0, 232.0, "", Callable(self, "_cycle_gender"))
    scouter_color_button = _wardrobe_button(18.0, 158.0, 232.0, "", Callable(self, "_cycle_scouter_color"))
    scouter_eye_button = _wardrobe_button(266.0, 158.0, 232.0, "", Callable(self, "_cycle_scouter_eye"))

    var outfits_header := Label.new()
    outfits_header.position = Vector2(18.0, 208.0)
    outfits_header.size = Vector2(480.0, 28.0)
    outfits_header.text = "OUTFIT SKINS // BUY WITH GAME CASH"
    outfits_header.add_theme_font_size_override("font_size", 13)
    outfits_header.add_theme_color_override("font_color", Color("52e7ff"))
    wardrobe_panel.add_child(outfits_header)

    outfit_buttons.clear()
    for i in range(CharacterCustomization.OUTFITS.size()):
        var button := _wardrobe_button(18.0, 242.0 + float(i) * 50.0, 480.0, "", Callable(self, "_choose_outfit").bind(i))
        outfit_buttons.append(button)

    wardrobe_feedback = Label.new()
    wardrobe_feedback.position = Vector2(18.0, 548.0)
    wardrobe_feedback.size = Vector2(480.0, 44.0)
    wardrobe_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    wardrobe_feedback.add_theme_font_size_override("font_size", 11)
    wardrobe_feedback.add_theme_color_override("font_color", Color("ffcf72"))
    wardrobe_panel.add_child(wardrobe_feedback)

    var close := _wardrobe_button(18.0, 612.0, 480.0, "CLOSE WARDROBE", Callable(self, "_hide_wardrobe"))
    close.add_theme_color_override("font_color", Color("d8f8e3"))

    wardrobe_layer.visible = false
    wardrobe_installed = true
    _refresh_wardrobe()

func _wardrobe_button(x: float, y: float, width: float, text_value: String, action: Callable) -> Button:
    var button := Button.new()
    button.position = Vector2(x, y)
    button.size = Vector2(width, 40.0)
    button.text = text_value
    button.add_theme_font_size_override("font_size", 11)
    button.pressed.connect(action)
    wardrobe_panel.add_child(button)
    return button

func _show_wardrobe() -> void:
    _clear_detail_panels()
    if is_instance_valid(wardrobe_layer):
        wardrobe_layer.visible = true
    _refresh_wardrobe()
    _close_drawer_after_choice()

func _hide_wardrobe() -> void:
    if is_instance_valid(wardrobe_layer):
        wardrobe_layer.visible = false

func _clear_detail_panels() -> void:
    if is_instance_valid(wardrobe_layer):
        wardrobe_layer.visible = false
    super._clear_detail_panels()

func _cycle_skin_tone() -> void:
    var next_idx: int = (int(player.get("skin_tone_idx", CharacterCustomization.DEFAULT_SKIN_TONE)) + 1) % CharacterCustomization.SKIN_TONES.size()
    player["skin_tone_idx"] = next_idx
    get_tree().set_meta("hashrace_character_skin_tone", next_idx)
    wardrobe_feedback.text = "Skin tone changed. Identity customization is free."
    _refresh_wardrobe()
    queue_redraw()

func _cycle_gender() -> void:
    var next_idx: int = (int(player.get("gender_idx", CharacterCustomization.DEFAULT_GENDER)) + 1) % CharacterCustomization.GENDERS.size()
    player["gender_idx"] = next_idx
    get_tree().set_meta("hashrace_character_gender", next_idx)
    wardrobe_feedback.text = "Gender / presentation changed. Identity customization is free."
    _refresh_wardrobe()
    queue_redraw()

func _cycle_scouter_color() -> void:
    var next_idx: int = (int(player.get("scouter_color_idx", CharacterCustomization.DEFAULT_SCOUTER_COLOR)) + 1) % CharacterCustomization.SCOUTER_COLORS.size()
    player["scouter_color_idx"] = next_idx
    get_tree().set_meta("hashrace_character_scouter_color", next_idx)
    wardrobe_feedback.text = "Scouter lens changed. Suit colors stay independent."
    _refresh_wardrobe()
    queue_redraw()

func _cycle_scouter_eye() -> void:
    var next_idx: int = (int(player.get("scouter_eye_idx", CharacterCustomization.DEFAULT_SCOUTER_EYE)) + 1) % CharacterCustomization.SCOUTER_EYES.size()
    player["scouter_eye_idx"] = next_idx
    get_tree().set_meta("hashrace_character_scouter_eye", next_idx)
    wardrobe_feedback.text = "Scouter moved to %s." % String(CharacterCustomization.scouter_eye(next_idx)["name"])
    _refresh_wardrobe()
    queue_redraw()

func _choose_outfit(outfit_idx: int) -> void:
    outfit_idx = clampi(outfit_idx, 0, CharacterCustomization.OUTFITS.size() - 1)
    var owned: Dictionary = player.get("owned_outfits", {CharacterCustomization.DEFAULT_OUTFIT: true})
    if bool(owned.get(outfit_idx, false)):
        player["outfit_idx"] = outfit_idx
        get_tree().set_meta("hashrace_character_outfit", outfit_idx)
        wardrobe_feedback.text = "%s equipped." % CharacterCustomization.outfit_name(outfit_idx)
        _refresh_wardrobe()
        queue_redraw()
        return

    var cost: float = CharacterCustomization.outfit_cost(outfit_idx)
    if float(player["cash"]) < cost:
        wardrobe_feedback.text = "Need $%d game cash to unlock %s." % [int(cost), CharacterCustomization.outfit_name(outfit_idx)]
        return

    player["cash"] = float(player["cash"]) - cost
    owned[outfit_idx] = true
    player["owned_outfits"] = owned
    player["outfit_idx"] = outfit_idx
    get_tree().set_meta("hashrace_character_outfit", outfit_idx)
    wardrobe_feedback.text = "Bought and equipped %s for $%d." % [CharacterCustomization.outfit_name(outfit_idx), int(cost)]
    _refresh_ui()
    _refresh_wardrobe()
    queue_redraw()

func _refresh_wardrobe() -> void:
    if not wardrobe_installed or player.is_empty():
        return
    var skin_idx: int = int(player.get("skin_tone_idx", CharacterCustomization.DEFAULT_SKIN_TONE))
    var gender_idx: int = int(player.get("gender_idx", CharacterCustomization.DEFAULT_GENDER))
    var outfit_idx: int = int(player.get("outfit_idx", CharacterCustomization.DEFAULT_OUTFIT))
    var scouter_color_idx: int = int(player.get("scouter_color_idx", CharacterCustomization.DEFAULT_SCOUTER_COLOR))
    var scouter_eye_idx: int = int(player.get("scouter_eye_idx", CharacterCustomization.DEFAULT_SCOUTER_EYE))
    var owned: Dictionary = player.get("owned_outfits", {CharacterCustomization.DEFAULT_OUTFIT: true})

    wardrobe_summary.text = "Cash $%d  •  Equipped: %s\nIdentity + scouter settings are free to change." % [
        int(player["cash"]), CharacterCustomization.outfit_name(outfit_idx)
    ]
    skin_tone_button.text = "SKIN TONE: %s" % String(CharacterCustomization.skin_tone(skin_idx)["name"])
    gender_button.text = "GENDER: %s" % String(CharacterCustomization.gender(gender_idx)["name"])
    scouter_color_button.text = "SCOUTER: %s" % String(CharacterCustomization.scouter_color(scouter_color_idx)["name"])
    scouter_eye_button.text = "EYE: %s" % String(CharacterCustomization.scouter_eye(scouter_eye_idx)["name"])

    for i in range(outfit_buttons.size()):
        var button: Button = outfit_buttons[i]
        var outfit: Dictionary = CharacterCustomization.outfit(i)
        var state: String = "$%d" % int(outfit["cost"])
        if i == outfit_idx:
            state = "EQUIPPED"
        elif bool(owned.get(i, false)):
            state = "OWNED // EQUIP"
        elif float(outfit["cost"]) <= 0.0:
            state = "FREE"
        button.text = "%s  //  %s" % [String(outfit["name"]), state]

# Replace only the playable representative sprite. NPCs retain their own accent
# colors, while the player's skin tone, presentation and purchased outfit drive
# the live pixel renderer.
func _draw_hashrace_player(pos: Vector2) -> void:
    var skin_idx: int = int(player.get("skin_tone_idx", CharacterCustomization.DEFAULT_SKIN_TONE))
    var gender_idx: int = int(player.get("gender_idx", CharacterCustomization.DEFAULT_GENDER))
    var outfit_idx: int = int(player.get("outfit_idx", CharacterCustomization.DEFAULT_OUTFIT))
    var tone: Dictionary = CharacterCustomization.skin_tone(skin_idx)
    var outfit: Dictionary = CharacterCustomization.outfit(outfit_idx)
    var skin: Color = tone["skin"]
    var skin_hi: Color = tone["highlight"]
    var armor: Color = outfit["primary"]
    var armor_hi: Color = outfit["secondary"]
    var neon: Color = outfit["neon"]
    var neon_dark: Color = neon.darkened(0.55)
    var scouter_color_idx: int = int(player.get("scouter_color_idx", CharacterCustomization.DEFAULT_SCOUTER_COLOR))
    var scouter_eye_idx: int = int(player.get("scouter_eye_idx", CharacterCustomization.DEFAULT_SCOUTER_EYE))
    var scouter_neon: Color = CharacterCustomization.scouter_lens_color(scouter_color_idx)
    var scouter_dark: Color = scouter_neon.darkened(0.55)
    var black := Color("070b11")
    var hair := Color("11141b")
    var hair_hi := Color("292b3c")
    var metal := Color("d7dfdf")

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

    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 40.0)), 25.0, 8.0)
    _part(o, -5, 5 + left_leg, 4, 5, black)
    _part(o, 1, 5 + right_leg, 4, 5, black)
    _part(o, -4, 5 + left_leg, 3, 4, armor)
    _part(o, 1, 5 + right_leg, 3, 4, armor)
    _part(o, -5, 8 + left_leg, 4, 2, neon)
    _part(o, 1, 8 + right_leg, 4, 2, neon)

    # Presentation changes silhouette and hair while keeping identical gameplay.
    var torso_left: int = -7
    var torso_width: int = 14
    if gender_idx == 1:
        torso_left = -6
        torso_width = 12
    elif gender_idx == 2:
        torso_left = -7
        torso_width = 14
    _part(o, torso_left, -3, torso_width, 9, black)
    _part(o, torso_left + 1, -2, torso_width - 2, 7, armor)
    _part(o, -5, 2, 10, 3, armor_hi)
    _part(o, -4, -1, 8, 5, black)
    _part(o, -3, 0, 6, 3, armor)
    _part(o, -6, -2, 2, 2, neon)
    _part(o, 4, -2, 2, 2, neon)
    _part(o, -8, -1 + left_arm, 3, 6, black)
    _part(o, 5, -1 + right_arm, 3, 6, black)
    _part(o, -7, 0 + left_arm, 2, 3, armor_hi)
    _part(o, 5, 0 + right_arm, 2, 3, armor_hi)
    _part(o, -7, 1 + left_arm, 1, 2, neon)
    _part(o, 6, 1 + right_arm, 1, 2, neon)
    _part(o, -7, 4 + left_arm, 2, 2, skin)
    _part(o, 5, 4 + right_arm, 2, 2, skin)

    _part(o, -5, -11, 10, 7, black)
    _part(o, -4, -10, 8, 6, skin)
    _part(o, -3, -9, 2, 1, skin_hi)
    _part(o, -3, -7, 1, 1, black)
    _part(o, 2, -7, 1, 1, black)
    _part(o, -1, -5, 2, 1, black)

    if gender_idx == 1:
        # Longer side/back hair presentation.
        _part(o, -5, -15, 10, 4, hair)
        _part(o, -6, -13, 2, 8, hair)
        _part(o, 4, -13, 2, 8, hair)
        _part(o, -4, -14, 1, 3, hair_hi)
        _part(o, 3, -14, 1, 3, hair_hi)
    elif gender_idx == 2:
        # Short cropped hair presentation.
        _part(o, -5, -14, 10, 3, hair)
        _part(o, -5, -12, 2, 2, hair)
        _part(o, 3, -12, 2, 2, hair)
        _part(o, -2, -14, 3, 1, hair_hi)
    else:
        # Neutral / mixed-length default presentation.
        _part(o, -5, -14, 10, 4, hair)
        _part(o, -6, -12, 2, 4, hair)
        _part(o, 4, -12, 2, 4, hair)
        _part(o, -3, -15, 2, 4, hair)
        _part(o, 1, -15, 2, 4, hair)
        _part(o, 0, -14, 1, 2, hair_hi)

    # Scanner visor and suit badge inherit the equipped outfit's neon color.
    _part(o, -6, -10, 2, 5, black)
    _part(o, 5, -10, 2, 5, black)
    _part(o, -5, -9, 1, 3, metal)
    _part(o, 5, -9, 1, 3, metal)
    _part(o, -5, -8, 1, 2, neon)
    _part(o, 5, -8, 1, 2, neon)
    var scanner_side: String = CharacterCustomization.scouter_scanner_side(scouter_eye_idx)
    var visor_x: int = -6 if scanner_side == "left" else 1
    _part(o, visor_x, -9, 5, 4, black)
    _part(o, visor_x, -8, 4, 2, scouter_dark)
    _part(o, visor_x + 1, -8, 2, 1, scouter_neon)
    _part(o, visor_x + 1, -8, 1, 1, scouter_neon.lightened(0.45))
    _part(o, -2, 0, 4, 3, black)
    _part(o, -1, 0, 2, 3, neon)

func debug_character_customization_ready() -> bool:
    return wardrobe_installed and CharacterCustomization.SKIN_TONES.size() >= 6 and CharacterCustomization.OUTFITS.size() >= 6

func debug_character_skin_tone() -> int:
    return int(player.get("skin_tone_idx", -1))

func debug_character_gender() -> int:
    return int(player.get("gender_idx", -1))

func debug_character_outfit() -> int:
    return int(player.get("outfit_idx", -1))

func debug_character_scouter_color() -> int:
    return int(player.get("scouter_color_idx", -1))

func debug_character_scouter_eye() -> int:
    return int(player.get("scouter_eye_idx", -1))

func debug_character_suit_color() -> int:
    return int(player.get("suit_color_idx", -1))

func debug_paid_outfits_use_game_cash() -> bool:
    for i in range(1, CharacterCustomization.OUTFITS.size()):
        if CharacterCustomization.outfit_cost(i) <= 0.0:
            return false
    return true
