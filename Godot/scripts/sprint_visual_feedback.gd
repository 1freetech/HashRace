extends Node2D

func _ready() -> void:
    set_process(true)

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    queue_redraw()
