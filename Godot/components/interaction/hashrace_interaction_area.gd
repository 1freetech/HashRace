@tool
extends Area2D
class_name HashRaceInteractionArea
## Lightweight Hash Race interaction area adapted from Ste's top-down template.

signal interaction_ready(actor: Node2D)
signal interaction_left(actor: Node2D)
signal interacted(actor: Node2D)

@export var interaction_text := "PRESS E"
@export var player_group := "player"
@export var one_shot := false
@export var reset_delay := 0.15

var _candidate: Node2D
var _candidates: Array[Node2D] = []
var _locked := false

func _init() -> void:
    monitorable = false
    monitoring = true

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group(player_group) or body in _candidates:
        return
    _candidates.append(body)
    if _candidate == null:
        _candidate = body
        interaction_ready.emit(body)

func _on_body_exited(body: Node2D) -> void:
    if body not in _candidates:
        return
    _candidates.erase(body)
    if body != _candidate:
        return
    interaction_left.emit(body)
    _candidate = _candidates.front() if not _candidates.is_empty() else null
    if _candidate != null:
        interaction_ready.emit(_candidate)

func try_interact(actor: Node2D = _candidate) -> bool:
    if _locked or actor == null or actor != _candidate or actor not in _candidates:
        return false
    _locked = true
    interacted.emit(actor)
    if one_shot:
        monitoring = false
        _candidates.clear()
        _candidate = null
    else:
        _unlock_later()
    return true

func _unlock_later() -> void:
    await get_tree().create_timer(maxf(reset_delay, 0.0)).timeout
    _locked = false
