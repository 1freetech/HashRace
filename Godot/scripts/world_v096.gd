extends "res://scripts/world_v095.gd"

# Hash Race v0.096 navigation quality pass.
# Keeps the world readable while making interface switching faster and safer.

const V096_NAV_QUALITY_REVISION: int = 1
const NAV_EDGE_MARGIN: float = 14.0
const NAV_MIN_WIDTH: float = 248.0
const TOAST_DEDUPE_SECONDS: float = 0.65

var v096_nav_buttons: Dictionary = {}
var v096_last_toast: String = ""
var v096_last_toast_msec: int = -10000

func _ready() -> void:
    super._ready()
    get_tree().process_frame.connect(Callable(self, "_v096_upgrade_navigation"), CONNECT_ONE_SHOT)
    set_meta("hashrace_v096_nav_quality_revision", V096_NAV_QUALITY_REVISION)

func _v096_upgrade_navigation() -> void:
    if not navigation_installed:
        get_tree().process_frame.connect(Callable(self, "_v096_upgrade_navigation"), CONNECT_ONE_SHOT)
        return
    _v096_index_navigation_buttons()
    navigation_button.tooltip_text = "Open navigation (M). Escape returns to the world. 1-6 open key workspaces."
    navigation_status.text = "WORLD • M MENU • 1-6 QUICK OPEN • ESC WORLD"
    _v096_layout_navigation()
    _v096_refresh_button_state()

func _v096_index_navigation_buttons() -> void:
    v096_nav_buttons.clear()
    for child in navigation_panel.get_children():
        if child is Button and child != navigation_turn_button:
            var button := child as Button
            var key := button.text.to_lower()
            if "world" in key:
                key = "world"
            elif "mining" in key:
                key = "ops"
            elif "company" in key:
                key = "company"
            elif "market" in key:
                key = "market"
            elif "infrastructure" in key:
                key = "infrastructure"
            elif "treasury" in key:
                key = "treasury"
            elif "life" in key:
                key = "site"
            elif "league" in key:
                key = "league"
            elif "wardrobe" in key:
                key = "wardrobe"
            elif "dialog" in key:
                key = "dialog"
            elif "tools" in key:
                key = "tools"
            if not v096_nav_buttons.has(key):
                v096_nav_buttons[key] = button

func _layout_navigation_shell() -> void:
    super._layout_navigation_shell()
    _v096_layout_navigation()

func _v096_layout_navigation() -> void:
    if not is_instance_valid(navigation_panel) or not is_instance_valid(navigation_button):
        return
    var viewport_size := get_viewport_rect().size
    var available_width := maxf(NAV_MIN_WIDTH, viewport_size.x - NAV_EDGE_MARGIN * 2.0)
    var panel_width := minf(NAV_PANEL_SIZE.x, available_width)
    navigation_panel.position = Vector2(NAV_EDGE_MARGIN, 58.0)
    navigation_panel.size.x = panel_width
    navigation_button.position.x = NAV_EDGE_MARGIN
    # Keep the panel on-screen on short windows instead of letting the bottom controls disappear.
    navigation_panel.size.y = minf(NAV_PANEL_SIZE.y, maxf(250.0, viewport_size.y - 72.0))
    navigation_turn_button.position.y = navigation_panel.size.y - 50.0
    navigation_turn_button.size.x = maxf(120.0, panel_width - 28.0)

func _toggle_navigation_panel() -> void:
    super._toggle_navigation_panel()
    if is_instance_valid(navigation_panel) and navigation_panel.visible:
        _v096_refresh_button_state()
        var world_button: Button = v096_nav_buttons.get("world") as Button
        if world_button != null:
            world_button.grab_focus()

func _activate_workspace(workspace: String) -> void:
    super._activate_workspace(workspace)
    _v096_refresh_button_state()

func _v096_refresh_button_state() -> void:
    if not navigation_installed:
        return
    for key in v096_nav_buttons:
        var button: Button = v096_nav_buttons[key] as Button
        if button == null:
            continue
        var selected := String(key) == active_workspace
        button.disabled = selected
        button.modulate = Color(0.78, 1.0, 0.84, 1.0) if selected else Color.WHITE
    if is_instance_valid(navigation_status):
        navigation_status.text = "%s • M MENU • 1-6 QUICK OPEN • ESC WORLD" % active_workspace.to_upper()

func _show_toast(message: String) -> void:
    var now := Time.get_ticks_msec()
    if message == v096_last_toast and now - v096_last_toast_msec < int(TOAST_DEDUPE_SECONDS * 1000.0):
        return
    v096_last_toast = message
    v096_last_toast_msec = now
    super._show_toast(message)

func _v096_quick_workspace(keycode: Key) -> String:
    match keycode:
        KEY_1:
            return "ops"
        KEY_2:
            return "company"
        KEY_3:
            return "market"
        KEY_4:
            return "infrastructure"
        KEY_5:
            return "treasury"
        KEY_6:
            return "league"
    return ""

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and get_viewport().gui_get_focus_owner() == null:
            # Escape is a reliable hierarchy: close NAV first, then close any workspace.
            if key_event.keycode == KEY_ESCAPE:
                if is_instance_valid(navigation_panel) and navigation_panel.visible:
                    navigation_panel.visible = false
                    get_viewport().set_input_as_handled()
                    return
                if active_workspace != "world":
                    _activate_workspace("world")
                    _show_toast("WORLD • interface closed")
                    get_viewport().set_input_as_handled()
                    return
            # Direct workspace keys remove repeated menu-open/click/close friction.
            var quick_workspace := _v096_quick_workspace(key_event.keycode)
            if not quick_workspace.is_empty():
                _activate_workspace(quick_workspace)
                get_viewport().set_input_as_handled()
                return
    super._unhandled_input(event)

func debug_v096_ready() -> bool:
    return (
        V096_NAV_QUALITY_REVISION == 1
        and debug_v095_ready()
        and navigation_installed
        and NAV_MIN_WIDTH >= 240.0
        and TOAST_DEDUPE_SECONDS > 0.0
        and _v096_quick_workspace(KEY_1) == "ops"
        and _v096_quick_workspace(KEY_6) == "league"
    )
