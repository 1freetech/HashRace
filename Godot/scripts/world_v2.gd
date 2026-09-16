extends Node2D

const WORLD_SIZE := Vector2(3300, 2000)
const WALK_SPEED := 300.0
const CYAN := Color("52e7ff")
const GREEN := Color("64ff8c")
const ORANGE := Color("ffb85c")
const RED := Color("ff6b6b")
const WHITE := Color("dffaff")
const PANEL := Color("091119ee")
const TURN_DAYS := 7
const SATS_PER_BTC := 100000000.0

const COMPANY_NAMES := [
    "Emberline Compute",
    "Helix Circuit Labs",
    "ArcCurrent Systems",
    "StoneGrid Infrastructure",
    "Meridian Node Group",
    "BlueLoop Compute",
    "SignalPeak Systems",
    "Parallax Digital Works",
    "Lattice Energy Labs",
    "Epoch Harbor Holdings"
]

const COMPANY_COLORS := [
    "ff8a57", "a678ff", "55d7ff", "c9a45a", "ff6f91",
    "42dbc8", "69a8ff", "d37aff", "8ee35f", "ffc857"
]

const MACHINE_CATALOG := [
    {"name":"Garage ASIC", "th":90.0, "kw":3.0, "price":450.0, "unlock_cost":0.0, "requires":"Garage"},
    {"name":"S19j Pro-class", "th":104.0, "kw":3.068, "price":650.0, "unlock_cost":18000.0, "requires":"Garage"},
    {"name":"S21-class Air", "th":200.0, "kw":3.5, "price":1900.0, "unlock_cost":85000.0, "requires":"Local Site"},
    {"name":"S21 Pro-class", "th":234.0, "kw":3.51, "price":2600.0, "unlock_cost":220000.0, "requires":"Industrial Campus"},
    {"name":"S21 Hydro-class", "th":335.0, "kw":5.36, "price":5200.0, "unlock_cost":650000.0, "requires":"Hydro Cooling"},
    {"name":"Future 1 MW Rack", "th":60000.0, "kw":1000.0, "price":850000.0, "unlock_cost":2500000.0, "requires":"Captive Fab"}
]

const ENERGY_OPTIONS := [
    {"name":"Grid", "price":0.078, "capex":0.0, "reliability":0.00, "note":"Easy start; expensive and exposed to market rates."},
    {"name":"Utility PPA", "price":0.055, "capex":70000.0, "reliability":0.008, "note":"Stable contracted power; requires utility partnership."},
    {"name":"Natural Gas", "price":0.046, "capex":180000.0, "reliability":0.004, "note":"Reliable lower-cost generation; higher maintenance risk."},
    {"name":"Hydro", "price":0.036, "capex":420000.0, "reliability":0.012, "note":"Low-cost reliable power; high build cost and geography limits."},
    {"name":"Solar + Storage", "price":0.030, "capex":600000.0, "reliability":-0.012, "note":"Cheap marginal energy; land-intensive and storage-limited."},
    {"name":"Nuclear PPA", "price":0.042, "capex":2500000.0, "reliability":0.018, "note":"Dense stable power; only large regional operators qualify."}
]

const COOLING_LEVELS := [
    {"name":"Air", "capex":0.0, "uptime":0.0, "overhead":1.06, "note":"Lowest capex; fans and ambient heat limit density."},
    {"name":"Immersion", "capex":160000.0, "uptime":0.012, "overhead":1.04, "note":"Oil loops improve reliability and allow denser operation."},
    {"name":"Hydro Cooling", "capex":650000.0, "uptime":0.020, "overhead":1.035, "note":"Water loops support high-density hydro miners and future racks."}
]

const CHIP_LEVELS := [
    {"name":"Third-party chips", "cost":0.0, "discount":0.00},
    {"name":"Strategic wafer deal", "cost":150000.0, "discount":0.06},
    {"name":"Co-designed silicon", "cost":700000.0, "discount":0.12},
    {"name":"Captive chip manufacturing", "cost":4000000.0, "discount":0.22}
]

const SITE_STAGES := [
    {"name":"Garage Town", "machines":0, "mw":0.0, "acres":0.0, "cash":0.0},
    {"name":"Local Mining Site", "machines":100, "mw":0.35, "acres":5.0, "cash":75000.0},
    {"name":"Industrial Campus", "machines":400, "mw":1.5, "acres":20.0, "cash":300000.0},
    {"name":"Regional Mining Town", "machines":1200, "mw":6.0, "acres":60.0, "cash":1500000.0},
    {"name":"Fab-Integrated Tech Town", "machines":2500, "mw":25.0, "acres":120.0, "cash":8000000.0}
]

