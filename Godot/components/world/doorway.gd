@tool
extends Area2D
class_name HashRaceDoorway

signal doorway_entered(actor: Node2D)
signal doorway_left(actor: Node2D)

@export_file("*.tscn") var target_scene: String
@export var target_spawn_point: String = "SpawnPoint_Default"
@export var preserve_current_scene: bool = true
@export var auto_enter: bool = true
@export var require_interact: bool = false
@export var player_groups: Array[StringName] = [&"Player", &"player"]

var _candidate: Node2D
var _locked: bool = false

func _ready() -> void:
    monitoring = true
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
    if not _is_player(body):
        return
    _candidate = body
    doorway_entered.emit(body)
    if auto_enter and not require_interact:
        _activate()

func _on_body_exited(body: Node2D) -> void:
    if body != _candidate:
        return
    doorway_left.emit(body)
    _candidate = null

func try_interact(actor: Node2D = _candidate) -> bool:
    if _locked or actor == null or actor != _candidate or not _is_player(actor):
        return false
    _activate()
    return true

func _activate() -> void:
    if _locked or target_scene.is_empty():
        return
    var manager := get_node_or_null("/root/SceneManager")
    if manager == null:
        push_warning("HashRaceDoorway requires the SceneManager autoload.")
        return
    _locked = true
    manager.call_deferred("transition_to", target_scene, target_spawn_point, preserve_current_scene, {})

func _is_player(body: Node) -> bool:
    for group_name in player_groups:
        if body.is_in_group(group_name):
            return true
    return false

func debug_doorway_ready() -> bool:
    return has_node("CollisionShape2D") and not player_groups.is_empty()
