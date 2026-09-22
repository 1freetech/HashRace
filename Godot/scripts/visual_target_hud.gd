extends Control
class_name HashRaceVisualTargetHUD

const GREEN := Color("64ff71")
const GREEN_DIM := Color("31c95d")
const CYAN := Color("52e7ff")
const ORANGE := Color("f7931a")
const YELLOW := Color("ffd34e")
const WHITE := Color("e8f0f2")
const MUTED := Color("9db2bd")
const PANEL := Color(0.025, 0.065, 0.095, 0.96)
const PANEL_2 := Color(0.035, 0.085, 0.115, 0.96)
const BORDER := Color("29495c")

var world: Node
var _redraw_accum := 0.0

func setup(world_node: Node) -> void:
    world = world_node
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    queue_redraw()

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
    _redraw_accum += delta
    if _redraw_accum >= 0.20:
        _redraw_accum = 0.0
        queue_redraw()

func _draw() -> void:
    if not is_instance_valid(world):
        return
    _draw_top_bar()
    _draw_objective()
    _draw_input_hint()
    _draw_minimap()

func _metric(method: StringName, fallback: float = 0.0) -> float:
    if is_instance_valid(world) and world.has_method(method):
        return float(world.call(method))
    return fallback

func _player_value(key: String, fallback: float = 0.0) -> float:
    var data = world.get("player")
    if data is Dictionary:
        return float((data as Dictionary).get(key, fallback))
    return fallback

func _draw_top_bar() -> void:
    var vw := size.x
    var h := 76.0
    draw_rect(Rect2(Vector2.ZERO, Vector2(vw, h)), Color("06131d"), true)
    draw_line(Vector2(0.0, h), Vector2(vw, h), Color("203c4b"), 2.0)

    _panel(Rect2(10, 6, 220, 62))
    _text(Vector2(22, 31), "HASH", 26, WHITE)
    _text(Vector2(111, 31), "RACE", 26, GREEN)
    _text(Vector2(22, 55), _version_text(), 11, MUTED)

    var available := maxf(0.0, _metric(&"_effective_available_mw", 0.0))
    var load := maxf(0.0, _metric(&"_machine_load_kw", 0.0) / 1000.0)
    var hashrate := maxf(0.0, _metric(&"_hashrate_th", 0.0))
    var efficiency := 0.0
    if hashrate > 0.0:
        efficiency = maxf(0.0, _metric(&"_machine_load_kw", 0.0) * 1000.0 / hashrate)
    var btc := _player_value("sats", 0.0) / 100000000.0
    var cash := _player_value("cash", 0.0)

    var x := 240.0
    var gap := 7.0
    var widths := [190.0, 180.0, 200.0, 190.0, 190.0]
    _stat(Rect2(x, 6, widths[0], 62), "BTC TREASURY", "%.6f" % btc, ORANGE, "₿")
    x += widths[0] + gap
    _stat(Rect2(x, 6, widths[1], 62), "CASH", "$%s" % _money(cash), GREEN, "$")
    x += widths[1] + gap
    _stat(Rect2(x, 6, widths[2], 62), "POWER", "%.1f MW / %.1f MW" % [load, available], YELLOW, "⚡")
    x += widths[2] + gap
    _stat(Rect2(x, 6, widths[3], 62), "HASHRATE", "%s TH/s" % _compact(hashrate), GREEN, "📈")
    x += widths[3] + gap
    _stat(Rect2(x, 6, widths[4], 62), "EFFICIENCY", "%.2f J/TH" % efficiency, GREEN, "📉")

    var right := Rect2(vw - 148.0, 6.0, 138.0, 62.0)
    _panel(right)
    _text(right.position + Vector2(15, 20), "Mine.", 11, GREEN)
    _text(right.position + Vector2(15, 37), "Expand.", 11, GREEN)
    _text(right.position + Vector2(15, 54), "Race Ahead.", 11, GREEN)

