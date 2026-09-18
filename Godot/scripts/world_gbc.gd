extends "res://scripts/world_grid.gd"

# Modern GBC-inspired presentation layer for Hash Race.
# The goal is readability and tile discipline, not copying any commercial game
# artwork. Terrain is generated as a real logical tile field using the ported
# GB Studio paint helpers and Tilemap Studio editing operations.

const GBPaint = preload("res://scripts/gbstudio_paint.gd")
const TileOps = preload("res://scripts/tilemap_studio_ops.gd")
const VisualStack = preload("res://scripts/visual_reference_stack.gd")

const ART_TILE_SIZE: float = 48.0
const TILE_GRASS: int = 0
const TILE_GRASS_DARK: int = 1
const TILE_ROAD_TEMP: int = 2
const TILE_ROAD: int = 3
const TILE_PLAZA: int = 4
const TILE_WATER: int = 5
const TILE_LOT: int = 6

const GBC_INK: Color = Color("071014")
const GBC_GRASS_0: Color = Color("102c25")
const GBC_GRASS_1: Color = Color("173d31")
const GBC_GRASS_2: Color = Color("245441")
const GBC_GRASS_3: Color = Color("3b7354")
const GBC_ROAD_0: Color = Color("151c22")
const GBC_ROAD_1: Color = Color("28343d")
const GBC_ROAD_2: Color = Color("44545d")
const GBC_ROAD_3: Color = Color("8ba0a5")
const GBC_WATER_0: Color = Color("082c44")
const GBC_WATER_1: Color = Color("0c526d")
const GBC_WATER_2: Color = Color("16839a")
const GBC_WATER_3: Color = Color("45c4cf")
const GBC_LOT_0: Color = Color("182126")
const GBC_LOT_1: Color = Color("2b363d")
const GBC_LOT_2: Color = Color("4b5960")
const GBC_LOT_3: Color = Color("829197")

var art_cells: Dictionary = {}
var art_columns: int = 0
var art_rows: int = 0
var gbc_map_ready: bool = false
var tile_ops_changed: int = 0

func _ready() -> void:
	super._ready()
	_build_art_tilemap()
	_open_message(
		"PIXEL GRID ONLINE // %s" % _current_town_name(),
		"Hash Race now uses a tile-built company world with a nine-source 2D visual stack. Roads, lots, water and grass stay aligned to the pixel grid while facilities, props and representatives gain sharper outlines, richer shading and motion. Walk with WASD/arrows, click open ground to pathfind, E talks, and T travels between mining towns."
	)
	queue_redraw()

