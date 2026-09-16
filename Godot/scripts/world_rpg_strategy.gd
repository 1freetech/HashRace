extends "res://scripts/world_gbc.gd"

# RPG + strategy presentation layer.
# Uses the CC0 Python-Monsters movement helper for directional state and
# axis-separated collision while keeping Hash Race's quarterly company economy.
# The reachable-grid overlay is an original Hash Race implementation inspired by
# common turn-based tactics navigation patterns.

const RPGMovement = preload("res://scripts/rpg_movement.gd")
const SCANNER_RANGE_CELLS: int = 7

var rep_facing: String = "down"
var rep_animation_state: String = "down_idle"
var rep_step_phase: float = 0.0
var scanner_overlay_enabled: bool = true
var scanner_cells: Array[Vector2i] = []
var scanner_button: Button
var phase_label: Label
var last_scanner_cell: Vector2i = Vector2i(-999, -999)

func _ready() -> void:
    super._ready()
    _install_rpg_strategy_ui()
    _refresh_scanner_cells(true)
    _open_message(
        "COMPANY FIELD MODE // %s" % _current_town_name(),
        "Explore like an RPG, plan like a strategy game. Movement now respects buildings and water. Your scanner visor shows reachable grid cells; press R to toggle it, E to talk, T for town transit, and end the quarter only after your company plan is ready."
    )
    queue_redraw()

func _install_rpg_strategy_ui() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    layer.name = "RPGStrategyLayer"
    layer.layer = 10
    add_child(layer)

    scanner_button = Button.new()
    scanner_button.position = Vector2(218.0, 88.0)
    scanner_button.size = Vector2(190.0, 42.0)
    scanner_button.text = "SCANNER GRID  [R]"
    scanner_button.add_theme_font_size_override("font_size", 12)
    scanner_button.pressed.connect(_toggle_scanner_overlay)
    layer.add_child(scanner_button)

    phase_label = Label.new()
    phase_label.position = Vector2(418.0, 92.0)
    phase_label.size = Vector2(330.0, 34.0)
    phase_label.text = "QUARTER PHASE: PLAN • DEAL • BUILD"
    phase_label.add_theme_font_size_override("font_size", 12)
    phase_label.add_theme_color_override("font_color", Color("8cecff"))
    layer.add_child(phase_label)

func _process(delta: float) -> void:
    var before: Vector2 = rep_pos
    super._process(delta)
    var requested_motion: Vector2 = rep_pos - before

    if RPGMovement.is_moving(requested_motion):
        var corrected: Vector2 = RPGMovement.resolve_axis_motion(grid_nav, before, requested_motion)
        if corrected != rep_pos:
            rep_pos = corrected
            if corrected.distance_to(before) <= 0.01 and has_click_target:
                _clear_nav_path()
            if is_instance_valid(camera):
                camera.position = rep_pos
        var actual_motion: Vector2 = rep_pos - before
        if RPGMovement.is_moving(actual_motion):
            rep_facing = RPGMovement.facing_from_motion(actual_motion, rep_facing)
            rep_animation_state = RPGMovement.animation_state(rep_facing, true)
            rep_step_phase = fmod(rep_step_phase + delta * 8.0, TAU)
        else:
            rep_animation_state = RPGMovement.animation_state(rep_facing, false)
    else:
        rep_animation_state = RPGMovement.animation_state(rep_facing, false)

    _refresh_scanner_cells(false)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_R:
                _toggle_scanner_overlay()
                get_viewport().set_input_as_handled()
                return
            if key_event.keycode == KEY_E or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE:
                var idx: int = _nearest_entity()
                if idx >= 0:
                    var entity: Dictionary = entities[idx]
                    rep_facing = RPGMovement.face_target(rep_pos, entity["pos"], rep_facing)
                    rep_animation_state = RPGMovement.animation_state(rep_facing, false)
    super._unhandled_input(event)

