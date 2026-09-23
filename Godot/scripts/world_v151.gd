extends "res://scripts/world_v150.gd"

# Hash Race v0.151: consistent interaction controls.
# Keep the ten-company Bitcoin mining league unchanged while making E and F
# follow the same nearby interaction/quick-route rules advertised by the HUD.
const V151_INTERACTION_CONSISTENCY_REVISION := 1

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode in [KEY_E, KEY_F]:
            if get_viewport().gui_get_focus_owner() != null:
                return
            # Do not let a second interaction key silently replace an active route.
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
                        var target_name := String(entities[idx].get("name", "TARGET")).to_upper()
                        _queue_or_open_interaction(idx)
                        _refresh_compact_prompt()
                        _feedback("Routing to %s. Press Esc to cancel." % target_name)
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

func _refresh_interaction_prompt() -> void:
    if not is_instance_valid(interact_label):
        return
    var idx := _nearest_entity()
    if idx < 0:
        interact_label.text = ""
        return
    var entity: Dictionary = entities[idx]
    var label := String(entity.get("name", entity.get("label", "target"))).to_upper()
    var distance := rep_pos.distance_to(_entity_interaction_point(idx))
    if _entity_in_interact_range(idx):
        interact_label.text = "[E/F] INTERACT // %s // %dm" % [label, int(round(distance))]
    elif distance <= INTERACT_RANGE * V148_QUICK_ROUTE_MULTIPLIER:
        interact_label.text = "[E/F] QUICK ROUTE // %s // %dm" % [label, int(round(distance))]
    else:
        interact_label.text = ""

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
            compact_prompt.text = "[E/F] QUICK ROUTE  •  %s  •  %dm" % [target_name, int(round(distance))]
            compact_prompt.add_theme_color_override("font_color", Color("c4e4ea"))
            return
    compact_prompt.text = "WASD MOVE  •  M MENU  •  T TRANSIT  •  R SCANNER  •  E/F INTERACT"
    compact_prompt.add_theme_color_override("font_color", Color("c4e4ea"))

func debug_v151_ready() -> bool:
    return V151_INTERACTION_CONSISTENCY_REVISION == 1 \
        and V138_MINING_COMPANIES.size() == 10 \
        and debug_v150_ready()
