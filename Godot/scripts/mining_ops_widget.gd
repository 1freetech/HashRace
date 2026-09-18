extends Control

# Hash Race v0.067
# High-fidelity draggable/minimizable mining-operations HUD based on the approved
# six-card visual reference. All displayed values are sampled from the live world.
signal close_requested
signal mount_changed(slot: int)

const BASE_SIZE := Vector2(1200.0, 336.0)
const HEADER_H: float = 52.0
const FOOTER_H: float = 42.0
const CARD_TOP: float = 62.0
const CARD_BOTTOM: float = 286.0
const MARGIN_X: float = 22.0
const CARD_GAP: float = 8.0
const SAMPLE_INTERVAL: float = 0.35
const MAX_HISTORY: int = 28

const BG := Color("02090d")
const PANEL := Color("061117")
const PANEL_2 := Color("07151b")
const BORDER := Color("173542")
const BORDER_HI := Color("1e6b71")
const GREEN := Color("37f6a0")
const GREEN_HI := Color("5dffc1")
const CYAN := Color("61bff2")
const MUTED := Color("7896a8")
const MUTED_2 := Color("3a5968")
const WHITE := Color("d8edf2")
const WARNING := Color("ffc45e")
const BAD := Color("ff6b6b")

const METRIC_KEYS: Array[String] = ["hashrate", "power", "efficiency", "uptime", "btc", "cash"]
const METRIC_LABELS: Array[String] = ["HASHRATE", "POWER", "EFFICIENCY", "UPTIME", "BTC TREASURY", "USD CASH"]

var world: Node
var current: Dictionary = {}
var histories: Dictionary = {}
var sample_accum: float = 0.0
var pulse_phase: float = 0.0

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var collapsed: bool = false
var mount_slot: int = -1
var default_position_set: bool = false

func setup(world_node: Node) -> void:
    world = world_node
    name = "MiningOpsWidget"
    size = BASE_SIZE
    custom_minimum_size = BASE_SIZE
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    focus_mode = Control.FOCUS_NONE
    tooltip_text = "Live company metrics. Drag the title bar. Square button cycles mounted corners."
    for key in METRIC_KEYS:
        histories[key] = []
    set_process(true)
    force_refresh()

func set_screen_scale(viewport_size: Vector2) -> void:
    var fit: float = minf(viewport_size.x / 1440.0, viewport_size.y / 900.0)
    var ui_scale: float = clampf(fit * 0.92, 0.60, 1.08)
    scale = Vector2(ui_scale, ui_scale)
    if mount_slot >= 0:
        _snap_to_mount(mount_slot)
    elif not default_position_set:
        position = Vector2(maxf(8.0, (viewport_size.x - BASE_SIZE.x * ui_scale) * 0.5), 96.0 * fit)
        default_position_set = true
    else:
        _clamp_to_viewport()

func force_refresh() -> void:
    if world == null or not is_instance_valid(world):
        return
    current = _sample_metrics()
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
    pulse_phase = fmod(pulse_phase + delta, TAU * 100.0)
    sample_accum += delta
    if sample_accum >= SAMPLE_INTERVAL:
        sample_accum = 0.0
        force_refresh()

