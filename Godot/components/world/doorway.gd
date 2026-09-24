@tool
extends Area2D
class_name HashRaceDoorway

signal doorway_entered(actor: Node2D)
signal doorway_left(actor: Node2D)

@export_file("*.tscn") var target_scene: String
@export var target_spawn_point: String = "SpawnPoint_Default"
@export var door_tag: String = ""
@export var target_door_tag: String = ""
@export var preserve_current_scene: bool = true
@export var return_to_previous_scene: bool = false
@export var auto_enter: bool = true
@export var require_interact: bool = false
@export var player_groups: Array[StringName] = [&"Player", &"player"]

var _candidate: Node2D
var _locked: bool = false

func _ready() -> void:
    monitoring = true
    add_to_group("doors")
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
    if _candidate == null or auto_enter or not require_interact:
        return
    var interact_pressed := event.is_action_pressed("ui_accept")
    if event is InputEventKey:
        var key_event := event as InputEventKey
        interact_pressed = interact_pressed or (
            key_event.pressed
            and not key_event.echo
            and key_event.keycode in [KEY_E, KEY_ENTER, KEY_SPACE]
        )
    if interact_pressed and try_interact():
        get_viewport().set_input_as_handled()

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
    if _locked:
        return
    var manager := get_node_or_null("/root/SceneManager")
    if manager == null:
        push_warning("HashRaceDoorway requires the SceneManager autoload.")
        return

    _locked = true
    if return_to_previous_scene:
        manager.call_deferred("return_to_previous", target_spawn_point, {})
        return

    if target_scene.is_empty():
        _locked = false
        return

    var destination := target_spawn_point
    if destination.is_empty() and not target_door_tag.is_empty():
        destination = target_door_tag
    manager.call_deferred("transition_to", target_scene, destination, preserve_current_scene, {})

func _is_player(body: Node) -> bool:
    for group_name in player_groups:
        if body.is_in_group(group_name):
            return true
    return false

func debug_doorway_ready() -> bool:
    return (
        has_node("CollisionShape2D")
        and not player_groups.is_empty()
        and (target_scene.is_empty() or target_scene.ends_with(".tscn"))
    )
