extends "res://scripts/world_v082.gd"

# Hash Race v0.085 turn-flow shortcut.
# Space previews the current settlement and Space again confirms it, while
# Escape continues to cancel a pending preview. Keyboard activation is ignored
# while a GUI control owns focus so editing Custom days remains safe.

const V085_TURN_SHORTCUT_REVISION: int = 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_turn_shortcut_revision", V085_TURN_SHORTCUT_REVISION)
    if is_instance_valid(quarter_button):
        quarter_button.tooltip_text = "End the current %s turn. Shortcut: Space to preview, Space again to confirm; Esc cancels." % turn_length_name()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
            if get_viewport().gui_get_focus_owner() == null and not campaign_complete:
                _end_quarter()
                get_viewport().set_input_as_handled()
                return
    super._unhandled_input(event)

func _refresh_ui() -> void:
    super._refresh_ui()
    if is_instance_valid(quarter_button):
        quarter_button.tooltip_text = "End the current %s turn. Shortcut: Space to preview, Space again to confirm; Esc cancels." % turn_length_name()

func debug_turn_shortcut_ready() -> bool:
    return V085_TURN_SHORTCUT_REVISION == 1 and has_method("_end_quarter")
