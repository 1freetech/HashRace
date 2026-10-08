extends Node2D

# Lightweight movement feedback. Never draw a replacement character,
# foundation, collision shape, or texture over authored sprite-sheet art.
@export var moving: bool = false
@export var sprinting: bool = false

func _ready() -> void:
    set_process(false)
    queue_redraw()

func set_movement_state(is_moving: bool, is_sprinting: bool) -> void:
    var next_sprinting: bool = is_moving and is_sprinting
    if moving == is_moving and sprinting == next_sprinting:
        return
    moving = is_moving
    sprinting = next_sprinting
    queue_redraw()

func _draw() -> void:
    if not moving or not sprinting:
        return
    # Small ground-level speed ticks only; no full-screen overlays or blocks.
    var tint: Color = Color(0.40, 1.0, 0.55, 0.55)
    draw_line(Vector2(-10, 4), Vector2(-17, 8), tint, 1.0, false)
    draw_line(Vector2(10, 4), Vector2(17, 8), tint, 1.0, false)
