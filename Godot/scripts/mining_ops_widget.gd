extends Control

# Hash Race v0.068 compact Mining Ops HUD.
# One consolidated upper-right widget replaces the duplicate full-width stat bar.
# Six live metrics remain: hashrate, power, efficiency, uptime, BTC and USD cash.

signal close_requested
signal mount_changed(slot: int)

const BASE_SIZE := Vector2(528.0, 248.0)
const MIN_SIZE := Vector2(420.0, 208.0)
const EDGE_GRAB: float = 8.0
const MIN_CARD_H: float = 54.0

const RESIZE_NONE: int = 0
const RESIZE_LEFT: int = 1
const RESIZE_RIGHT: int = 2
const RESIZE_TOP: int = 4
const RESIZE_BOTTOM: int = 8

const HEADER_H: float = 44.0
const FOOTER_H: float = 24.0
const CARD_TOP: float = 50.0
const CARD_H: float = 82.0
const MARGIN_X: float = 12.0
const CARD_GAP: float = 7.0
const ROW_GAP: float = 5.0
const SAMPLE_INTERVAL: float = 1.0
const MAX_HISTORY: int = 24

const BG := Color("02090d")
const PANEL := Color("061117")
const BORDER := Color("173542")
const BORDER_HI := Color("1e6b71")
const GREEN := Color("37f6a0")
const GREEN_HI := Color("5dffc1")
const CYAN := Color("61bff2")
const MUTED := Color("7896a8")
const WHITE := Color("d8edf2")
const WARNING := Color("ffc45e")
const BAD := Color("ff6b6b")

const METRIC_KEYS: Array[String] = ["hashrate", "power", "efficiency", "uptime", "btc", "cash"]
const METRIC_LABELS: Array[String] = ["HASHRATE", "POWER", "EFFICIENCY", "UPTIME", "BTC TREASURY", "USD CASH"]

var world: Node
var current: Dictionary = {}
var histories: Dictionary = {}
var simulation_snapshot: Dictionary = {}
var sample_accum := 0.0

var dragging := false
var drag_offset := Vector2.ZERO
var resizing := false
var resize_mask: int = RESIZE_NONE
var hover_resize_mask: int = RESIZE_NONE
var resize_start_mouse := Vector2.ZERO
var resize_start_position := Vector2.ZERO
var resize_start_size := BASE_SIZE
var expanded_size := BASE_SIZE
var collapsed := false
var mount_slot: int = 1
var default_position_set := false

func setup(world_node: Node) -> void:
    world = world_node
    name = "MiningOpsWidget"
    size = BASE_SIZE
    expanded_size = BASE_SIZE
    custom_minimum_size = MIN_SIZE
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    focus_mode = Control.FOCUS_NONE
    tooltip_text = "Live Mining Ops. Drag the title bar to move it. Drag any top/side/bottom edge or corner to resize it."
    for key in METRIC_KEYS:
        histories[key] = []
    set_process(true)
    force_refresh()

func apply_simulation_snapshot(snapshot_data: Dictionary) -> void:
    simulation_snapshot = snapshot_data.duplicate(true)
    _accept_sample(_normalized_snapshot(simulation_snapshot))

func mount_top_right() -> void:
    mount_slot = 1
    default_position_set = true
    _snap_to_mount(1)

func set_screen_scale(viewport_size: Vector2) -> void:
    var fit := minf(viewport_size.x / 1440.0, viewport_size.y / 900.0)
    var ui_scale := clampf(fit, 0.72, 1.0)
    scale = Vector2(ui_scale, ui_scale)
    if mount_slot >= 0:
        _snap_to_mount(mount_slot)
    elif not default_position_set:
        mount_top_right()
    else:
        _clamp_to_viewport()

func force_refresh() -> void:
    if world == null or not is_instance_valid(world):
        return
    # UI-triggered refreshes update the cards immediately without fabricating a
    # new time-series point. History is recorded only by the fixed simulation
    # tick (or the one-second fallback when no simulation snapshot exists).
    current = _sample_metrics()
    queue_redraw()

