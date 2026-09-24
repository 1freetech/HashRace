extends "res://scripts/world_v146.gd"

# Hash Race v0.147: interaction routing and keyboard-focus safety.
# Keep the ten-company Bitcoin mining league unchanged while making F useful
# both inside and just outside interaction range and keeping UI focus safe.
const V147_INTERACTION_ROUTE_REVISION := 1

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F:
            # A focused UI control owns keyboard input; do not fire a world action.
            if get_viewport().gui_get_focus_owner() != null:
                return
            var idx := _nearest_entity()
            if idx >= 0:
                if _entity_in_interact_range(idx):
                    if _v145_try_interact_nearest():
                        get_viewport().set_input_as_handled()
                        return
                else:
                    # Reuse the proven click-interaction route so F approaches the
                    # target's real interaction point rather than its building center.
                    _queue_or_open_interaction(idx)
                    _refresh_compact_prompt()
                    get_viewport().set_input_as_handled()
                    return
            _feedback("No interaction target available.")
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
        compact_prompt.text = "ROUTING  •  %s  •  %dm  •  ESC CANCEL" % [route_name, int(round(route_distance))]
        compact_prompt.add_theme_color_override("font_color", Color("8affbd"))
        return
    super._refresh_compact_prompt()

func debug_v147_ready() -> bool:
    return V147_INTERACTION_ROUTE_REVISION == 1 \
        and V138_MINING_COMPANIES.size() == 10 \
        and debug_v146_ready()
