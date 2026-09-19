extends RefCounted

# Hash Race grid navigation helper.
# Native AStarGrid2D handles primary routes; bounded tactical scans remain small
# breadth-first searches. v0.109 improves edge correctness, deterministic open
# cell recovery, bounded-route safety, and route presentation without changing
# the game's existing movement rules.

var world_size: Vector2 = Vector2.ZERO
var cell_size: float = 48.0
var columns: int = 0
var rows: int = 0
var blocked: Dictionary = {}
var astar_grid: AStarGrid2D = AStarGrid2D.new()

func configure(size: Vector2, requested_cell_size: float = 48.0) -> void:
    world_size = Vector2(maxf(0.0, size.x), maxf(0.0, size.y))
    cell_size = maxf(16.0, requested_cell_size)
    columns = int(ceil(world_size.x / cell_size))
    rows = int(ceil(world_size.y / cell_size))
    blocked.clear()
    astar_grid = AStarGrid2D.new()
    astar_grid.region = Rect2i(Vector2i.ZERO, Vector2i(columns, rows))
    astar_grid.cell_size = Vector2(cell_size, cell_size)
    astar_grid.offset = Vector2(cell_size * 0.5, cell_size * 0.5)
    astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    astar_grid.update()

func world_to_cell(world_pos: Vector2) -> Vector2i:
    return Vector2i(
        clampi(int(floor(world_pos.x / cell_size)), 0, max(0, columns - 1)),
        clampi(int(floor(world_pos.y / cell_size)), 0, max(0, rows - 1))
    )

func cell_to_world(cell: Vector2i) -> Vector2:
    return Vector2((float(cell.x) + 0.5) * cell_size, (float(cell.y) + 0.5) * cell_size)

func set_blocked(cell: Vector2i, value: bool = true) -> void:
    if not _in_bounds(cell):
        return
    if value:
        blocked[cell] = true
    else:
        blocked.erase(cell)
    astar_grid.set_point_solid(cell, value)

func block_rect(rect: Rect2) -> void:
    if columns <= 0 or rows <= 0 or rect.size.x <= 0.0 or rect.size.y <= 0.0:
        return
    var world_bounds := Rect2(Vector2.ZERO, world_size)
    var clipped := rect.intersection(world_bounds)
    if clipped.size.x <= 0.0 or clipped.size.y <= 0.0:
        return
    var min_cell: Vector2i = world_to_cell(clipped.position)
    var max_cell: Vector2i = world_to_cell(clipped.end - Vector2(0.001, 0.001))
    for y in range(min_cell.y, max_cell.y + 1):
        for x in range(min_cell.x, max_cell.x + 1):
            set_blocked(Vector2i(x, y), true)

func carve_world_point(world_pos: Vector2, radius_cells: int = 0) -> void:
    if not _world_point_in_bounds(world_pos):
        return
    var center: Vector2i = world_to_cell(world_pos)
    for y in range(center.y - maxi(0, radius_cells), center.y + maxi(0, radius_cells) + 1):
        for x in range(center.x - maxi(0, radius_cells), center.x + maxi(0, radius_cells) + 1):
            set_blocked(Vector2i(x, y), false)

func is_walkable(cell: Vector2i) -> bool:
    return _in_bounds(cell) and not blocked.has(cell)

func world_is_walkable(world_pos: Vector2) -> bool:
    return _world_point_in_bounds(world_pos) and is_walkable(world_to_cell(world_pos))

func nearest_open(cell: Vector2i, max_radius: int = 10) -> Vector2i:
    if is_walkable(cell):
        return cell
    for radius in range(1, max_radius + 1):
        var ring: Array[Vector2i] = []
        for y in range(cell.y - radius, cell.y + radius + 1):
            for x in range(cell.x - radius, cell.x + radius + 1):
                var candidate := Vector2i(x, y)
                if abs(candidate.x - cell.x) + abs(candidate.y - cell.y) == radius and is_walkable(candidate):
                    ring.append(candidate)
        if not ring.is_empty():
            ring.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
                if a.y == b.y:
                    return a.x < b.x
                return a.y < b.y)
            return ring[0]
    return Vector2i(-1, -1)

func reachable_cells(start_world: Vector2, max_steps: int = 7) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if columns <= 0 or rows <= 0 or max_steps < 0 or not _world_point_in_bounds(start_world):
        return result
    var start: Vector2i = nearest_open(world_to_cell(start_world))
    if start.x < 0:
        return result
    var queue: Array[Vector2i] = [start]
    var distance: Dictionary = {start: 0}
    var head := 0
    while head < queue.size():
        var current: Vector2i = queue[head]
        head += 1
        result.append(current)
        var current_steps := int(distance.get(current, 0))
        if current_steps >= max_steps:
            continue
        for neighbor in _neighbors(current):
            if not is_walkable(neighbor) or distance.has(neighbor):
                continue
            distance[neighbor] = current_steps + 1
            queue.append(neighbor)
    return result

func reachable_frontier(start_world: Vector2, max_steps: int = 7) -> Array[Vector2i]:
    var reachable := reachable_cells(start_world, max_steps)
    var lookup: Dictionary = {}
    for cell in reachable:
        lookup[cell] = true
    var frontier: Array[Vector2i] = []
    for cell in reachable:
        for neighbor in _neighbors(cell):
            if not lookup.has(neighbor):
                frontier.append(cell)
                break
    return frontier