const PARTNER_DEFS := [
    {"name":"Cascadia Utility District", "kind":"City-State Utility", "boost":"POWER", "cost":35000.0, "note":"Cuts electricity cost by $0.012/kWh and unlocks Utility PPA."},
    {"name":"Harbor Land Authority", "kind":"Real Estate", "boost":"ACRES", "cost":28000.0, "note":"Adds 10 acres of development-ready land."},
    {"name":"Ironline Infrastructure", "kind":"Infrastructure", "boost":"MW", "cost":45000.0, "note":"Adds 0.25 MW of energized interconnect capacity."},
    {"name":"FoundryWorks Silicon", "kind":"Semiconductor", "boost":"MACHINES", "cost":52000.0, "note":"Delivers 10 current-generation machines and speeds chip progression."},
    {"name":"Meridian Finance Cooperative", "kind":"Finance", "boost":"CASH", "cost":18000.0, "note":"Adds $60,000 growth capital and increases loan-to-asset capacity."},
    {"name":"QuickBite Services", "kind":"Food", "boost":"PROFIT", "cost":30000.0, "note":"Adds $1,500 per turn of recurring commercial profit."},
    {"name":"Pro Circuit Sports", "kind":"Sports", "boost":"PROFIT", "cost":55000.0, "note":"Adds $2,500 per turn through sponsorship and venue contracts."},
    {"name":"BlueRiver Energy Authority", "kind":"Energy", "boost":"ENERGY", "cost":90000.0, "note":"Unlocks Hydro energy development and improves energy project access."},
    {"name":"Satoshi Treasury Network", "kind":"Digital Finance", "boost":"SATS", "cost":22000.0, "note":"Adds 20,000,000 sats to treasury reserves."}
]

var towns: Array = []
var partner_nodes: Array = []
var player_town_idx := 0
var selected_town_idx := 0
var selected_partner_idx := -1

var player_pos := Vector2.ZERO
var click_target := Vector2.ZERO
var has_click_target := false
var camera: Camera2D

var turn := 1
var season := 1
var btc_price := 118000.0
var network_hashrate_th := 850000000.0
var average_fees_btc := 0.15
var block_subsidy_btc := 3.125

var top_stats: Label
var selected_label: Label
var event_label: Label
var market_label: Label
var partner_label: Label

func _ready() -> void:
    randomize()
    build_world_data()
    var player := towns[player_town_idx]
    player_pos = player["center"] + Vector2(0, 220)
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
    update_hud("Garage operation online. Reach 100 machines, 0.35 MW, 5 acres, and $75K to commission your first real site.")
    queue_redraw()

func build_world_data() -> void:
    towns.clear()
    var positions := [
        Vector2(380, 370), Vector2(1000, 370), Vector2(1620, 370), Vector2(2240, 370), Vector2(2860, 370),
        Vector2(380, 1300), Vector2(1000, 1300), Vector2(1620, 1300), Vector2(2240, 1300), Vector2(2860, 1300)
    ]
    for i in range(COMPANY_NAMES.size()):
        var stage := 0 if i == 0 else min(3, 1 + i % 3)
        var base_machines := 12 if i == 0 else 120 + i * 55
        var counts := [0, 0, 0, 0, 0, 0]
        counts[min(3, stage)] = base_machines
        var town := {
            "name": COMPANY_NAMES[i],
            "center": positions[i],
            "color": Color(COMPANY_COLORS[i]),
            "stage": stage,
            "sats": 0.0 if i == 0 else float(5000000 + i * 3500000),
            "power_cost": 0.078 - min(0.025, float(i) * 0.0025),
            "mw": 0.06 if i == 0 else 0.6 + float(i) * 0.45,
            "machine_counts": counts,
            "energy": "Grid" if i < 3 else ("Utility PPA" if i < 7 else "Hydro"),
            "cash": 85000.0 if i == 0 else 180000.0 + i * 95000.0,
            "acres": 0.75 if i == 0 else 8.0 + float(i) * 6.0,
            "cooling": 0 if stage < 2 else 1,
            "chip_level": 0 if i == 0 else min(2, i / 4),
            "unlocked_tier": 0 if i == 0 else min(3, stage),
            "debt": 0.0,
            "hosting": false,
            "treasury_hold": 0.30,
            "partners": [],
            "weekly_bonus": 0.0,
            "utility_discount": 0.0,
            "finance_bonus": 0.0,
            "hydro_access": false,
            "uptime_base": 0.955 + min(0.025, float(i) * 0.002),
            "last_profit": 0.0
        }
        towns.append(town)

    partner_nodes.clear()
    var partner_positions := [
        Vector2(610, 845), Vector2(900, 845), Vector2(1190, 845), Vector2(1480, 845), Vector2(1770, 845),
        Vector2(2060, 845), Vector2(2350, 845), Vector2(2640, 845), Vector2(2930, 845)
    ]
    for i in range(PARTNER_DEFS.size()):
        var node := PARTNER_DEFS[i].duplicate(true)
        node["pos"] = partner_positions[i]
        node["signed"] = false
        partner_nodes.append(node)

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
        if player_pos.distance_to(click_target) < 6.0:
            has_click_target = false
    player_pos.x = clamp(player_pos.x, 40.0, WORLD_SIZE.x - 40.0)
    player_pos.y = clamp(player_pos.y, 80.0, WORLD_SIZE.y - 40.0)
    camera.position = player_pos
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var p := get_global_mouse_position()
        for i in range(towns.size()):
            if town_rect(towns[i]).has_point(p):
                selected_town_idx = i
                selected_partner_idx = -1
                click_target = towns[i]["center"]
                has_click_target = true
                update_hud("Inspecting %s." % towns[i]["name"])
                return
        for i in range(partner_nodes.size()):
            if p.distance_to(partner_nodes[i]["pos"]) < 48.0:
                selected_partner_idx = i
                update_hud("Selected NPC partner: %s." % partner_nodes[i]["name"])
                return
        click_target = p
        has_click_target = true

