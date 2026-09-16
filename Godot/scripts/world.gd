extends Node2D

const WORLD_SIZE := Vector2(1800, 1120)
const WALK_SPEED := 240.0
const CYAN := Color("55e7ff")
const GREEN := Color("64ff8c")
const ORANGE := Color("ffb65c")
const RED := Color("ff6b6b")
const PANEL := Color("111923e6")

var player_pos := Vector2(420, 560)
var click_target := Vector2.ZERO
var has_click_target := false
var camera: Camera2D

var company_name := "BlockForge Mining"
var day := 1
var season := 1
var cash := 12500.0
var fleet := 8
var machine_hashrate_th := 5.0
var efficiency_jth := 78.0
var electricity_price := 0.055
var uptime := 0.972
var site_capacity_mw := 0.12
var research := 0.0
var research_target := 15000.0
var generation := 1
var operating_focus := "Balanced"
var selected_building := "Hash Hall A"
var expansion_level := 0

var top_stats: Label
var detail_label: Label
var event_label: Label
var focus_button: Button
var lab_button: Button

var building_defs := [
    {"name":"Hash Hall A", "rect":Rect2(220, 180, 360, 260), "color":Color("1e5d74"), "kind":"Mining", "desc":"Primary ASIC hall. Racks turn electricity into hashrate."},
    {"name":"Hash Hall B", "rect":Rect2(640, 180, 330, 260), "color":Color("24506c"), "kind":"Mining", "desc":"Expansion hall for additional ASIC capacity."},
    {"name":"Hydro Cooling", "rect":Rect2(250, 690, 300, 220), "color":Color("195c63"), "kind":"Cooling", "desc":"Pumps, heat exchangers and water loops protect uptime."},
    {"name":"Substation", "rect":Rect2(1030, 155, 300, 250), "color":Color("514824"), "kind":"Power", "desc":"Transformers and switchgear feed the mining campus."},
    {"name":"ASIC Lab", "rect":Rect2(1040, 500, 300, 210), "color":Color("4a2d68"), "kind":"Research", "desc":"Engineers test silicon, boards, firmware and cooling ideas."},
    {"name":"NOC + HQ", "rect":Rect2(620, 720, 350, 210), "color":Color("263a68"), "kind":"Operations", "desc":"Network operations, finance, league strategy and company control."}
]

var worker_waypoints := [
    Vector2(330, 520), Vector2(760, 520), Vector2(1170, 460), Vector2(1180, 760),
    Vector2(760, 840), Vector2(390, 820), Vector2(900, 600), Vector2(610, 570)
]

var workers := [
    {"pos":Vector2(360, 510), "target":2, "speed":52.0, "color":CYAN},
    {"pos":Vector2(760, 530), "target":5, "speed":46.0, "color":GREEN},
    {"pos":Vector2(1130, 450), "target":4, "speed":49.0, "color":ORANGE},
    {"pos":Vector2(670, 850), "target":0, "speed":44.0, "color":CYAN}
]

func _ready() -> void:
    camera = Camera2D.new()
    camera.position = player_pos
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 8.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(WORLD_SIZE.x)
    camera.limit_bottom = int(WORLD_SIZE.y)
    add_child(camera)
    camera.make_current()
    build_hud()
    update_hud("Campus online. Walk with WASD/arrows or click anywhere on the site.")
    queue_redraw()

func _process(delta: float) -> void:
    var motion := Vector2.ZERO
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        motion.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        motion.y += 1.0
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        motion.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        motion.x += 1.0

    if motion.length() > 0.0:
        has_click_target = false
        player_pos += motion.normalized() * WALK_SPEED * delta
    elif has_click_target:
        player_pos = player_pos.move_toward(click_target, WALK_SPEED * delta)
        if player_pos.distance_to(click_target) < 5.0:
            has_click_target = false

    player_pos.x = clamp(player_pos.x, 40.0, WORLD_SIZE.x - 40.0)
    player_pos.y = clamp(player_pos.y, 80.0, WORLD_SIZE.y - 40.0)
    camera.position = player_pos
    update_workers(delta)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var world_click := get_global_mouse_position()
        for building in building_defs:
            if building.rect.has_point(world_click):
                selected_building = building.name
                update_hud("Selected %s." % selected_building)
                return
        click_target = world_click
        has_click_target = true

func update_workers(delta: float) -> void:
    for worker in workers:
        var target_pos: Vector2 = worker_waypoints[worker.target]
        worker.pos = worker.pos.move_toward(target_pos, worker.speed * delta)
        if worker.pos.distance_to(target_pos) < 8.0:
            worker.target = (worker.target + 1 + randi_range(0, 2)) % worker_waypoints.size()

