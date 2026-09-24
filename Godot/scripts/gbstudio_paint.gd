# Hash Race tile-paint helpers.
#
# Portions of the algorithmic structure in paint_rect() and paint_line() are
# adapted from GB Studio's src/shared/lib/helpers/paint.ts.
# GB Studio is MIT licensed:
# Copyright (c) 2019-2026 Chris Maltby
# https://github.com/chrismaltby/gb-studio
#
# This GDScript port is used to build Hash Race's grid-aligned town graphics.
extends RefCounted

static func paint_rect(
	cells: Dictionary,
	x: int,
	y: int,
	width: int,
	height: int,
	value: int,
	columns: int,
	rows: int
) -> void:
	for xi in range(x, x + width):
		for yi in range(y, y + height):
			if xi >= 0 and yi >= 0 and xi < columns and yi < rows:
				cells[Vector2i(xi, yi)] = value


# Bresenham-style line painting adapted from GB Studio's MIT paintLine helper.
static func paint_line(
	cells: Dictionary,
	start: Vector2i,
	finish: Vector2i,
	brush_size: int,
	value: int,
	columns: int,
	rows: int
) -> void:
	var x1: int = start.x
	var y1: int = start.y
	var x2: int = finish.x
	var y2: int = finish.y
	var dx: int = absi(x2 - x1)
	var dy: int = absi(y2 - y1)
	var sx: int = 1 if x1 < x2 else -1
	var sy: int = 1 if y1 < y2 else -1
	var err: int = dx - dy

	paint_rect(cells, x1, y1, brush_size, brush_size, value, columns, rows)
	while not (x1 == x2 and y1 == y2):
		var e2: int = err << 1
		if e2 > -dy:
			err -= dy
			x1 += sx
		if e2 < dx:
			err += dx
			y1 += sy
		paint_rect(cells, x1, y1, brush_size, brush_size, value, columns, rows)


# Paint every cell whose tile id matches target_id. This follows the same
# useful editor behavior as GB Studio's "magic" paint helper, adapted for the
# Hash Race tile dictionary.
static func paint_matching(
	cells: Dictionary,
	target_id: int,
	value: int
) -> int:
	var changed: int = 0
	var keys: Array = cells.keys()
	for key in keys:
		if int(cells[key]) == target_id:
			cells[key] = value
			changed += 1
	return changed