func _build_art_tilemap() -> void:
	art_columns = int(ceil(WORLD_SIZE.x / ART_TILE_SIZE))
	art_rows = int(ceil(WORLD_SIZE.y / ART_TILE_SIZE))
	art_cells.clear()
	for y in range(art_rows):
		for x in range(art_columns):
			art_cells[Vector2i(x, y)] = TILE_GRASS

	# Water barriers match the gameplay/navigation world.
	GBPaint.paint_rect(art_cells, 0, 37, art_columns, 4, TILE_WATER, art_columns, art_rows)
	GBPaint.paint_rect(art_cells, 54, 0, 10, 16, TILE_WATER, art_columns, art_rows)

	# GB Studio's line-paint structure builds the main intercity routes.
	GBPaint.paint_line(art_cells, Vector2i(2, 19), Vector2i(60, 19), 4, TILE_ROAD_TEMP, art_columns, art_rows)
	GBPaint.paint_line(art_cells, Vector2i(29, 7), Vector2i(29, 35), 6, TILE_ROAD_TEMP, art_columns, art_rows)
	GBPaint.paint_line(art_cells, Vector2i(7, 9), Vector2i(52, 9), 3, TILE_ROAD_TEMP, art_columns, art_rows)
	GBPaint.paint_line(art_cells, Vector2i(7, 29), Vector2i(52, 29), 3, TILE_ROAD_TEMP, art_columns, art_rows)

	# Tilemap Studio-style replace turns the temporary road paint into the final
	# road material in one operation, mirroring its Ctrl+click replace workflow.
	tile_ops_changed = TileOps.substitute_tile(art_cells, TILE_ROAD_TEMP, TILE_ROAD)

	# Stamp readable company lots around every mining HQ/town.
	for raw_zone in town_zones:
		var zone: Dictionary = raw_zone
		var center: Vector2 = zone["center"]
		var c: Vector2i = _world_to_art_cell(center)
		GBPaint.paint_rect(art_cells, c.x - 3, c.y - 3, 7, 6, TILE_LOT, art_columns, art_rows)
		GBPaint.paint_rect(art_cells, c.x - 1, c.y + 3, 3, 1, TILE_PLAZA, art_columns, art_rows)

	# Partner/business pads receive smaller paved footprints.
	for raw_entity in entities:
		var entity: Dictionary = raw_entity
		var kind: String = String(entity["kind"])
		if kind == "partner" or kind == "machines" or kind == "power" or kind == "bank" or kind == "land":
			var c: Vector2i = _world_to_art_cell(entity["pos"])
			GBPaint.paint_rect(art_cells, c.x - 2, c.y - 2, 5, 5, TILE_LOT, art_columns, art_rows)
			GBPaint.paint_rect(art_cells, c.x, c.y + 2, 1, 1, TILE_PLAZA, art_columns, art_rows)

	# Use the Tilemap Studio queue-based flood fill on the north-west connected
	# grass region to create a second terrain shade without touching roads/lots.
	tile_ops_changed += TileOps.flood_fill(art_cells, Vector2i(0, 0), TILE_GRASS_DARK, art_columns, art_rows)
	gbc_map_ready = true

func _world_to_art_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor(pos.x / ART_TILE_SIZE)), 0, art_columns - 1),
		clampi(int(floor(pos.y / ART_TILE_SIZE)), 0, art_rows - 1)
	)

func _draw() -> void:
	_draw_pixel_tile_world()
	_draw_pixel_town_labels()
	_draw_world_props_pixel()
	for i in range(entities.size()):
		var entity: Dictionary = entities[i]
		_draw_entity(entity, i)
	_draw_rep()
	draw_string(ThemeDB.fallback_font, Vector2(1110.0, 278.0), "HASH RACE // PIXEL TECH CORRIDOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("d5fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(1110.0, 306.0), "GRID TOWNS • ASIC MARKETS • POWER • CAPITAL • 2D STACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("77b9c4"))

func _draw_pixel_tile_world() -> void:
	if not gbc_map_ready:
		draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), GBC_GRASS_1, true)
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var left: int = clampi(int(floor((rep_pos.x - viewport_size.x * 0.70) / ART_TILE_SIZE)) - 2, 0, art_columns - 1)
	var right: int = clampi(int(ceil((rep_pos.x + viewport_size.x * 0.70) / ART_TILE_SIZE)) + 2, 0, art_columns - 1)
	var top: int = clampi(int(floor((rep_pos.y - viewport_size.y * 0.70) / ART_TILE_SIZE)) - 2, 0, art_rows - 1)
	var bottom: int = clampi(int(ceil((rep_pos.y + viewport_size.y * 0.70) / ART_TILE_SIZE)) + 2, 0, art_rows - 1)
	for y in range(top, bottom + 1):
		for x in range(left, right + 1):
			_draw_art_tile(Vector2i(x, y), int(art_cells.get(Vector2i(x, y), TILE_GRASS)))