func _sample_metrics() -> Dictionary:
    if world == null or not is_instance_valid(world):
        return {"hashrate":0.0, "power":0.0, "efficiency":0.0, "uptime":0.0, "btc":0.0, "cash":0.0, "load_mw":0.0}
    var player_variant: Variant = world.get("player")
    if not (player_variant is Dictionary):
        return {"hashrate":0.0, "power":0.0, "efficiency":0.0, "uptime":0.0, "btc":0.0, "cash":0.0, "load_mw":0.0}
    var player: Dictionary = player_variant

    var hashrate_th: float = float(world.call("_hashrate_th")) if world.has_method("_hashrate_th") else 0.0
    var load_kw: float = float(world.call("_machine_load_kw")) if world.has_method("_machine_load_kw") else 0.0
    var power_mw: float = float(world.call("_effective_available_mw")) if world.has_method("_effective_available_mw") else float(player.get("mw", 0.0))
    var uptime_ratio: float = float(world.call("_uptime")) if world.has_method("_uptime") else 0.0
    var efficiency_jth: float = (load_kw * 1000.0 / hashrate_th) if hashrate_th > 0.001 else 0.0
    var btc: float = float(player.get("sats", 0.0)) / 100000000.0
    var cash: float = float(player.get("cash", 0.0))
    return {
        "hashrate": hashrate_th,
        "power": maxf(0.0, power_mw),
        "efficiency": maxf(0.0, efficiency_jth),
        "uptime": clampf(uptime_ratio * 100.0, 0.0, 100.0),
        "btc": maxf(0.0, btc),
        "cash": cash,
        "load_mw": maxf(0.0, load_kw / 1000.0)
    }

func _draw() -> void:
    var font: Font = get_theme_default_font()
    _draw_shell(font)
    if collapsed:
        return
    _draw_cards(font)
    _draw_footer(font)

