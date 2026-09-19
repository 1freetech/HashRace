extends "res://scripts/world_v093.gd"

# Hash Race v0.094 focused navigation / HUD declutter pass.
# Normal play is world-first: one small NAV control stays on screen, while
# detailed interfaces are opened one at a time and routine feedback uses a
# temporary toast instead of keeping the large dialogue panel visible.

const V094_NAVIGATION_REVISION: int = 1
const NAV_PANEL_SIZE := Vector2(288.0, 378.0)
const TOAST_SECONDS: float = 4.0

var navigation_layer: CanvasLayer
var navigation_button: Button
var navigation_panel: Panel
var navigation_status: Label
var navigation_turn_button: Button
var navigation_installed: bool = false
var active_workspace: String = "world"
var toast_label: Label
var toast_remaining: float = 0.0

func _ready() -> void:
    super._ready()
    get_tree().process_frame.connect(Callable(self, "_try_install_navigation_shell"), CONNECT_ONE_SHOT)
    set_meta("hashrace_v094_navigation_revision", V094_NAVIGATION_REVISION)

func _process(delta: float) -> void:
    super._process(delta)
    if toast_remaining > 0.0:
        toast_remaining = maxf(0.0, toast_remaining - maxf(0.0, delta))
        if toast_remaining <= 0.0 and is_instance_valid(toast_label):
            toast_label.visible = false

func _try_install_navigation_shell() -> void:
    if navigation_installed:
        return
    if not compact_ui_installed:
        get_tree().process_frame.connect(Callable(self, "_try_install_navigation_shell"), CONNECT_ONE_SHOT)
        return
    _install_navigation_shell()

func _install_navigation_shell() -> void:
    navigation_layer = CanvasLayer.new()
    navigation_layer.name = "NavigationShell"
    navigation_layer.layer = 34
    add_child(navigation_layer)

    navigation_button = Button.new()
    navigation_button.name = "NavigationButton"
    navigation_button.position = Vector2(14.0, 14.0)
    navigation_button.size = Vector2(118.0, 36.0)
    navigation_button.text = "NAV • WORLD"
    navigation_button.tooltip_text = "Open interface navigation. Shortcut: M."
    navigation_button.add_theme_font_size_override("font_size", 11)
    navigation_button.pressed.connect(_toggle_navigation_panel)
    navigation_layer.add_child(navigation_button)

    navigation_panel = Panel.new()
    navigation_panel.name = "NavigationPanel"
    navigation_panel.position = Vector2(14.0, 58.0)
    navigation_panel.size = NAV_PANEL_SIZE
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("06141df4")
    panel_style.border_width_left = 2
    panel_style.border_width_top = 2
    panel_style.border_width_right = 2
    panel_style.border_width_bottom = 2
    panel_style.border_color = Color("42f58d")
    panel_style.corner_radius_top_left = 7
    panel_style.corner_radius_top_right = 7
    panel_style.corner_radius_bottom_left = 7
    panel_style.corner_radius_bottom_right = 7
    navigation_panel.add_theme_stylebox_override("panel", panel_style)
    navigation_layer.add_child(navigation_panel)

    var title := Label.new()
    title.position = Vector2(14.0, 10.0)
    title.size = Vector2(260.0, 24.0)
    title.text = "INTERFACES"
    title.add_theme_font_size_override("font_size", 16)
    title.add_theme_color_override("font_color", Color("64ff8c"))
    navigation_panel.add_child(title)

    navigation_status = Label.new()
    navigation_status.position = Vector2(14.0, 34.0)
    navigation_status.size = Vector2(260.0, 26.0)
    navigation_status.text = "WORLD VIEW • ONE PANEL AT A TIME"
    navigation_status.add_theme_font_size_override("font_size", 9)
    navigation_status.add_theme_color_override("font_color", Color("b7dbe2"))
    navigation_panel.add_child(navigation_status)

    _add_navigation_button("WORLD", "world", 0, 0)
    _add_navigation_button("MINING OPS", "ops", 0, 1)
    _add_navigation_button("COMPANY", "company", 1, 0)
    _add_navigation_button("MARKET", "market", 1, 1)
    _add_navigation_button("INFRASTRUCTURE", "infrastructure", 2, 0)
    _add_navigation_button("BTC TREASURY", "treasury", 2, 1)
    _add_navigation_button("LIFE + SITE", "site", 3, 0)
    _add_navigation_button("LEAGUE", "league", 3, 1)
    _add_navigation_button("WARDROBE", "wardrobe", 4, 0)
    _add_navigation_button("DIALOG", "dialog", 4, 1)
    _add_navigation_button("TOOLS", "tools", 5, 0)
    _add_navigation_button("WORLD / HIDE ALL", "world", 5, 1)

    navigation_turn_button = Button.new()
    navigation_turn_button.position = Vector2(14.0, 328.0)
    navigation_turn_button.size = Vector2(260.0, 34.0)
    navigation_turn_button.text = "PREVIEW TURN"
    navigation_turn_button.tooltip_text = "Preview the selected Day, Month, or Year turn. Press again to confirm."
    navigation_turn_button.add_theme_font_size_override("font_size", 10)
    navigation_turn_button.pressed.connect(_nav_turn_pressed)
    navigation_panel.add_child(navigation_turn_button)

    toast_label = Label.new()
    toast_label.name = "GameplayToast"
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    toast_label.add_theme_font_size_override("font_size", 10)
    toast_label.add_theme_color_override("font_color", Color("e7f7fa"))
    var toast_style := StyleBoxFlat.new()
    toast_style.bg_color = Color("06141de8")
    toast_style.border_width_left = 1
    toast_style.border_width_top = 1
    toast_style.border_width_right = 1
    toast_style.border_width_bottom = 1
    toast_style.border_color = Color("28596b")
    toast_style.corner_radius_top_left = 5
    toast_style.corner_radius_top_right = 5
    toast_style.corner_radius_bottom_left = 5
    toast_style.corner_radius_bottom_right = 5
    toast_label.add_theme_stylebox_override("normal", toast_style)
    toast_label.visible = false
    navigation_layer.add_child(toast_label)

    navigation_panel.visible = false
    navigation_installed = true

    if is_instance_valid(menu_button):
        menu_button.visible = false
    if is_instance_valid(compact_prompt):
        compact_prompt.visible = false
    if is_instance_valid(mining_ops_restore_button):
        mining_ops_restore_button.visible = false

    get_viewport().size_changed.connect(_layout_navigation_shell)
    _layout_navigation_shell()
    _activate_workspace("world")
    _refresh_nav_turn_button()