func _draw_art_tile(cell: Vector2i, tile_id: int) -> void:
	var p: Vector2 = VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
	var rect: Rect2 = Rect2(p, Vector2(ART_TILE_SIZE + 1.0, ART_TILE_SIZE + 1.0))
	var c0: Color = GBC_GRASS_0
	var c1: Color = GBC_GRASS_1
	var c2: Color = GBC_GRASS_2
	var c3: Color = GBC_GRASS_3
	match tile_id:
		TILE_GRASS_DARK:
			c0 = Color("0b211c"); c1 = GBC_GRASS_0; c2 = GBC_GRASS_1; c3 = GBC_GRASS_2
		TILE_ROAD:
			c0 = GBC_ROAD_0; c1 = GBC_ROAD_1; c2 = GBC_ROAD_2; c3 = GBC_ROAD_3
		TILE_PLAZA:
			c0 = Color("20272b"); c1 = Color("384247"); c2 = Color("667278"); c3 = Color("a3b0b3")
		TILE_WATER:
			c0 = GBC_WATER_0; c1 = GBC_WATER_1; c2 = GBC_WATER_2; c3 = GBC_WATER_3
		TILE_LOT:
			c0 = GBC_LOT_0; c1 = GBC_LOT_1; c2 = GBC_LOT_2; c3 = GBC_LOT_3
		_:
			pass

	draw_rect(rect, c1, true)
	# Graphite-inspired procedural variation removes obvious checker repetition
	# while staying deterministic for every logical tile.
	var mini: float = ART_TILE_SIZE / 4.0
	var noise_value: float = VisualStack.procedural_noise(cell, tile_id * 19 + 7)
	if noise_value < 0.34:
		draw_rect(Rect2(p + Vector2(0.0, 0.0), Vector2(mini, mini)), c2, true)
		draw_rect(Rect2(p + Vector2(mini * 2.0, mini * 2.0), Vector2(mini, mini)), c0, true)
	elif noise_value < 0.67:
		draw_rect(Rect2(p + Vector2(mini * 3.0, 0.0), Vector2(mini, mini)), c0, true)
		draw_rect(Rect2(p + Vector2(mini, mini * 3.0), Vector2(mini, mini)), c2, true)
	else:
		draw_rect(Rect2(p + Vector2(mini, mini), Vector2(mini, mini)), c3.darkened(0.12), true)
		draw_rect(Rect2(p + Vector2(mini * 3.0, mini * 2.0), Vector2(mini, mini)), c0, true)

	if tile_id == TILE_ROAD:
		_draw_road_connections(cell, p, c3)
	elif tile_id == TILE_WATER:
		_draw_crisp_line(p + Vector2(8.0, 15.0), p + Vector2(28.0, 15.0), c3, 3.0)
		_draw_crisp_line(p + Vector2(20.0, 34.0), p + Vector2(43.0, 34.0), c2, 3.0)
	elif tile_id == TILE_LOT:
		draw_rect(Rect2(p + Vector2(4.0, 4.0), Vector2(40.0, 40.0)), c0, false, _screen_stroke(2.0))
	elif tile_id == TILE_PLAZA:
		draw_rect(Rect2(p + Vector2(10.0, 10.0), Vector2(28.0, 28.0)), c3, false, _screen_stroke(2.0))

func _draw_road_connections(cell: Vector2i, p: Vector2, marking: Color) -> void:
	var center: Vector2 = p + Vector2(ART_TILE_SIZE * 0.5, ART_TILE_SIZE * 0.5)
	var left_road: bool = int(art_cells.get(cell + Vector2i.LEFT, -1)) == TILE_ROAD
	var right_road: bool = int(art_cells.get(cell + Vector2i.RIGHT, -1)) == TILE_ROAD
	var up_road: bool = int(art_cells.get(cell + Vector2i.UP, -1)) == TILE_ROAD
	var down_road: bool = int(art_cells.get(cell + Vector2i.DOWN, -1)) == TILE_ROAD
	if left_road or right_road:
		_draw_crisp_line(center + Vector2(-22.0, 0.0), center + Vector2(22.0, 0.0), marking, 2.0)
	if up_road or down_road:
		_draw_crisp_line(center + Vector2(0.0, -22.0), center + Vector2(0.0, 22.0), marking, 2.0)
	if not (left_road or right_road or up_road or down_road):
		draw_rect(Rect2(center - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), marking, true)

