extends "res://scripts/world_v094.gd"

# Hash Race v0.095 focused usability/readability maintenance pass.
# Keeps v0.094 world-first navigation while tightening keyboard flow,
# small-screen layout, duplicate feedback, and workspace discoverability.

const V095_QUALITY_REVISION: int = 1
const NAV_MARGIN := 14.0
const NAV_GAP := 8.0
const NAV_MIN_WIDTH := 236.0
const NAV_MAX_WIDTH := 288.0

var workspace_buttons: Dictionary = {}
var last_toast_message: String = ""
var last_toast_at_ms: int = -10000

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v095_quality_revision", V095_QUALITY_REVISION)

func _add_navigation_button(label_text: String, workspace: String, row: int, column: int) -> Button:
    var button := super._add_navigation_button(label_text, workspace, row, column)
    if not workspace_buttons.has(workspace) or workspace == "world":
        workspace_buttons[workspace] = button
    return button

func _layout_navigation_shell() -> void:
    super._layout_navigation_shell()
    if not is_instance_valid(navigation_panel) or not is_instance_valid(navigation_button):
        return
    var viewport_size := get_viewport_rect().size
    var panel_width := clampf(viewport_size.x - NAV_MARGIN * 2.0, NAV_MIN_WIDTH, NAV_MAX_WIDTH)
    navigation_panel.size.x = panel_width
    navigation_panel.position.x = NAV_MARGIN
    navigation_button.position.x = NAV_MARGIN
    # Keep the navigation menu entirely on-screen on short laptop/window sizes.
    var max_panel_y := maxf(NAV_MARGIN + navigation_button.size.y + NAV_GAP, viewport_size.y - navigation_panel.size.y - NAV_MARGIN)
    navigation_panel.position.y = minf(NAV_MARGIN + navigation_button.size.y + NAV_GAP, max_panel_y)

func _toggle_navigation_panel() -> void:
    super._toggle_navigation_panel()
    if is_instance_valid(navigation_panel) and navigation_panel.visible:
        var first := workspace_buttons.get("world") as Button
        if is_instance_valid(first):
            first.grab_focus()

func _activate_workspace(workspace: String) -> void:
    super._activate_workspace(workspace)
    _refresh_workspace_button_states()

func _refresh_workspace_button_states() -> void:
    for workspace in workspace_buttons:
        var button := workspace_buttons[workspace] as Button
        if not is_instance_valid(button):
            continue
        button.disabled = workspace == active_workspace and workspace != "world"

func _show_toast(message: String) -> void:
    var clean := message.strip_edges()
    if clean.is_empty():
        return
    var now := Time.get_ticks_msec()
    # Parent feedback paths can converge; suppress identical double-toasts.
    if clean == last_toast_message and now - last_toast_at_ms < 500:
        return
    last_toast_message = clean
    last_toast_at_ms = now
    super._show_toast(clean)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_ESCAPE and navigation_installed:
                if is_instance_valid(navigation_panel) and navigation_panel.visible:
                    navigation_panel.visible = false
                    get_viewport().set_input_as_handled()
                    return
                if active_workspace != "world":
                    _activate_workspace("world")
                    _show_toast("WORLD VIEW • interfaces hidden")
                    get_viewport().set_input_as_handled()
                    return
            if get_viewport().gui_get_focus_owner() == null:
                match key_event.keycode:
                    KEY_O:
                        _activate_workspace("ops")
                        get_viewport().set_input_as_handled()
                        return
                    KEY_C:
                        _activate_workspace("company")
                        get_viewport().set_input_as_handled()
                        return
                    KEY_B:
                        _activate_workspace("market")
                        get_viewport().set_input_as_handled()
                        return
                    KEY_I:
                        _activate_workspace("infrastructure")
                        get_viewport().set_input_as_handled()
                        return
                    KEY_T:
                        _activate_workspace("treasury")
                        get_viewport().set_input_as_handled()
                        return
                    KEY_L:
                        _activate_workspace("league")
                        get_viewport().set_input_as_handled()
                        return
    super._unhandled_input(event)

func _install_navigation_shell() -> void:
    super._install_navigation_shell()
    if is_instance_valid(navigation_button):
        navigation_button.tooltip_text = "Interfaces [M] • Ops [O] • Company [C] • Market [B] • Infra [I] • Treasury [T] • League [L] • World [Esc]"
    _refresh_workspace_button_states()

func debug_v095_quality_ready() -> bool:
    return (
        V095_QUALITY_REVISION == 1
        and navigation_installed
        and is_instance_valid(navigation_panel)
        and is_instance_valid(navigation_button)
        and navigation_panel.position.x >= NAV_MARGIN
        and navigation_panel.size.x <= NAV_MAX_WIDTH
        and workspace_buttons.has("world")
        and workspace_buttons.has("ops")
        and workspace_buttons.has("company")
        and workspace_buttons.has("market")
        and workspace_buttons.has("infrastructure")
        and workspace_buttons.has("treasury")
        and workspace_buttons.has("league")
    )
