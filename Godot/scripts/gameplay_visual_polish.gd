extends Node2D
class_name HashRaceGameplayVisualPolish

# Lightweight world-space polish layered over the proven v0.165 gameplay head.
# This script does not own simulation state, collision, sprites, or placement.
# It only makes existing roads/facilities/interactions read like a finished game.
const WorldScale = preload("res://scripts/world_scale_rules.gd")
const ROAD_TILE := 3
const TILE_SIZE := 48.0
const POLISH_REVISION := 2
const INTERACT_DISTANCE := 145.0
const ROAD_EDGE := Color("3b4143")
const ROAD_GLEAM := Color("a3aaa5")
const ROAD_REFLECTOR := Color("e7c65b")
const PANEL_DARK := Color("0a1217")
const PANEL_MID := Color("26343a")
const GLASS := Color("47626b")
const PROMPT_GREEN := Color("70ff9b")

var redraw_accumulator := 0.0

func _ready() -> void:
    set_process(true)
    set_meta("hashrace_gameplay_visual_polish_revision", POLISH_REVISION)
    queue_redraw()

func _process(delta: float) -> void:
    redraw_accumulator += delta
    if redraw_accumulator >= 0.10:
        redraw_accumulator = 0.0
        queue_redraw()

func _draw() -> void:
    var world := get_parent()
    if world == null:
        return
    _draw_road_readability(world)
    _draw_facility_detail(world)
    _draw_interaction_feedback(world)
    _draw_click_target(world)

func _draw_road_readability(world: Node) -> void:
    var cells_value: Variant = world.get("art_cells")
    if not cells_value is Dictionary:
        return
    var cells: Dictionary = cells_value
    for raw_cell in cells.keys():
        var cell: Vector2i = raw_cell
        if int(cells.get(cell, -1)) != ROAD_TILE:
            continue
        var p := Vector2(float(cell.x) * TILE_SIZE, float(cell.y) * TILE_SIZE)
        var left := int(cells.get(cell + Vector2i.LEFT, -1)) == ROAD_TILE
        var right := int(cells.get(cell + Vector2i.RIGHT, -1)) == ROAD_TILE
        var up := int(cells.get(cell + Vector2i.UP, -1)) == ROAD_TILE
        var down := int(cells.get(cell + Vector2i.DOWN, -1)) == ROAD_TILE
        var horizontal := left or right
        var vertical := up or down

        # Edge-only treatment keeps player/NPC sprites unobstructed while making
        # the inherited pale path read as a deliberate road with curbs/reflectors.
        if horizontal:
            draw_rect(Rect2(p + Vector2(0.0, 2.0), Vector2(TILE_SIZE, 3.0)), ROAD_EDGE, true)
            draw_rect(Rect2(p + Vector2(0.0, TILE_SIZE - 5.0), Vector2(TILE_SIZE, 3.0)), ROAD_EDGE, true)
            draw_rect(Rect2(p + Vector2(4.0, 6.0), Vector2(8.0, 1.0)), ROAD_GLEAM, true)
            if (cell.x + cell.y) % 2 == 0:
                draw_rect(Rect2(p + Vector2(21.0, 4.0), Vector2(6.0, 2.0)), ROAD_REFLECTOR, true)
                draw_rect(Rect2(p + Vector2(21.0, TILE_SIZE - 6.0), Vector2(6.0, 2.0)), ROAD_REFLECTOR.darkened(0.18), true)
        if vertical:
            draw_rect(Rect2(p + Vector2(2.0, 0.0), Vector2(3.0, TILE_SIZE)), ROAD_EDGE, true)
            draw_rect(Rect2(p + Vector2(TILE_SIZE - 5.0, 0.0), Vector2(3.0, TILE_SIZE)), ROAD_EDGE, true)
            if (cell.x + cell.y) % 2 == 0:
                draw_rect(Rect2(p + Vector2(4.0, 21.0), Vector2(2.0, 6.0)), ROAD_REFLECTOR, true)
                draw_rect(Rect2(p + Vector2(TILE_SIZE - 6.0, 21.0), Vector2(2.0, 6.0)), ROAD_REFLECTOR.darkened(0.18), true)
        if horizontal and vertical:
            draw_rect(Rect2(p + Vector2(7.0, 7.0), Vector2(5.0, 5.0)), ROAD_GLEAM.darkened(0.25), true)
            draw_rect(Rect2(p + Vector2(TILE_SIZE - 12.0, TILE_SIZE - 12.0), Vector2(5.0, 5.0)), ROAD_GLEAM.darkened(0.25), true)

func _draw_facility_detail(world: Node) -> void:
    var entities_value: Variant = world.get("entities")
    if not entities_value is Array:
        return
    var entities: Array = entities_value
    for raw_entity in entities:
        if not raw_entity is Dictionary:
            continue
        var entity: Dictionary = raw_entity
        var kind := String(entity.get("kind", ""))
        if not WorldScale.is_building_kind(kind):
            continue
        var pos := Vector2(entity.get("pos", Vector2.ZERO))
        var size_value := WorldScale.size_for_kind(kind)
        var rect := Rect2(pos - size_value * Vector2(0.5, 0.62), size_value)
        var accent := _entity_accent(entity, kind)
        _draw_rooftop_equipment(rect, accent)
        _draw_facade_panels(rect, accent)
        _draw_service_lights(rect, accent)

func _entity_accent(entity: Dictionary, kind: String) -> Color:
    if entity.has("accent") and entity.get("accent") is Color:
        return entity.get("accent")
    match kind:
        "machines": return Color("bd8cff")
        "power": return Color("ffd36e")
        "bank": return Color("e69a58")
        "land": return Color("55d5a6")
        "partner": return Color("55d5a6")
        "rival": return Color("d68c5c")
        "hq": return Color("7bcf83")
    return Color("6fe6a2")