func _add_navigation_button(label_text: String, workspace: String, row: int, column: int) -> Button:
    var button := Button.new()
    button.position = Vector2(14.0 + float(column) * 132.0, 70.0 + float(row) * 42.0)
    button.size = Vector2(128.0, 34.0)
    button.text = label_text
    button.tooltip_text = "Open %s and minimize other gameplay interfaces." % label_text.to_lower()
    button.add_theme_font_size_override("font_size", 9)
    button.pressed.connect(Callable(self, "_activate_workspace").bind(workspace))
    navigation_panel.add_child(button)
    return button

func _layout_navigation_shell() -> void:
    if not is_instance_valid(toast_label):
        return
    var viewport_size := get_viewport_rect().size
    var toast_width := minf(720.0, maxf(240.0, viewport_size.x - 28.0))
    toast_label.position = Vector2(maxf(14.0, (viewport_size.x - toast_width) * 0.5), maxf(58.0, viewport_size.y - 52.0))
    toast_label.size = Vector2(toast_width, 34.0)

func _toggle_navigation_panel() -> void:
    if not is_instance_valid(navigation_panel):
        return
    navigation_panel.visible = not navigation_panel.visible

func _hide_workspace_panels() -> void:
    if is_instance_valid(company_panel):
        company_panel.visible = false
    if is_instance_valid(market_panel):
        market_panel.visible = false
    if is_instance_valid(dialog_panel):
        dialog_panel.visible = false
    if is_instance_valid(drawer_panel):
        drawer_panel.visible = false
    if is_instance_valid(mining_ops_widget):
        mining_ops_widget.hide()
    if is_instance_valid(mining_ops_restore_button):
        mining_ops_restore_button.visible = false

    for layer_name in [
        "LifeOpsLayer",
        "LiveTreasuryLayer",
        "LeagueStandingsLayer",
        "WardrobeLayer",
        "RPGStrategyLayer",
        "TownTransitLayer",
        "TurnScaleLayer"
    ]:
        var layer := get_node_or_null(layer_name) as CanvasLayer
        if layer != null:
            layer.visible = false

func _activate_workspace(workspace: String) -> void:
    if not navigation_installed:
        return
    _hide_workspace_panels()
    active_workspace = workspace

    match workspace:
        "world":
            pass
        "ops":
            if is_instance_valid(mining_ops_widget):
                mining_ops_widget.show()
                if bool(mining_ops_widget.get("collapsed")) and mining_ops_widget.has_method("_toggle_collapsed"):
                    mining_ops_widget.call("_toggle_collapsed")
                mining_ops_widget.call("force_refresh")
        "company":
            if is_instance_valid(company_panel):
                company_panel.visible = true
        "market":
            if is_instance_valid(market_panel):
                market_panel.visible = true
        "infrastructure":
            if has_method("_open_infrastructure_inventory"):
                call("_open_infrastructure_inventory")
            if is_instance_valid(dialog_panel):
                dialog_panel.visible = true
        "treasury":
            _show_layer_only("LiveTreasuryLayer")
        "site":
            _show_layer_only("LifeOpsLayer")
        "league":
            if has_method("_open_league_standings"):
                call("_open_league_standings")
            if is_instance_valid(dialog_panel):
                dialog_panel.visible = true
        "wardrobe":
            if has_method("_show_wardrobe"):
                call("_show_wardrobe")
            _show_layer_only("WardrobeLayer")
        "dialog":
            if is_instance_valid(dialog_panel):
                dialog_panel.visible = true
        "tools":
            if is_instance_valid(drawer_panel):
                drawer_panel.visible = true

    if is_instance_valid(navigation_panel):
        navigation_panel.visible = false
    _refresh_navigation_status()

