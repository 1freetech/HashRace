extends Node
class_name HashRaceNegotiationManager

signal negotiation_started(context: Dictionary)
signal negotiation_resolved(result: Dictionary)

const NEGOTIATION_SCENE: PackedScene = preload("res://scenes/NegotiationScene.tscn")

var active_scene: Node = null
var last_result: Dictionary = {}
var active_context: Dictionary = {}

func launch(host: Node, context: Dictionary) -> Node:
    if is_instance_valid(active_scene):
        return active_scene
    if host == null:
        return null

    var scene: Node = NEGOTIATION_SCENE.instantiate()
    if scene == null:
        return null

    active_context = context.duplicate(true)
    scene.call("configure", active_context)
    scene.connect("negotiation_finished", Callable(self, "_on_negotiation_finished"))
    scene.connect("scene_closed", Callable(self, "_on_scene_closed"))
    scene.tree_exited.connect(Callable(self, "_on_scene_tree_exited"))
    active_scene = scene
    host.add_child(scene)
    negotiation_started.emit(active_context.duplicate(true))
    return scene

func close_active() -> void:
    if not is_instance_valid(active_scene):
        active_scene = null
        return
    active_scene.queue_free()
    active_scene = null

func _on_negotiation_finished(result: Dictionary) -> void:
    last_result = result.duplicate(true)
    negotiation_resolved.emit(last_result.duplicate(true))

func _on_scene_closed(_result: Dictionary) -> void:
    active_scene = null

func _on_scene_tree_exited() -> void:
    active_scene = null

func debug_ready() -> bool:
    return NEGOTIATION_SCENE != null

func debug_snapshot() -> Dictionary:
    return {
        "active": is_instance_valid(active_scene),
        "context": active_context.duplicate(true),
        "result": last_result.duplicate(true)
    }
