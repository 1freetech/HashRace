extends Camera2D
class_name HashRacePixelPerfectCamera
## Smooth target follow with final pixel snapping for crisp low-resolution art.

@export var target: Node2D
@export var smooth_speed := 8.0
@export var pixel_snap := true

func _process(delta: float) -> void:
    if not is_instance_valid(target):
        return
    var weight := 1.0 - exp(-smooth_speed * delta)
    global_position = global_position.lerp(target.global_position, weight)
    if pixel_snap:
        global_position = global_position.round()
