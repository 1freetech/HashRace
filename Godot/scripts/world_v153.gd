extends "res://scripts/world_v152.gd"

# Hash Race v0.153: resilient quick-route state.
# Keep the ten-company Bitcoin mining league unchanged while preventing stale
# navigation targets from trapping or silently redirecting player interaction.
const V153_ROUTE_RESILIENCE_REVISION := 1

func _route_target_is_valid() -> bool:
    return pending_interaction_idx >= 0 and pending_interaction_idx < entities.size()

func _recover_stale_route() -> bool:
    if pending_interaction_idx < 0 or _route_target_is_valid():
        return false
    pending_interaction_idx = -1
    _refresh_compact_prompt()
    _feedback("Route target is no longer available. Route cleared.")
    return true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode in [KEY_E, KEY_F, KEY_Q]:
            if get_viewport().gui_get_focus_owner() != null:
                return
            # Entity lists can change after deals, site updates, or world events.
            # Clear an out-of-range route before inherited interaction code can
            # accidentally treat the stale index as a new valid destination.
            if _recover_stale_route():
                get_viewport().set_input_as_handled()
                return
    super._unhandled_input(event)

func _refresh_compact_prompt() -> void:
    if not is_instance_valid(compact_prompt):
        return
    if pending_interaction_idx >= 0 and not _route_target_is_valid():
        pending_interaction_idx = -1
    super._refresh_compact_prompt()

func debug_v153_ready() -> bool:
    return V153_ROUTE_RESILIENCE_REVISION == 1 \
        and V138_MINING_COMPANIES.size() == 10 \
        and debug_v152_ready()