func _draw_shell(font: Font) -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.62), true)
    draw_rect(Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0)), PANEL, true)
    draw_rect(Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0)), BORDER, false, 2.0)

    # Neon corner cuts from the approved reference.
    var c: float = 12.0
    draw_line(Vector2(2.0, c), Vector2(c, 2.0), GREEN, 2.0)
    draw_line(Vector2(2.0, c), Vector2(2.0, c + 13.0), GREEN, 2.0)
    draw_line(Vector2(size.x - c, 2.0), Vector2(size.x - 2.0, c), GREEN, 2.0)
    draw_line(Vector2(size.x - 2.0, c), Vector2(size.x - 2.0, c + 13.0), GREEN, 2.0)
    if not collapsed:
        draw_line(Vector2(2.0, size.y - c), Vector2(c, size.y - 2.0), GREEN, 2.0)
        draw_line(Vector2(size.x - c, size.y - 2.0), Vector2(size.x - 2.0, size.y - c), GREEN, 2.0)

    draw_rect(Rect2(2.0, 2.0, size.x - 4.0, HEADER_H - 2.0), Color("091822"), true)
    draw_line(Vector2(2.0, HEADER_H), Vector2(size.x - 2.0, HEADER_H), BORDER, 1.0)

    # Drag-grip dots.
    for gy in range(3):
        for gx in range(3):
            draw_rect(Rect2(18.0 + gx * 7.0, 19.0 + gy * 7.0, 3.0, 3.0), MUTED, true)
    draw_line(Vector2(52.0, 4.0), Vector2(52.0, HEADER_H - 2.0), BORDER, 1.0)

    draw_string(font, Vector2(68.0, 32.0), "MINING OPS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, WHITE)
    draw_string(font, Vector2(190.0, 32.0), "// LIVE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, GREEN)
    draw_string(font, Vector2(size.x - 400.0, 31.0), "DRAG TO MOVE", HORIZONTAL_ALIGNMENT_LEFT, 180.0, 9, MUTED)

    var bx: float = size.x - 132.0
    for i in range(3):
        var r := Rect2(bx + float(i) * 42.0, 7.0, 36.0, 36.0)
        draw_rect(r, BG, true)
        draw_rect(r, BORDER, false, 1.0)
    draw_line(Vector2(bx + 11.0, 25.0), Vector2(bx + 25.0, 25.0), MUTED, 2.0)
    draw_rect(Rect2(bx + 51.0, 17.0, 13.0, 13.0), CYAN, false, 1.5)
    draw_line(Vector2(bx + 94.0, 16.0), Vector2(bx + 112.0, 34.0), MUTED, 2.0)
    draw_line(Vector2(bx + 112.0, 16.0), Vector2(bx + 94.0, 34.0), MUTED, 2.0)

func _draw_cards(font: Font) -> void:
    var card_w: float = (BASE_SIZE.x - MARGIN_X * 2.0 - CARD_GAP * 5.0) / 6.0
    for i in range(6):
        var x: float = MARGIN_X + float(i) * (card_w + CARD_GAP)
        var rect := Rect2(x, CARD_TOP, card_w, CARD_BOTTOM - CARD_TOP)
        draw_rect(rect, Color("030c10"), true)
        draw_rect(rect, BORDER, false, 1.0)
        # tiny top corner notch
        draw_line(rect.position + Vector2(0.0, 8.0), rect.position + Vector2(8.0, 0.0), BORDER_HI, 1.0)
        draw_line(Vector2(rect.end.x - 8.0, rect.position.y), Vector2(rect.end.x, rect.position.y + 8.0), BORDER_HI, 1.0)

        var key: String = METRIC_KEYS[i]
        var value: float = float(current.get(key, 0.0))
        var accent: Color = _metric_color(key, value)
        _draw_metric_icon(key, rect.position + Vector2(25.0, 29.0), accent, font)
        draw_string(font, rect.position + Vector2(48.0, 31.0), METRIC_LABELS[i], HORIZONTAL_ALIGNMENT_LEFT, card_w - 60.0, 9, Color("a9c8d7"))
        draw_circle(rect.position + Vector2(card_w - 16.0, 25.0), 3.2, accent)

        draw_string(font, rect.position + Vector2(16.0, 78.0), _format_metric(key, value), HORIZONTAL_ALIGNMENT_LEFT, card_w - 25.0, 18, GREEN_HI)

        var graph_rect := Rect2(rect.position + Vector2(15.0, 96.0), Vector2(card_w - 30.0, 63.0))
        _draw_sparkline(key, graph_rect, accent)

        var progress_rect := Rect2(rect.position + Vector2(15.0, 172.0), Vector2(card_w - 30.0, 9.0))
        _draw_progress(progress_rect, _progress_for(key, value), accent)

        draw_string(font, rect.position + Vector2(15.0, 207.0), _bottom_text(key), HORIZONTAL_ALIGNMENT_LEFT, card_w - 30.0, 9, _bottom_color(key))

func _draw_metric_icon(key: String, center: Vector2, accent: Color, font: Font) -> void:
    draw_circle(center, 17.0, Color(accent, 0.10))
    draw_circle(center, 16.0, Color(accent, 0.20), false, 1.0)
    match key:
        "hashrate":
            draw_rect(Rect2(center - Vector2(7.0, 7.0), Vector2(14.0, 14.0)), accent, false, 2.0)
            draw_rect(Rect2(center - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), accent, false, 1.0)
            for d in [-9.0, 9.0]:
                draw_line(center + Vector2(d, -4.0), center + Vector2(d, 4.0), accent, 1.0)
                draw_line(center + Vector2(-4.0, d), center + Vector2(4.0, d), accent, 1.0)
        "power":
            var pts := PackedVector2Array([
                center + Vector2(2.0, -13.0), center + Vector2(-8.0, 2.0),
                center + Vector2(-1.0, 2.0), center + Vector2(-5.0, 13.0),
                center + Vector2(10.0, -4.0), center + Vector2(3.0, -4.0)
            ])
            draw_colored_polygon(pts, accent)
        "efficiency":
            draw_circle(center, 8.0, accent, false, 2.0)
            draw_circle(center, 2.5, accent)
            for a in range(0, 8):
                var ang: float = float(a) * TAU / 8.0
                draw_line(center + Vector2(cos(ang), sin(ang)) * 9.0, center + Vector2(cos(ang), sin(ang)) * 13.0, accent, 2.0)
        "uptime":
            draw_circle(center, 11.0, accent, false, 2.0)
            draw_line(center, center + Vector2(0.0, -7.0), accent, 2.0)
            draw_line(center, center + Vector2(6.0, 2.0), accent, 2.0)
        "btc":
            draw_string(font, center + Vector2(-8.0, 7.0), "₿", HORIZONTAL_ALIGNMENT_CENTER, 16.0, 18, accent)
        "cash":
            draw_string(font, center + Vector2(-7.0, 7.0), "$", HORIZONTAL_ALIGNMENT_CENTER, 14.0, 17, accent)

func _draw_sparkline(key: String, rect: Rect2, accent: Color) -> void:
    draw_rect(rect, Color("031014"), true)
    for gx in range(1, 5):
        var x: float = rect.position.x + rect.size.x * float(gx) / 5.0
        draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(0.08, 0.20, 0.24, 0.22), 1.0)
    for gy in range(1, 3):
        var y: float = rect.position.y + rect.size.y * float(gy) / 3.0
        draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color(0.08, 0.20, 0.24, 0.22), 1.0)

    var series: Array = histories.get(key, [])
    if series.size() < 2:
        var y0: float = rect.position.y + rect.size.y * 0.55
        draw_line(Vector2(rect.position.x + 2.0, y0), Vector2(rect.end.x - 2.0, y0), accent, 1.5)
        return

    var min_v: float = INF
    var max_v: float = -INF
    for raw in series:
        var v: float = float(raw)
        min_v = minf(min_v, v)
        max_v = maxf(max_v, v)
    if absf(max_v - min_v) < 0.000001:
        min_v -= 1.0
        max_v += 1.0
    var points := PackedVector2Array()
    for i in range(series.size()):
        var t: float = float(i) / maxf(1.0, float(series.size() - 1))
        var normalized: float = inverse_lerp(min_v, max_v, float(series[i]))
        points.append(Vector2(rect.position.x + 2.0 + t * (rect.size.x - 4.0), rect.end.y - 4.0 - normalized * (rect.size.y - 8.0)))
    if points.size() >= 2:
        draw_polyline(points, accent, 1.6, true)