func _draw_pixel_town_labels() -> void:
	for raw_zone in town_zones:
		var zone: Dictionary = raw_zone
		var center: Vector2 = VisualStack.snap_to_pixel(zone["center"])
		var profile_idx: int = int(zone["profile_idx"])
		var accent: Color = COMPANY_ACCENTS[profile_idx]
		var sign_rect: Rect2 = Rect2(center + Vector2(-150.0, -170.0), Vector2(300.0, 30.0))
		_draw_layered_stroke_rect(sign_rect, GBC_INK, accent, accent.darkened(0.55), 3.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-142.0, -148.0), String(zone["town"]).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 284.0, 13, accent)

func _draw_world_props_pixel() -> void:
	# Simple2D-inspired colored quads give the solar field readable light falloff.
	for row in range(2):
		for col in range(5):
			var p: Vector2 = VisualStack.snap_to_pixel(Vector2(2130.0 + float(col) * 48.0, 245.0 + float(row) * 38.0))
			var panel_rect := Rect2(p, Vector2(38.0, 26.0))
			draw_polygon(VisualStack.quad_points(panel_rect), VisualStack.quad_colors(Color("122d45"), Color("367eb0")))
			draw_rect(panel_rect, Color("071018"), false, _screen_stroke(2.0))
			_draw_crisp_line(p + Vector2(19.0, 4.0), p + Vector2(19.0, 22.0), Color("76c1e2"), 2.0)
			_draw_crisp_line(p + Vector2(4.0, 13.0), p + Vector2(34.0, 13.0), Color("4b94bc"), 1.0)

	# Luxor regular-polygon concept + Galacean lerp + Spine-style mix concept:
	# animated octagonal cooling fans make the industrial campus feel alive.
	var cycle: float = fmod(float(Time.get_ticks_msec()), 900.0)
	var mirrored: float = cycle if cycle <= 450.0 else 900.0 - cycle
	var mix: float = VisualStack.mix_alpha(mirrored, 450.0)
	var glow_alpha: float = VisualStack.lerp_number(0.42, 0.95, mix)
	for center in [Vector2(2200.0, 760.0), Vector2(2270.0, 760.0), Vector2(2340.0, 760.0)]:
		var fan_center: Vector2 = VisualStack.snap_to_pixel(center)
		var housing: PackedVector2Array = VisualStack.regular_polygon(fan_center, 27.0, 8, PI / 8.0)
		draw_colored_polygon(housing, Color("132832"))
		_draw_polygon_outline(housing, Color("4b7380"), 2.0)
		for blade in range(4):
			var angle: float = mix * TAU + float(blade) * PI / 2.0
			var tip: Vector2 = fan_center + Vector2(cos(angle), sin(angle)) * 18.0
			_draw_crisp_line(fan_center, tip, Color(0.32, 0.88, 1.0, glow_alpha), 3.0)
		draw_circle(fan_center, 4.0, Color("071018"))

	# Substation pylons become chunky readable silhouettes with crisp conductors.
	for x in [660.0, 760.0, 1760.0, 1860.0]:
		draw_rect(Rect2(x - 5.0, 700.0, 10.0, 80.0), Color("6f8188"), true)
		draw_rect(Rect2(x - 22.0, 720.0, 44.0, 8.0), Color("98a7aa"), true)
		draw_rect(Rect2(x - 18.0, 732.0, 7.0, 7.0), Color("ffbd66"), true)
		draw_rect(Rect2(x + 11.0, 732.0, 7.0, 7.0), Color("ffbd66"), true)

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
	# PixiJS-style pixel snapping keeps the sprite crisp. Galacean-style lerp and
	# a Spine-inspired normalized mix create a tiny breathing/step transition.
	var cycle: float = fmod(float(Time.get_ticks_msec()), 600.0)
	var mirrored: float = cycle if cycle <= 300.0 else 600.0 - cycle
	var pose_mix: float = VisualStack.mix_alpha(mirrored, 300.0)
	var bob: float = round(VisualStack.lerp_number(0.0, -2.0, pose_mix))
	var step: int = int(round(VisualStack.lerp_number(0.0, 1.0, pose_mix)))
	var draw_pos: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(0.0, bob))
	var px: float = 4.0
	var skin0: Color = Color("7b4c38")
	var skin1: Color = Color("a86f52")
	var skin2: Color = Color("d69a72")
	var cloth0: Color = Color("0a1118")
	var cloth1: Color = Color("172633")
	var cloth2: Color = accent.darkened(0.45)
	var cloth3: Color = accent
	draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 31.0)), 20.0, 7.0)

	# Boots / legs alternate by one pixel-grid row for subtle motion.
	_draw_px(draw_pos, -3, 4, 2, 5, px, cloth0)
	_draw_px(draw_pos, 1, 4, 2, 5, px, cloth0)
	_draw_px(draw_pos, -4, 8 + step, 3, 2, px, cloth2)
	_draw_px(draw_pos, 1, 9 - step, 3, 2, px, cloth2)
	# Jacket / shoulders.
	_draw_px(draw_pos, -5, -2, 10, 7, px, cloth1)
	_draw_px(draw_pos, -6, -1 + step, 2, 5, px, cloth2)
	_draw_px(draw_pos, 4, step, 2, 5, px, cloth2)
	_draw_px(draw_pos, -3, -1, 6, 5, px, cloth2)
	_draw_px(draw_pos, 0, -1, 1, 5, px, cloth3)
	_draw_px(draw_pos, -2, 2, 4, 1, px, cloth0)
	# Neck/head/hair.
	_draw_px(draw_pos, -1, -4, 2, 2, px, skin1)
	_draw_px(draw_pos, -3, -8, 6, 5, px, skin2)
	_draw_px(draw_pos, -3, -8, 6, 1, px, cloth0)
	_draw_px(draw_pos, -3, -7, 1, 2, px, skin0)
	_draw_px(draw_pos, 2, -7, 1, 2, px, skin0)
	# Scanner visor on requested eye.
	var lens_x: int = -3 if scanner == "left" else 1
	_draw_px(draw_pos, lens_x, -6, 2, 1, px, cloth3)
	_draw_px(draw_pos, -4 if scanner == "left" else 3, -7, 1, 3, px, cloth2)
	# Tiny face highlight and belt badge.
	_draw_px(draw_pos, -1, -5, 1, 1, px, Color("f0c09a"))
	_draw_px(draw_pos, 2, -5, 1, 1, px, Color("f0c09a"))
	_draw_px(draw_pos, -1, 3, 2, 1, px, cloth3)
	if is_player:
		var player_rect := Rect2(draw_pos + Vector2(-28.0, -39.0), Vector2(56.0, 82.0))
		_draw_layered_stroke_rect(player_rect, Color(0.0, 0.0, 0.0, 0.0), Color(accent.r, accent.g, accent.b, 0.72), Color(accent.r, accent.g, accent.b, 0.28), 2.0)

