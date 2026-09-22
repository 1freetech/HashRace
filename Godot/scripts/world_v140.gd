extends "res://scripts/world_v139.gd"

# Hash Race v0.140: character-motion quality + release-proof pass.
# The approved 32-pose binary remains unchanged; this layer verifies that the
# live representative now advances walk frames from actual resolved travel.
const RPGMovementV140 = preload("res://scripts/rpg_movement.gd")
const V140_CHARACTER_MOTION_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v140_distance_synced_walk", RPGMovementV140.debug_distance_synced_walk())

func debug_v140_ready() -> bool:
    return V140_CHARACTER_MOTION_REVISION == 1 \
        and bool(get_meta("hashrace_v140_distance_synced_walk", false)) \
        and RPGMovementV140.debug_distance_synced_walk() \
        and debug_v139_ready()