func _draw_objective() -> void:
    var r := Rect2(12, 88, 250, 118)
    _panel(r)
    _text(r.position + Vector2(14, 22), "Current Objective", 13, GREEN)
    _text(r.position + Vector2(14, 48), "Upgrade Transformer", 13, WHITE)
    draw_rect(Rect2(r.position + Vector2(16, 66), Vector2(17, 17)), PANEL_2, true)
    draw_rect(Rect2(r.position + Vector2(16, 66), Vector2(17, 17)), MUTED, false, 1.0)
    var cash := _player_value("cash", 0.0)
    _text(r.position + Vector2(44, 80), "Gather $25,000", 11, WHITE)
    _text(r.position + Vector2(44, 101), "(%s / 25,000)" % _money(cash), 10, MUTED)

func _draw_input_hint() -> void:
    var y := size.y - 72.0
    var r := Rect2(12, y, 330, 58)
    _panel(r)
    _key(r.position + Vector2(18, 17), "W")
    _key(r.position + Vector2(18, 35), "A")
    _key(r.position + Vector2(38, 35), "S")
    _key(r.position + Vector2(58, 35), "D")
    _text(r.position + Vector2(90, 38), "Move", 11, WHITE)
    _key(r.position + Vector2(205, 25), "E")
    _text(r.position + Vector2(235, 38), "Interact", 11, WHITE)

func _draw_minimap() -> void:
    var r := Rect2(size.x - 215.0, size.y - 178.0, 202.0, 164.0)
    _panel(r)
    _text(r.position + Vector2(92, 18), "N", 11, WHITE)
    var inner := Rect2(r.position + Vector2(12, 26), r.size - Vector2(24, 38))
    draw_rect(inner, Color("173c29"), true)
    draw_rect(Rect2(inner.position + Vector2(0, inner.size.y * 0.58), Vector2(inner.size.x, 18)), Color("4c5358"), true)
    draw_rect(Rect2(inner.position + Vector2(inner.size.x * 0.18, 8), Vector2(36, 24)), Color("5b6167"), true)
    draw_rect(Rect2(inner.position + Vector2(inner.size.x * 0.58, 8), Vector2(42, 26)), Color("5b6167"), true)
    draw_rect(Rect2(inner.position + Vector2(inner.size.x * 0.66, inner.size.y * 0.68), Vector2(48, 31)), Color("474f54"), true)
    var dot := inner.position + inner.size * Vector2(0.50, 0.56)
    draw_circle(dot, 6.0, Color("071014"))
    draw_circle(dot, 4.0, GREEN)

func _panel(r: Rect2) -> void:
    draw_rect(r, PANEL, true)
    draw_rect(r, BORDER, false, 2.0)

func _stat(r: Rect2, label: String, value: String, accent: Color, icon: String) -> void:
    _panel(r)
    _text(r.position + Vector2(13, 37), icon, 25, accent)
    _text(r.position + Vector2(48, 20), label, 10, WHITE)
    _text(r.position + Vector2(48, 46), value, 14, accent if label == "CASH" else WHITE)

func _key(pos: Vector2, label: String) -> void:
    draw_rect(Rect2(pos, Vector2(18, 18)), PANEL_2, true)
    draw_rect(Rect2(pos, Vector2(18, 18)), MUTED, false, 1.0)
    _text(pos + Vector2(5, 13), label, 9, WHITE)

func _text(pos: Vector2, value: String, font_size: int, color: Color) -> void:
    draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _version_text() -> String:
    var path := "res://../VERSION"
    if FileAccess.file_exists(path):
        var file := FileAccess.open(path, FileAccess.READ)
        if file != null:
            var value := file.get_as_text().strip_edges()
            if not value.is_empty():
                return value
    return "dev"

func _money(value: float) -> String:
    var whole := maxi(0, int(round(value)))
    var raw := str(whole)
    var out := ""
    while raw.length() > 3:
        out = "," + raw.right(3) + out
        raw = raw.left(raw.length() - 3)
    return raw + out

func _compact(value: float) -> String:
    if value >= 1000000.0:
        return "%.1fM" % (value / 1000000.0)
    if value >= 1000.0:
        return "%.1fK" % (value / 1000.0)
    return "%.0f" % value

func debug_visual_target_hud_ready() -> bool:
    return GREEN.g > 0.9 and PANEL.a > 0.9