func _draw_px(origin: Vector2, gx: int, gy: int, gw: int, gh: int, px: float, color: Color) -> void:
	draw_rect(Rect2(origin + Vector2(float(gx) * px, float(gy) * px), Vector2(float(gw) * px, float(gh) * px)), color, true)

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
	var pos: Vector2 = entity["pos"]
	var profile_idx: int = int(entity.get("profile_idx", company_idx))
	var accent: Color = COMPANY_ACCENTS[profile_idx]
	var merged: bool = false
	if String(entity["kind"]) == "rival":
		merged = bool(rivals[int(entity["rival_idx"])]["merged"])
	if merged:
		accent = Color("657078")
	_selection_ring(pos, idx, 122.0)
	_draw_pixel_facility(pos, Vector2(208.0, 118.0), accent, 3, "HQ")
	draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 82.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 12, WHITE)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-118.0, 100.0), String(entity["subtitle"]), HORIZONTAL_ALIGNMENT_CENTER, 236.0, 9, accent)

func _draw_partner_building(entity: Dictionary, idx: int) -> void:
	var pos: Vector2 = entity["pos"]
	var accent: Color = PARTNER_ACCENTS[int(entity["partner_idx"])]
	_selection_ring(pos, idx, 106.0)
	_draw_pixel_facility(pos, Vector2(170.0, 104.0), accent, 2, String(entity["subtitle"]))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-102.0, 76.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 204.0, 11, WHITE)

