extends "res://scripts/world_gbc.gd"

const RPGMovement = preload("res://scripts/rpg_movement.gd")
const SCANNER_RANGE_CELLS: int = 7
const INTERACT_RANGE: float = 92.0

var rep_facing: String = "down"
var rep_animation_state: String = "down_idle"
var rep_step_phase: float = 0.0
var scanner_overlay_enabled: bool = true
var scanner_cells: Array[Vector2i] = []
var scanner_button: Button
var phase_label: Label
var interact_label: Label
var last_scanner_cell: Vector2i = Vector2i(-999, -999)
var live_quarter_confirmation_pending: bool = false

func _ready() -> void:
    super._ready()
    _install_rpg_strategy_ui()
    _refresh_scanner_cells(true)
    _open_message("COMPANY FIELD MODE // %s" % _current_town_name(), "Explore like an RPG, plan like a strategy game. Walk near a company, partner, property, or deal target and press E to interact. R toggles the scanner and T opens town transit.")
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
    interact_label = Label.new()
    interact_label.position = Vector2(418.0, 118.0)
    interact_label.size = Vector2(500.0, 30.0)
    interact_label.text = ""
    interact_label.add_theme_font_size_override("font_size", 12)
    interact_label.add_theme_color_override("font_color", Color("8affbd"))
    layer.add_child(interact_label)

func _process(delta: float) -> void:
    var before: Vector2 = rep_pos
    super._process(delta)
    var requested_motion: Vector2 = rep_pos - before
    if RPGMovement.is_moving(requested_motion):
        _invalidate_quarter_preview("Quarter preview cancelled because your field position changed.")
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
    _refresh_interaction_prompt()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_ESCAPE and live_quarter_confirmation_pending:
                _cancel_live_quarter_confirmation()
                get_viewport().set_input_as_handled()
                return
            if key_event.keycode == KEY_R:
                _invalidate_quarter_preview("Quarter preview cancelled because the field plan changed.")
                _toggle_scanner_overlay()
                get_viewport().set_input_as_handled()
                return
            if key_event.keycode == KEY_E or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE:
                var idx: int = _nearest_entity()
                if idx >= 0 and _entity_in_interact_range(idx):
                    _invalidate_quarter_preview("Quarter preview cancelled because you opened a new interaction.")
                    var entity: Dictionary = entities[idx]
                    rep_facing = RPGMovement.face_target(rep_pos, entity["pos"], rep_facing)
                    rep_animation_state = RPGMovement.animation_state(rep_facing, false)
                    _open_entity(idx)
                    get_viewport().set_input_as_handled()
                    return
                _feedback("Move closer to a company, partner, property, or deal target to interact.")
                get_viewport().set_input_as_handled()
                return
    super._unhandled_input(event)

func _entity_in_interact_range(idx: int) -> bool:
    if idx < 0 or idx >= entities.size():
        return false
    var entity: Dictionary = entities[idx]
    return rep_pos.distance_to(Vector2(entity["pos"])) <= INTERACT_RANGE

func _refresh_interaction_prompt() -> void:
    if not is_instance_valid(interact_label):
        return
    var idx: int = _nearest_entity()
    if idx < 0 or not _entity_in_interact_range(idx):
        interact_label.text = ""
        return
    var entity: Dictionary = entities[idx]
    var label: String = String(entity.get("name", entity.get("label", "target")))
    interact_label.text = "[E] INTERACT // %s" % label.to_upper()

func _project_live_quarter_profit() -> float:
    var mined_btc: float = _btc_per_day() * QUARTER_DAYS
    var sold_btc: float = mined_btc * (1.0 - float(player["treasury_hold"]))
    var revenue: float = sold_btc * btc_price + float(player["recurring_income"])
    var power_cost: float = _machine_load_kw() * 24.0 * QUARTER_DAYS * _effective_power_cost() * _uptime()
    var ops_cost: float = float(player["machines"]) * 0.38 * QUARTER_DAYS
    var debt_cost: float = float(player["debt"]) * float(player["debt_rate"]) * (QUARTER_DAYS / 365.0)
    return revenue - power_cost - ops_cost - debt_cost

