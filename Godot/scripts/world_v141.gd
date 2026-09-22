extends "res://scripts/world_v140.gd"

# Hash Race v0.141: player-control polish.
# Keep the approved 32-pose binary and make its runtime behavior calmer:
# tiny analog drift is ignored and every stop settles back to the authored idle.
const RPGMovementV141 = preload("res://scripts/rpg_movement.gd")
const V141_PLAYER_CONTROL_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v141_input_deadzone", RPGMovementV141.debug_input_deadzone())
    set_meta("hashrace_v141_idle_reset", RPGMovementV141.debug_idle_reset())

func debug_v141_ready() -> bool:
    return V141_PLAYER_CONTROL_REVISION == 1 \
        and bool(get_meta("hashrace_v141_input_deadzone", false)) \
        and bool(get_meta("hashrace_v141_idle_reset", false)) \
        and RPGMovementV141.debug_equal_speed() \
        and RPGMovementV141.debug_distance_synced_walk() \
        and debug_v140_ready()
