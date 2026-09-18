extends Control

const Profiles = preload("res://scripts/company_profiles.gd")
const CharacterCustomization = preload("res://scripts/character_customization.gd")
const CharacterPreview = preload("res://scripts/character_creator_preview.gd")
const GREEN := Color("64ff8c")
const CYAN := Color("52e7ff")
const WHITE := Color("dffaff")
const PANEL := Color("091119f2")

var company_option: OptionButton
var years_option: OptionButton
var skin_tone_option: OptionButton
var gender_option: OptionButton
var hair_style_option: OptionButton
var hair_color_option: OptionButton
var suit_color_option: OptionButton
var accent_color_option: OptionButton
var character_preview: Control
var company_label: Label
var summary_label: Label
var character_summary: Label

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    build_background()
    build_menu()

func build_background() -> void:
    var bg := ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color("061015")
    add_child(bg)
    for x in range(0, 1440, 48):
        var line := ColorRect.new()
        line.position = Vector2(x, 0)
        line.size = Vector2(1, 900)
        line.color = Color("0b1b22")
        bg.add_child(line)
    for y in range(0, 900, 48):
        var line := ColorRect.new()
        line.position = Vector2(0, y)
        line.size = Vector2(1440, 1)
        line.color = Color("0b1b22")
        bg.add_child(line)

