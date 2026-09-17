extends "res://scripts/world_pixel_landscape.gd"

# Hash Race v0.043 compact HUD.
# The old simulation panels still exist, but only one information module is
# shown at a time. The map stays readable and the player opens detail on demand.

const COMPACT_UI_REVISION: int = 1
const MENU_WIDTH: float = 270.0

var compact_ui_installed: bool = false
var compact_layer: CanvasLayer
var drawer_panel: Panel
var compact_prompt: Label
var drawer_status: Label
var menu_button: Button
var turn_menu_button: Button
var scanner_menu_button: Button
var company_panel: Panel
var market_panel: Panel

func _ready() -> void:
    super._ready()
    scanner_overlay_enabled = false
    scanner_cells.clear()
    call_deferred("_try_install_compact_ui")

func _process(delta: float) -> void:
    super._process(delta)
    if not compact_ui_installed:
        _try_install_compact_ui()
    if compact_ui_installed:
        _refresh_compact_prompt()
        _refresh_compact_status()

func _try_install_compact_ui() -> void:
    if compact_ui_installed:
        return
    # Treasury installs deferred from its scene child, so wait until every module
    # that used to overlap the map is present before hiding and compartmentalizing.
    if get_node_or_null("LiveTreasuryLayer") == null:
        return

    _find_base_hud_panels()
    _hide_legacy_overlays()
    _build_compact_layer()
    compact_ui_installed = true
    queue_redraw()

func _find_base_hud_panels() -> void:
    for child in get_children():
        if not (child is CanvasLayer):
            continue
        var layer := child as CanvasLayer
        var layer_name: String = String(layer.name)
        if layer_name in ["BootFallback", "RPGStrategyLayer", "TownTransitLayer", "TurnScaleLayer", "LeagueStandingsLayer", "LifeOpsLayer", "LiveTreasuryLayer", "CompactUILayer"]:
            continue
        for control in layer.get_children():
            if control is Panel:
                var panel := control as Panel
                if panel.position.x > 1000.0 and panel.position.y < 120.0:
                    company_panel = panel
                elif panel.position.x < 100.0 and panel.position.y > 600.0 and panel.position.y < 705.0:
                    market_panel = panel

func _hide_legacy_overlays() -> void:
    for layer_name in ["RPGStrategyLayer", "TownTransitLayer", "TurnScaleLayer", "LeagueStandingsLayer", "LifeOpsLayer", "LiveTreasuryLayer"]:
        var layer := get_node_or_null(layer_name) as CanvasLayer
        if layer != null:
            layer.visible = false
    if is_instance_valid(company_panel):
        company_panel.visible = false
    if is_instance_valid(market_panel):
        market_panel.visible = false
    if is_instance_valid(prompt_label):
        prompt_label.visible = false

func _build_compact_layer() -> void:
    compact_layer = CanvasLayer.new()
    compact_layer.name = "CompactUILayer"
    compact_layer.layer = 30
    add_child(compact_layer)

    menu_button = Button.new()
    menu_button.position = Vector2(18.0, 88.0)
    menu_button.size = Vector2(150.0, 42.0)
    menu_button.text = "MENU  [M]"
    menu_button.tooltip_text = "Open the Hash Race control center. Only one detail panel is shown at a time."
    menu_button.add_theme_font_size_override("font_size", 13)
    menu_button.pressed.connect(_toggle_drawer)
    compact_layer.add_child(menu_button)

    compact_prompt = Label.new()
    compact_prompt.position = Vector2(300.0, 91.0)
    compact_prompt.size = Vector2(720.0, 34.0)
    compact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    compact_prompt.add_theme_font_size_override("font_size", 13)
    compact_prompt.add_theme_color_override("font_color", Color("d8f8e3"))
    compact_layer.add_child(compact_prompt)

    drawer_panel = Panel.new()
    drawer_panel.position = Vector2(18.0, 138.0)
    drawer_panel.size = Vector2(MENU_WIDTH, 500.0)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("06141df2")
    style.border_width_left = 3
    style.border_width_top = 3
    style.border_width_right = 3
    style.border_width_bottom = 3
    style.border_color = Color("42f58d")
    style.corner_radius_top_left = 7
    style.corner_radius_top_right = 7
    style.corner_radius_bottom_left = 7
    style.corner_radius_bottom_right = 7
    drawer_panel.add_theme_stylebox_override("panel", style)
    compact_layer.add_child(drawer_panel)

    var title := Label.new()
    title.position = Vector2(16.0, 14.0)
    title.size = Vector2(235.0, 28.0)
    title.text = "CONTROL CENTER"
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", Color("64ff8c"))
    drawer_panel.add_child(title)

    drawer_status = Label.new()
    drawer_status.position = Vector2(16.0, 45.0)
    drawer_status.size = Vector2(235.0, 46.0)
    drawer_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    drawer_status.add_theme_font_size_override("font_size", 11)
    drawer_status.add_theme_color_override("font_color", Color("b7dbe2"))
    drawer_panel.add_child(drawer_status)

    _add_menu_button("COMPANY", 98.0, Callable(self, "_show_company_module"))
    _add_menu_button("BTC TREASURY", 142.0, Callable(self, "_show_named_module").bind("LiveTreasuryLayer"))
    _add_menu_button("LIFE + SITE", 186.0, Callable(self, "_show_named_module").bind("LifeOpsLayer"))
    _add_menu_button("LEAGUE STANDINGS", 230.0, Callable(self, "_show_league"))
    _add_menu_button("MARKET INFO", 274.0, Callable(self, "_show_market_module"))

    turn_menu_button = _add_menu_button("TURN LENGTH", 318.0, Callable(self, "_cycle_turn_from_menu"))
    scanner_menu_button = _add_menu_button("SCANNER", 362.0, Callable(self, "_toggle_scanner_from_menu"))
    _add_menu_button("NEXT MINING TOWN  [T]", 406.0, Callable(self, "_travel_from_menu"))
    _add_menu_button("CLEAR PANELS", 450.0, Callable(self, "_clear_detail_panels"))

    drawer_panel.visible = false
    _refresh_menu_button_text()

