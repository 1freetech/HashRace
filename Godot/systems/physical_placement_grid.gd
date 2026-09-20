class_name HashRacePhysicalPlacementGrid
extends Node2D

const PlacementFeedback = preload("res://components/building/placement_feedback.gd")

## World-space placement registry inspired by GDQuest's EntityPlacer.
## v0.111 adds multi-tile footprints plus four-way infrastructure orientation
## so power, cooling, fuel, and facility assets can occupy believable parcels.

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

func _normalize_orientation(orientation: String) -> String:
    var clean := orientation.to_lower()
    return clean if clean in ["up", "right", "down", "left"] else "up"

func oriented_footprint(footprint: Vector2i, orientation: String = "up") -> Vector2i:
    var clean := _normalize_orientation(orientation)
    var safe := Vector2i(maxi(1, footprint.x), maxi(1, footprint.y))
    if clean == "left" or clean == "right":
        return Vector2i(safe.y, safe.x)
    return safe

func footprint_cells(world_position: Vector2, footprint: Vector2i, orientation: String = "up") -> Array[Vector2i]:
    var anchor := cell_key(world_position)
    var size := oriented_footprint(footprint, orientation)
    var cells: Array[Vector2i] = []
    for y in range(size.y):
        for x in range(size.x):
            cells.append(anchor + Vector2i(x, y))
    return cells

func can_place(world_position: Vector2, origin: Variant = null) -> bool:
    return can_place_footprint(world_position, Vector2i.ONE, "up", origin)

func can_place_footprint(world_position: Vector2, footprint: Vector2i, orientation: String = "up", origin: Variant = null) -> bool:
    var source: Vector2 = world_position if origin == null else Vector2(origin)
    if not PlacementFeedback.within_work_distance(source, world_position, maximum_place_distance):
        return false
    for key in footprint_cells(world_position, footprint, orientation):
        if occupied.has(key):
            return false
    return true

func place(node: Node2D, world_position: Vector2, origin: Variant = null) -> bool:
    return place_footprint(node, world_position, Vector2i.ONE, "up", origin)

func place_footprint(node: Node2D, world_position: Vector2, footprint: Vector2i, orientation: String = "up", origin: Variant = null) -> bool:
    if node == null:
        placement_rejected.emit("No node supplied.")
        return false
    var source: Vector2 = world_position if origin == null else Vector2(origin)
    var clean := _normalize_orientation(orientation)
    var size := oriented_footprint(footprint, clean)
    if not can_place_footprint(world_position, size, clean, source):
        placement_rejected.emit("Infrastructure footprint is blocked or out of placement range.")
        return false
    var cells := footprint_cells(world_position, size, clean)
    for key in cells:
        occupied[key] = node
    node.position = snap(world_position)
    node.set_meta("hashrace_anchor_cell", cell_key(world_position))
    node.set_meta("hashrace_footprint", size)
    node.set_meta("hashrace_orientation", clean)
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
    for node in placed_nodes:
        if not is_instance_valid(node):
            continue
        data.append({
            "cell": node.get_meta("hashrace_anchor_cell", cell_key(node.position)),
            "position": node.position,
            "scene_path": node.scene_file_path,
            "footprint": node.get_meta("hashrace_footprint", Vector2i.ONE),
            "orientation": node.get_meta("hashrace_orientation", "up"),
        })
    return data

func debug_ready() -> bool:
    return grid_size.x > 0 \
        and grid_size.y > 0 \
        and maximum_place_distance > 0.0 \
        and footprint_cells(Vector2.ZERO, Vector2i(2, 3), "right").size() == 6 \
        and oriented_footprint(Vector2i(2, 3), "right") == Vector2i(3, 2)