func build_menu() -> void:
    var panel := Panel.new()
    panel.position = Vector2(190, 30)
    panel.size = Vector2(1060, 840)
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = Color("28596b")
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    panel.add_theme_stylebox_override("panel", style)
    add_child(panel)

    var title := Label.new()
    title.position = Vector2(34, 14)
    title.size = Vector2(992, 44)
    title.text = "HASH RACE // NEW CAMPAIGN"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", GREEN)
    panel.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(40, 58)
    subtitle.size = Vector2(980, 38)
    subtitle.text = "Pick a Bitcoin mining company, then create the representative you will walk around the world as."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 14)
    subtitle.add_theme_color_override("font_color", WHITE)
    panel.add_child(subtitle)

    var company_hdr := Label.new()
    company_hdr.position = Vector2(78, 100)
    company_hdr.size = Vector2(300, 28)
    company_hdr.text = "MINING COMPANY"
    company_hdr.add_theme_font_size_override("font_size", 17)
    company_hdr.add_theme_color_override("font_color", CYAN)
    panel.add_child(company_hdr)

    company_option = OptionButton.new()
    company_option.position = Vector2(78, 130)
    company_option.size = Vector2(684, 42)
    company_option.add_theme_font_size_override("font_size", 14)
    for i in range(Profiles.PROFILES.size()):
        var profile: Dictionary = Profiles.PROFILES[i]
        company_option.add_item("%s  //  %s  //  %s" % [profile["name"], profile["posture"], profile["strengths"]], i)
    company_option.item_selected.connect(_on_company_changed)
    panel.add_child(company_option)

    company_label = Label.new()
    company_label.position = Vector2(78, 180)
    company_label.size = Vector2(684, 176)
    company_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    company_label.add_theme_font_size_override("font_size", 11)
    company_label.add_theme_color_override("font_color", Color("b8dce5"))
    panel.add_child(company_label)

    var character_hdr := Label.new()
    character_hdr.position = Vector2(48, 365)
    character_hdr.size = Vector2(300, 28)
    character_hdr.text = "YOUR CHARACTER"
    character_hdr.add_theme_font_size_override("font_size", 17)
    character_hdr.add_theme_color_override("font_color", CYAN)
    panel.add_child(character_hdr)

    var skin_label := Label.new()
    skin_label.position = Vector2(48, 397)
    skin_label.size = Vector2(320, 22)
    skin_label.text = "SKIN TONE"
    skin_label.add_theme_font_size_override("font_size", 11)
    skin_label.add_theme_color_override("font_color", Color("b8dce5"))
    panel.add_child(skin_label)

    var gender_label := Label.new()
    gender_label.position = Vector2(280, 397)
    gender_label.size = Vector2(320, 22)
    gender_label.text = "GENDER / PRESENTATION"
    gender_label.add_theme_font_size_override("font_size", 11)
    gender_label.add_theme_color_override("font_color", Color("b8dce5"))
    panel.add_child(gender_label)

    skin_tone_option = OptionButton.new()
    skin_tone_option.position = Vector2(48, 420)
    skin_tone_option.size = Vector2(220, 40)
    skin_tone_option.add_theme_font_size_override("font_size", 13)
    for i in range(CharacterCustomization.SKIN_TONES.size()):
        skin_tone_option.add_item(String(CharacterCustomization.SKIN_TONES[i]["name"]), i)
    skin_tone_option.select(CharacterCustomization.DEFAULT_SKIN_TONE)
    skin_tone_option.item_selected.connect(_on_character_changed)
    panel.add_child(skin_tone_option)

    gender_option = OptionButton.new()
    gender_option.position = Vector2(280, 420)
    gender_option.size = Vector2(220, 40)
    gender_option.add_theme_font_size_override("font_size", 13)
    for i in range(CharacterCustomization.GENDERS.size()):
        gender_option.add_item(String(CharacterCustomization.GENDERS[i]["name"]), i)
    gender_option.select(CharacterCustomization.DEFAULT_GENDER)
    gender_option.item_selected.connect(_on_character_changed)
    panel.add_child(gender_option)

    var customization_rows := [
        ["HAIR STYLE", CharacterCustomization.HAIR_STYLES, CharacterCustomization.DEFAULT_HAIR_STYLE],
        ["HAIR COLOR", CharacterCustomization.HAIR_COLORS, CharacterCustomization.DEFAULT_HAIR_COLOR],
        ["SUIT COLOR", CharacterCustomization.SUIT_COLORS, CharacterCustomization.DEFAULT_SUIT_COLOR],
        ["ACCENT", CharacterCustomization.ACCENT_COLORS, CharacterCustomization.DEFAULT_ACCENT_COLOR]
    ]
    var controls: Array[OptionButton] = []
    for i in range(customization_rows.size()):
        var data: Array = customization_rows[i]
        var label := Label.new()
        label.position = Vector2(48 + (i % 2) * 232, 472 + int(i / 2) * 72)
        label.size = Vector2(220, 20)
        label.text = String(data[0])
        label.add_theme_font_size_override("font_size", 10)
        label.add_theme_color_override("font_color", Color("b8dce5"))
        panel.add_child(label)
        var option := OptionButton.new()
        option.position = label.position + Vector2(0, 21)
        option.size = Vector2(220, 38)
        for j in range(data[1].size()):
            option.add_item(String(data[1][j]["name"]), j)
        option.select(int(data[2]))
        option.item_selected.connect(_on_character_changed)
        panel.add_child(option)
        controls.append(option)
    hair_style_option = controls[0]
    hair_color_option = controls[1]
    suit_color_option = controls[2]
    accent_color_option = controls[3]

    character_preview = CharacterPreview.new()
    character_preview.position = Vector2(560, 372)
    character_preview.size = Vector2(420, 300)
    character_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(character_preview)

    character_summary = Label.new()
    character_summary.position = Vector2(48, 620)
    character_summary.size = Vector2(452, 50)
    character_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    character_summary.add_theme_font_size_override("font_size", 11)
    character_summary.add_theme_color_override("font_color", GREEN)
    panel.add_child(character_summary)

    var clock_label := Label.new()
    clock_label.position = Vector2(48, 680)
    clock_label.size = Vector2(300, 28)
    clock_label.text = "CAMPAIGN LENGTH"
    clock_label.add_theme_font_size_override("font_size", 17)
    clock_label.add_theme_color_override("font_color", CYAN)
    panel.add_child(clock_label)

    years_option = OptionButton.new()
    years_option.position = Vector2(48, 710)
    years_option.size = Vector2(452, 42)
    years_option.add_theme_font_size_override("font_size", 14)
    for years in range(1, 21):
        years_option.add_item("%d year%s" % [years, "" if years == 1 else "s"], years)
    years_option.select(3)
    years_option.item_selected.connect(_on_clock_changed)
    panel.add_child(years_option)

    summary_label = Label.new()
    summary_label.position = Vector2(520, 690)
    summary_label.size = Vector2(480, 62)
    summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    summary_label.add_theme_font_size_override("font_size", 12)
    summary_label.add_theme_color_override("font_color", Color("b8dce5"))
    panel.add_child(summary_label)

    var rule := Label.new()
    rule.position = Vector2(520, 752)
    rule.size = Vector2(480, 44)
    rule.text = "Identity choices are free. Extra outfit skins are bought with in-game company cash from the Wardrobe menu."
    rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rule.add_theme_font_size_override("font_size", 12)
    rule.add_theme_color_override("font_color", Color("ffcf72"))
    panel.add_child(rule)

    var start := Button.new()
    start.position = Vector2(106, 772)
    start.size = Vector2(340, 56)
    start.text = "START MINING RACE"
    start.add_theme_font_size_override("font_size", 18)
    start.pressed.connect(start_campaign)
    panel.add_child(start)

    _on_company_changed(0)
    _on_character_changed(0)
    _on_clock_changed(years_option.selected)

