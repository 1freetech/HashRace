extends "res://scripts/world_v095.gd"

# Hash Race v0.096 world-focus escape behavior.
# Escape acts as a predictable back control for the decluttered navigation shell:
# it closes NAV first, then returns an open workspace to the playable overworld.

const V096_ESCAPE_WORLD_REVISION: int = 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v096_escape_world_revision", V096_ESCAPE_WORLD_REVISION)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
            # Preserve the established turn-preview cancellation path first.
            if live_quarter_confirmation_pending:
                super._unhandled_input(event)
                _refresh_nav_turn_button()
                return
            # First Escape closes the lightweight NAV chooser.
            if is_instance_valid(navigation_panel) and navigation_panel.visible:
                navigation_panel.visible = false
                get_viewport().set_input_as_handled()
                return
            # Second Escape (or Escape from any workspace) restores world play.
            if navigation_installed and active_workspace != "world":
                _activate_workspace("world")
                get_viewport().set_input_as_handled()
                return
    super._unhandled_input(event)

func debug_v096_ready() -> bool:
    return (
        V096_ESCAPE_WORLD_REVISION == 1
        and debug_v095_ready()
        and navigation_installed
        and active_workspace == "world"
    )
