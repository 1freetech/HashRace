extends "res://scripts/world_v091.gd"

# Hash Race v0.092 focused route/input/readability maintenance pass.
# Keeps v0.091 interaction geometry while tightening keyboard focus, route
# cancellation, nearest-target selection, and contextual field prompts.

const V092_QUALITY_REVISION: int = 1
const V092_INTERACT_PROMPT_DISTANCE: float = INTERACT_RANGE

var _last_pending_interaction_idx: int = -1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v092_quality_revision", V092_QUALITY_REVISION)
    _refresh_v092_turn_hint()

func _process(delta: float) -> void:
    _last_pending_interaction_idx = pending_interaction_idx
    super._process(delta)

    # A route that becomes invalid should never disappear without telling the
    # player why. v0.091 cleared this silently when movement/path state ended.
    if _last_pending_interaction_idx >= 0 and pending_interaction_idx < 0:
        if _last_pending_interaction_idx < entities.size() and not _entity_in_interact_range(_last_pending_interaction_idx):
            _feedback("Route stopped before interaction range. Pick another approach or move closer.")

    # Interaction copy is useful only when an actionable target is nearby.
    if is_instance_valid(interact_label):
        var nearest := _nearest_entity()
        interact_label.visible = (
            not interact_label.text.is_empty()
            and nearest >= 0
            and rep_pos.distance_to(_entity_interaction_point(nearest)) <= V092_INTERACT_PROMPT_DISTANCE
        )

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo:
            # Do not turn Space into a world action while a UI control owns
            # keyboard focus (sliders, text fields, buttons, future menus).
            if key_event.keycode == KEY_SPACE and get_viewport().gui_get_focus_owner() != null:
                return
            if key_event.keycode == KEY_ESCAPE and pending_interaction_idx >= 0:
                _cancel_pending_interaction()
                _feedback("Route cancelled.")
                get_viewport().set_input_as_handled()
                return

    if event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
            var idx := _entity_at(get_global_mouse_position())
            # A normal ground click intentionally replaces a queued interaction
            # instead of leaving a stale target waiting to open later.
            if idx < 0 and pending_interaction_idx >= 0:
                pending_interaction_idx = -1

    super._unhandled_input(event)

func _nearest_entity() -> int:
    # Use the same front-door interaction geometry for selection that v0.091
    # uses for range checks. Center-distance could choose the wrong large building.
    var best_idx := -1
    var best_distance := INF
    for i in range(entities.size()):
        var distance := rep_pos.distance_to(_entity_interaction_point(i))
        if distance < best_distance:
            best_distance = distance
            best_idx = i
    return best_idx

func _queue_or_open_interaction(idx: int) -> void:
    if idx < 0 or idx >= entities.size():
        return
    if pending_interaction_idx == idx and not _entity_in_interact_range(idx):
        var entity: Dictionary = entities[idx]
        _feedback("Still routing to %s. Esc cancels the route." % String(entity.get("name", "target")))
        return
    super._queue_or_open_interaction(idx)

func _draw_pixel_town_labels() -> void:
    # When a company interaction is selected, the dialog and selected-building
    # plate already provide location context; suppress the extra town banner.
    if selected_entity_idx >= 0:
        return
    super._draw_pixel_town_labels()

func _show_building_name(pos: Vector2, idx: int) -> bool:
    # While routing, label only the destination building. Otherwise retain the
    # v0.091 selected/nearest contextual rule.
    if pending_interaction_idx >= 0:
        return idx == pending_interaction_idx
    return super._show_building_name(pos, idx)

func _refresh_ui() -> void:
    super._refresh_ui()
    _refresh_v092_turn_hint()

func _refresh_v092_turn_hint() -> void:
    if is_instance_valid(quarter_button):
        quarter_button.tooltip_text = "Q previews the current %s turn. Space interacts nearby. Esc cancels a queued route or turn preview." % turn_length_name()

func debug_v092_ready() -> bool:
    return (
        V092_QUALITY_REVISION == 1
        and has_method("debug_v091_ready")
        and has_method("_entity_interaction_point")
        and has_method("_cancel_pending_interaction")
        and has_method("_nearest_entity")
    )
