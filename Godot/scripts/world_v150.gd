extends "res://scripts/world_v149.gd"

# Hash Race v0.150: interaction-control clarity.
# Preserve the ten-company Bitcoin mining league while making field prompts
# describe only actions that are actually available in the current state.
const V150_INTERACTION_CLARITY_REVISION := 1

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F:
            if get_viewport().gui_get_focus_owner() != null:
                return
            if pending_interaction_idx < 0:
                var idx := _nearest_entity()
                if idx >= 0 and not _entity_in_interact_range(idx):
                    var distance := rep_pos.distance_to(_entity_interaction_point(idx))
                    if distance <= INTERACT_RANGE * V148_QUICK_ROUTE_MULTIPLIER:
                        var target_name := String(entities[idx].get("name", "TARGET")).to_upper()
                        _queue_or_open_interaction(idx)
                        _refresh_compact_prompt()
                        _feedback("Routing to %s. Press Esc to cancel." % target_name)
                        get_viewport().set_input_as_handled()
                        return
    super._unhandled_input(event)

func _refresh_compact_prompt() -> void:
    if not is_instance_valid(compact_prompt):
        return
    if pending_interaction_idx >= 0 and pending_interaction_idx < entities.size():
        super._refresh_compact_prompt()
        return
    var idx := _nearest_entity()
    if idx >= 0:
        var entity: Dictionary = entities[idx]
        var target_name := String(entity.get("name", "TARGET")).to_upper()
        var distance := rep_pos.distance_to(_entity_interaction_point(idx))
        if _entity_in_interact_range(idx):
            compact_prompt.text = "[E/F] INTERACT  •  %s  •  %dm" % [target_name, int(round(distance))]
            compact_prompt.add_theme_color_override("font_color", Color("8affbd"))
            return
        if distance <= INTERACT_RANGE * V148_QUICK_ROUTE_MULTIPLIER:
            # Esc cancels an active route; do not advertise it before routing begins.
            compact_prompt.text = "[F] QUICK ROUTE  •  %s  •  %dm" % [target_name, int(round(distance))]
            compact_prompt.add_theme_color_override("font_color", Color("c4e4ea"))
            return
    # E and F are both valid interaction keys in range, so the idle legend must
    # not imply that only F is supported.
    compact_prompt.text = "WASD MOVE  •  M MENU  •  T TRANSIT  •  R SCANNER  •  E/F INTERACT"
    compact_prompt.add_theme_color_override("font_color", Color("c4e4ea"))

func debug_v150_ready() -> bool:
    return V150_INTERACTION_CLARITY_REVISION == 1 \
        and V138_MINING_COMPANIES.size() == 10 \
        and debug_v149_ready()