func _draw_progress(rect: Rect2, amount: float, accent: Color) -> void:
    draw_rect(rect, Color("10232c"), true)
    draw_rect(rect, Color("36505d"), false, 1.0)
    var clamped: float = clampf(amount, 0.0, 1.0)
    if clamped > 0.0:
        draw_rect(Rect2(rect.position + Vector2(1.0, 1.0), Vector2((rect.size.x - 2.0) * clamped, rect.size.y - 2.0)), accent, true)
    var segment_w: float = rect.size.x / 10.0
    for i in range(1, 10):
        var x: float = rect.position.x + segment_w * float(i)
        draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color(0.0, 0.0, 0.0, 0.25), 1.0)

func _draw_footer(font: Font) -> void:
    var y: float = size.y - FOOTER_H
    draw_rect(Rect2(2.0, y, size.x - 4.0, FOOTER_H - 2.0), Color("07151b"), true)
    draw_line(Vector2(2.0, y), Vector2(size.x - 2.0, y), BORDER, 1.0)
    draw_circle(Vector2(27.0, y + 21.0), 4.0, GREEN)
    draw_string(font, Vector2(41.0, y + 25.0), "NETWORK: ONLINE", HORIZONTAL_ALIGNMENT_LEFT, 160.0, 9, Color("9eb8c7"))
    draw_string(font, Vector2(200.0, y + 25.0), "MINERS: %s" % _miner_count_text(), HORIZONTAL_ALIGNMENT_LEFT, 130.0, 9, MUTED)
    draw_string(font, Vector2(350.0, y + 25.0), "COMPANY: %s" % _company_name(), HORIZONTAL_ALIGNMENT_LEFT, 360.0, 9, MUTED)
    draw_string(font, Vector2(size.x - 330.0, y + 25.0), "LIVE COMPANY DATA", HORIZONTAL_ALIGNMENT_LEFT, 180.0, 9, MUTED)
    for i in range(4):
        draw_rect(Rect2(size.x - 90.0 + float(i) * 12.0, y + 27.0 - float(i) * 4.0, 6.0, 5.0 + float(i) * 4.0), Color("9bd4ed"), true)

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
            if value >= 1000.0:
                return "%s BTC" % _format_int_commas(int(round(value)))
            if value >= 1.0:
                return "%.3f BTC" % value
            return "%.5f BTC" % value
        "cash":
            return "$%s" % _format_int_commas(int(round(value)))
    return "%.2f" % value

