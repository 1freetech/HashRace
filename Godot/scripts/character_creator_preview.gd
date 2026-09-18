extends Control
class_name HashRaceCharacterCreatorPreview

var skin := Color("9a5d3c")
var skin_high := Color("c47b4c")
var hair := Color("33221d")
var suit := Color("e9eeee")
var accent := Color("e07a2f")
var hair_style: int = 0

func set_appearance(skin_data: Dictionary, hair_data: Dictionary, style_index: int, suit_data: Dictionary, accent_data: Dictionary) -> void:
	skin = skin_data["skin"]
	skin_high = skin_data["highlight"]
	hair = hair_data["color"]
	hair_style = style_index
	suit = suit_data["color"]
	accent = accent_data["color"]
	queue_redraw()

func _draw() -> void:
	# Large procedural preview uses the same crisp rectangles/circles as the
	# overworld fallback, so every selector visibly updates without asset loads.
	var o := Vector2(size.x * 0.5, 20.0)
	draw_rect(Rect2(o + Vector2(-34, 92), Vector2(68, 82)), Color("071015"), true)
	draw_rect(Rect2(o + Vector2(-29, 96), Vector2(58, 76)), suit.darkened(0.42), true)
	draw_rect(Rect2(o + Vector2(-24, 99), Vector2(48, 69)), suit, true)
	draw_rect(Rect2(o + Vector2(-24, 103), Vector2(48, 9)), accent, true)
	draw_rect(Rect2(o + Vector2(-18, 168), Vector2(14, 38)), suit.darkened(0.32), true)
	draw_rect(Rect2(o + Vector2(4, 168), Vector2(14, 38)), suit.darkened(0.32), true)
	draw_rect(Rect2(o + Vector2(-27, 202), Vector2(22, 8)), Color("111820"), true)
	draw_rect(Rect2(o + Vector2(5, 202), Vector2(22, 8)), Color("111820"), true)
	draw_rect(Rect2(o + Vector2(-27, 38), Vector2(54, 58)), skin.darkened(0.35), true)
	draw_rect(Rect2(o + Vector2(-23, 42), Vector2(46, 50)), skin, true)
	draw_rect(Rect2(o + Vector2(-18, 48), Vector2(12, 5)), skin_high, true)
	draw_rect(Rect2(o + Vector2(-13, 65), Vector2(5, 5)), Color("101820"), true)
	draw_rect(Rect2(o + Vector2(8, 65), Vector2(5, 5)), Color("101820"), true)
	draw_rect(Rect2(o + Vector2(-6, 82), Vector2(12, 3)), skin.darkened(0.28), true)
	_draw_hair(o)
	# ID badge and wrist terminal give the representative a mining-operator read.
	draw_rect(Rect2(o + Vector2(8, 121), Vector2(12, 15)), Color("0a151b"), true)
	draw_rect(Rect2(o + Vector2(10, 123), Vector2(8, 6)), accent.lightened(0.18), true)
	draw_rect(Rect2(o + Vector2(25, 126), Vector2(9, 20)), accent.darkened(0.18), true)

func _draw_hair(o: Vector2) -> void:
	match hair_style:
		1: # fade
			draw_rect(Rect2(o + Vector2(-24, 35), Vector2(48, 14)), hair, true)
			draw_rect(Rect2(o + Vector2(-27, 44), Vector2(8, 25)), hair.darkened(0.25), true)
		2: # waves
			for x in range(-23, 24, 9):
				draw_circle(o + Vector2(x, 42 + (abs(x) % 3)), 7.0, hair)
		3: # locs
			draw_rect(Rect2(o + Vector2(-24, 35), Vector2(48, 13)), hair, true)
			for x in range(-21, 22, 10):
				draw_rect(Rect2(o + Vector2(x, 43), Vector2(6, 35 + abs(x) * 0.3)), hair.darkened(0.08), true)
		4: # curly
			for x in range(-23, 24, 9):
				for y in range(36, 52, 8):
					draw_circle(o + Vector2(x, y), 7.0, hair)
		5: # long
			draw_rect(Rect2(o + Vector2(-25, 34), Vector2(50, 16)), hair, true)
			draw_rect(Rect2(o + Vector2(-29, 45), Vector2(10, 58)), hair.darkened(0.12), true)
			draw_rect(Rect2(o + Vector2(19, 45), Vector2(10, 58)), hair.darkened(0.12), true)
		_: # short
			draw_rect(Rect2(o + Vector2(-24, 35), Vector2(48, 15)), hair, true)
			draw_rect(Rect2(o + Vector2(-20, 31), Vector2(40, 8)), hair.lightened(0.08), true)