func _draw_machine_market(entity: Dictionary, idx: int) -> void:
	var pos: Vector2 = entity["pos"]
	var accent: Color = Color("bd8cff")
	_selection_ring(pos, idx, 106.0)
	_draw_pixel_facility(pos, Vector2(184.0, 108.0), accent, 2, "ASIC")
	for col in range(4):
		for row in range(3):
			draw_rect(Rect2(pos + Vector2(-62.0 + float(col) * 38.0, -27.0 + float(row) * 17.0), Vector2(22.0, 10.0)), Color("071018"), true)
			draw_rect(Rect2(pos + Vector2(-58.0 + float(col) * 38.0, -23.0 + float(row) * 17.0), Vector2(4.0, 4.0)), GREEN, true)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 78.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 11, WHITE)

func _draw_power_building(entity: Dictionary, idx: int) -> void:
	var pos: Vector2 = entity["pos"]
	var accent: Color = Color("ffd36e")
	_selection_ring(pos, idx, 106.0)
	_draw_pixel_facility(pos, Vector2(180.0, 104.0), accent, 2, "MW")
	for x in [-48.0, 0.0, 48.0]:
		draw_rect(Rect2(pos + Vector2(x - 12.0, -16.0), Vector2(24.0, 24.0)), Color("101820"), true)
		draw_rect(Rect2(pos + Vector2(x - 6.0, -10.0), Vector2(12.0, 12.0)), accent, false, _screen_stroke(3.0))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 78.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 11, WHITE)

func _draw_bank_building(entity: Dictionary, idx: int) -> void:
	var pos: Vector2 = entity["pos"]
	var accent: Color = ORANGE
	_selection_ring(pos, idx, 104.0)
	_draw_pixel_facility(pos, Vector2(168.0, 108.0), accent, 2, "BANK")
	for x in [-45.0, -15.0, 15.0, 45.0]:
		draw_rect(Rect2(pos + Vector2(x - 4.0, -28.0), Vector2(8.0, 55.0)), accent.darkened(0.35), true)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 78.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 11, WHITE)

func _draw_land_building(entity: Dictionary, idx: int) -> void:
	var pos: Vector2 = entity["pos"]
	var accent: Color = Color("8ed06c")
	_selection_ring(pos, idx, 104.0)
	_draw_pixel_facility(pos, Vector2(166.0, 102.0), accent, 2, "LAND")
	for gx in range(3):
		for gy in range(2):
			draw_rect(Rect2(pos + Vector2(-46.0 + float(gx) * 34.0, -18.0 + float(gy) * 25.0), Vector2(24.0, 15.0)), accent.darkened(0.55), false, _screen_stroke(2.0))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-106.0, 76.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 212.0, 11, WHITE)