func _end_quarter() -> void:
    if campaign_complete:
        super._end_quarter()
        return
    if not live_quarter_confirmation_pending:
        live_quarter_confirmation_pending = true
        var projected_profit: float = _project_live_quarter_profit()
        var projected_cash: float = float(player["cash"]) + projected_profit
        quarter_button.text = "CONFIRM END QUARTER"
        var risk: String = ""
        if projected_cash < 0.0:
            risk = " DANGER: projected cash falls below $0."
        elif projected_profit < 0.0:
            risk = " Warning: this quarter is projected to lose cash."
        _feedback("QUARTER PREVIEW: projected cash result $%d • projected ending cash $%d.%s Click CONFIRM END QUARTER to settle about 91 days, or press Esc to cancel." % [int(projected_profit), int(projected_cash), risk])
        return
    live_quarter_confirmation_pending = false
    quarter_button.text = "END QUARTER"
    super._end_quarter()

func _invalidate_quarter_preview(reason: String) -> void:
    if not live_quarter_confirmation_pending:
        return
    live_quarter_confirmation_pending = false
    if is_instance_valid(quarter_button) and not campaign_complete:
        quarter_button.text = "END QUARTER"
    _feedback(reason)

func _cancel_live_quarter_confirmation() -> void:
    _invalidate_quarter_preview("Quarter settlement cancelled. Keep planning, dealing, or building before advancing time.")

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

func _draw_scanner_overlay() -> void:
    if grid_nav == null:
        return
    for cell in scanner_cells:
        var center: Vector2 = grid_nav.cell_to_world(cell)
        var rect: Rect2 = Rect2(center - Vector2(20.0, 20.0), Vector2(40.0, 40.0))
        draw_rect(rect, Color("55efff12"), true)
        draw_rect(rect, Color("55efff3f"), false, 1.0)
    draw_string(ThemeDB.fallback_font, rep_pos + Vector2(-54.0, -72.0), "VISOR R%d" % SCANNER_RANGE_CELLS, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("75f6ff"))

func _draw_direction_state() -> void:
    var direction: Vector2 = Vector2.DOWN
    match rep_facing:
        "up": direction = Vector2.UP
        "left": direction = Vector2.LEFT
        "right": direction = Vector2.RIGHT
        _: direction = Vector2.DOWN
    var tip: Vector2 = rep_pos + direction * 30.0
    draw_line(rep_pos + direction * 17.0, tip, Color("8affbd"), 3.0)
    draw_circle(tip, 3.0, Color("d7fff0"))

func debug_interaction_range_ready() -> bool:
    return INTERACT_RANGE >= 80.0 and INTERACT_RANGE <= 120.0

func debug_interaction_prompt_ready() -> bool:
    return is_instance_valid(interact_label)

func debug_rpg_collision_ready() -> bool:
    if grid_nav == null or entities.is_empty():
        return false
    var first_entity: Dictionary = entities[0]
    var blocked_pos: Vector2 = first_entity["pos"]
    return not grid_nav.world_is_walkable(blocked_pos)

func debug_scanner_reachable_count() -> int:
    if grid_nav == null:
        return 0
    return grid_nav.reachable_cells(rep_pos, SCANNER_RANGE_CELLS).size()

func debug_rep_animation_state() -> String:
    return rep_animation_state

func debug_range_limited_path_exists() -> bool:
    if grid_nav == null:
        return false
    var reachable: Array[Vector2i] = grid_nav.reachable_cells(rep_pos, SCANNER_RANGE_CELLS)
    if reachable.size() < 2:
        return false
    var destination: Vector2 = grid_nav.cell_to_world(reachable[reachable.size() - 1])
    var path: Array[Vector2] = grid_nav.find_path_in_range(rep_pos, destination, reachable)
    return not path.is_empty()
