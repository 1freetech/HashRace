extends Node
class_name HashRaceMachineStateController
## Small state controller adapted from Ste's state-machine lifecycle pattern.
## Designed for ASIC, cooling and power visuals without replacing simulation math.

signal state_changed(old_state: StringName, new_state: StringName)

const IDLE := &"idle"
const RUNNING := &"running"
const HOT := &"hot"
const CRITICAL := &"critical"
const BROWNOUT := &"brownout"
const OFFLINE := &"offline"

@export var heat_warning_c := 68.0
@export var heat_critical_c := 82.0

var state: StringName = IDLE
var previous_state: StringName = IDLE

func update_from_operating_values(load_mw: float, available_mw: float, temperature_c: float, uptime: float) -> StringName:
    var safe_load := maxf(load_mw, 0.0)
    var safe_available := maxf(available_mw, 0.0)
    var safe_uptime := clampf(uptime, 0.0, 1.0)
    var warning_threshold := minf(heat_warning_c, heat_critical_c)
    var critical_threshold := maxf(heat_warning_c, heat_critical_c)

    var next := RUNNING
    if safe_uptime <= 0.01:
        next = OFFLINE
    elif safe_load <= 0.001:
        next = IDLE
    elif safe_available + 0.0001 < safe_load:
        next = BROWNOUT
    elif temperature_c >= critical_threshold:
        next = CRITICAL
    elif temperature_c >= warning_threshold:
        next = HOT
    _set_state(next)
    return state

func _set_state(next: StringName) -> void:
    if next == state:
        return
    previous_state = state
    state = next
    state_changed.emit(previous_state, state)

func status_color() -> Color:
    match state:
        RUNNING:
            return Color("37f6a0")
        HOT:
            return Color("ffc45e")
        CRITICAL:
            return Color("ff3b30")
        BROWNOUT, OFFLINE:
            return Color("ff6b6b")
        _:
            return Color("7896a8")
