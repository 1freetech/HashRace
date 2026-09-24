@tool
extends Area2D
class_name HashRaceRoofFadeArea

@export var target_path: NodePath
@export_range(0.1, 1.0, 0.05) var faded_alpha: float = 0.30
@export_range(0.0, 1.0, 0.05) var fade_seconds: float = 0.20
@export var player_groups: Array[StringName] = [&"Player", &"player"]

var _inside_count: int = 0
var _active_tween: Tween

func _ready() -> void:
    monitoring = true
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
    if not _is_player(body):
        return
    _inside_count += 1
    _fade_to(faded_alpha)

func _on_body_exited(body: Node2D) -> void:
    if not _is_player(body):
        return
    _inside_count = maxi(0, _inside_count - 1)
    if _inside_count == 0:
        _fade_to(1.0)

func _fade_to(alpha: float) -> void:
    var target := _target_canvas_item()
    if target == null:
        return
    if is_instance_valid(_active_tween):
        _active_tween.kill()
    if fade_seconds <= 0.0:
        target.modulate.a = alpha
        return
    _active_tween = create_tween()
    _active_tween.tween_property(target, "modulate:a", alpha, fade_seconds)

func _target_canvas_item() -> CanvasItem:
    if not target_path.is_empty():
        return get_node_or_null(target_path) as CanvasItem
    return get_parent() as CanvasItem

func _is_player(body: Node) -> bool:
    for group_name in player_groups:
        if body.is_in_group(group_name):
            return true
    return false

func debug_roof_fade_ready() -> bool:
    return faded_alpha < 1.0
