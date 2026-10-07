extends Node2D
class_name HashRacePhysicalCampusCollision

# Physical collision for the two live-site structures that are visual-only in
# the inherited draw stack: the capacity-scaled C-01 mining container and the
# Command Center. Energy and transformer equipment own their collision in the
# world render chain; this node gives the remaining visible campus the same
# grounded navigation contract without changing mining simulation state.
const COLLISION_REVISION := 1
const CONTAINER_OFFSET := Vector2(-170.0, -165.0)
const COMMAND_OFFSET := Vector2(-205.0, 215.0)

var world: Node
var grid_nav
var container_rect := Rect2()
var command_rect := Rect2()
var container_owned_cells: Array[Vector2i] = []
var command_owned_cells: Array[Vector2i] = []
var last_capacity_tiles := -1
var campus_origin := Vector2.ZERO
var campus_origin_cached := false

func _ready() -> void:
    world = get_parent()
    set_process(true)
    call_deferred("_sync_collision")

func _exit_tree() -> void:
    _clear_owned(container_owned_cells)
    _clear_owned(command_owned_cells)

func _process(_delta: float) -> void:
    # The campus location is static after world generation. Recheck only the
    # inexpensive capacity tier each frame; the expensive placement search is
    # cached once and footprints rebuild only when that tier changes.
    _sync_collision()

func _sync_collision() -> void:
    if world == null or not is_instance_valid(world):
        return
    grid_nav = world.get("grid_nav")
    var player_value = world.get("player")
    if grid_nav == null or not player_value is Dictionary or Dictionary(player_value).is_empty():
        return
    if not world.has_method("_energy_campus_origin") \
        or not world.has_method("_player_hq_center") \
        or not world.has_method("_v114_capacity_mw_for_site") \
        or not world.has_method("_v114_footprint_tiles") \
        or not world.has_method("_v128_container_size"):
        return

    var hq_center: Vector2 = world.call("_player_hq_center")
    var capacity_mw: float = float(world.call("_v114_capacity_mw_for_site", hq_center))
    var capacity_tiles: int = int(world.call("_v114_footprint_tiles", capacity_mw))
    if campus_origin_cached \
        and capacity_tiles == last_capacity_tiles \
        and container_rect.size != Vector2.ZERO \
        and command_rect.size != Vector2.ZERO:
        return

    if not campus_origin_cached:
        campus_origin = world.call("_energy_campus_origin")
        campus_origin_cached = true

    var size_value: Vector2 = world.call("_v128_container_size", capacity_mw)
    var container_center := campus_origin + CONTAINER_OFFSET
    var container_dest := Rect2(container_center - size_value * Vector2(0.5, 0.55), size_value)
    var new_container_rect := Rect2(
        container_dest.position + Vector2(container_dest.size.x * 0.10, container_dest.size.y * 0.68),
        Vector2(container_dest.size.x * 0.80, container_dest.size.y * 0.23)
    )

    var command_center := campus_origin + COMMAND_OFFSET
    var command_body := Rect2(command_center - Vector2(56.0, 39.6), Vector2(112.0, 72.0))
    var new_command_rect := Rect2(
        Vector2(command_body.position.x + 10.0, command_body.end.y - 18.0),
        Vector2(command_body.size.x - 20.0, 18.0)
    )

    _sync_owned_rect(new_container_rect, container_rect, container_owned_cells)
    container_rect = new_container_rect
    _sync_owned_rect(new_command_rect, command_rect, command_owned_cells)
    command_rect = new_command_rect
    last_capacity_tiles = capacity_tiles

    set_meta("hashrace_physical_campus_collision_revision", COLLISION_REVISION)
    set_meta("hashrace_container_collision_rect", container_rect)
    set_meta("hashrace_command_collision_rect", command_rect)
    set_meta("hashrace_capacity_collision_tiles", last_capacity_tiles)
    set_meta("hashrace_campus_origin_cached", campus_origin_cached)

func _sync_owned_rect(next_rect: Rect2, current_rect: Rect2, owned_cells: Array[Vector2i]) -> void:
    if next_rect.size == Vector2.ZERO or grid_nav == null:
        return
    if next_rect == current_rect and not owned_cells.is_empty():
        return
    _clear_owned(owned_cells)
    for cell in _cells_for_rect(next_rect):
        if grid_nav.is_walkable(cell):
            owned_cells.append(cell)
            grid_nav.set_blocked(cell, true)

func _clear_owned(owned_cells: Array[Vector2i]) -> void:
    if grid_nav != null:
        for cell in owned_cells:
            grid_nav.set_blocked(cell, false)
    owned_cells.clear()

func _cells_for_rect(rect: Rect2) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if grid_nav == null or rect.size == Vector2.ZERO:
        return result
    var min_cell: Vector2i = grid_nav.world_to_cell(rect.position)
    var max_cell: Vector2i = grid_nav.world_to_cell(rect.end - Vector2.ONE)
    for y in range(min_cell.y, max_cell.y + 1):
        for x in range(min_cell.x, max_cell.x + 1):
            result.append(Vector2i(x, y))
    return result

func debug_ready() -> bool:
    return COLLISION_REVISION == 1 \
        and grid_nav != null \
        and campus_origin_cached \
        and container_rect.size.x > 0.0 \
        and command_rect.size.x > 0.0 \
        and not container_owned_cells.is_empty() \
        and not command_owned_cells.is_empty() \
        and not grid_nav.world_is_walkable(container_rect.get_center()) \
        and not grid_nav.world_is_walkable(command_rect.get_center())

func debug_snapshot() -> Dictionary:
    return {
        "container_rect": container_rect,
        "command_rect": command_rect,
        "container_cells": container_owned_cells.duplicate(),
        "command_cells": command_owned_cells.duplicate(),
        "capacity_tiles": last_capacity_tiles,
        "campus_origin": campus_origin,
        "campus_origin_cached": campus_origin_cached,
    }