func town_rect(town: Dictionary) -> Rect2:
    return Rect2(town["center"] - Vector2(220, 155), Vector2(440, 310))

func total_machines(town: Dictionary) -> int:
    var total := 0
    for count in town["machine_counts"]:
        total += int(count)
    return total

func total_hashrate_th(town: Dictionary) -> float:
    var total := 0.0
    for i in range(MACHINE_CATALOG.size()):
        total += float(town["machine_counts"][i]) * float(MACHINE_CATALOG[i]["th"])
    return total

func raw_machine_kw(town: Dictionary) -> float:
    var total := 0.0
    for i in range(MACHINE_CATALOG.size()):
        total += float(town["machine_counts"][i]) * float(MACHINE_CATALOG[i]["kw"])
    return total

func cooling_overhead(town: Dictionary) -> float:
    return float(COOLING_LEVELS[int(town["cooling"])]["overhead"])

func site_load_kw(town: Dictionary) -> float:
    return raw_machine_kw(town) * cooling_overhead(town)

func effective_uptime(town: Dictionary) -> float:
    var cooling_bonus := float(COOLING_LEVELS[int(town["cooling"])]["uptime"])
    var energy_bonus := 0.0
    for energy in ENERGY_OPTIONS:
        if energy["name"] == town["energy"]:
            energy_bonus = float(energy["reliability"])
            break
    return clamp(float(town["uptime_base"]) + cooling_bonus + energy_bonus, 0.80, 0.997)

func effective_power_cost(town: Dictionary) -> float:
    var base := float(town["power_cost"])
    for energy in ENERGY_OPTIONS:
        if energy["name"] == town["energy"]:
            base = float(energy["price"])
            break
    return max(0.018, base - float(town["utility_discount"]))

func btc_per_day(town: Dictionary) -> float:
    if network_hashrate_th <= 0.0:
        return 0.0
    var network_share := total_hashrate_th(town) / network_hashrate_th
    return network_share * 144.0 * (block_subsidy_btc + average_fees_btc) * effective_uptime(town)

func sats_per_day(town: Dictionary) -> float:
    return btc_per_day(town) * SATS_PER_BTC

func hosting_profit_per_day(town: Dictionary) -> float:
    if not bool(town["hosting"]):
        return 0.0
    var spare_kw := max(0.0, float(town["mw"]) * 1000.0 - site_load_kw(town))
    var hosted_kw := spare_kw * 0.65
    var customer_rate := 0.075
    var margin := max(0.0, customer_rate - effective_power_cost(town))
    return hosted_kw * 24.0 * margin

func operating_cost_per_day(town: Dictionary) -> float:
    var machine_ops := float(total_machines(town)) * 0.38
    var fixed_site := float(town["stage"]) * 180.0
    var power := site_load_kw(town) * 24.0 * effective_power_cost(town) * effective_uptime(town)
    var debt_interest := float(town["debt"]) * 0.10 / 365.0
    return machine_ops + fixed_site + power + debt_interest

func gross_revenue_per_day(town: Dictionary) -> float:
    return btc_per_day(town) * btc_price + hosting_profit_per_day(town) + float(town["weekly_bonus"]) / 7.0

func net_profit_per_day(town: Dictionary) -> float:
    return gross_revenue_per_day(town) - operating_cost_per_day(town)

func asset_value(town: Dictionary) -> float:
    var machine_book := 0.0
    for i in range(MACHINE_CATALOG.size()):
        machine_book += float(town["machine_counts"][i]) * float(MACHINE_CATALOG[i]["price"]) * 0.70
    var sats_value := float(town["sats"]) / SATS_PER_BTC * btc_price
    var mw_value := float(town["mw"]) * 90000.0
    var land_value := float(town["acres"]) * 8000.0
    var site_value := float(town["stage"]) * 250000.0
    var chip_value := float(town["chip_level"]) * 500000.0
    return max(0.0, float(town["cash"])) + sats_value + machine_book + mw_value + land_value + site_value + chip_value

func loan_limit(town: Dictionary) -> float:
    var ratio := 0.35 + float(town["finance_bonus"])
    return max(0.0, asset_value(town) * ratio - float(town["debt"]))

func current_machine(town: Dictionary) -> Dictionary:
    return MACHINE_CATALOG[int(town["unlocked_tier"])]

func machine_discount(town: Dictionary) -> float:
    return float(CHIP_LEVELS[int(town["chip_level"])]["discount"])

func machine_purchase_price(town: Dictionary) -> float:
    return float(current_machine(town)["price"]) * (1.0 - machine_discount(town))

