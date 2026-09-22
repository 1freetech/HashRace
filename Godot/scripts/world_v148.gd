extends "res://scripts/world_v147.gd"

# Hash Race v0.148: predictable interaction-route intent.
# Keep the ten-company Bitcoin mining league unchanged while preventing F from
# silently retargeting an active route or starting an accidental cross-map walk.
const V148_ROUTE_INTENT_REVISION := 1
const V148_QUICK_ROUTE_MULTIPLIER := 2.5

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F:
            if get_viewport().gui_get_focus_owner() != null:
                return
            # Preserve the player's current destination. A second F press should
            # report the active route rather than silently jumping to a new target.
            if pending_interaction_idx >= 0 and pending_interaction_idx < entities.size():
                _refresh_compact_prompt()
                _feedback("Route already active. Press Esc to cancel.")
                get_viewport().set_input_as_handled()
                return
            var idx := _nearest_entity()
            if idx >= 0:
                if _entity_in_interact_range(idx):
                    if _v145_try_interact_nearest():
                        get_viewport().set_input_as_handled()
                        return
                else:
                    var distance := rep_pos.distance_to(_entity_interaction_point(idx))
                    var quick_route_limit := INTERACT_RANGE * V148_QUICK_ROUTE_MULTIPLIER
                    if distance <= quick_route_limit:
                        _queue_or_open_interaction(idx)
                        _refresh_compact_prompt()
                        get_viewport().set_input_as_handled()
                        return
                    var target_name := String(entities[idx].get("name", "TARGET")).to_upper()
                    _feedback("%s is %dm away. Move closer before quick-routing." % [target_name, int(round(distance))])
                    get_viewport().set_input_as_handled()
                    return
            _feedback("No interaction target available.")
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)

func debug_v148_ready() -> bool:
    return V148_ROUTE_INTENT_REVISION == 1 \
        and is_equal_approx(V148_QUICK_ROUTE_MULTIPLIER, 2.5) \
        and V138_MINING_COMPANIES.size() == 10 \
        and debug_v147_ready()