func _accept_sample(sample: Dictionary) -> void:
    current = sample
    for key in METRIC_KEYS:
        var series: Array = histories.get(key, [])
        series.append(float(current.get(key, 0.0)))
        while series.size() > MAX_HISTORY:
            series.pop_front()
        histories[key] = series
    queue_redraw()

func snapshot() -> Dictionary:
    if current.is_empty():
        current = _sample_metrics()
    return current.duplicate(true)

func _process(delta: float) -> void:
    # SimulationManager already supplies one authoritative snapshot per tick.
    # Do not double-sample that same tick from the widget's own process loop.
    if not simulation_snapshot.is_empty():
        return
    sample_accum += delta
    if sample_accum >= SAMPLE_INTERVAL:
        sample_accum = fmod(sample_accum, SAMPLE_INTERVAL)
        _accept_sample(_sample_metrics())

func _normalized_snapshot(raw: Dictionary) -> Dictionary:
    return {
        "hashrate": float(raw.get("hashrate", 0.0)),
        "power": maxf(0.0, float(raw.get("power", 0.0))),
        "efficiency": maxf(0.0, float(raw.get("efficiency", 0.0))),
        "uptime": clampf(float(raw.get("uptime", 0.0)), 0.0, 100.0),
        "btc": maxf(0.0, float(raw.get("btc", 0.0))),
        "cash": float(raw.get("cash", 0.0)),
        "load_mw": maxf(0.0, float(raw.get("load_mw", 0.0))),
        "temperature_c": float(raw.get("temperature_c", 0.0)),
        "power_state": String(raw.get("power_state", "online"))
    }

func _sample_metrics() -> Dictionary:
    if not simulation_snapshot.is_empty():
        return _normalized_snapshot(simulation_snapshot)
    if world == null or not is_instance_valid(world):
        return _normalized_snapshot({})

    if world.has_method("debug_simulation_snapshot"):
        var sim: Variant = world.call("debug_simulation_snapshot")
        if sim is Dictionary and not (sim as Dictionary).is_empty():
            return _normalized_snapshot(sim as Dictionary)

    var player_variant: Variant = world.get("player")
    if not (player_variant is Dictionary):
        return _normalized_snapshot({})
    var player := player_variant as Dictionary

    # Compatibility fallback while older scenes are still able to instantiate
    # this widget without the v0.068 SimulationManager.
    var hashrate_th := float(world.call("_hashrate_th")) if world.has_method("_hashrate_th") else 0.0
    var load_kw := float(world.call("_machine_load_kw")) if world.has_method("_machine_load_kw") else 0.0
    var power_mw := float(world.call("_effective_available_mw")) if world.has_method("_effective_available_mw") else float(player.get("mw", 0.0))
    var uptime_ratio := float(world.call("_uptime")) if world.has_method("_uptime") else 0.0
    var efficiency_jth := (load_kw * 1000.0 / hashrate_th) if hashrate_th > 0.001 else 0.0
    return _normalized_snapshot({
        "hashrate": hashrate_th,
        "power": power_mw,
        "efficiency": efficiency_jth,
        "uptime": uptime_ratio * 100.0,
        "btc": float(player.get("sats", 0.0)) / 100000000.0,
        "cash": float(player.get("cash", 0.0)),
        "load_mw": load_kw / 1000.0,
        "power_state": "online"
    })

func _draw() -> void:
    var font := get_theme_default_font()
    _draw_shell(font)
    if collapsed:
        return
    _draw_cards(font)
    _draw_footer(font)

