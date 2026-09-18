class_name HashRacePhysicalPlacementGrid
extends Node2D

const PlacementFeedback = preload("res://components/building/placement_feedback.gd")

## World-space placement registry inspired by GDQuest's EntityPlacer.
## It gives Hash Race a real physical deployment layer instead of stat-only buys.

signal placement_changed
signal placement_rejected(reason: String)

@export var grid_size := Vector2i(32, 32)
@export var maximum_place_distance := 420.0

var occupied: Dictionary = {}
var placed_nodes: Array[Node2D] = []

func snap(world_position: Vector2) -> Vector2:
    return PlacementFeedback.snap_to_grid(world_position, grid_size)

func cell_key(world_position: Vector2) -> Vector2i:
    var snapped := snap(world_position)
    return Vector2i(
        int(round(snapped.x / float(maxi(1, grid_size.x)))),
        int(round(snapped.y / float(maxi(1, grid_size.y))))
    )

func can_place(world_position: Vector2, origin: Vector2 = world_position) -> bool:
    if not PlacementFeedback.within_work_distance(origin, world_position, maximum_place_distance):
        return false
    return not occupied.has(cell_key(world_position))

func place(node: Node2D, world_position: Vector2, origin: Vector2 = world_position) -> bool:
    if node == null:
        placement_rejected.emit("No node supplied.")
        return false
    var key := cell_key(world_position)
    if not can_place(world_position, origin):
        placement_rejected.emit("Grid cell is blocked or out of placement range.")
        return false
    occupied[key] = node
    node.position = snap(world_position)
    add_child(node)
    placed_nodes.append(node)
    placement_changed.emit()
    return true

func remove_placement(node: Node2D) -> bool:
    if node == null:
        return false
    var erased := false
    for key in occupied.keys():
        if occupied[key] == node:
            occupied.erase(key)
            erased = true
            break
    placed_nodes.erase(node)
    if erased:
        placement_changed.emit()
    return erased

func clear_all() -> void:
    for node in placed_nodes.duplicate():
        if is_instance_valid(node):
            node.queue_free()
    placed_nodes.clear()
    occupied.clear()
    placement_changed.emit()

func serialize_layout() -> Array:
    var data: Array = []
    for key in occupied.keys():
        var node: Node2D = occupied[key]
        data.append({
            "cell": key,
            "position": node.position,
            "scene_path": node.scene_file_path
        })
    return data

func debug_ready() -> bool:
    return grid_size.x > 0 and grid_size.y > 0 and maximum_place_distance > 0.0
