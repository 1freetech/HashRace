extends Node
class_name HashRaceCameraProportionController

signal zoom_changed(zoom_value: float, mode_name: String)

# Lower zoom values show more of the city. The presets deliberately avoid
# arbitrary per-frame scaling: players switch between a small set of stable
# views while all world positions remain pixel-snapped by the live renderer.
const ZOOM_LEVELS: Array[float] = [0.75, 1.0, 1.5, 2.0]
const ZOOM_NAMES: Array[String] = ["CITY", "STREET", "DETAIL", "CLOSE"]

var camera: Camera2D
var world_size := Vector2.ZERO
var zoom_index: int = 0
var default_zoom_index: int = 0

func bind(target_camera: Camera2D, map_size: Vector2, initial_index: int = 0) -> void:
    camera = target_camera
    world_size = map_size
    default_zoom_index = clampi(initial_index, 0, ZOOM_LEVELS.size() - 1)
    zoom_index = default_zoom_index
    _apply_zoom()

func zoom_in() -> void:
    set_zoom_index(zoom_index + 1)

func zoom_out() -> void:
    set_zoom_index(zoom_index - 1)

func reset_zoom() -> void:
    set_zoom_index(default_zoom_index)

func set_zoom_index(value: int) -> void:
    var next_index := clampi(value, 0, ZOOM_LEVELS.size() - 1)
    if next_index == zoom_index and is_instance_valid(camera):
        _apply_zoom()
        return
    zoom_index = next_index
    _apply_zoom()

func _apply_zoom() -> void:
    if not is_instance_valid(camera):
        return
    var value := ZOOM_LEVELS[zoom_index]
    camera.zoom = Vector2(value, value)
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(world_size.x)
    camera.limit_bottom = int(world_size.y)
    zoom_changed.emit(value, ZOOM_NAMES[zoom_index])

func _unhandled_input(event: InputEvent) -> void:
    if not is_instance_valid(camera):
        return
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if not key_event.pressed or key_event.echo:
            return
        if key_event.keycode == KEY_MINUS:
            zoom_out()
            get_viewport().set_input_as_handled()
        elif key_event.keycode == KEY_EQUAL:
            zoom_in()
            get_viewport().set_input_as_handled()
        elif key_event.keycode == KEY_0:
            reset_zoom()
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton:
        var mouse_event := event as InputEventMouseButton
        if not mouse_event.pressed or not mouse_event.ctrl_pressed:
            return
        if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom_in()
            get_viewport().set_input_as_handled()
        elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom_out()
            get_viewport().set_input_as_handled()

func current_zoom() -> float:
    return ZOOM_LEVELS[zoom_index]

func current_mode_name() -> String:
    return ZOOM_NAMES[zoom_index]

func debug_camera_proportion_ready() -> bool:
    return ZOOM_LEVELS.size() == 4 and ZOOM_LEVELS[0] < 1.0 and ZOOM_LEVELS[ZOOM_LEVELS.size() - 1] >= 2.0
