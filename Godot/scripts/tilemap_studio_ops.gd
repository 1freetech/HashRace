# Hash Race tilemap editing operations.
#
# This file is a GDScript adaptation of Tilemap Studio's tilemap operations:
# flood_fill(), substitute_tile(), and swap_tiles() from src/main-window.cpp.
# Upstream: https://github.com/Rangi42/tilemap-studio
# Upstream license: GNU LGPL-3.0.
#
# This adapted file is distributed under GNU LGPL-3.0. The rest of Hash Race
# remains under its own project terms. See docs/THIRD_PARTY_TILEMAP.md.
extends RefCounted

static func flood_fill(
	cells: Dictionary,
	start: Vector2i,
	new_value: int,
	columns: int,
	rows: int
) -> int:
	if not cells.has(start):
		return 0
	var from_value: int = int(cells[start])
	if from_value == new_value:
		return 0

	var filled: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	var changed: int = 0

	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell.x < 0 or cell.y < 0 or cell.x >= columns or cell.y >= rows:
			continue
		if filled.has(cell):
			continue
		if not cells.has(cell) or int(cells[cell]) != from_value:
			continue

		cells[cell] = new_value
		filled[cell] = true
		changed += 1

		if cell.x > 0:
			queue.push_back(cell + Vector2i.LEFT)
		if cell.x < columns - 1:
			queue.push_back(cell + Vector2i.RIGHT)
		if cell.y > 0:
			queue.push_back(cell + Vector2i.UP)
		if cell.y < rows - 1:
			queue.push_back(cell + Vector2i.DOWN)

	return changed


static func substitute_tile(cells: Dictionary, from_value: int, to_value: int) -> int:
	var changed: int = 0
	var keys: Array = cells.keys()
	for key in keys:
		if int(cells[key]) == from_value:
			cells[key] = to_value
			changed += 1
	return changed


static func swap_tiles(cells: Dictionary, first_value: int, second_value: int) -> int:
	if first_value == second_value:
		return 0
	var changed: int = 0
	var keys: Array = cells.keys()
	for key in keys:
		var value: int = int(cells[key])
		if value == first_value:
			cells[key] = second_value
			changed += 1
		elif value == second_value:
			cells[key] = first_value
			changed += 1
	return changed
