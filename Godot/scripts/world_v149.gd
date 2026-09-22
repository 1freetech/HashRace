extends "res://scripts/world_v148.gd"

# Hash Race v0.149: truthful interaction geometry and route guidance.
# Keep the ten-company Bitcoin mining league unchanged while making every
# nearby interaction cue agree with the front-door point used by routing.
const V149_INTERACTION_GUIDANCE_REVISION := 1

func _refresh_interaction_prompt() -> void:
    if not is_instance_valid(interact_label):
        return
    var idx := _nearest_entity()
    if idx < 0:
        interact_label.text = ""
        return
    var entity: Dictionary = entities[idx]
    var label := String(entity.get("name", entity.get("label", "target"))).to_upper()
    # Use the same front-door interaction point as range checks and routing.
    # Large buildings should never advertise a misleading center-distance.
    var distance := rep_pos.distance_to(_entity_interaction_point(idx))
    if _entity_in_interact_range(idx):
        interact_label.text = "[E/F] INTERACT // %s // %dm" % [label, int(round(distance))]
    elif distance <= INTERACT_RANGE * V148_QUICK_ROUTE_MULTIPLIER:
        interact_label.text = "[F] QUICK ROUTE // %s // %dm" % [label, int(round(distance))]
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
            compact_prompt.text = "[F] QUICK ROUTE  •  %s  •  %dm  •  ESC CANCEL" % [target_name, int(round(distance))]
            compact_prompt.add_theme_color_override("font_color", Color("c4e4ea"))
            return
    compact_prompt.text = "WASD MOVE  •  M MENU  •  T TRANSIT  •  R SCANNER  •  F INTERACT"
    compact_prompt.add_theme_color_override("font_color", Color("c4e4ea"))

func debug_v149_ready() -> bool:
    return V149_INTERACTION_GUIDANCE_REVISION == 1 \
        and V138_MINING_COMPANIES.size() == 10 \
        and debug_v148_ready()