func build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    var top := Panel.new()
    top.position = Vector2(0, 0)
    top.size = Vector2(1440, 66)
    var top_style := StyleBoxFlat.new()
    top_style.bg_color = PANEL
    top_style.border_width_bottom = 2
    top_style.border_color = Color("1e8ea8")
    top.add_theme_stylebox_override("panel", top_style)
    layer.add_child(top)

    var title := Label.new()
    title.position = Vector2(18, 8)
    title.size = Vector2(340, 48)
    title.text = "HASH RACE // TECH TOWNS"
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", GREEN)
    top.add_child(title)

    top_stats = Label.new()
    top_stats.position = Vector2(360, 6)
    top_stats.size = Vector2(1060, 50)
    top_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    top_stats.add_theme_font_size_override("font_size", 14)
    top_stats.add_theme_color_override("font_color", WHITE)
    top.add_child(top_stats)

    var side := Panel.new()
    side.position = Vector2(1035, 82)
    side.size = Vector2(385, 795)
    var side_style := StyleBoxFlat.new()
    side_style.bg_color = Color("071018f2")
    side_style.border_width_left = 2
    side_style.border_width_top = 2
    side_style.border_width_right = 2
    side_style.border_width_bottom = 2
    side_style.border_color = Color("28596b")
    side_style.corner_radius_top_left = 10
    side_style.corner_radius_top_right = 10
    side_style.corner_radius_bottom_left = 10
    side_style.corner_radius_bottom_right = 10
    side.add_theme_stylebox_override("panel", side_style)
    layer.add_child(side)

    var hdr := Label.new()
    hdr.position = Vector2(16, 12)
    hdr.size = Vector2(355, 28)
    hdr.text = "COMPANY / TOWN CONTROL"
    hdr.add_theme_font_size_override("font_size", 18)
    hdr.add_theme_color_override("font_color", CYAN)
    side.add_child(hdr)

    selected_label = Label.new()
    selected_label.position = Vector2(16, 46)
    selected_label.size = Vector2(355, 252)
    selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    selected_label.add_theme_font_size_override("font_size", 13)
    side.add_child(selected_label)

    add_hud_button(side, "END TURN +7D", Vector2(16, 307), advance_turn)
    add_hud_button(side, "BUY MACHINES", Vector2(198, 307), buy_machines)
    add_hud_button(side, "BUY +0.25 MW", Vector2(16, 355), buy_power)
    add_hud_button(side, "BUY +5 ACRES", Vector2(198, 355), buy_land)
    add_hud_button(side, "BUILD / UPGRADE SITE", Vector2(16, 403), build_or_upgrade_site, Vector2(355, 40))
    add_hud_button(side, "UPGRADE MACHINE", Vector2(16, 451), unlock_next_machine)
    add_hud_button(side, "UPGRADE COOLING", Vector2(198, 451), upgrade_cooling)
    add_hud_button(side, "UPGRADE CHIPS", Vector2(16, 499), upgrade_chips)
    add_hud_button(side, "CHANGE ENERGY", Vector2(198, 499), change_energy)
    add_hud_button(side, "SIGN SELECTED NPC", Vector2(16, 547), sign_selected_partner, Vector2(355, 40))
    add_hud_button(side, "TAKE ASSET LOAN", Vector2(16, 595), take_loan)
    add_hud_button(side, "HOSTING ON/OFF", Vector2(198, 595), toggle_hosting)
    add_hud_button(side, "TREASURY HOLD", Vector2(16, 643), cycle_treasury)
    add_hud_button(side, "OLD MANAGEMENT", Vector2(198, 643), open_management)

    partner_label = Label.new()
    partner_label.position = Vector2(16, 692)
    partner_label.size = Vector2(355, 40)
    partner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    partner_label.add_theme_font_size_override("font_size", 11)
    partner_label.add_theme_color_override("font_color", Color("a9ccd7"))
    side.add_child(partner_label)

    event_label = Label.new()
    event_label.position = Vector2(16, 738)
    event_label.size = Vector2(355, 46)
    event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    event_label.add_theme_font_size_override("font_size", 11)
    event_label.add_theme_color_override("font_color", ORANGE)
    side.add_child(event_label)

    var market := Panel.new()
    market.position = Vector2(18, 810)
    market.size = Vector2(995, 67)
    var market_style := StyleBoxFlat.new()
    market_style.bg_color = Color("071018e8")
    market_style.border_width_top = 1
    market_style.border_width_bottom = 1
    market_style.border_color = Color("204653")
    market.add_theme_stylebox_override("panel", market_style)
    layer.add_child(market)

    market_label = Label.new()
    market_label.position = Vector2(14, 8)
    market_label.size = Vector2(965, 50)
    market_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    market_label.add_theme_font_size_override("font_size", 13)
    market_label.add_theme_color_override("font_color", Color("c1e8ef"))
    market.add_child(market_label)

func add_hud_button(parent: Control, text: String, pos: Vector2, callback: Callable, button_size := Vector2(173, 40)) -> Button:
    var button := Button.new()
    button.position = pos
    button.size = button_size
    button.text = text
    button.add_theme_font_size_override("font_size", 11)
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func selected_town_text() -> String:
    var town := towns[selected_town_idx]
    var profit := net_profit_per_day(town)
    var stage_name := SITE_STAGES[int(town["stage"])]["name"]
    return "%s\n%s\n\n1 SATS: %d\n2 Power: $%.3f/kWh\n3 Capacity: %.2f MW (load %.2f MW)\n4 Machines: %d | %.2f PH/s\n5 Energy: %s | Cooling: %s\n6 Cash: $%d | Profit/day: $%d\n7 Acres: %.2f\n\nChips: %s | Debt: $%d" % [
        town["name"], stage_name, int(town["sats"]), effective_power_cost(town), float(town["mw"]), site_load_kw(town) / 1000.0,
        total_machines(town), total_hashrate_th(town) / 1000.0, town["energy"], COOLING_LEVELS[int(town["cooling"])]["name"],
        int(town["cash"]), int(profit), float(town["acres"]), CHIP_LEVELS[int(town["chip_level"])]["name"], int(town["debt"])
    ]

