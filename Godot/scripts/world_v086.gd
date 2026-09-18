extends "res://scripts/world_v085.gd"

# Hash Race v0.086 turn-flow correctness fix.
# Route the Space shortcut through the same preview/confirmation path as the
# visible End Turn button. v0.085 called _end_quarter() directly, bypassing the
# market-layer request_end_quarter() confirmation gate.

const V086_TURN_PREVIEW_REVISION: int = 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_turn_preview_revision", V086_TURN_PREVIEW_REVISION)
    _refresh_v086_turn_tooltip()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
            if get_viewport().gui_get_focus_owner() == null and not campaign_complete:
                request_end_quarter()
                get_viewport().set_input_as_handled()
                return
    # Skip world_v085.gd's Space handler after handling non-Space events here;
    # its parent chain still owns Escape/cancel and all other gameplay input.
    super._unhandled_input(event)

func _refresh_ui() -> void:
    super._refresh_ui()
    _refresh_v086_turn_tooltip()

func _refresh_v086_turn_tooltip() -> void:
    if is_instance_valid(quarter_button):
        quarter_button.tooltip_text = "End the current %s turn. Space previews first; Space again confirms. Esc cancels." % turn_length_name()

func debug_v086_turn_preview_ready() -> bool:
    return V086_TURN_PREVIEW_REVISION == 1 and has_method("request_end_quarter")
