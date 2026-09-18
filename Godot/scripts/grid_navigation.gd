extends RefCounted

# Hash Race grid navigation helper.
# The primary point-to-point solver uses Godot's native AStarGrid2D so route
# expansion runs in engine code. The bounded scanner/reachable helper remains a
# small GDScript breadth-first search because it intentionally returns every
# reachable cell inside a short tactical radius rather than one route.

var world_size: Vector2 = Vector2.ZERO
var cell_size: float = 48.0
var columns: int = 0
var rows: int = 0
var blocked: Dictionary = {}
var astar_grid: AStarGrid2D = AStarGrid2D.new()

func configure(size: Vector2, requested_cell_size: float = 48.0) -> void:
    world_size = size
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
    if columns <= 0 or rows <= 0:
        return
    var min_cell: Vector2i = world_to_cell(rect.position)
    var max_point: Vector2 = rect.position + rect.size - Vector2.ONE
    var max_cell: Vector2i = world_to_cell(max_point)
    for y in range(min_cell.y, max_cell.y + 1):
        for x in range(min_cell.x, max_cell.x + 1):
            set_blocked(Vector2i(x, y), true)

func carve_world_point(world_pos: Vector2, radius_cells: int = 0) -> void:
    var center: Vector2i = world_to_cell(world_pos)
    for y in range(center.y - radius_cells, center.y + radius_cells + 1):
        for x in range(center.x - radius_cells, center.x + radius_cells + 1):
            set_blocked(Vector2i(x, y), false)

func is_walkable(cell: Vector2i) -> bool:
    return _in_bounds(cell) and not blocked.has(cell)

func world_is_walkable(world_pos: Vector2) -> bool:
    return is_walkable(world_to_cell(world_pos))

func nearest_open(cell: Vector2i, max_radius: int = 10) -> Vector2i:
    if is_walkable(cell):
        return cell
    for radius in range(1, max_radius + 1):
        for y in range(cell.y - radius, cell.y + radius + 1):
            for x in range(cell.x - radius, cell.x + radius + 1):
                var candidate := Vector2i(x, y)
                if abs(candidate.x - cell.x) + abs(candidate.y - cell.y) != radius:
                    continue
                if is_walkable(candidate):
                    return candidate
    return Vector2i(-1, -1)

func reachable_cells(start_world: Vector2, max_steps: int = 7) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if columns <= 0 or rows <= 0 or max_steps < 0:
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

func find_path(start_world: Vector2, end_world: Vector2) -> Array[Vector2]:
    var result: Array[Vector2] = []
    if columns <= 0 or rows <= 0:
        return result
    var start := nearest_open(world_to_cell(start_world))
    var goal := nearest_open(world_to_cell(end_world))
    if start.x < 0 or goal.x < 0:
        return result
    if start == goal:
        result.append(cell_to_world(goal))
        return result
    var ids: Array[Vector2i] = []
    for point in astar_grid.get_id_path(start, goal, false):
        ids.append(point)
    if ids.is_empty():
        return result
    ids = _compress_collinear_cells(ids)
    for i in range(1, ids.size()):
        result.append(cell_to_world(ids[i]))
    return result

func find_path_in_range(start_world: Vector2, end_world: Vector2, allowed_cells: Array[Vector2i]) -> Array[Vector2]:
    var allowed_lookup: Dictionary = {}
    for cell in allowed_cells:
        allowed_lookup[cell] = true
    var start := nearest_open(world_to_cell(start_world))
    var goal := nearest_open(world_to_cell(end_world))
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

func blocked_count() -> int:
    return blocked.size()

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

func _in_bounds(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < columns and cell.y < rows

func debug_native_astar_ready() -> bool:
    return columns > 0 and rows > 0 and astar_grid.region.size == Vector2i(columns, rows) and astar_grid.diagonal_mode == AStarGrid2D.DIAGONAL_MODE_NEVER
