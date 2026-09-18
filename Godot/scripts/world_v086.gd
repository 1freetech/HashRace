extends "res://scripts/world_v085.gd"

# Hash Race v0.086 turn-confirmation clarity pass.
# v0.085 already routes Space through the live _end_quarter() settlement gate,
# which owns live_quarter_confirmation_pending. This layer makes that state
# visible on the End Turn button instead of calling the unrelated legacy
# world_market.gd request_end_quarter() path.

const V086_TURN_CONFIRMATION_REVISION: int = 2

func _ready() -> void:
    super._ready()
    set_meta("hashrace_turn_confirmation_revision", V086_TURN_CONFIRMATION_REVISION)
    _refresh_v086_turn_button()

func _refresh_ui() -> void:
    super._refresh_ui()
    _refresh_v086_turn_button()

func _refresh_v086_turn_button() -> void:
    if not is_instance_valid(quarter_button):
        return
    var label := turn_length_name()
    if live_quarter_confirmation_pending:
        quarter_button.text = "CONFIRM %s TURN" % label
        quarter_button.tooltip_text = "Settlement preview is armed. End Turn or Space confirms; Esc cancels."
    else:
        quarter_button.text = "PREVIEW %s TURN" % label
        quarter_button.tooltip_text = "Preview the current %s settlement before committing it. Shortcut: Space." % label

func debug_v086_turn_confirmation_ready() -> bool:
    return V086_TURN_CONFIRMATION_REVISION == 2 and has_method("_end_quarter")