func _show_layer_only(layer_name: String) -> void:
    var layer := get_node_or_null(layer_name) as CanvasLayer
    if layer != null:
        layer.visible = true

func _refresh_navigation_status() -> void:
    var label := active_workspace.to_upper()
    match active_workspace:
        "ops":
            label = "MINING OPS"
        "treasury":
            label = "BTC TREASURY"
        "site":
            label = "LIFE + SITE"
        "infrastructure":
            label = "INFRA"
    if is_instance_valid(navigation_button):
        navigation_button.text = "NAV • %s" % label
    if is_instance_valid(navigation_status):
        navigation_status.text = "%s • ONE PANEL AT A TIME" % label

func _nav_turn_pressed() -> void:
    _end_quarter()
    _refresh_nav_turn_button()

func _refresh_nav_turn_button() -> void:
    if not is_instance_valid(navigation_turn_button):
        return
    navigation_turn_button.disabled = campaign_complete
    if campaign_complete:
        navigation_turn_button.text = "CAMPAIGN COMPLETE"
    elif live_quarter_confirmation_pending:
        navigation_turn_button.text = "CONFIRM %s TURN" % turn_length_name()
    else:
        navigation_turn_button.text = "PREVIEW %s TURN" % turn_length_name()

func _show_toast(message: String) -> void:
    if not navigation_installed or not is_instance_valid(toast_label):
        return
    toast_label.text = message.left(180)
    toast_label.visible = true
    toast_remaining = TOAST_SECONDS

func _open_entity(idx: int) -> void:
    super._open_entity(idx)
    if navigation_installed:
        _activate_workspace("dialog")

func _open_message(title_text: String, body_text: String) -> void:
    super._open_message(title_text, body_text)
    if not navigation_installed:
        return
    var upper_title := title_text.to_upper()
    if "SETTLEMENT" in upper_title or "CAMPAIGN COMPLETE" in upper_title or "TRANSIT" in upper_title:
        _activate_workspace("dialog")
    else:
        _show_toast("%s • %s" % [title_text, body_text])

func _feedback(message: String) -> void:
    super._feedback(message)
    _show_toast(message)

func _open_life_overview() -> void:
    super._open_life_overview()
    if navigation_installed:
        _activate_workspace("dialog")

func _refresh_ui() -> void:
    super._refresh_ui()
    _refresh_nav_turn_button()

func _on_mining_ops_widget_closed() -> void:
    if is_instance_valid(mining_ops_restore_button):
        mining_ops_restore_button.visible = false
    active_workspace = "world"
    _refresh_navigation_status()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_M and get_viewport().gui_get_focus_owner() == null:
                _toggle_navigation_panel()
                get_viewport().set_input_as_handled()
                return
            if key_event.keycode == KEY_ESCAPE and is_instance_valid(navigation_panel) and navigation_panel.visible:
                navigation_panel.visible = false
                get_viewport().set_input_as_handled()
                return
    super._unhandled_input(event)

func debug_v094_navigation_ready() -> bool:
    return (
        V094_NAVIGATION_REVISION == 1
        and navigation_installed
        and is_instance_valid(navigation_button)
        and is_instance_valid(navigation_panel)
        and not navigation_panel.visible
        and is_instance_valid(dialog_panel)
        and not dialog_panel.visible
        and is_instance_valid(mining_ops_widget)
        and not mining_ops_widget.visible
        and (not is_instance_valid(menu_button) or not menu_button.visible)
        and (not is_instance_valid(compact_prompt) or not compact_prompt.visible)
        and (get_node_or_null("LeagueStandingsLayer") == null or not (get_node("LeagueStandingsLayer") as CanvasLayer).visible)
        and (get_node_or_null("LifeOpsLayer") == null or not (get_node("LifeOpsLayer") as CanvasLayer).visible)
        and (get_node_or_null("LiveTreasuryLayer") == null or not (get_node("LiveTreasuryLayer") as CanvasLayer).visible)
        and (get_node_or_null("WardrobeLayer") == null or not (get_node("WardrobeLayer") as CanvasLayer).visible)
    )