func total_hashrate() -> float:
    return float(fleet) * machine_hashrate_th

func power_kw() -> float:
    return total_hashrate() * efficiency_jth / 1000.0

func daily_profit() -> float:
    var focus_mult := 1.0
    if operating_focus == "Efficiency":
        focus_mult = 1.06
    elif operating_focus == "Reliability":
        focus_mult = 1.03
    elif operating_focus == "R&D":
        focus_mult = 0.95
    var revenue := total_hashrate() * 2.25 * uptime * focus_mult
    var power_cost := power_kw() * 24.0 * electricity_price * uptime
    var operations := float(fleet) * 1.5
    return revenue - power_cost - operations

func site_limit_kw() -> float:
    return site_capacity_mw * 1000.0

func build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var top := Panel.new()
    top.position = Vector2(0, 0)
    top.size = Vector2(1280, 58)
    var top_style := StyleBoxFlat.new()
    top_style.bg_color = PANEL
    top_style.border_width_bottom = 2
    top_style.border_color = Color("1e8ea8")
    top.add_theme_stylebox_override("panel", top_style)
    layer.add_child(top)

    var title := Label.new()
    title.position = Vector2(20, 9)
    title.size = Vector2(340, 40)
    title.text = "HASH RACE // %s" % company_name
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", GREEN)
    top.add_child(title)

    top_stats = Label.new()
    top_stats.position = Vector2(365, 9)
    top_stats.size = Vector2(900, 40)
    top_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    top_stats.add_theme_font_size_override("font_size", 15)
    top_stats.add_theme_color_override("font_color", Color("d7f7ff"))
    top.add_child(top_stats)

    var side := Panel.new()
    side.position = Vector2(930, 76)
    side.size = Vector2(330, 620)
    var side_style := StyleBoxFlat.new()
    side_style.bg_color = Color("0b111ae8")
    side_style.border_width_left = 2
    side_style.border_width_top = 2
    side_style.border_width_right = 2
    side_style.border_width_bottom = 2
    side_style.border_color = Color("24485a")
    side_style.corner_radius_top_left = 10
    side_style.corner_radius_top_right = 10
    side_style.corner_radius_bottom_left = 10
    side_style.corner_radius_bottom_right = 10
    side.add_theme_stylebox_override("panel", side_style)
    layer.add_child(side)

    var header := Label.new()
    header.position = Vector2(18, 14)
    header.size = Vector2(294, 30)
    header.text = "SITE CONTROL"
    header.add_theme_font_size_override("font_size", 19)
    header.add_theme_color_override("font_color", CYAN)
    side.add_child(header)

    detail_label = Label.new()
    detail_label.position = Vector2(18, 52)
    detail_label.size = Vector2(294, 160)
    detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detail_label.add_theme_font_size_override("font_size", 14)
    side.add_child(detail_label)

    add_hud_button(side, "ADVANCE DAY", Vector2(18, 230), advance_day)
    add_hud_button(side, "BUY ASIC", Vector2(168, 230), buy_asic)
    add_hud_button(side, "FUND R&D", Vector2(18, 282), fund_rd)
    add_hud_button(side, "EXPAND SITE", Vector2(168, 282), expand_site)

    focus_button = add_hud_button(side, "FOCUS: BALANCED", Vector2(18, 342), cycle_focus, Vector2(294, 44))
    lab_button = add_hud_button(side, "OPEN OLD MANAGEMENT", Vector2(18, 394), open_management, Vector2(294, 44))

    var help := Label.new()
    help.position = Vector2(18, 452)
    help.size = Vector2(294, 75)
    help.text = "MOVE: WASD / arrows\nCLICK: walk or inspect building\nWORLD: workers and equipment keep moving"
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.add_theme_font_size_override("font_size", 12)
    help.add_theme_color_override("font_color", Color("a8c4d0"))
    side.add_child(help)

    event_label = Label.new()
    event_label.position = Vector2(18, 540)
    event_label.size = Vector2(294, 64)
    event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    event_label.add_theme_font_size_override("font_size", 12)
    event_label.add_theme_color_override("font_color", ORANGE)
    side.add_child(event_label)

func add_hud_button(parent: Control, text: String, pos: Vector2, callback: Callable, button_size := Vector2(140, 44)) -> Button:
    var button := Button.new()
    button.position = pos
    button.size = button_size
    button.text = text
    button.add_theme_font_size_override("font_size", 12)
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func selected_description() -> String:
    for building in building_defs:
        if building.name == selected_building:
            return "%s // %s\n%s" % [building.name, building.kind, building.desc]
    return selected_building