func _bottom_text(key: String) -> String:
    if key == "power":
        var power: float = maxf(0.0001, float(current.get("power", 0.0)))
        var load: float = maxf(0.0, float(current.get("load_mw", 0.0)))
        return "%d%% CAPACITY" % int(round(clampf(load / power, 0.0, 1.5) * 100.0))
    if key == "uptime":
        return "LIVE RELIABILITY"
    var series: Array = histories.get(key, [])
    if series.size() < 2:
        return "LIVE"
    var old_v: float = float(series[0])
    var new_v: float = float(series[series.size() - 1])
    if key == "btc":
        return "%+.5f BTC" % (new_v - old_v)
    if absf(old_v) < 0.000001:
        return "LIVE"
    var pct: float = (new_v - old_v) / absf(old_v) * 100.0
    if key == "efficiency":
        pct *= -1.0
    return "%+.1f%% LIVE" % pct

func _bottom_color(key: String) -> Color:
    if key == "uptime":
        return MUTED
    if key == "power":
        var power: float = maxf(0.0001, float(current.get("power", 0.0)))
        var load: float = maxf(0.0, float(current.get("load_mw", 0.0)))
        return WARNING if load > power else GREEN
    return GREEN

func _progress_for(key: String, value: float) -> float:
    match key:
        "hashrate":
            return clampf(log(1.0 + value) / log(1.0 + 10000000.0), 0.04, 1.0)
        "power":
            var load: float = float(current.get("load_mw", 0.0))
            return clampf(load / maxf(0.001, value), 0.0, 1.0)
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
        var load: float = float(current.get("load_mw", 0.0))
        if load > value:
            return BAD
        if load > value * 0.90:
            return WARNING
    if key == "efficiency" and value > 50.0:
        return WARNING
    return GREEN

func _format_int_commas(value: int) -> String:
    var negative: bool = value < 0
    var raw: String = str(absi(value))
    var result: String = ""
    var count: int = 0
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

func _miner_count_text() -> String:
    if world == null:
        return "0"
    var player_variant: Variant = world.get("player")
    if player_variant is Dictionary:
        return _format_int_commas(int((player_variant as Dictionary).get("machines", 0)))
    return "0"

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var button := event as InputEventMouseButton
        if button.button_index != MOUSE_BUTTON_LEFT:
            return
        if button.pressed:
            var bx: float = size.x - 132.0
            if button.position.y <= HEADER_H and button.position.x >= bx:
                if button.position.x < bx + 42.0:
                    _toggle_collapsed()
                elif button.position.x < bx + 84.0:
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
        else:
            if dragging:
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
    var viewport_size: Vector2 = get_viewport_rect().size
    var scaled_size: Vector2 = size * scale
    var margin: float = 10.0
    match slot:
        0:
            position = Vector2(margin, margin + 74.0)
        1:
            position = Vector2(viewport_size.x - scaled_size.x - margin, margin + 74.0)
        2:
            position = Vector2(viewport_size.x - scaled_size.x - margin, viewport_size.y - scaled_size.y - margin)
        3:
            position = Vector2(margin, viewport_size.y - scaled_size.y - margin)
    _clamp_to_viewport()

func _clamp_to_viewport() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    var scaled_size: Vector2 = size * scale
    position.x = clampf(position.x, 0.0, maxf(0.0, viewport_size.x - scaled_size.x))
    position.y = clampf(position.y, 0.0, maxf(0.0, viewport_size.y - scaled_size.y))