func _ratings_line(profile: Dictionary) -> String:
    return "AGG %d  RISK %d  GROW %d  R&D %d  TREAS %d  OPS %d  REP %d" % [
        int(profile["aggression"]), int(profile["risk"]), int(profile["growth"]), int(profile["research"]),
        int(profile["treasury"]), int(profile["operations"]), int(profile["reputation"])
    ]

func _on_company_changed(index: int) -> void:
    var profile: Dictionary = Profiles.PROFILES[index]
    company_label.text = "POSTURE: %s  •  STARTING STRENGTH: %s\n%s\n\nBACKGROUND: %s\n\nCONTROVERSY: %s" % [
        String(profile["posture"]), String(profile["strengths"]), _ratings_line(profile),
        String(profile["background"]), String(profile["controversy"])
    ]

func _on_character_changed(_index: int) -> void:
    if not is_instance_valid(character_summary):
        return
    var skin_idx: int = skin_tone_option.get_item_id(skin_tone_option.selected)
    var gender_idx: int = gender_option.get_item_id(gender_option.selected)
    var hair_style_idx: int = hair_style_option.get_item_id(hair_style_option.selected) if is_instance_valid(hair_style_option) else CharacterCustomization.DEFAULT_HAIR_STYLE
    var hair_color_idx: int = hair_color_option.get_item_id(hair_color_option.selected) if is_instance_valid(hair_color_option) else CharacterCustomization.DEFAULT_HAIR_COLOR
    var suit_idx: int = suit_color_option.get_item_id(suit_color_option.selected) if is_instance_valid(suit_color_option) else CharacterCustomization.DEFAULT_SUIT_COLOR
    var accent_idx: int = accent_color_option.get_item_id(accent_color_option.selected) if is_instance_valid(accent_color_option) else CharacterCustomization.DEFAULT_ACCENT_COLOR
    character_summary.text = "%s skin • %s • %s hair • %s suit" % [
        String(CharacterCustomization.skin_tone(skin_idx)["name"]),
        String(CharacterCustomization.hair_style(hair_style_idx)["name"]),
        String(CharacterCustomization.hair_color(hair_color_idx)["name"]),
        String(CharacterCustomization.suit_color(suit_idx)["name"])
    ]
    if is_instance_valid(character_preview):
        character_preview.set_appearance(CharacterCustomization.skin_tone(skin_idx), CharacterCustomization.hair_color(hair_color_idx), hair_style_idx, CharacterCustomization.suit_color(suit_idx), CharacterCustomization.accent_color(accent_idx))

func _on_clock_changed(index: int) -> void:
    var years := years_option.get_item_id(index)
    var monthly_turns := years * 12
    var halving_count := int(years / 4)
    summary_label.text = "Selected campaign: %d year%s  •  Default month scale: about %d turns  •  Bitcoin halvings: %d  •  Turn length can change in game." % [
        years, "" if years == 1 else "s", monthly_turns, halving_count
    ]

func start_campaign() -> void:
    var years := years_option.get_item_id(years_option.selected)
    get_tree().set_meta("hashrace_company_idx", company_option.get_item_id(company_option.selected))
    get_tree().set_meta("hashrace_campaign_years", years)
    get_tree().set_meta("hashrace_character_skin_tone", skin_tone_option.get_item_id(skin_tone_option.selected))
    get_tree().set_meta("hashrace_character_gender", gender_option.get_item_id(gender_option.selected))
    get_tree().set_meta("hashrace_character_outfit", CharacterCustomization.DEFAULT_OUTFIT)
    get_tree().set_meta("hashrace_character_hair_style", hair_style_option.get_item_id(hair_style_option.selected))
    get_tree().set_meta("hashrace_character_hair_color", hair_color_option.get_item_id(hair_color_option.selected))
    get_tree().set_meta("hashrace_character_suit_color", suit_color_option.get_item_id(suit_color_option.selected))
    get_tree().set_meta("hashrace_character_accent_color", accent_color_option.get_item_id(accent_color_option.selected))
    if get_tree().has_meta("hashrace_campaign_turns"):
        get_tree().remove_meta("hashrace_campaign_turns")
    get_tree().change_scene_to_file("res://scenes/world.tscn")
