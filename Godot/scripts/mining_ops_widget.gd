extends Control

# Hash Race v0.068 compact Mining Ops HUD.
# One consolidated upper-right widget replaces the duplicate full-width stat bar.
# Six live metrics remain: hashrate, power, efficiency, uptime, BTC and USD cash.

signal close_requested
signal mount_changed(slot: int)

const BASE_SIZE := Vector2(528.0, 326.0)
const HEADER_H: float = 54.0
const FOOTER_H: float = 30.0
const CARD_TOP: float = 62.0
const CARD_H: float = 106.0
const MARGIN_X: float = 12.0
const CARD_GAP: float = 7.0
const ROW_GAP: float = 7.0
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
var collapsed := false
var mount_slot: int = 1
var default_position_set := false

func setup(world_node: Node) -> void:
    world = world_node
    name = "MiningOpsWidget"
    size = BASE_SIZE
    custom_minimum_size = BASE_SIZE
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    focus_mode = Control.FOCUS_NONE
    tooltip_text = "Live Mining Ops. Starts mounted upper-right; drag the title bar to move it."
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
    _accept_sample(_sample_metrics())

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
    sample_accum += delta
    if sample_accum >= SAMPLE_INTERVAL:
        sample_accum = 0.0
        force_refresh()

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
    draw_string(font, Vector2(34.0, 41.0), _context_line(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 174.0, 8, Color("a9c8d7"))

    var bx := size.x - 108.0
    for i in range(3):
        var r := Rect2(bx + float(i) * 34.0, 8.0, 29.0, 29.0)
        draw_rect(r, BG, true)
        draw_rect(r, BORDER, false, 1.0)
    draw_line(Vector2(bx + 8.0, 23.0), Vector2(bx + 20.0, 23.0), MUTED, 1.5)
    draw_rect(Rect2(bx + 42.0, 17.0, 10.0, 10.0), CYAN, false, 1.0)
    draw_line(Vector2(bx + 75.0, 15.0), Vector2(bx + 91.0, 31.0), MUTED, 1.5)
    draw_line(Vector2(bx + 91.0, 15.0), Vector2(bx + 75.0, 31.0), MUTED, 1.5)

func _draw_cards(font: Font) -> void:
    var card_w := (BASE_SIZE.x - MARGIN_X * 2.0 - CARD_GAP * 2.0) / 3.0
    for i in range(6):
        var col := i % 3
        var row := i / 3
        var x := MARGIN_X + float(col) * (card_w + CARD_GAP)
        var y := CARD_TOP + float(row) * (CARD_H + ROW_GAP)
        var rect := Rect2(x, y, card_w, CARD_H)
        draw_rect(rect, Color("030c10"), true)
        draw_rect(rect, BORDER, false, 1.0)
        draw_line(rect.position + Vector2(0.0, 6.0), rect.position + Vector2(6.0, 0.0), BORDER_HI, 1.0)

        var key := METRIC_KEYS[i]
        var value := float(current.get(key, 0.0))
        var accent := _metric_color(key, value)

        _draw_metric_icon(key, rect.position + Vector2(16.0, 17.0), accent, font)
        draw_string(font, rect.position + Vector2(31.0, 19.0), METRIC_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, card_w - 42.0, 8, Color("a9c8d7"))
        draw_circle(rect.position + Vector2(card_w - 10.0, 14.0), 2.0, accent)

        draw_string(font, rect.position + Vector2(10.0, 45.0), _format_metric(key, value), HORIZONTAL_ALIGNMENT_LEFT, card_w - 18.0, 13, GREEN_HI)

        var graph_rect := Rect2(rect.position + Vector2(10.0, 51.0), Vector2(card_w - 20.0, 28.0))
        _draw_sparkline(key, graph_rect, accent)
        var progress_rect := Rect2(rect.position + Vector2(10.0, 85.0), Vector2(card_w - 20.0, 6.0))
        _draw_progress(progress_rect, _progress_for(key, value), accent)
        draw_string(font, rect.position + Vector2(10.0, 101.0), _bottom_text(key), HORIZONTAL_ALIGNMENT_LEFT, card_w - 20.0, 7, _bottom_color(key))

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

func _bottom_color(key: String) -> Color:
    if key == "uptime":
        return MUTED
    if key == "power":
        return WARNING if float(current.get("load_mw", 0.0)) > float(current.get("power", 0.0)) else GREEN
    return GREEN

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
        elif dragging:
            dragging = false
            mouse_default_cursor_shape = Control.CURSOR_MOVE
            _clamp_to_viewport()
            accept_event()
    elif event is InputEventMouseMotion and dragging:
        global_position = get_global_mouse_position() - drag_offset
        _clamp_to_viewport()
        accept_event()

func _toggle_collapsed() -> void:
    collapsed = not collapsed
    size = Vector2(BASE_SIZE.x, HEADER_H if collapsed else BASE_SIZE.y)
    custom_minimum_size = size
    if mount_slot >= 0:
        _snap_to_mount(mount_slot)
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