func _draw_pixel_facility(pos: Vector2, size_value: Vector2, accent: Color, floors: int, badge: String) -> void:
	var snapped_pos: Vector2 = VisualStack.snap_to_pixel(pos)
	var left: float = snapped_pos.x - size_value.x * 0.5
	var top: float = snapped_pos.y - size_value.y * 0.62
	var body: Rect2 = Rect2(left, top, size_value.x, size_value.y)
	# Ground every facility at its visual foot instead of letting the sprite mass
	# hover above the terrain. A compact contact shadow, foundation apron and
	# bottom-edge seam make the building read as attached to its lot at every zoom.
	var ground_y: float = body.end.y
	var contact_shadow := Rect2(Vector2(left + 6.0, ground_y - 5.0), Vector2(size_value.x - 12.0, 13.0))
	draw_rect(contact_shadow, Color("00000078"), true)
	var foundation := Rect2(Vector2(left - 3.0, ground_y - 7.0), Vector2(size_value.x + 6.0, 9.0))
	draw_rect(foundation, GBC_LOT_0, true)
	draw_rect(Rect2(Vector2(left + 3.0, ground_y - 5.0), Vector2(size_value.x - 6.0, 3.0)), accent.darkened(0.62), true)
	# Vger-inspired layered stroke and Simple2D-style roof gradient make every
	# facility read as a distinct pixel building instead of a flat rectangle.
	_draw_layered_stroke_rect(body, Color("0b1720"), Color("020609"), accent.darkened(0.58), 4.0)
	var roof_rect := Rect2(left, top, size_value.x, 14.0)
	draw_polygon(VisualStack.quad_points(roof_rect), VisualStack.quad_colors(accent.darkened(0.18), accent.lightened(0.16)))
	var floor_h: float = (size_value.y - 28.0) / float(maxi(floors, 1))
	for floor_idx in range(floors):
		var fy: float = top + 18.0 + float(floor_idx) * floor_h
		for window_idx in range(4):
			var wx: float = left + 16.0 + float(window_idx) * ((size_value.x - 32.0) / 4.0)
			draw_rect(Rect2(wx, fy, 18.0, 12.0), accent.darkened(0.48), true)
			draw_rect(Rect2(wx + 4.0, fy + 3.0, 10.0, 6.0), Color(accent.r, accent.g, accent.b, 0.72), true)
	# Door and rooftop tech mast.
	draw_rect(Rect2(snapped_pos + Vector2(-14.0, size_value.y * 0.12), Vector2(28.0, size_value.y * 0.27)), Color("020609"), true)
	draw_rect(Rect2(snapped_pos + Vector2(-11.0, size_value.y * 0.15), Vector2(7.0, size_value.y * 0.20)), accent.darkened(0.25), true)
	draw_rect(Rect2(snapped_pos + Vector2(size_value.x * 0.28, -size_value.y * 0.76), Vector2(6.0, 35.0)), accent.darkened(0.15), true)
	draw_rect(Rect2(snapped_pos + Vector2(size_value.x * 0.23, -size_value.y * 0.80), Vector2(26.0, 7.0)), accent, true)
	draw_rect(Rect2(left + 8.0, top + 17.0, 42.0, 18.0), GBC_INK, true)
	draw_string(ThemeDB.fallback_font, Vector2(left + 11.0, top + 31.0), badge, HORIZONTAL_ALIGNMENT_LEFT, 36.0, 9, accent)

func _screen_stroke(base_width: float) -> float:
	var zoom_value: float = 1.0
	if is_instance_valid(camera):
		zoom_value = camera.zoom.x
	return VisualStack.constant_screen_stroke(base_width, zoom_value)

func _draw_crisp_line(from: Vector2, to: Vector2, color: Color, base_width: float) -> void:
	var width: float = _screen_stroke(base_width)
	var line: PackedVector2Array = VisualStack.crisp_line(from, to, width)
	draw_line(line[0], line[1], color, width)

func _draw_layered_stroke_rect(rect: Rect2, fill_color: Color, outer_color: Color, inner_color: Color, base_width: float) -> void:
	draw_rect(rect, fill_color, true)
	var outer_width: float = _screen_stroke(base_width)
	draw_rect(rect, outer_color, false, outer_width)
	var inner_rect: Rect2 = VisualStack.inner_stroke_rect(rect, maxf(2.0, outer_width))
	if inner_rect.size.x > 2.0 and inner_rect.size.y > 2.0:
		draw_rect(inner_rect, inner_color, false, _screen_stroke(1.0))

func _draw_polygon_outline(points: PackedVector2Array, color: Color, base_width: float) -> void:
	if points.size() < 2:
		return
	for i in range(points.size()):
		_draw_crisp_line(points[i], points[(i + 1) % points.size()], color, base_width)

func debug_gbc_map_ready() -> bool:
	return gbc_map_ready and art_cells.size() == art_columns * art_rows

func debug_gbc_road_tiles() -> int:
	var count: int = 0
	for value in art_cells.values():
		if int(value) == TILE_ROAD:
			count += 1
	return count

func debug_tile_ops_changed() -> int:
	return tile_ops_changed

func debug_visual_stack_ready() -> bool:
	return VisualStack.source_contract_ready()

func debug_visual_reference_count() -> int:
	return VisualStack.SOURCE_COUNT