func update_hud(message: String = "") -> void:
    if not is_instance_valid(top_stats):
        return
    var player := towns[player_town_idx]
    top_stats.text = "S%d T%d | SATS %d | $%.3f/kWh | %.2f MW | %d units | %s | Cash $%d | Acres %.1f" % [
        season, turn, int(player["sats"]), effective_power_cost(player), float(player["mw"]), total_machines(player), player["energy"], int(player["cash"]), float(player["acres"])
    ]
    selected_label.text = selected_town_text()
    market_label.text = "MARKET  BTC $%d  | Network %.0f EH/s | Block subsidy %.3f BTC + %.2f fees | Your expected sats/day %d | Loan headroom $%d | Treasury hold %.0f%% | Hosting %s" % [
        int(btc_price), network_hashrate_th / 1000000.0, block_subsidy_btc, average_fees_btc, int(sats_per_day(player)), int(loan_limit(player)), float(player["treasury_hold"]) * 100.0, "ON" if player["hosting"] else "OFF"
    ]
    if selected_partner_idx >= 0:
        var partner := partner_nodes[selected_partner_idx]
        partner_label.text = "NPC: %s // %s // %s" % [partner["name"], partner["boost"], partner["note"]]
    else:
        partner_label.text = "NPC DISTRICT: click a diamond company between the two mining-town rows, then sign it here."
    if message != "":
        event_label.text = message

func advance_turn() -> void:
    var player := towns[player_town_idx]
    var mined_btc := btc_per_day(player) * TURN_DAYS
    var mined_sats := mined_btc * SATS_PER_BTC
    var hold_sats := mined_sats * float(player["treasury_hold"])
    var sold_btc := mined_btc * (1.0 - float(player["treasury_hold"]))
    var cash_revenue := sold_btc * btc_price + (hosting_profit_per_day(player) * TURN_DAYS) + float(player["weekly_bonus"])
    var costs := operating_cost_per_day(player) * TURN_DAYS
    player["sats"] = float(player["sats"]) + hold_sats
    player["cash"] = float(player["cash"]) + cash_revenue - costs
    player["last_profit"] = cash_revenue - costs

    simulate_rivals()
    turn += 1
    if turn % 13 == 0:
        season += 1
    btc_price = max(18000.0, btc_price * randf_range(0.95, 1.055))
    network_hashrate_th *= randf_range(0.997, 1.018)
    average_fees_btc = clamp(average_fees_btc * randf_range(0.85, 1.20), 0.04, 0.55)
    update_hud("Turn closed: mined %d sats, held %d, cash result $%d." % [int(mined_sats), int(hold_sats), int(player["last_profit"])])

func simulate_rivals() -> void:
    for i in range(towns.size()):
        if i == player_town_idx:
            continue
        var town := towns[i]
        var profit := net_profit_per_day(town) * TURN_DAYS
        town["cash"] = float(town["cash"]) + profit
        town["sats"] = float(town["sats"]) + sats_per_day(town) * TURN_DAYS * 0.35
        if profit > 1000.0 and randf() < 0.35:
            var tier := int(town["unlocked_tier"])
            town["machine_counts"][tier] += 10 + randi_range(0, 20)
        if site_load_kw(town) > float(town["mw"]) * 900.0:
            town["mw"] = float(town["mw"]) + 0.25
        if randf() < 0.08:
            town["acres"] = float(town["acres"]) + 5.0

func buy_machines() -> void:
    var town := towns[player_town_idx]
    var tier := int(town["unlocked_tier"])
    var machine := MACHINE_CATALOG[tier]
    var count := 1 if tier == 5 else 10
    var price_each := machine_purchase_price(town)
    var cost := price_each * count
    var added_kw := float(machine["kw"]) * count * cooling_overhead(town)
    if float(town["cash"]) < cost:
        update_hud("Need $%d to buy %d × %s." % [int(cost), count, machine["name"]])
        return
    if site_load_kw(town) + added_kw > float(town["mw"]) * 1000.0:
        update_hud("Not enough energized MW. Buy interconnect capacity first.")
        return
    town["cash"] = float(town["cash"]) - cost
    town["machine_counts"][tier] += count
    update_hud("Installed %d × %s for $%d." % [count, machine["name"], int(cost)])

func buy_power() -> void:
    var town := towns[player_town_idx]
    var increment := 0.25
    var cost := 26000.0 + float(town["mw"]) * 42000.0
    if float(town["cash"]) < cost:
        update_hud("Need $%d for another 0.25 MW of energized capacity." % int(cost))
        return
    town["cash"] = float(town["cash"]) - cost
    town["mw"] = float(town["mw"]) + increment
    update_hud("Interconnect expanded by 0.25 MW. Total %.2f MW." % float(town["mw"]))

func buy_land() -> void:
    var town := towns[player_town_idx]
    var cost := 30000.0 + float(town["acres"]) * 2200.0
    if float(town["cash"]) < cost:
        update_hud("Need $%d for the next 5-acre parcel." % int(cost))
        return
    town["cash"] = float(town["cash"]) - cost
    town["acres"] = float(town["acres"]) + 5.0
    update_hud("Purchased 5 acres. Total land is %.2f acres." % float(town["acres"]))