func _draw_rooftop_equipment(rect: Rect2, accent: Color) -> void:
    var roof_y := rect.position.y + 8.0
    var unit_w := clampf(rect.size.x * 0.12, 26.0, 42.0)
    var gap := clampf(rect.size.x * 0.07, 18.0, 34.0)
    var total := unit_w * 3.0 + gap * 2.0
    var start_x := rect.position.x + (rect.size.x - total) * 0.5
    for i in range(3):
        var x := start_x + float(i) * (unit_w + gap)
        var unit := Rect2(Vector2(x, roof_y), Vector2(unit_w, 13.0))
        draw_rect(unit, PANEL_DARK, true)
        draw_rect(unit.grow(-2.0), PANEL_MID, false, 1.0)
        draw_line(unit.position + Vector2(5.0, 5.0), Vector2(unit.end.x - 5.0, unit.position.y + 5.0), accent.darkened(0.45), 2.0)
    var conduit_y := roof_y + 17.0
    draw_line(Vector2(start_x + unit_w * 0.5, conduit_y), Vector2(start_x + total - unit_w * 0.5, conduit_y), Color("66757b"), 2.0)

func _draw_facade_panels(rect: Rect2, accent: Color) -> void:
    var y0 := rect.position.y + 70.0
    var y1 := rect.end.y - 20.0
    if y1 <= y0:
        return
    for i in range(1, 4):
        var x := rect.position.x + rect.size.x * float(i) / 4.0
        draw_line(Vector2(x, y0), Vector2(x, y1), Color(0.10, 0.16, 0.18, 0.65), 1.0)
    var win_size := Vector2(clampf(rect.size.x * 0.12, 26.0, 42.0), 15.0)
    var left_win := Rect2(rect.position + Vector2(18.0, rect.size.y * 0.47), win_size)
    var right_win := Rect2(Vector2(rect.end.x - 18.0 - win_size.x, left_win.position.y), win_size)
    for win in [left_win, right_win]:
        draw_rect(win, PANEL_DARK, true)
        draw_rect(win.grow(-3.0), GLASS, true)
        draw_line(win.position + Vector2(4.0, win.size.y - 4.0), win.end - Vector2(4.0, 4.0), accent.darkened(0.30), 1.0)

func _draw_service_lights(rect: Rect2, accent: Color) -> void:
    var y := rect.position.y + rect.size.y * 0.62
    for x in [rect.position.x + 15.0, rect.end.x - 15.0]:
        draw_circle(Vector2(x, y), 4.0, Color("182126"))
        draw_circle(Vector2(x, y), 2.0, accent.lightened(0.35))

func _draw_interaction_feedback(world: Node) -> void:
    var value: Variant = world.get("entities")
    if not value is Array:
        return
    var entities: Array = value
    var player_pos := Vector2(world.get("rep_pos"))
    var idx := -1
    var nearest := INTERACT_DISTANCE
    # Match the real E-key target selection, not the previously selected entity.
    for i in range(entities.size()):
        var candidate: Dictionary = entities[i]
        var distance := player_pos.distance_to(Vector2(candidate.get("pos", Vector2.ZERO)))
        if distance < nearest:
            nearest = distance
            idx = i
    if idx < 0:
        return
    var entity: Dictionary = entities[idx]
    var kind := String(entity.get("kind", ""))
    var pos := Vector2(entity.get("pos", Vector2.ZERO))
    var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 180.0)
    var arrow_y := pos.y - 118.0
    if WorldScale.is_building_kind(kind):
        arrow_y = pos.y - WorldScale.size_for_kind(kind).y * 0.72
    var arrow := PackedVector2Array([
        Vector2(pos.x - 8.0, arrow_y),
        Vector2(pos.x + 8.0, arrow_y),
        Vector2(pos.x, arrow_y + 10.0),
    ])
    draw_colored_polygon(arrow, PROMPT_GREEN.lerp(Color.WHITE, pulse * 0.25))
    var label := "[E]  " + _action_for_kind(kind)
    var width := maxf(108.0, float(label.length()) * 8.0 + 14.0)
    var plate := Rect2(Vector2(pos.x - width * 0.5, arrow_y - 29.0), Vector2(width, 21.0))
    draw_rect(plate, Color("03080be8"), true)
    draw_rect(plate, PROMPT_GREEN.darkened(0.35), false, 1.0)
    draw_string(ThemeDB.fallback_font, plate.position + Vector2(0.0, 14.0), label, HORIZONTAL_ALIGNMENT_CENTER, width, 11, PROMPT_GREEN)

func _action_for_kind(kind: String) -> String:
    match kind:
        "hq": return "MANAGE"
        "machines": return "BUY MINERS"
        "power": return "POWER"
        "bank": return "FINANCE"
        "land": return "LAND"
        "partner": return "PARTNER"
        "rival": return "NEGOTIATE"
    return "TALK" if kind.ends_with("_rep") else "INTERACT"

func _draw_click_target(world: Node) -> void:
    if not bool(world.get("has_click_target")):
        return
    var target := Vector2(world.get("click_target"))
    var phase := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 140.0)
    var radius := 8.0 + phase * 3.0
    draw_circle(target, radius, Color(0.35, 1.0, 0.55, 0.22), false, 2.0)
    draw_line(target + Vector2(-6.0, 0.0), target + Vector2(6.0, 0.0), PROMPT_GREEN, 1.0)
    draw_line(target + Vector2(0.0, -6.0), target + Vector2(0.0, 6.0), PROMPT_GREEN, 1.0)

func debug_ready() -> bool:
    var world := get_parent()
    return world != null and int(get_meta("hashrace_gameplay_visual_polish_revision", 0)) == POLISH_REVISION