func update_hud(message: String = "") -> void:
    if not is_instance_valid(top_stats):
        return
    top_stats.text = "S%d D%d  |  $%d  |  %d ASICs  |  %.1f TH/s  |  %.1f J/TH  |  %.1f/%.0f kW" % [season, day, int(cash), fleet, total_hashrate(), efficiency_jth, power_kw(), site_limit_kw()]
    detail_label.text = "%s\n\nFocus: %s\nUptime: %.1f%%\nEst. profit/day: $%d\nR&D: $%d / $%d" % [selected_description(), operating_focus, uptime * 100.0, int(daily_profit()), int(research), int(research_target)]
    focus_button.text = "FOCUS: %s" % operating_focus.to_upper()
    if message != "":
        event_label.text = message

func advance_day() -> void:
    day += 1
    cash += daily_profit()
    if operating_focus == "R&D":
        research += 180.0
    if day % 90 == 0:
        season += 1
        event_label.text = "Season %d begins. Rival miners also advanced." % season
    else:
        event_label.text = "Day %d closed. Net: $%d." % [day, int(daily_profit())]
    update_hud()

func buy_asic() -> void:
    var price := 650.0 * pow(1.9, generation - 1)
    var added_kw := machine_hashrate_th * efficiency_jth / 1000.0
    if cash < price:
        update_hud("Need $%d for the current ASIC." % int(price))
        return
    if power_kw() + added_kw > site_limit_kw():
        update_hud("Power ceiling reached. Expand the site first.")
        return
    cash -= price
    fleet += 1
    update_hud("New Gen %d ASIC installed in the visible hash hall." % generation)

func fund_rd() -> void:
    var spend := min(cash, 2500.0)
    if spend <= 0.0:
        update_hud("No cash available for R&D.")
        return
    cash -= spend
    var focus_bonus := 1.25 if operating_focus == "R&D" else 1.0
    research += spend * focus_bonus
    if research >= research_target:
        research = 0.0
        generation += 1
        machine_hashrate_th *= 1.8
        efficiency_jth = max(1.0, efficiency_jth * 0.78)
        research_target *= 2.6
        update_hud("ASIC Lab unlocked Gen %d: %.1f TH/s at %.1f J/TH." % [generation, machine_hashrate_th, efficiency_jth])
    else:
        update_hud("ASIC Lab funded. Research is now $%d / $%d." % [int(research), int(research_target)])

func expand_site() -> void:
    var cost := 16000.0 * (1.0 + expansion_level * 0.7)
    if cash < cost:
        update_hud("Need $%d to energize the next expansion pad." % int(cost))
        return
    cash -= cost
    expansion_level += 1
    site_capacity_mw *= 1.65
    update_hud("Expansion %d energized. Site capacity is now %.2f MW." % [expansion_level, site_capacity_mw])

func cycle_focus() -> void:
    var modes := ["Balanced", "Efficiency", "Reliability", "R&D"]
    var idx := modes.find(operating_focus)
    operating_focus = modes[(idx + 1) % modes.size()]
    if operating_focus == "Efficiency":
        electricity_price = 0.051
    elif operating_focus == "Reliability":
        uptime = 0.989
    else:
        electricity_price = 0.055
        uptime = 0.972
    update_hud("Campus operating focus changed to %s." % operating_focus)

func open_management() -> void:
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("081015"), true)
    draw_grid()
    draw_campus_paths()
    for building in building_defs:
        draw_building(building)
    draw_power_network()
    draw_hash_racks()
    draw_cooling_system()
    draw_substation_detail()
    draw_workers()
    draw_player()
    draw_world_labels()

func draw_grid() -> void:
    for x in range(0, int(WORLD_SIZE.x), 40):
        draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), Color("0e1c23"), 1.0)
    for y in range(0, int(WORLD_SIZE.y), 40):
        draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), Color("0e1c23"), 1.0)

func draw_campus_paths() -> void:
    var road := Color("17272f")
    draw_rect(Rect2(120, 500, 1380, 100), road, true)
    draw_rect(Rect2(560, 100, 90, 900), road, true)
    draw_rect(Rect2(980, 100, 80, 860), road, true)
    for x in range(150, 1480, 70):
        draw_line(Vector2(x, 550), Vector2(x + 34, 550), Color("43636e"), 3.0)

func draw_building(building: Dictionary) -> void:
    var rect: Rect2 = building.rect
    var color: Color = building.color
    draw_rect(rect, Color("081015"), true)
    draw_rect(rect.grow(-5), color, true)
    draw_rect(rect, CYAN if building.name == selected_building else Color("3e6572"), false, 3.0)
    draw_rect(Rect2(rect.position + Vector2(14, 14), Vector2(rect.size.x - 28, 26)), Color("0a151c"), true)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(22, 34), building.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d9fbff"))