func build_or_upgrade_site() -> void:
    var town := towns[player_town_idx]
    var next_stage := int(town["stage"]) + 1
    if next_stage >= SITE_STAGES.size():
        update_hud("Your mining town is already at the current maximum stage.")
        return
    var req := SITE_STAGES[next_stage]
    if total_machines(town) < int(req["machines"]):
        update_hud("Need at least %d machines for %s." % [int(req["machines"]), req["name"]])
        return
    if float(town["mw"]) < float(req["mw"]):
        update_hud("Need at least %.2f MW for %s." % [float(req["mw"]), req["name"]])
        return
    if float(town["acres"]) < float(req["acres"]):
        update_hud("Need at least %.0f acres for %s." % [float(req["acres"]), req["name"]])
        return
    if next_stage == 4 and int(town["chip_level"]) < 2:
        update_hud("Fab-Integrated Tech Town requires co-designed silicon first.")
        return
    if float(town["cash"]) < float(req["cash"]):
        update_hud("Need $%d construction cash for %s." % [int(req["cash"]), req["name"]])
        return
    town["cash"] = float(town["cash"]) - float(req["cash"])
    town["stage"] = next_stage
    update_hud("Commissioned %s. The town visibly expands next redraw." % req["name"])

func unlock_next_machine() -> void:
    var town := towns[player_town_idx]
    var next_tier := int(town["unlocked_tier"]) + 1
    if next_tier >= MACHINE_CATALOG.size():
        update_hud("All current machine platforms are unlocked.")
        return
    var next_machine := MACHINE_CATALOG[next_tier]
    if next_tier == 2 and int(town["stage"]) < 1:
        update_hud("S21-class deployment requires a Local Mining Site.")
        return
    if next_tier == 3 and int(town["stage"]) < 2:
        update_hud("S21 Pro-class deployment requires an Industrial Campus.")
        return
    if next_tier == 4 and int(town["cooling"]) < 2:
        update_hud("S21 Hydro-class deployment requires Hydro Cooling.")
        return
    if next_tier == 5 and (int(town["stage"]) < 4 or int(town["chip_level"]) < 3 or int(town["cooling"]) < 2 or season < 8):
        update_hud("Future 1 MW racks require Season 8+, Fab Town, captive chips, and Hydro Cooling.")
        return
    var cost := float(next_machine["unlock_cost"])
    if float(town["cash"]) < cost:
        update_hud("Need $%d R&D/certification cash to unlock %s." % [int(cost), next_machine["name"]])
        return
    town["cash"] = float(town["cash"]) - cost
    town["unlocked_tier"] = next_tier
    update_hud("Unlocked %s: %.0f TH/s at %.3f kW per unit." % [next_machine["name"], float(next_machine["th"]), float(next_machine["kw"])])

func upgrade_cooling() -> void:
    var town := towns[player_town_idx]
    var next_level := int(town["cooling"]) + 1
    if next_level >= COOLING_LEVELS.size():
        update_hud("Hydro Cooling is already installed.")
        return
    if next_level == 1 and int(town["stage"]) < 1:
        update_hud("Immersion requires a commissioned Local Mining Site.")
        return
    if next_level == 2 and (int(town["stage"]) < 2 or float(town["mw"]) < 2.0):
        update_hud("Hydro Cooling requires an Industrial Campus and at least 2 MW.")
        return
    var system := COOLING_LEVELS[next_level]
    var cost := float(system["capex"])
    if float(town["cash"]) < cost:
        update_hud("Need $%d for %s." % [int(cost), system["name"]])
        return
    town["cash"] = float(town["cash"]) - cost
    town["cooling"] = next_level
    update_hud("Cooling upgraded to %s. Uptime and density improve." % system["name"])

func upgrade_chips() -> void:
    var town := towns[player_town_idx]
    var next_level := int(town["chip_level"]) + 1
    if next_level >= CHIP_LEVELS.size():
        update_hud("Captive chip manufacturing is already online.")
        return
    if next_level == 1 and int(town["stage"]) < 1:
        update_hud("A strategic wafer deal requires a Local Mining Site.")
        return
    if next_level == 2 and int(town["stage"]) < 2:
        update_hud("Co-designed silicon requires an Industrial Campus.")
        return
    if next_level == 3 and int(town["stage"]) < 4:
        update_hud("Captive chip manufacturing requires a Fab-Integrated Tech Town.")
        return
    var level := CHIP_LEVELS[next_level]
    var cost := float(level["cost"])
    if float(town["cash"]) < cost:
        update_hud("Need $%d for %s." % [int(cost), level["name"]])
        return
    town["cash"] = float(town["cash"]) - cost
    town["chip_level"] = next_level
    update_hud("Semiconductor strategy advanced to %s. Machine prices fall." % level["name"])

