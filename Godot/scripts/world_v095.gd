extends "res://scripts/world_v094.gd"

# Hash Race v0.095 world-focus escape behavior.
# v0.094 made the overworld intentionally clean, but Escape only closed the NAV
# popup. This revision makes Escape a predictable "back to gameplay" action:
# it closes NAV first, then dismisses whichever workspace is open and restores
# the unobstructed world without changing simulation state.

const V095_ESCAPE_WORLD_REVISION: int = 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v095_escape_world_revision", V095_ESCAPE_WORLD_REVISION)

func _return_to_world() -> void:
    if not navigation_installed:
        return
    _activate_workspace("world")
    if is_instance_valid(navigation_panel):
        navigation_panel.visible = false
    _show_toast("WORLD VIEW")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
            if is_instance_valid(navigation_panel) and navigation_panel.visible:
                navigation_panel.visible = false
                get_viewport().set_input_as_handled()
                return
            if navigation_installed and active_workspace != "world":
                _return_to_world()
                get_viewport().set_input_as_handled()
                return
    super._unhandled_input(event)

func debug_v095_escape_world_ready() -> bool:
    return (
        V095_ESCAPE_WORLD_REVISION == 1
        and has_method("_return_to_world")
        and navigation_installed
        and active_workspace == "world"
    )
