extends "res://scripts/world_v123.gd"

# Hash Race v0.124 keyboard interaction routing.
# E/Enter/Space still opens an in-range target immediately, but when the nearest
# company, partner, property, or deal target is outside interaction range the
# same key now queues the proven navigation route instead of only showing an
# error. This makes keyboard exploration match the existing click-to-route loop.

const V124_KEYBOARD_ROUTE_REVISION := 1

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_E or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE:
                # Preserve focused UI controls: Space must never leak through a
                # button, slider, text field, or future menu into world routing.
                if key_event.keycode == KEY_SPACE and get_viewport().gui_get_focus_owner() != null:
                    super._unhandled_input(event)
                    return
                var idx := _nearest_entity()
                if idx >= 0 and not _entity_in_interact_range(idx):
                    _invalidate_quarter_preview("Turn preview cancelled because you started a field route.")
                    var entity: Dictionary = entities[idx]
                    _queue_or_open_interaction(idx)
                    _feedback("Routing to %s. Esc cancels the route." % String(entity.get("name", "target")))
                    get_viewport().set_input_as_handled()
                    return
    super._unhandled_input(event)

func debug_v124_ready() -> bool:
    return V124_KEYBOARD_ROUTE_REVISION == 1 and has_method("_queue_or_open_interaction") and debug_v123_ready()