func _draw_shell(font: Font) -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.70), true)
    draw_rect(Rect2(2.0, 2.0, size.x - 4.0, size.y - 4.0), PANEL, true)
    draw_rect(Rect2(2.0, 2.0, size.x - 4.0, size.y - 4.0), BORDER, false, 2.0)

    var cut := 9.0
    draw_line(Vector2(2.0, cut), Vector2(cut, 2.0), GREEN, 1.5)
    draw_line(Vector2(size.x - cut, 2.0), Vector2(size.x - 2.0, cut), GREEN, 1.5)

    draw_rect(Rect2(2.0, 2.0, size.x - 4.0, HEADER_H - 2.0), Color("091822"), true)
    draw_line(Vector2(2.0, HEADER_H), Vector2(size.x - 2.0, HEADER_H), BORDER, 1.0)

    for gy in range(2):
        for gx in range(3):
            draw_rect(Rect2(12.0 + gx * 5.0, 13.0 + gy * 5.0, 2.0, 2.0), MUTED, true)

    draw_string(font, Vector2(34.0, 21.0), "MINING OPS", HORIZONTAL_ALIGNMENT_LEFT, 100.0, 10, WHITE)
    draw_string(font, Vector2(118.0, 21.0), "// LIVE", HORIZONTAL_ALIGNMENT_LEFT, 50.0, 8, GREEN)
    draw_string(font, Vector2(34.0, 36.0), _context_line(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 174.0, 7, Color("a9c8d7"))

    var bx := size.x - 108.0
    for i in range(3):
        var r := Rect2(bx + float(i) * 34.0, 8.0, 29.0, 29.0)
        draw_rect(r, BG, true)
        draw_rect(r, BORDER, false, 1.0)
    draw_line(Vector2(bx + 8.0, 23.0), Vector2(bx + 20.0, 23.0), MUTED, 1.5)
    draw_rect(Rect2(bx + 42.0, 17.0, 10.0, 10.0), CYAN, false, 1.0)
    draw_line(Vector2(bx + 75.0, 15.0), Vector2(bx + 91.0, 31.0), MUTED, 1.5)
    draw_line(Vector2(bx + 91.0, 15.0), Vector2(bx + 75.0, 31.0), MUTED, 1.5)
    _draw_resize_affordance()

func _draw_cards(font: Font) -> void:
    var card_w := maxf(96.0, (size.x - MARGIN_X * 2.0 - CARD_GAP * 2.0) / 3.0)
    var content_bottom := size.y - FOOTER_H - 7.0
    var available_h := maxf(MIN_CARD_H * 2.0 + ROW_GAP, content_bottom - CARD_TOP)
    var card_h := maxf(MIN_CARD_H, (available_h - ROW_GAP) / 2.0)

    for i in range(6):
        var col := i % 3
        var row := i / 3
        var x := MARGIN_X + float(col) * (card_w + CARD_GAP)
        var y := CARD_TOP + float(row) * (card_h + ROW_GAP)
        var rect := Rect2(x, y, card_w, card_h)
        draw_rect(rect, Color("030c10"), true)
        draw_rect(rect, BORDER, false, 1.0)
        draw_line(rect.position + Vector2(0.0, 6.0), rect.position + Vector2(6.0, 0.0), BORDER_HI, 1.0)

        var key := METRIC_KEYS[i]
        var value := float(current.get(key, 0.0))
        var accent := _metric_color(key, value)

        var icon_y := clampf(card_h * 0.20, 12.0, 15.0)
        _draw_metric_icon(key, rect.position + Vector2(16.0, icon_y), accent, font)
        draw_string(font, rect.position + Vector2(31.0, icon_y + 2.0), METRIC_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, card_w - 42.0, 8, Color("a9c8d7"))
        draw_circle(rect.position + Vector2(card_w - 10.0, 14.0), 2.0, accent)

        var value_y := clampf(card_h * 0.43, 27.0, 36.0)
        var value_font := clampi(int(round(12.0 * clampf(card_h / CARD_H, 0.90, 1.12))), 10, 13)
        draw_string(font, rect.position + Vector2(10.0, value_y), _format_metric(key, value), HORIZONTAL_ALIGNMENT_LEFT, card_w - 18.0, value_font, GREEN_HI)

        var progress_y := card_h - 14.0
        var graph_y := value_y + 6.0
        var graph_h := maxf(7.0, progress_y - graph_y - 4.0)
        var graph_rect := Rect2(rect.position + Vector2(10.0, graph_y), Vector2(card_w - 20.0, graph_h))
        _draw_sparkline(key, graph_rect, accent)

        var progress_rect := Rect2(rect.position + Vector2(10.0, progress_y), Vector2(card_w - 20.0, 4.0))
        _draw_progress(progress_rect, _progress_for(key, value), accent)
        draw_string(font, rect.position + Vector2(10.0, card_h - 5.0), _bottom_text(key), HORIZONTAL_ALIGNMENT_LEFT, card_w - 20.0, 7, _bottom_color(key))

func _draw_metric_icon(key: String, center: Vector2, accent: Color, font: Font) -> void:
    draw_circle(center, 10.0, Color(accent.r, accent.g, accent.b, 0.12))
    draw_circle(center, 9.0, Color(accent.r, accent.g, accent.b, 0.28), false, 1.0)
    match key:
        "hashrate":
            draw_rect(Rect2(center - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), accent, false, 1.0)
            draw_rect(Rect2(center - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), accent, true)
        "power":
            var pts := PackedVector2Array([center + Vector2(1.0, -7.0), center + Vector2(-5.0, 1.0), center, center + Vector2(-2.0, 7.0), center + Vector2(6.0, -2.0), center + Vector2(2.0, -2.0)])
            draw_colored_polygon(pts, accent)
        "efficiency":
            draw_circle(center, 5.0, accent, false, 1.0)
            draw_circle(center, 1.5, accent)
        "uptime":
            draw_circle(center, 6.0, accent, false, 1.0)
            draw_line(center, center + Vector2(0.0, -4.0), accent, 1.0)
            draw_line(center, center + Vector2(3.0, 1.0), accent, 1.0)
        "btc":
            draw_string(font, center + Vector2(-5.0, 5.0), "₿", HORIZONTAL_ALIGNMENT_CENTER, 10.0, 10, accent)
        "cash":
            draw_string(font, center + Vector2(-4.0, 5.0), "$", HORIZONTAL_ALIGNMENT_CENTER, 8.0, 10, accent)

func _draw_sparkline(key: String, rect: Rect2, accent: Color) -> void:
    draw_rect(rect, Color("031014"), true)
    draw_line(Vector2(rect.position.x, rect.end.y - 1.0), Vector2(rect.end.x, rect.end.y - 1.0), Color("12303a"), 1.0)
    var series: Array = histories.get(key, [])
    if series.size() < 2:
        var y0 := rect.position.y + rect.size.y * 0.55
        draw_line(Vector2(rect.position.x + 2.0, y0), Vector2(rect.end.x - 2.0, y0), accent, 1.0)
        return
    var min_v := INF
    var max_v := -INF
    for raw in series:
        min_v = minf(min_v, float(raw))
        max_v = maxf(max_v, float(raw))
    if absf(max_v - min_v) < 0.000001:
        min_v -= 1.0
        max_v += 1.0
    var points := PackedVector2Array()
    for i in range(series.size()):
        var t := float(i) / maxf(1.0, float(series.size() - 1))
        var normalized := inverse_lerp(min_v, max_v, float(series[i]))
        points.append(Vector2(rect.position.x + 2.0 + t * (rect.size.x - 4.0), rect.end.y - 3.0 - normalized * (rect.size.y - 6.0)))
    if points.size() >= 2:
        draw_polyline(points, accent, 1.2, true)

func _draw_progress(rect: Rect2, amount: float, accent: Color) -> void:
    draw_rect(rect, Color("10232c"), true)
    draw_rect(rect, Color("36505d"), false, 1.0)
    var clamped := clampf(amount, 0.0, 1.0)
    if clamped > 0.0:
        draw_rect(Rect2(rect.position + Vector2(1.0, 1.0), Vector2((rect.size.x - 2.0) * clamped, rect.size.y - 2.0)), accent, true)

func _draw_footer(font: Font) -> void:
    var y := size.y - FOOTER_H
    draw_rect(Rect2(2.0, y, size.x - 4.0, FOOTER_H - 2.0), Color("07151b"), true)
    draw_line(Vector2(2.0, y), Vector2(size.x - 2.0, y), BORDER, 1.0)
    var state := String(current.get("power_state", "online")).to_upper()
    var status_color := GREEN if state == "ONLINE" else (WARNING if state in ["IDLE", "THERMAL"] else BAD)
    draw_circle(Vector2(16.0, y + 14.0), 3.0, status_color)
    draw_string(font, Vector2(26.0, y + 18.0), "SIM %s" % state, HORIZONTAL_ALIGNMENT_LEFT, 92.0, 7, Color("9eb8c7"))
    draw_string(font, Vector2(size.x - 104.0, y + 18.0), "1.0s TICK", HORIZONTAL_ALIGNMENT_RIGHT, 90.0, 7, MUTED)

func _context_line() -> String:
    if world == null or not is_instance_valid(world):
        return "COMPANY • LIVE"
    var company := _company_name()
    var turn := int(world.get("turn")) if world.get("turn") != null else 1
    var scale_name := String(world.call("turn_length_name")) if world.has_method("turn_length_name") else "TURN"
    var elapsed := float(world.get("elapsed_campaign_days")) if world.get("elapsed_campaign_days") != null else 0.0
    var year := int(elapsed / 365.25) + 1
    var day := int(fmod(elapsed, 365.25)) + 1
    var quarter := clampi(int((day - 1) / (365.25 / 4.0)) + 1, 1, 4)
    return "%s  •  Y%d Q%d DAY %d  •  TURN %d  •  %s" % [company, year, quarter, day, turn, scale_name]

func _format_metric(key: String, value: float) -> String:
    match key:
        "hashrate":
            if value >= 1000000.0:
                return "%.2f EH/s" % (value / 1000000.0)
            if value >= 1000.0:
                return "%.2f PH/s" % (value / 1000.0)
            return "%.0f TH/s" % value
        "power":
            return "%.2f MW" % value
        "efficiency":
            return "%.1f J/TH" % value
        "uptime":
            return "%.1f%%" % value
        "btc":
            if value >= 1.0:
                return "%.3f BTC" % value
            return "%.5f BTC" % value
        "cash":
            return "$%s" % _format_int_commas(int(round(value)))
    return "%.2f" % value

func _bottom_text(key: String) -> String:
    if key == "power":
        var power := maxf(0.0001, float(current.get("power", 0.0)))
        var load := maxf(0.0, float(current.get("load_mw", 0.0)))
        return "%d%% LOAD" % int(round(clampf(load / power, 0.0, 1.5) * 100.0))
    if key == "uptime":
        return "RELIABILITY"
    var series: Array = histories.get(key, [])
    if series.size() < 2:
        return "LIVE"
    var old_v := float(series[0])
    var new_v := float(series[series.size() - 1])
    if key == "btc":
        return "%+.5f BTC" % (new_v - old_v)
    if absf(old_v) < 0.000001:
        return "LIVE"
    var pct := (new_v - old_v) / absf(old_v) * 100.0
    if key == "efficiency":
        pct *= -1.0
    return "%+.1f%%" % pct

func _trend_direction(key: String) -> int:
    var series: Array = histories.get(key, [])
    if series.size() < 2:
        return 0
    var old_v := float(series[0])
    var new_v := float(series[series.size() - 1])
    var delta := new_v - old_v
    var deadband := maxf(0.000001, absf(old_v) * 0.0005)
    if absf(delta) <= deadband:
        return 0
    # Lower J/TH is an improvement, unlike the other tracked metrics.
    if key == "efficiency":
        delta *= -1.0
    return 1 if delta > 0.0 else -1

func _bottom_color(key: String) -> Color:
    if key == "uptime":
        var uptime := float(current.get("uptime", 0.0))
        if uptime < 85.0:
            return BAD
        if uptime < 94.0:
            return WARNING
        return GREEN
    if key == "power":
        var load := float(current.get("load_mw", 0.0))
        var power := float(current.get("power", 0.0))
        if load > power:
            return BAD
        if load > power * 0.90:
            return WARNING
        return GREEN
    var trend := _trend_direction(key)
    if trend > 0:
        return GREEN
    if trend < 0:
        return WARNING
    return MUTED

func _progress_for(key: String, value: float) -> float:
    match key:
        "hashrate":
            return clampf(log(1.0 + value) / log(1.0 + 10000000.0), 0.04, 1.0)
        "power":
            return clampf(float(current.get("load_mw", 0.0)) / maxf(0.001, value), 0.0, 1.0)
        "efficiency":
            return clampf((60.0 - value) / 55.0, 0.06, 1.0)
        "uptime":
            return clampf(value / 100.0, 0.0, 1.0)
        "btc":
            return clampf(log(1.0 + value) / log(1001.0), 0.03, 1.0)
        "cash":
            return clampf(log(1.0 + maxf(0.0, value)) / log(1.0 + 5000000.0), 0.03, 1.0)
    return 0.0

func _metric_color(key: String, value: float) -> Color:
    if key == "uptime":
        if value < 85.0:
            return BAD
        if value < 94.0:
            return WARNING
    if key == "power":
        var load := float(current.get("load_mw", 0.0))
        if load > value:
            return BAD
        if load > value * 0.90:
            return WARNING
    if key == "efficiency" and value > 50.0:
        return WARNING
    return GREEN

func _format_int_commas(value: int) -> String:
    var negative := value < 0
    var raw := str(absi(value))
    var result := ""
    var count := 0
    for i in range(raw.length() - 1, -1, -1):
        if count > 0 and count % 3 == 0:
            result = "," + result
        result = raw.substr(i, 1) + result
        count += 1
    return ("-" if negative else "") + result

func _company_name() -> String:
    if world == null:
        return "MINING CO."
    var player_variant: Variant = world.get("player")
    if player_variant is Dictionary:
        return String((player_variant as Dictionary).get("name", "MINING CO.")).to_upper()
    return "MINING CO."

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var button := event as InputEventMouseButton
        if button.button_index != MOUSE_BUTTON_LEFT:
            return
        if button.pressed:
            var edge_mask := _resize_mask_at(button.position)
            if edge_mask != RESIZE_NONE:
                _begin_resize(edge_mask)
                accept_event()
                return

            var bx := size.x - 108.0
            if button.position.y <= HEADER_H and button.position.x >= bx:
                if button.position.x < bx + 34.0:
                    _toggle_collapsed()
                elif button.position.x < bx + 68.0:
                    _cycle_mount()
                else:
                    hide()
                    close_requested.emit()
                accept_event()
                return
            if button.position.y <= HEADER_H:
                dragging = true
                drag_offset = get_global_mouse_position() - global_position
                mount_slot = -1
                mouse_default_cursor_shape = Control.CURSOR_DRAG
                accept_event()
        elif resizing:
            _finish_resize()
            accept_event()
        elif dragging:
            dragging = false
            mouse_default_cursor_shape = Control.CURSOR_ARROW
            _clamp_to_viewport()
            accept_event()

    elif event is InputEventMouseMotion:
        var motion := event as InputEventMouseMotion
        if resizing:
            _resize_from_global_pointer(get_global_mouse_position())
            accept_event()
        elif dragging:
            global_position = get_global_mouse_position() - drag_offset
            _clamp_to_viewport()
            accept_event()
        else:
            _update_hover_cursor(motion.position)

func _resize_mask_at(local_pos: Vector2) -> int:
    var mask := RESIZE_NONE
    if local_pos.x <= EDGE_GRAB:
        mask |= RESIZE_LEFT
    elif local_pos.x >= size.x - EDGE_GRAB:
        mask |= RESIZE_RIGHT

    if not collapsed:
        if local_pos.y <= EDGE_GRAB:
            mask |= RESIZE_TOP
        elif local_pos.y >= size.y - EDGE_GRAB:
            mask |= RESIZE_BOTTOM
    return mask

func _update_hover_cursor(local_pos: Vector2) -> void:
    var next_mask := _resize_mask_at(local_pos)
    if hover_resize_mask != next_mask:
        hover_resize_mask = next_mask
        queue_redraw()

    if next_mask == (RESIZE_LEFT | RESIZE_TOP) or next_mask == (RESIZE_RIGHT | RESIZE_BOTTOM):
        mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
    elif next_mask == (RESIZE_RIGHT | RESIZE_TOP) or next_mask == (RESIZE_LEFT | RESIZE_BOTTOM):
        mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
    elif (next_mask & (RESIZE_LEFT | RESIZE_RIGHT)) != 0:
        mouse_default_cursor_shape = Control.CURSOR_HSIZE
    elif (next_mask & (RESIZE_TOP | RESIZE_BOTTOM)) != 0:
        mouse_default_cursor_shape = Control.CURSOR_VSIZE
    elif local_pos.y <= HEADER_H:
        mouse_default_cursor_shape = Control.CURSOR_MOVE
    else:
        mouse_default_cursor_shape = Control.CURSOR_ARROW

func _begin_resize(mask: int) -> void:
    resizing = true
    dragging = false
    resize_mask = mask
    resize_start_mouse = get_global_mouse_position()
    resize_start_position = global_position
    resize_start_size = size
    mount_slot = -1
    _update_hover_cursor(Vector2(
        0.0 if (mask & RESIZE_LEFT) != 0 else size.x,
        0.0 if (mask & RESIZE_TOP) != 0 else size.y
    ))

func _resize_from_global_pointer(pointer: Vector2) -> void:
    var sx := maxf(absf(scale.x), 0.001)
    var sy := maxf(absf(scale.y), 0.001)
    var global_delta := pointer - resize_start_mouse
    var local_delta := Vector2(global_delta.x / sx, global_delta.y / sy)

    var min_h := HEADER_H if collapsed else MIN_SIZE.y
    var min_size := Vector2(MIN_SIZE.x, min_h)
    var viewport_size := get_viewport_rect().size
    var new_size := resize_start_size
    var new_pos := resize_start_position

    if (resize_mask & RESIZE_RIGHT) != 0:
        var max_w_right := maxf(min_size.x, (viewport_size.x - resize_start_position.x) / sx)
        new_size.x = clampf(resize_start_size.x + local_delta.x, min_size.x, max_w_right)
    elif (resize_mask & RESIZE_LEFT) != 0:
        var right_edge := resize_start_position.x + resize_start_size.x * sx
        var max_w_left := maxf(min_size.x, right_edge / sx)
        new_size.x = clampf(resize_start_size.x - local_delta.x, min_size.x, max_w_left)
        new_pos.x = right_edge - new_size.x * sx

    if not collapsed:
        if (resize_mask & RESIZE_BOTTOM) != 0:
            var max_h_bottom := maxf(min_size.y, (viewport_size.y - resize_start_position.y) / sy)
            new_size.y = clampf(resize_start_size.y + local_delta.y, min_size.y, max_h_bottom)
        elif (resize_mask & RESIZE_TOP) != 0:
            var bottom_edge := resize_start_position.y + resize_start_size.y * sy
            var max_h_top := maxf(min_size.y, bottom_edge / sy)
            new_size.y = clampf(resize_start_size.y - local_delta.y, min_size.y, max_h_top)
            new_pos.y = bottom_edge - new_size.y * sy

    size = new_size
    global_position = new_pos
    if collapsed:
        expanded_size.x = new_size.x
    else:
        expanded_size = new_size
    _clamp_to_viewport()
    queue_redraw()

func _finish_resize() -> void:
    resizing = false
    resize_mask = RESIZE_NONE
    hover_resize_mask = RESIZE_NONE
    mouse_default_cursor_shape = Control.CURSOR_ARROW
    _clamp_to_viewport()
    queue_redraw()

func _draw_resize_affordance() -> void:
    if not collapsed:
        for i in range(3):
            var offset := float(i) * 4.0
            draw_line(
                Vector2(size.x - 5.0 - offset, size.y - 2.0),
                Vector2(size.x - 2.0, size.y - 5.0 - offset),
                BORDER_HI,
                1.0
            )

    var active := resize_mask if resizing else hover_resize_mask
    if active == RESIZE_NONE:
        return
    var hi := Color(GREEN_HI.r, GREEN_HI.g, GREEN_HI.b, 0.78)
    if (active & RESIZE_LEFT) != 0:
        draw_line(Vector2(2.0, 8.0), Vector2(2.0, size.y - 8.0), hi, 2.0)
    if (active & RESIZE_RIGHT) != 0:
        draw_line(Vector2(size.x - 2.0, 8.0), Vector2(size.x - 2.0, size.y - 8.0), hi, 2.0)
    if (active & RESIZE_TOP) != 0:
        draw_line(Vector2(8.0, 2.0), Vector2(size.x - 8.0, 2.0), hi, 2.0)
    if (active & RESIZE_BOTTOM) != 0:
        draw_line(Vector2(8.0, size.y - 2.0), Vector2(size.x - 8.0, size.y - 2.0), hi, 2.0)

func debug_resizable_ready() -> bool:
    return (
        MIN_SIZE.x < BASE_SIZE.x
        and MIN_SIZE.y < BASE_SIZE.y
        and EDGE_GRAB >= 6.0
        and not collapsed
    )

func debug_resize_edge_mask(local_pos: Vector2) -> int:
    return _resize_mask_at(local_pos)

func debug_set_widget_size(target_size: Vector2) -> void:
    collapsed = false
    custom_minimum_size = MIN_SIZE
    var sx := maxf(absf(scale.x), 0.001)
    var sy := maxf(absf(scale.y), 0.001)
    var viewport_size := get_viewport_rect().size
    var max_size := Vector2(viewport_size.x / sx, viewport_size.y / sy)
    size = Vector2(
        clampf(target_size.x, MIN_SIZE.x, max_size.x),
        clampf(target_size.y, MIN_SIZE.y, max_size.y)
    )
    expanded_size = size
    if mount_slot >= 0:
        _snap_to_mount(mount_slot)
    else:
        _clamp_to_viewport()
    queue_redraw()

func _toggle_collapsed() -> void:
    collapsed = not collapsed
    if collapsed:
        expanded_size = Vector2(maxf(size.x, MIN_SIZE.x), maxf(size.y, MIN_SIZE.y))
        custom_minimum_size = Vector2(MIN_SIZE.x, HEADER_H)
        size = Vector2(expanded_size.x, HEADER_H)
    else:
        custom_minimum_size = MIN_SIZE
        size = Vector2(maxf(expanded_size.x, MIN_SIZE.x), maxf(expanded_size.y, MIN_SIZE.y))
    if mount_slot >= 0:
        _snap_to_mount(mount_slot)
    else:
        _clamp_to_viewport()
    queue_redraw()

func _cycle_mount() -> void:
    mount_slot = 0 if mount_slot < 0 else (mount_slot + 1) % 4
    _snap_to_mount(mount_slot)
    mount_changed.emit(mount_slot)

func _snap_to_mount(slot: int) -> void:
    var viewport_size := get_viewport_rect().size
    var scaled_size := size * scale
    var margin := 10.0
    match slot:
        0:
            position = Vector2(margin, margin)
        1:
            position = Vector2(viewport_size.x - scaled_size.x - margin, margin)
        2:
            position = Vector2(viewport_size.x - scaled_size.x - margin, viewport_size.y - scaled_size.y - margin)
        3:
            position = Vector2(margin, viewport_size.y - scaled_size.y - margin)
    _clamp_to_viewport()

func _clamp_to_viewport() -> void:
    var viewport_size := get_viewport_rect().size
    var scaled_size := size * scale
    position.x = clampf(position.x, 0.0, maxf(0.0, viewport_size.x - scaled_size.x))
    position.y = clampf(position.y, 0.0, maxf(0.0, viewport_size.y - scaled_size.y))
