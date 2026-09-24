extends "res://scripts/world_v151.gd"

# Hash Race v0.152: clearer active-route controls.
# Preserve the ten-company Bitcoin mining league while making an active
# interaction route easier to understand and cancel without opening menus.
const V152_ROUTE_CONTROL_REVISION := 1

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if get_viewport().gui_get_focus_owner() != null:
                return
            # Q is an explicit route-cancel shortcut in addition to Esc. This
            # keeps route control available to the movement hand.
            if key_event.keycode == KEY_Q and pending_interaction_idx >= 0:
                _cancel_pending_interaction()
                _refresh_compact_prompt()
                _feedback("Route cancelled.")
                get_viewport().set_input_as_handled()
                return
            # When a route is active, E/F should identify that route rather
            # than replacing it or returning a generic warning.
            if key_event.keycode in [KEY_E, KEY_F] \
                    and pending_interaction_idx >= 0 \
                    and pending_interaction_idx < entities.size():
                var route_entity: Dictionary = entities[pending_interaction_idx]
                var route_name := String(route_entity.get("name", "TARGET")).to_upper()
                var route_distance := rep_pos.distance_to(_entity_interaction_point(pending_interaction_idx))
                _refresh_compact_prompt()
                _feedback("Routing to %s (%dm). Esc/Q cancels." % [route_name, int(round(route_distance))])
                get_viewport().set_input_as_handled()
                return
    super._unhandled_input(event)

func _refresh_compact_prompt() -> void:
    if not is_instance_valid(compact_prompt):
        return
    if pending_interaction_idx >= 0 and pending_interaction_idx < entities.size():
        var route_entity: Dictionary = entities[pending_interaction_idx]
        var route_name := String(route_entity.get("name", "TARGET")).to_upper()
        var route_distance := rep_pos.distance_to(_entity_interaction_point(pending_interaction_idx))
        compact_prompt.text = "ROUTING  •  %s  •  %dm  •  ESC/Q CANCEL" % [route_name, int(round(route_distance))]
        compact_prompt.add_theme_color_override("font_color", Color("8affbd"))
        return
    super._refresh_compact_prompt()

func debug_v152_ready() -> bool:
    return V152_ROUTE_CONTROL_REVISION == 1 \
        and V138_MINING_COMPANIES.size() == 10 \
        and debug_v151_ready()