func change_energy() -> void:
    var town := towns[player_town_idx]
    var current_idx := 0
    for i in range(ENERGY_OPTIONS.size()):
        if ENERGY_OPTIONS[i]["name"] == town["energy"]:
            current_idx = i
            break
    var next_idx := (current_idx + 1) % ENERGY_OPTIONS.size()
    var target := ENERGY_OPTIONS[next_idx]
    if target["name"] == "Utility PPA" and float(town["utility_discount"]) <= 0.0:
        update_hud("Utility PPA requires Cascadia Utility District partnership first.")
        return
    if target["name"] == "Hydro" and not bool(town["hydro_access"]):
        update_hud("Hydro requires BlueRiver Energy Authority partnership first.")
        return
    if target["name"] == "Solar + Storage" and float(town["acres"]) < 30.0:
        update_hud("Solar + Storage requires at least 30 acres.")
        return
    if target["name"] == "Nuclear PPA" and (int(town["stage"]) < 3 or float(town["mw"]) < 10.0):
        update_hud("Nuclear PPA requires a Regional Mining Town and at least 10 MW.")
        return
    var cost := float(target["capex"])
    if float(town["cash"]) < cost:
        update_hud("Need $%d energy-project capex for %s." % [int(cost), target["name"]])
        return
    town["cash"] = float(town["cash"]) - cost
    town["energy"] = target["name"]
    town["power_cost"] = float(target["price"])
    update_hud("Energy source changed to %s. %s" % [target["name"], target["note"]])

func sign_selected_partner() -> void:
    if selected_partner_idx < 0:
        update_hud("Click an NPC company diamond first.")
        return
    var town := towns[player_town_idx]
    var partner := partner_nodes[selected_partner_idx]
    if bool(partner["signed"]):
        update_hud("%s is already partnered with your company." % partner["name"])
        return
    var cost := float(partner["cost"])
    if float(town["cash"]) < cost:
        update_hud("Need $%d to sign %s." % [int(cost), partner["name"]])
        return
    town["cash"] = float(town["cash"]) - cost
    partner["signed"] = true
    town["partners"].append(partner["name"])
    match partner["boost"]:
        "POWER":
            town["utility_discount"] = float(town["utility_discount"]) + 0.012
        "ACRES":
            town["acres"] = float(town["acres"]) + 10.0
        "MW":
            town["mw"] = float(town["mw"]) + 0.25
        "MACHINES":
            town["machine_counts"][int(town["unlocked_tier"])] += 10
        "CASH":
            town["cash"] = float(town["cash"]) + 60000.0
            town["finance_bonus"] = 0.10
        "PROFIT":
            town["weekly_bonus"] = float(town["weekly_bonus"]) + (1500.0 if partner["kind"] == "Food" else 2500.0)
        "ENERGY":
            town["hydro_access"] = true
        "SATS":
            town["sats"] = float(town["sats"]) + 20000000.0
    update_hud("Partnership signed: %s. Boost applied to %s." % [partner["name"], partner["boost"]])

func take_loan() -> void:
    var town := towns[player_town_idx]
    var available := loan_limit(town)
    if available < 5000.0:
        update_hud("Asset-backed loan headroom is too small right now.")
        return
    var amount := min(available, max(25000.0, asset_value(town) * 0.15))
    town["debt"] = float(town["debt"]) + amount
    town["cash"] = float(town["cash"]) + amount
    update_hud("Borrowed $%d against company assets. Debt now $%d." % [int(amount), int(town["debt"])])

func toggle_hosting() -> void:
    var town := towns[player_town_idx]
    town["hosting"] = not bool(town["hosting"])
    update_hud("Third-party hosting is now %s. Spare MW can earn a power margin." % ("ON" if town["hosting"] else "OFF"))

func cycle_treasury() -> void:
    var town := towns[player_town_idx]
    var holds := [0.0, 0.30, 0.60, 1.0]
    var idx := holds.find(float(town["treasury_hold"]))
    town["treasury_hold"] = holds[(idx + 1) % holds.size()]
    update_hud("Treasury policy now holds %.0f%% of newly mined sats." % (float(town["treasury_hold"]) * 100.0))

func open_management() -> void:
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("061015"), true)
    draw_grid()
    draw_interstate_network()
    draw_partner_district()
    for i in range(towns.size()):
        draw_town(towns[i], i)
    draw_player()
    draw_world_titles()

func draw_grid() -> void:
    for x in range(0, int(WORLD_SIZE.x), 50):
        draw_line(Vector2(x, 0), Vector2(x, WORLD_SIZE.y), Color("0b1b22"), 1.0)
    for y in range(0, int(WORLD_SIZE.y), 50):
        draw_line(Vector2(0, y), Vector2(WORLD_SIZE.x, y), Color("0b1b22"), 1.0)

func draw_interstate_network() -> void:
    var road := Color("152a32")
    draw_rect(Rect2(120, 760, 3060, 120), road, true)
    draw_rect(Rect2(120, 900, 3060, 120), road, true)
    for x in range(160, 3140, 90):
        draw_line(Vector2(x, 820), Vector2(x + 45, 820), Color("48717e"), 3.0)
        draw_line(Vector2(x, 960), Vector2(x + 45, 960), Color("48717e"), 3.0)
    for town in towns:
        draw_line(town["center"] + Vector2(0, 155), Vector2(town["center"].x, 760), Color("1c3943"), 22.0)
        draw_line(town["center"] - Vector2(0, 155), Vector2(town["center"].x, 1020), Color("1c3943"), 22.0)