func draw_hash_racks() -> void:
    var blink := int(Time.get_ticks_msec() / 420) % 2
    var rack_count := min(fleet, 24)
    for i in range(rack_count):
        var hall_b := i >= 12
        var local_i := i - 12 if hall_b else i
        var col := local_i % 4
        var row := local_i / 4
        var base := Vector2(255, 235) if not hall_b else Vector2(675, 235)
        var p := base + Vector2(col * 72, row * 58)
        draw_rect(Rect2(p, Vector2(48, 34)), Color("0b1218"), true)
        draw_rect(Rect2(p, Vector2(48, 34)), Color("45606b"), false, 2.0)
        var led := GREEN if (i + blink) % 3 != 0 else CYAN
        draw_circle(p + Vector2(39, 9), 3.5, led)
        draw_line(p + Vector2(8, 12), p + Vector2(31, 12), Color("2d8aa0"), 2.0)
        draw_line(p + Vector2(8, 20), p + Vector2(31, 20), Color("2d8aa0"), 2.0)

func draw_cooling_system() -> void:
    var center_positions := [Vector2(320, 790), Vector2(405, 790), Vector2(490, 790)]
    var spin := float(Time.get_ticks_msec() % 3000) / 3000.0 * TAU
    for center in center_positions:
        draw_circle(center, 30, Color("0d2026"))
        draw_circle(center, 28, Color("3f727a"), false, 3.0)
        for blade in range(4):
            var angle := spin + blade * PI / 2.0
            draw_line(center, center + Vector2(cos(angle), sin(angle)) * 22.0, CYAN, 4.0)
    draw_line(Vector2(280, 860), Vector2(510, 860), Color("3bb7c9"), 8.0)

func draw_substation_detail() -> void:
    for i in range(3):
        var p := Vector2(1080 + i * 78, 255)
        draw_rect(Rect2(p, Vector2(48, 70)), Color("242822"), true)
        draw_rect(Rect2(p, Vector2(48, 70)), ORANGE, false, 2.0)
        draw_circle(p + Vector2(24, 14), 7, Color("d8b65c"), false, 2.0)
        draw_line(p + Vector2(24, 21), p + Vector2(24, 56), Color("a88d48"), 3.0)

func draw_power_network() -> void:
    var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 260.0)
    var live_color := Color(CYAN, pulse)
    draw_line(Vector2(1030, 340), Vector2(970, 340), live_color, 4.0)
    draw_line(Vector2(970, 340), Vector2(970, 470), live_color, 4.0)
    draw_line(Vector2(970, 470), Vector2(580, 470), live_color, 4.0)
    draw_line(Vector2(580, 470), Vector2(580, 350), live_color, 4.0)
    draw_line(Vector2(580, 350), Vector2(220, 350), live_color, 4.0)

func draw_workers() -> void:
    for worker in workers:
        var p: Vector2 = worker.pos
        draw_circle(p, 9, Color("091116"))
        draw_circle(p, 7, worker.color)
        draw_line(p + Vector2(0, 7), p + Vector2(0, 18), worker.color, 4.0)
        draw_line(p + Vector2(-7, 12), p + Vector2(7, 12), worker.color, 3.0)

func draw_player() -> void:
    draw_circle(player_pos, 16, Color("071014"))
    draw_circle(player_pos, 13, GREEN)
    draw_circle(player_pos + Vector2(0, -3), 5, Color("d7f7ff"))
    draw_line(player_pos + Vector2(0, 8), player_pos + Vector2(0, 24), GREEN, 5.0)
    draw_line(player_pos + Vector2(-9, 14), player_pos + Vector2(9, 14), GREEN, 4.0)
    draw_string(ThemeDB.fallback_font, player_pos + Vector2(-34, -24), "YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GREEN)

func draw_world_labels() -> void:
    draw_string(ThemeDB.fallback_font, Vector2(110, 105), "BLOCKFORGE CAMPUS // ACTIVE MINING SITE", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("8cf8ff"))
    draw_string(ThemeDB.fallback_font, Vector2(110, 132), "LIVE POWER • COOLING • NETWORK • R&D • OPERATIONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("587f8c"))
    if expansion_level > 0:
        draw_rect(Rect2(1380, 230, 300, 420), Color("17313d"), true)
        draw_rect(Rect2(1380, 230, 300, 420), GREEN, false, 3.0)
        draw_string(ThemeDB.fallback_font, Vector2(1410, 270), "EXPANSION PAD %d" % expansion_level, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, GREEN)