func find_path(start_world: Vector2, end_world: Vector2) -> Array[Vector2]:
    var result: Array[Vector2] = []
    if columns <= 0 or rows <= 0 or not _world_point_in_bounds(start_world) or not _world_point_in_bounds(end_world):
        return result
    var start := nearest_open(world_to_cell(start_world))
    var goal := nearest_open(world_to_cell(end_world))
    if start.x < 0 or goal.x < 0:
        return result
    if start == goal:
        result.append(_safe_goal_point(end_world, goal))
        return result
    var ids: Array[Vector2i] = []
    for point in astar_grid.get_id_path(start, goal, false):
        ids.append(point)
    if ids.is_empty():
        return result
    ids = _compress_collinear_cells(ids)
    for i in range(1, ids.size()):
        result.append(cell_to_world(ids[i]))
    if goal == world_to_cell(end_world) and not result.is_empty():
        result[result.size() - 1] = _safe_goal_point(end_world, goal)
    return result

func find_path_in_range(start_world: Vector2, end_world: Vector2, allowed_cells: Array[Vector2i]) -> Array[Vector2]:
    var allowed_lookup: Dictionary = {}
    for cell in allowed_cells:
        if is_walkable(cell):
            allowed_lookup[cell] = true
    if not _world_point_in_bounds(start_world) or not _world_point_in_bounds(end_world):
        return []
    var start := world_to_cell(start_world)
    var goal := world_to_cell(end_world)
    if not allowed_lookup.has(start) or not allowed_lookup.has(goal):
        return []
    return _find_path_cells_bounded(start, goal, allowed_lookup)

func _find_path_cells_bounded(start: Vector2i, goal: Vector2i, allowed_lookup: Dictionary) -> Array[Vector2]:
    var result: Array[Vector2] = []
    if columns <= 0 or rows <= 0 or start.x < 0 or goal.x < 0:
        return result
    if not allowed_lookup.has(start) or not allowed_lookup.has(goal):
        return result
    if start == goal:
        result.append(cell_to_world(goal))
        return result
    var queue: Array[Vector2i] = [start]
    var came_from: Dictionary = {}
    var visited: Dictionary = {start: true}
    var head := 0
    while head < queue.size():
        var current: Vector2i = queue[head]
        head += 1
        if current == goal:
            return _reconstruct_world_path(came_from, current, start)
        for neighbor in _neighbors(current):
            if not is_walkable(neighbor) or not allowed_lookup.has(neighbor) or visited.has(neighbor):
                continue
            visited[neighbor] = true
            came_from[neighbor] = current
            queue.append(neighbor)
    return result

func route_distance(path: Array[Vector2], start_world: Vector2) -> float:
    var total := 0.0
    var previous := start_world
    for point in path:
        total += previous.distance_to(point)
        previous = point
    return total

func blocked_count() -> int:
    return blocked.size()

func _safe_goal_point(requested: Vector2, goal: Vector2i) -> Vector2:
    if world_to_cell(requested) == goal and is_walkable(goal):
        var inset := 1.0
        return Vector2(clampf(requested.x, inset, maxf(inset, world_size.x - inset)), clampf(requested.y, inset, maxf(inset, world_size.y - inset)))
    return cell_to_world(goal)

func _reconstruct_world_path(came_from: Dictionary, current: Vector2i, start: Vector2i) -> Array[Vector2]:
    var cells: Array[Vector2i] = [current]
    while current != start:
        if not came_from.has(current):
            return []
        current = came_from[current]
        cells.push_front(current)
    cells = _compress_collinear_cells(cells)
    var result: Array[Vector2] = []
    for i in range(1, cells.size()):
        result.append(cell_to_world(cells[i]))
    return result

func _compress_collinear_cells(cells: Array[Vector2i]) -> Array[Vector2i]:
    if cells.size() <= 2:
        return cells
    var result: Array[Vector2i] = [cells[0]]
    var last_direction := cells[1] - cells[0]
    for i in range(1, cells.size() - 1):
        var next_direction := cells[i + 1] - cells[i]
        if next_direction != last_direction:
            result.append(cells[i])
        last_direction = next_direction
    result.append(cells[cells.size() - 1])
    return result

func _neighbors(cell: Vector2i) -> Array[Vector2i]:
    return [Vector2i(cell.x + 1, cell.y), Vector2i(cell.x - 1, cell.y), Vector2i(cell.x, cell.y + 1), Vector2i(cell.x, cell.y - 1)]

func _world_point_in_bounds(point: Vector2) -> bool:
    return point.x >= 0.0 and point.y >= 0.0 and point.x < world_size.x and point.y < world_size.y

func _in_bounds(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < columns and cell.y < rows

func debug_native_astar_ready() -> bool:
    return columns > 0 and rows > 0 and astar_grid.region.size == Vector2i(columns, rows) and astar_grid.diagonal_mode == AStarGrid2D.DIAGONAL_MODE_NEVER

func debug_v109_navigation_ready() -> bool:
    return has_method("reachable_frontier") and has_method("route_distance") and has_method("_world_point_in_bounds")
