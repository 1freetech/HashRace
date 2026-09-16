extends Control

const Profiles = preload("res://scripts/company_profiles.gd")
const GREEN := Color("64ff8c")
const CYAN := Color("52e7ff")
const WHITE := Color("dffaff")
const PANEL := Color("091119f2")

var company_option: OptionButton
var years_option: OptionButton
var company_label: Label
var summary_label: Label

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
    panel.position = Vector2(320, 70)
    panel.size = Vector2(800, 760)
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
    title.position = Vector2(34, 22)
    title.size = Vector2(732, 48)
    title.text = "HASH RACE // NEW CAMPAIGN"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", GREEN)
    panel.add_child(title)

    var subtitle := Label.new()
    subtitle.position = Vector2(40, 78)
    subtitle.size = Vector2(720, 42)
    subtitle.text = "Pick your mining company and fixed game clock before Turn 1."
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 15)
    subtitle.add_theme_color_override("font_color", WHITE)
    panel.add_child(subtitle)

    var company_hdr := Label.new()
    company_hdr.position = Vector2(78, 138)
    company_hdr.size = Vector2(300, 30)
    company_hdr.text = "MINING COMPANY"
    company_hdr.add_theme_font_size_override("font_size", 18)
    company_hdr.add_theme_color_override("font_color", CYAN)
    panel.add_child(company_hdr)

    company_option = OptionButton.new()
    company_option.position = Vector2(78, 176)
    company_option.size = Vector2(644, 46)
    company_option.add_theme_font_size_override("font_size", 15)
    for i in range(Profiles.PROFILES.size()):
        var profile := Profiles.PROFILES[i]
        company_option.add_item("%s  //  %s" % [profile["name"], profile["strengths"]], i)
    company_option.item_selected.connect(_on_company_changed)
    panel.add_child(company_option)

    company_label = Label.new()
    company_label.position = Vector2(78, 234)
    company_label.size = Vector2(644, 92)
    company_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    company_label.add_theme_font_size_override("font_size", 14)
    company_label.add_theme_color_override("font_color", Color("b8dce5"))
    panel.add_child(company_label)

    var clock_label := Label.new()
    clock_label.position = Vector2(78, 342)
    clock_label.size = Vector2(300, 30)
    clock_label.text = "CAMPAIGN LENGTH"
    clock_label.add_theme_font_size_override("font_size", 18)
    clock_label.add_theme_color_override("font_color", CYAN)
    panel.add_child(clock_label)

    years_option = OptionButton.new()
    years_option.position = Vector2(78, 380)
    years_option.size = Vector2(644, 46)
    years_option.add_theme_font_size_override("font_size", 15)
    for years in range(1, 21):
        years_option.add_item("%d year%s  /  %d turns" % [years, "" if years == 1 else "s", years * 4], years)
    years_option.select(3)
    years_option.item_selected.connect(_on_clock_changed)
    panel.add_child(years_option)

    summary_label = Label.new()
    summary_label.position = Vector2(78, 444)
    summary_label.size = Vector2(644, 116)
    summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    summary_label.add_theme_font_size_override("font_size", 14)
    summary_label.add_theme_color_override("font_color", Color("b8dce5"))
    panel.add_child(summary_label)

    var rule := Label.new()
    rule.position = Vector2(78, 570)
    rule.size = Vector2(644, 54)
    rule.text = "1 TURN = 1 QUARTER  •  4 TURNS = 1 YEAR  •  HALVING EVERY 16 TURNS"
    rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    rule.add_theme_font_size_override("font_size", 13)
    rule.add_theme_color_override("font_color", Color("ffcf72"))
    panel.add_child(rule)

    var start := Button.new()
    start.position = Vector2(230, 650)
    start.size = Vector2(340, 58)
    start.text = "START MINING RACE"
    start.add_theme_font_size_override("font_size", 18)
    start.pressed.connect(start_campaign)
    panel.add_child(start)

    _on_company_changed(0)
    _on_clock_changed(years_option.selected)

func _on_company_changed(index: int) -> void:
    var profile := Profiles.PROFILES[index]
    company_label.text = "Starting strengths: %s\nYour company begins at Garage Town scale, but these advantages apply from Turn 1. Financing eligibility still depends on total assets." % profile["strengths"]

func _on_clock_changed(index: int) -> void:
    var years := years_option.get_item_id(index)
    var turns := years * 4
    var halving_count := int(turns / 16)
    summary_label.text = "Selected clock: %d year%s / %d quarterly turns\nBitcoin halvings during campaign: %d\nFirst halving: end of Year 4 / Turn 16\nMaximum: 20 years / 80 turns" % [
        years, "" if years == 1 else "s", turns, halving_count
    ]

func start_campaign() -> void:
    var years := years_option.get_item_id(years_option.selected)
    get_tree().set_meta("hashrace_company_idx", company_option.get_item_id(company_option.selected))
    get_tree().set_meta("hashrace_campaign_years", years)
    get_tree().set_meta("hashrace_campaign_turns", years * 4)
    get_tree().change_scene_to_file("res://scenes/world.tscn")