func _add_menu_button(text_value: String, y: float, action: Callable) -> Button:
    var button := Button.new()
    button.position = Vector2(14.0, y)
    button.size = Vector2(242.0, 36.0)
    button.text = text_value
    button.add_theme_font_size_override("font_size", 12)
    button.pressed.connect(action)
    drawer_panel.add_child(button)
    return button

func _toggle_drawer() -> void:
    if not is_instance_valid(drawer_panel):
        return
    drawer_panel.visible = not drawer_panel.visible
    menu_button.text = "CLOSE  [M]" if drawer_panel.visible else "MENU  [M]"

func _clear_detail_panels() -> void:
    if is_instance_valid(company_panel):
        company_panel.visible = false
    if is_instance_valid(market_panel):
        market_panel.visible = false
    for layer_name in ["LifeOpsLayer", "LiveTreasuryLayer"]:
        var layer := get_node_or_null(layer_name) as CanvasLayer
        if layer != null:
            layer.visible = false

func _show_company_module() -> void:
    _clear_detail_panels()
    if is_instance_valid(company_panel):
        company_panel.visible = true
    _close_drawer_after_choice()

func _show_market_module() -> void:
    _clear_detail_panels()
    if is_instance_valid(market_panel):
        market_panel.visible = true
    _close_drawer_after_choice()

func _show_named_module(layer_name: String) -> void:
    _clear_detail_panels()
    var layer := get_node_or_null(layer_name) as CanvasLayer
    if layer != null:
        layer.visible = true
    _close_drawer_after_choice()

func _show_league() -> void:
    _clear_detail_panels()
    _open_league_standings()
    _close_drawer_after_choice()

func _cycle_turn_from_menu() -> void:
    _cycle_turn_length()
    _refresh_menu_button_text()

func _toggle_scanner_from_menu() -> void:
    _toggle_scanner_overlay()
    _refresh_menu_button_text()

func _travel_from_menu() -> void:
    _travel_next_town()
    _close_drawer_after_choice()

func _close_drawer_after_choice() -> void:
    if is_instance_valid(drawer_panel):
        drawer_panel.visible = false
    if is_instance_valid(menu_button):
        menu_button.text = "MENU  [M]"

func _refresh_menu_button_text() -> void:
    if is_instance_valid(turn_menu_button):
        turn_menu_button.text = "TURN: %s  [CHANGE]" % turn_length_name()
    if is_instance_valid(scanner_menu_button):
        scanner_menu_button.text = "SCANNER: %s" % ("ON" if scanner_overlay_enabled else "OFF")

func _refresh_compact_prompt() -> void:
    if not is_instance_valid(compact_prompt):
        return
    var idx: int = _nearest_entity()
    if idx >= 0 and _entity_in_interact_range(idx):
        var entity: Dictionary = entities[idx]
        compact_prompt.text = "[E] INTERACT  •  %s" % String(entity.get("name", "TARGET")).to_upper()
        compact_prompt.add_theme_color_override("font_color", Color("8affbd"))
    else:
        compact_prompt.text = "WASD MOVE  •  M MENU  •  T TRANSIT  •  R SCANNER"
        compact_prompt.add_theme_color_override("font_color", Color("c4e4ea"))

func _refresh_compact_status() -> void:
    if not is_instance_valid(drawer_status) or player.is_empty():
        return
    drawer_status.text = "%s\nCash $%d  •  %d machines  •  %.2f MW" % [String(player["name"]), int(player["cash"]), int(player["machines"]), float(player["mw"])]
    _refresh_menu_button_text()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_M:
            _toggle_drawer()
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)

func debug_compact_ui_ready() -> bool:
    return COMPACT_UI_REVISION == 1 and compact_ui_installed and is_instance_valid(menu_button)
