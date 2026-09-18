extends Node
class_name HashRaceMachineStateController
## Small state controller adapted from Ste's state-machine lifecycle pattern.
## Designed for ASIC, cooling and power visuals without replacing simulation math.

signal state_changed(old_state: StringName, new_state: StringName)

const IDLE := &"idle"
const RUNNING := &"running"
const HOT := &"hot"
const BROWNOUT := &"brownout"
const OFFLINE := &"offline"

@export var heat_warning_c := 68.0
@export var heat_critical_c := 82.0

var state: StringName = IDLE
var previous_state: StringName = IDLE

func update_from_operating_values(load_mw: float, available_mw: float, temperature_c: float, uptime: float) -> StringName:
    var next := RUNNING
    if uptime <= 0.01:
        next = OFFLINE
    elif load_mw <= 0.001:
        next = IDLE
    elif available_mw + 0.0001 < load_mw:
        next = BROWNOUT
    elif temperature_c >= heat_critical_c:
        next = HOT
    elif temperature_c >= heat_warning_c:
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
        BROWNOUT, OFFLINE:
            return Color("ff6b6b")
        _:
            return Color("7896a8")