func draw_partner_district() -> void:
    draw_string(ThemeDB.fallback_font, Vector2(160, 742), "ADJACENT NPC TECH / CITY-STATE DISTRICT", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, CYAN)
    for i in range(partner_nodes.size()):
        var partner := partner_nodes[i]
        var p: Vector2 = partner["pos"]
        var color := GREEN if bool(partner["signed"]) else (ORANGE if i == selected_partner_idx else Color("5d7b86"))
        var pts := PackedVector2Array([p + Vector2(0, -24), p + Vector2(24, 0), p + Vector2(0, 24), p + Vector2(-24, 0)])
        draw_colored_polygon(pts, Color("10242c"))
        draw_polyline(pts + PackedVector2Array([pts[0]]), color, 3.0)
        draw_string(ThemeDB.fallback_font, p + Vector2(-62, 42), partner["boost"], HORIZONTAL_ALIGNMENT_CENTER, 124, 11, color)

func draw_town(town: Dictionary, idx: int) -> void:
    var rect := town_rect(town)
    var color: Color = town["color"]
    draw_rect(rect, Color("081218"), true)
    draw_rect(rect, color.darkened(0.68), true)
    var border := GREEN if idx == player_town_idx else (CYAN if idx == selected_town_idx else color)
    draw_rect(rect, border, false, 4.0)

    var stage := int(town["stage"])
    var center: Vector2 = town["center"]
    draw_rect(Rect2(rect.position + Vector2(12, 12), Vector2(rect.size.x - 24, 34)), Color("071017"), true)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(20, 35), town["name"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, WHITE)
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(20, 61), SITE_STAGES[stage]["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color.lightened(0.25))

    if stage == 0:
        draw_rect(Rect2(center + Vector2(-70, -25), Vector2(140, 80)), Color("1a2730"), true)
        draw_rect(Rect2(center + Vector2(-70, -25), Vector2(140, 80)), color, false, 3.0)
        draw_string(ThemeDB.fallback_font, center + Vector2(-44, 20), "GARAGE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)
    else:
        draw_rect(Rect2(center + Vector2(-170, -25), Vector2(150, 100)), Color("16262e"), true)
        draw_rect(Rect2(center + Vector2(20, -25), Vector2(150, 100)), Color("16262e"), true)
        draw_rect(Rect2(center + Vector2(-170, -25), Vector2(150, 100)), color, false, 2.0)
        draw_rect(Rect2(center + Vector2(20, -25), Vector2(150, 100)), color, false, 2.0)
        draw_string(ThemeDB.fallback_font, center + Vector2(-145, 8), "HASH HALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
        draw_string(ThemeDB.fallback_font, center + Vector2(48, 8), "POWER / NOC", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
        if stage >= 2:
            draw_rect(Rect2(center + Vector2(-72, 92), Vector2(144, 58)), Color("15202e"), true)
            draw_rect(Rect2(center + Vector2(-72, 92), Vector2(144, 58)), CYAN, false, 2.0)
            draw_string(ThemeDB.fallback_font, center + Vector2(-46, 127), "ASIC LAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, CYAN)
        if stage >= 3:
            draw_circle(center + Vector2(164, 108), 28, Color("14272b"))
            draw_circle(center + Vector2(164, 108), 26, GREEN, false, 3.0)
        if stage >= 4:
            draw_rect(Rect2(center + Vector2(-190, 92), Vector2(92, 58)), Color("2a1833"), true)
            draw_rect(Rect2(center + Vector2(-190, 92), Vector2(92, 58)), Color("cb78ff"), false, 2.0)
            draw_string(ThemeDB.fallback_font, center + Vector2(-179, 127), "CHIP FAB", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("dfb1ff"))

    draw_town_racks(town, rect, color)
    var stat_text := "%d units | %.2f MW | $%.3f/kWh | %.1f ac" % [total_machines(town), float(town["mw"]), effective_power_cost(town), float(town["acres"])]
    draw_string(ThemeDB.fallback_font, rect.position + Vector2(20, rect.size.y - 18), stat_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9cbfc8"))

func draw_town_racks(town: Dictionary, rect: Rect2, color: Color) -> void:
    var visible_units := min(30, total_machines(town))
    if int(town["unlocked_tier"]) == 5:
        visible_units = min(12, total_machines(town))
    for i in range(visible_units):
        var col := i % 10
        var row := i / 10
        var p := rect.position + Vector2(24 + col * 37, 84 + row * 26)
        draw_rect(Rect2(p, Vector2(28, 16)), Color("071016"), true)
        draw_rect(Rect2(p, Vector2(28, 16)), color, false, 1.0)
        if i % 3 != int(Time.get_ticks_msec() / 450) % 3:
            draw_circle(p + Vector2(23, 5), 2.0, GREEN)

func draw_player() -> void:
    draw_circle(player_pos, 17, Color("061015"))
    draw_circle(player_pos, 13, GREEN)
    draw_circle(player_pos + Vector2(0, -3), 5, WHITE)
    draw_line(player_pos + Vector2(0, 8), player_pos + Vector2(0, 24), GREEN, 5.0)
    draw_line(player_pos + Vector2(-9, 14), player_pos + Vector2(9, 14), GREEN, 4.0)
    draw_string(ThemeDB.fallback_font, player_pos + Vector2(-32, -25), "YOU", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GREEN)

func draw_world_titles() -> void:
    draw_string(ThemeDB.fallback_font, Vector2(120, 105), "HASH RACE // BITCOIN MINING TECH TOWNS", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("8ef7ff"))
    draw_string(ThemeDB.fallback_font, Vector2(120, 136), "BUILD POWER • LAND • MACHINES • COOLING • ENERGY • SILICON • PARTNERSHIPS", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("5f8d98"))
