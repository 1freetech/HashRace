extends "res://scripts/world_v090.gd"

# Hash Race v0.091 interaction-quality pass.
# Keep v0.090 strategy/runtime polish intact while fixing how the player reaches
# and activates world targets and reducing persistent field-layer clutter.

const V091_INTERACTION_REVISION: int = 1
const V091_BUILDING_LABEL_DISTANCE: float = 210.0
const V091_TOWN_LABEL_DISTANCE: float = 300.0

var pending_interaction_idx: int = -1

func _ready() -> void:
    super._ready()
    scanner_overlay_enabled = false
    if is_instance_valid(scanner_button):
        scanner_button.visible = false
    if is_instance_valid(phase_label):
        phase_label.visible = false
    _refresh_v091_turn_hint()
    set_meta("hashrace_v091_interaction_revision", V091_INTERACTION_REVISION)
    queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)

    if is_instance_valid(phase_label):
        phase_label.visible = live_quarter_confirmation_pending
        if live_quarter_confirmation_pending:
            phase_label.text = "TURN PREVIEW // CONFIRM OR ESC"
    if is_instance_valid(interact_label):
        interact_label.visible = not interact_label.text.is_empty()

    if pending_interaction_idx < 0:
        return
    if pending_interaction_idx >= entities.size():
        _cancel_pending_interaction()
        return

    if _entity_in_interact_range(pending_interaction_idx):
        var idx := pending_interaction_idx
        _cancel_pending_interaction()
        _invalidate_quarter_preview("Turn preview cancelled because you opened a new interaction.")
        _open_entity(idx)
        return

    # Manual movement clears the route in the inherited grid controller.
    if nav_path.is_empty() and not has_click_target:
        pending_interaction_idx = -1

func _unhandled_input(event: InputEvent) -> void:
    # Space is interaction only. v0.085 also mapped Space to turn advancement;
    # intercepting it here prevents an interaction key from changing the economy.
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_SPACE:
            _activate_nearest_interaction()
            get_viewport().set_input_as_handled()
            return

    # Entity clicks now mean "go there and interact" instead of opening a
    # distant building from across the map.
    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
            var idx := _entity_at(get_global_mouse_position())
            if idx >= 0:
                _queue_or_open_interaction(idx)
                get_viewport().set_input_as_handled()
                return

    super._unhandled_input(event)

func _activate_nearest_interaction() -> void:
    var idx := _nearest_entity()
    if idx < 0 or not _entity_in_interact_range(idx):
        _feedback("Move closer to a company, partner, property, or deal target to interact.")
        return
    _cancel_pending_interaction()
    _invalidate_quarter_preview("Turn preview cancelled because you opened a new interaction.")
    _open_entity(idx)

func _queue_or_open_interaction(idx: int) -> void:
    if idx < 0 or idx >= entities.size():
        return
    if _entity_in_interact_range(idx):
        _cancel_pending_interaction()
        _invalidate_quarter_preview("Turn preview cancelled because you opened a new interaction.")
        _open_entity(idx)
        return

    pending_interaction_idx = idx
    _invalidate_quarter_preview("Turn preview cancelled because the field plan changed.")
    _route_to(_entity_interaction_point(idx))
    if nav_path.is_empty() and not has_click_target:
        pending_interaction_idx = -1
        _feedback("No walkable route to that target.")
        return
    var entity: Dictionary = entities[idx]
    _feedback("Routing to %s. Interaction opens on arrival." % String(entity.get("name", "target")))

func _cancel_pending_interaction() -> void:
    pending_interaction_idx = -1
    if not nav_path.is_empty() or has_click_target:
        _clear_nav_path()

func _entity_interaction_point(idx: int) -> Vector2:
    if idx < 0 or idx >= entities.size():
        return rep_pos
    var entity: Dictionary = entities[idx]
    var pos: Vector2 = entity.get("pos", rep_pos)
    var kind := String(entity.get("kind", ""))
    if WorldScale.is_building_kind(kind):
        return WorldScale.front_door_world_pos(kind, pos)
    return pos

func _entity_in_interact_range(idx: int) -> bool:
    if idx < 0 or idx >= entities.size():
        return false
    return rep_pos.distance_to(_entity_interaction_point(idx)) <= INTERACT_RANGE

func _nearest_building_idx() -> int:
    var best_idx := -1
    var best_distance := INF
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind := String(entity.get("kind", ""))
        if not WorldScale.is_building_kind(kind):
            continue
        var distance := rep_pos.distance_to(_entity_interaction_point(i))
        if distance < best_distance:
            best_distance = distance
            best_idx = i
    return best_idx

func _show_building_name(pos: Vector2, idx: int) -> bool:
    if idx == selected_entity_idx:
        return true
    if idx != _nearest_building_idx():
        return false
    return rep_pos.distance_to(_entity_interaction_point(idx)) <= V091_BUILDING_LABEL_DISTANCE

func _draw_pixel_town_labels() -> void:
    var best_zone: Dictionary = {}
    var best_distance := INF
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = zone.get("center", Vector2.ZERO)
        var distance := rep_pos.distance_to(center)
        if distance < best_distance:
            best_distance = distance
            best_zone = zone
    if best_zone.is_empty() or best_distance > V091_TOWN_LABEL_DISTANCE:
        return

    var center: Vector2 = VisualStack.snap_to_pixel(best_zone["center"])
    var profile_idx := int(best_zone["profile_idx"])
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    var sign_rect := Rect2(center + Vector2(-116.0, -184.0), Vector2(232.0, 25.0))
    _draw_layered_stroke_rect(sign_rect, GBC_INK, Color("020609"), accent.darkened(0.48), 2.0)
    draw_string(
        ThemeDB.fallback_font,
        center + Vector2(-108.0, -166.0),
        String(best_zone["town"]).to_upper(),
        HORIZONTAL_ALIGNMENT_CENTER,
        216.0,
        11,
        accent
    )

func _refresh_ui() -> void:
    super._refresh_ui()
    _refresh_v091_turn_hint()

func _refresh_v091_turn_hint() -> void:
    if is_instance_valid(quarter_button):
        quarter_button.tooltip_text = "Q previews the current %s turn. Confirm with the on-screen button. Space only interacts." % turn_length_name()

func debug_v091_ready() -> bool:
    return (
        V091_INTERACTION_REVISION == 1
        and has_method("_entity_interaction_point")
        and has_method("_queue_or_open_interaction")
        and has_method("debug_v090_ready")
        and not scanner_overlay_enabled
    )
