class_name ProceduralBuildingDetails
extends RefCounted

# Clean-room procedural pixel facade helpers for Hash Race.
# Architecture is informed by MIT procedural-generation references; no external
# artwork or protected building assets are copied.

static func draw_brick_wall(canvas: CanvasItem, rect: Rect2, base: Color, mortar: Color, brick: Color) -> void:
	canvas.draw_rect(rect, base, true)
	var row_h := 8.0
	var brick_w := 18.0
	var y := rect.position.y
	var row := 0
	while y < rect.end.y:
		canvas.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), mortar, 1.0)
		var offset := 0.0 if row % 2 == 0 else brick_w * 0.5
		var x := rect.position.x + offset
		while x < rect.end.x:
			canvas.draw_line(Vector2(x, y), Vector2(x, minf(y + row_h, rect.end.y)), mortar, 1.0)
			if x + 3.0 < rect.end.x and y + 3.0 < rect.end.y:
				canvas.draw_rect(Rect2(Vector2(x + 2.0, y + 2.0), Vector2(minf(5.0, rect.end.x - x - 2.0), 2.0)), brick.lightened(0.12), true)
			x += brick_w
		y += row_h
		row += 1

static func draw_window(canvas: CanvasItem, rect: Rect2, frame: Color, glass: Color) -> void:
	canvas.draw_rect(rect.grow(2.0), frame.darkened(0.45), true)
	canvas.draw_rect(rect, frame, true)
	var pane := rect.grow(-3.0)
	canvas.draw_rect(pane, glass, true)
	canvas.draw_line(Vector2(pane.get_center().x, pane.position.y), Vector2(pane.get_center().x, pane.end.y), frame.darkened(0.35), 2.0)
	canvas.draw_line(Vector2(pane.position.x, pane.get_center().y), Vector2(pane.end.x, pane.get_center().y), frame.darkened(0.35), 2.0)
	canvas.draw_rect(Rect2(pane.position + Vector2(2.0, 2.0), Vector2(maxf(2.0, pane.size.x * 0.22), 2.0)), glass.lightened(0.32), true)

static func draw_door(canvas: CanvasItem, rect: Rect2, frame: Color, material: Color, knob: Color) -> void:
	canvas.draw_rect(rect.grow(2.0), frame.darkened(0.5), true)
	canvas.draw_rect(rect, material, true)
	canvas.draw_rect(rect.grow(-3.0), material.darkened(0.12), false, 2.0)
	var knob_center := Vector2(rect.end.x - 5.0, rect.get_center().y + 2.0)
	canvas.draw_circle(knob_center, 2.0, frame.darkened(0.55))
	canvas.draw_circle(knob_center, 1.0, knob)

static func draw_panel_wall(canvas: CanvasItem, rect: Rect2, base: Color, seam: Color) -> void:
	canvas.draw_rect(rect, base, true)
	var x := rect.position.x + 12.0
	while x < rect.end.x:
		canvas.draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), seam, 1.0)
		x += 16.0
	canvas.draw_line(Vector2(rect.position.x, rect.position.y + 5.0), Vector2(rect.end.x, rect.position.y + 5.0), base.lightened(0.14), 1.0)
