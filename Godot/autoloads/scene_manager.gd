extends Node

signal transition_started(scene_path: String, spawn_name: String)
signal transition_completed(scene_path: String, spawn_name: String)
signal transition_failed(scene_path: String, reason: String)

@export_range(0.0, 1.0, 0.05) var fade_seconds: float = 0.18

var pending_spawn_name: String = ""
var transition_payload: Dictionary = {}
var _scene_stack: Array[Dictionary] = []
var _busy: bool = false
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_fade_overlay()

func transition_to(
    scene_path: String,
    spawn_point_name: String = "",
    preserve_current_scene: bool = true,
    payload: Dictionary = {}
) -> bool:
    if _busy:
        return false
    var packed := ResourceLoader.load(scene_path) as PackedScene
    if packed == null:
        transition_failed.emit(scene_path, "Scene could not be loaded")
        return false

    _busy = true
    pending_spawn_name = spawn_point_name
    transition_payload = payload.duplicate(true)
    transition_started.emit(scene_path, spawn_point_name)
    await _fade_to(1.0)

    var tree := get_tree()
    var next_scene: Node

    if preserve_current_scene and is_instance_valid(tree.current_scene):
        var current := tree.current_scene
        tree.root.remove_child(current)
        _scene_stack.append({
            "node": current,
            "scene_path": current.scene_file_path
        })
        next_scene = packed.instantiate()
        tree.root.add_child(next_scene)
        tree.current_scene = next_scene
    else:
        var err := tree.change_scene_to_packed(packed)
        if err != OK:
            _busy = false
            await _fade_to(0.0)
            transition_failed.emit(scene_path, "change_scene_to_packed failed: %s" % str(err))
            return false
        await tree.process_frame
        next_scene = tree.current_scene

    await tree.process_frame
    _place_actor(next_scene)
    await _fade_to(0.0)

    _busy = false
    transition_completed.emit(scene_path, spawn_point_name)
    pending_spawn_name = ""
    transition_payload.clear()
    return true

func return_to_previous(spawn_point_name: String = "", payload: Dictionary = {}) -> bool:
    if _busy or _scene_stack.is_empty():
        return false

    _busy = true
    pending_spawn_name = spawn_point_name
    transition_payload = payload.duplicate(true)
    await _fade_to(1.0)

    var tree := get_tree()
    var current := tree.current_scene
    if is_instance_valid(current):
        tree.root.remove_child(current)
        current.queue_free()

    var entry: Dictionary = _scene_stack.pop_back()
    var previous: Node = entry.get("node")
    if not is_instance_valid(previous):
        _busy = false
        await _fade_to(0.0)
        transition_failed.emit(String(entry.get("scene_path", "")), "Preserved scene is no longer valid")
        return false

    tree.root.add_child(previous)
    tree.current_scene = previous
    await tree.process_frame
    _place_actor(previous)
    await _fade_to(0.0)

    _busy = false
    transition_completed.emit(previous.scene_file_path, spawn_point_name)
    pending_spawn_name = ""
    transition_payload.clear()
    return true

func clear_preserved_scenes() -> void:
    for entry in _scene_stack:
        var node: Node = entry.get("node")
        if is_instance_valid(node):
            node.queue_free()
    _scene_stack.clear()

func stack_depth() -> int:
    return _scene_stack.size()

func is_transitioning() -> bool:
    return _busy

func _place_actor(scene: Node) -> void:
    if not is_instance_valid(scene):
        return

    if scene.has_method("apply_scene_spawn"):
        scene.call("apply_scene_spawn", pending_spawn_name, transition_payload)
        return

    if pending_spawn_name.is_empty():
        return

    var spawn := scene.find_child(pending_spawn_name, true, false) as Node2D
    if spawn == null:
        return

    var actor := _find_player_actor(scene)
    if actor != null:
        actor.global_position = spawn.global_position

func _find_player_actor(scene: Node) -> Node2D:
    var direct := scene.get_node_or_null("Player") as Node2D
    if direct != null:
        return direct

    for group_name in ["Player", "player"]:
        for candidate in get_tree().get_nodes_in_group(group_name):
            if candidate is Node2D and scene.is_ancestor_of(candidate):
                return candidate as Node2D
    return null

func _ensure_fade_overlay() -> void:
    if is_instance_valid(_fade_rect):
        return
    _fade_layer = CanvasLayer.new()
    _fade_layer.name = "SceneTransitionFade"
    _fade_layer.layer = 4096
    add_child(_fade_layer)

    _fade_rect = ColorRect.new()
    _fade_rect.name = "Fade"
    _fade_rect.position = Vector2.ZERO
    _fade_rect.size = get_viewport().get_visible_rect().size
    _fade_rect.color = Color.BLACK
    _fade_rect.modulate.a = 0.0
    _fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _fade_layer.add_child(_fade_rect)

    if not get_viewport().size_changed.is_connected(_resize_fade):
        get_viewport().size_changed.connect(_resize_fade)

func _resize_fade() -> void:
    if is_instance_valid(_fade_rect):
        _fade_rect.size = get_viewport().get_visible_rect().size

func _fade_to(alpha: float) -> void:
    _ensure_fade_overlay()
    var target := clampf(alpha, 0.0, 1.0)
    if fade_seconds <= 0.0:
        _fade_rect.modulate.a = target
        return
    var tween := create_tween()
    tween.tween_property(_fade_rect, "modulate:a", target, fade_seconds)
    await tween.finished

func debug_scene_manager_ready() -> bool:
    return is_instance_valid(_fade_rect) and stack_depth() >= 0
