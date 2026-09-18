extends Control
class_name HashRaceMetricsLeaderboard

signal closed

const GREEN := Color("64ff8c")
const CYAN := Color("52e7ff")
const INK := Color("dffaff")
const MUTED := Color("88a9b3")
const BG := Color("061015f5")

var rows: Array = []
var sort_key := "assets"
var descending := true
var table: VBoxContainer
var sort_label: Label

const COLUMNS := [
	{"key":"assets","label":"ASSET VALUE","unit":"$","lower":false},
	{"key":"hashrate_ph","label":"HASHRATE","unit":" PH/s","lower":false},
	{"key":"mw","label":"POWER","unit":" MW","lower":false},
	{"key":"efficiency_jth","label":"EFFICIENCY","unit":" J/TH","lower":true},
	{"key":"cash","label":"CASH","unit":"$","lower":false},
	{"key":"profit","label":"PROFIT","unit":"$","lower":false},
	{"key":"machines","label":"MACHINES","unit":"","lower":false},
	{"key":"acres","label":"LAND","unit":" acres","lower":false},
	{"key":"sats","label":"BTC TREASURY","unit":" BTC","lower":false},
	{"key":"aggression","label":"AGGRESSION","unit":"/100","lower":false},
	{"key":"risk","label":"RISK","unit":"/100","lower":false},
	{"key":"growth","label":"GROWTH","unit":"/100","lower":false},
	{"key":"research","label":"R&D","unit":"/100","lower":false},
	{"key":"treasury","label":"TREASURY","unit":"/100","lower":false},
	{"key":"operations","label":"OPERATIONS","unit":"/100","lower":false},
	{"key":"reputation","label":"REPUTATION","unit":"/100","lower":false}
]

func configure(source_rows: Array) -> void:
	rows = source_rows.duplicate(true)
	_refresh()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = BG
	add_child(backdrop)
	var title := Label.new()
	title.position = Vector2(42, 22)
	title.size = Vector2(850, 38)
	title.text = "HASH RACE // MINING METRICS TERMINAL"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", GREEN)
	add_child(title)
	sort_label = Label.new()
	sort_label.position = Vector2(44, 62)
	sort_label.size = Vector2(900, 28)
	sort_label.add_theme_font_size_override("font_size", 11)
	sort_label.add_theme_color_override("font_color", MUTED)
	add_child(sort_label)
	var close := Button.new()
	close.position = Vector2(1180, 22)
	close.size = Vector2(120, 38)
	close.text = "CLOSE"
	close.pressed.connect(_close)
	add_child(close)
	var sorter := HFlowContainer.new()
	sorter.position = Vector2(42, 98)
	sorter.size = Vector2(1260, 94)
	add_child(sorter)
	for column in COLUMNS:
		var b := Button.new()
		b.text = String(column["label"])
		b.custom_minimum_size = Vector2(145, 30)
		b.add_theme_font_size_override("font_size", 9)
		b.pressed.connect(_sort_by.bind(String(column["key"]), bool(column["lower"])))
		sorter.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(42, 202)
	scroll.size = Vector2(1260, 610)
	add_child(scroll)
	table = VBoxContainer.new()
	table.custom_minimum_size = Vector2(1230, 0)
	scroll.add_child(table)
	_refresh()

func _sort_by(key: String, lower_is_better: bool) -> void:
	if sort_key == key:
		descending = not descending
	else:
		sort_key = key
		descending = not lower_is_better
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(table):
		return
	for child in table.get_children():
		child.queue_free()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var av := float(a.get(sort_key, 0.0))
		var bv := float(b.get(sort_key, 0.0))
		return av > bv if descending else av < bv
	)
	sort_label.text = "SORT: %s  %s  // click any metric; click again to reverse" % [_column_label(sort_key), "HIGH → LOW" if descending else "LOW → HIGH"]
	for i in range(rows.size()):
		var row: Dictionary = rows[i]
		var line := Label.new()
		line.custom_minimum_size = Vector2(1230, 34)
		line.add_theme_font_size_override("font_size", 10)
		line.add_theme_color_override("font_color", GREEN if bool(row.get("player", false)) else INK)
		line.text = _row_text(i + 1, row)
		table.add_child(line)

func _row_text(rank: int, row: Dictionary) -> String:
	return "%2d  %-22s | %10s | %9s | %8s | %9s | %11s | %11s | %8s | %8s | %9s" % [
		rank, String(row.get("name","")),
		_money(row.get("assets",0.0)),
		"%.2f PH/s" % float(row.get("hashrate_ph",0.0)),
		"%.2f MW" % float(row.get("mw",0.0)),
		"%.1f J/TH" % float(row.get("efficiency_jth",0.0)),
		_money(row.get("cash",0.0)),
		_money(row.get("profit",0.0)),
		int(row.get("machines",0)),
		"%.1f ac" % float(row.get("acres",0.0)),
		"%.4f BTC" % float(row.get("sats",0.0))
	]

func _money(value: Variant) -> String:
	var v := float(value)
	if absf(v) >= 1000000.0: return "$%.2fM" % (v / 1000000.0)
	if absf(v) >= 1000.0: return "$%.1fK" % (v / 1000.0)
	return "$%d" % int(v)

func _column_label(key: String) -> String:
	for column in COLUMNS:
		if String(column["key"]) == key: return String(column["label"])
	return key.to_upper()

func _close() -> void:
	closed.emit()
	queue_free()