func _toggle_scanner_overlay() -> void:
    scanner_overlay_enabled = not scanner_overlay_enabled
    if is_instance_valid(scanner_button):
        scanner_button.text = "SCANNER: %s  [R]" % ("ON" if scanner_overlay_enabled else "OFF")
    if scanner_overlay_enabled:
        _refresh_scanner_cells(true)
        _feedback("Scanner visor online: showing nearby reachable grid cells.")
    else:
        _feedback("Scanner visor overlay hidden. Navigation and collisions remain active.")
    queue_redraw()

func _refresh_scanner_cells(force: bool) -> void:
    if grid_nav == null:
        return
    var current_cell: Vector2i = grid_nav.world_to_cell(rep_pos)
    if not force and current_cell == last_scanner_cell:
        return
    last_scanner_cell = current_cell
    scanner_cells = grid_nav.reachable_cells(rep_pos, SCANNER_RANGE_CELLS)
    queue_redraw()

func _draw() -> void:
    super._draw()
    if scanner_overlay_enabled:
        _draw_scanner_overlay()
    _draw_direction_state()
    _draw_nearby_notice()

func _draw_scanner_overlay() -> void:
    if grid_nav == null:
        return
    for cell in scanner_cells:
        var center: Vector2 = grid_nav.cell_to_world(cell)
        var rect: Rect2 = Rect2(center - Vector2(20.0, 20.0), Vector2(40.0, 40.0))
        draw_rect(rect, Color("55efff12"), true)
        draw_rect(rect, Color("55efff3f"), false, 1.0)
    draw_string(
        ThemeDB.fallback_font,
        rep_pos + Vector2(-54.0, -72.0),
        "VISOR R%d" % SCANNER_RANGE_CELLS,
        HORIZONTAL_ALIGNMENT_LEFT,
        -1,
        11,
        Color("75f6ff")
    )

func _draw_direction_state() -> void:
    var direction: Vector2 = Vector2.DOWN
    match rep_facing:
        "up":
            direction = Vector2.UP
        "left":
            direction = Vector2.LEFT
        "right":
            direction = Vector2.RIGHT
        _:
            direction = Vector2.DOWN
    var tip: Vector2 = rep_pos + direction * 30.0
    draw_line(rep_pos + direction * 17.0, tip, Color("8affbd"), 3.0)
    draw_circle(tip, 3.0, Color("d7fff0"))

    if not rep_animation_state.ends_with("_idle"):
        var bob: float = sin(rep_step_phase) * 3.0
        draw_rect(Rect2(rep_pos + Vector2(-10.0, 21.0 + bob), Vector2(7.0, 4.0)), Color("071014"), true)
        draw_rect(Rect2(rep_pos + Vector2(3.0, 21.0 - bob), Vector2(7.0, 4.0)), Color("071014"), true)

func _draw_nearby_notice() -> void:
    var idx: int = _nearest_entity()
    if idx < 0:
        return
    var entity: Dictionary = entities[idx]
    var kind: String = String(entity["kind"])
    if kind != "rival_rep" and kind != "partner_rep":
        return
    var pos: Vector2 = entity["pos"]
    var bubble: Rect2 = Rect2(pos + Vector2(-12.0, -76.0), Vector2(24.0, 24.0))
    draw_rect(bubble, Color("f4ffed"), true)
    draw_rect(bubble, Color("071014"), false, 2.0)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-4.0, -58.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("071014"))

func debug_rpg_collision_ready() -> bool:
    if grid_nav == null:
        return false
    return not grid_nav.world_is_walkable(Vector2(100.0, 1800.0))

func debug_scanner_reachable_count() -> int:
    return scanner_cells.size()

func debug_rep_animation_state() -> String:
    return rep_animation_state

func debug_range_limited_path_exists() -> bool:
    if grid_nav == null:
        return false
    var start: Vector2 = rep_pos
    var reachable: Array[Vector2i] = grid_nav.reachable_cells(start, 5)
    if reachable.size() < 2:
        return false
    var destination: Vector2 = grid_nav.cell_to_world(reachable[reachable.size() - 1])
    var path: Array[Vector2] = grid_nav.find_path_in_range(start, destination, reachable)
    return not path.is_empty()
