extends Node2D

const Profiles = preload("res://scripts/company_profiles.gd")
const WORLD_SIZE: Vector2 = Vector2(3000.0, 1900.0)
const WALK_SPEED: float = 330.0
const INTERACT_DISTANCE: float = 145.0
const SATS_PER_BTC: float = 100000000.0
const QUARTER_DAYS: float = 91.25
const TURNS_PER_YEAR: int = 4
const HALVING_TURNS: int = 16
const MAX_CAMPAIGN_YEARS: int = 100

const GREEN: Color = Color("64ff8c")
const CYAN: Color = Color("52e7ff")
const WHITE: Color = Color("e7f7fa")
const ORANGE: Color = Color("ffbd66")
const RED: Color = Color("ff6b6b")
const DARK: Color = Color("061015")
const ROAD: Color = Color("24343b")
const GRASS: Color = Color("102b27")
const PANEL: Color = Color("071018f2")

const MACHINES: Array = [
    {"name":"Garage ASIC", "th":90.0, "kw":3.0, "price":450.0},
    {"name":"S19j Pro-class", "th":104.0, "kw":3.068, "price":650.0},
    {"name":"S21-class Air", "th":200.0, "kw":3.5, "price":1900.0},
    {"name":"S21 Pro-class", "th":234.0, "kw":3.51, "price":2600.0},
    {"name":"S21 Hydro-class", "th":335.0, "kw":5.36, "price":5200.0}
]

const ENERGIES: Array = [
    {"name":"Grid", "price":0.078, "capex":0.0, "reliability":0.0, "clean":false, "offgrid":false, "adv":"Easy to start and expand.", "disadv":"Highest rate exposure."},
    {"name":"Utility PPA", "price":0.055, "capex":70000.0, "reliability":0.008, "clean":false, "offgrid":false, "adv":"Contracted price stability.", "disadv":"Needs the utility partnership."},
    {"name":"Natural Gas", "price":0.046, "capex":180000.0, "reliability":0.004, "clean":false, "offgrid":true, "adv":"Reliable off-grid generation.", "disadv":"Fuel and maintenance cost."},
    {"name":"Hydro", "price":0.036, "capex":420000.0, "reliability":0.012, "clean":true, "offgrid":true, "adv":"Cheap reliable clean off-grid power.", "disadv":"High project cost and limited access."},
    {"name":"Solar + Storage", "price":0.030, "capex":600000.0, "reliability":-0.012, "clean":true, "offgrid":true, "adv":"Lowest energy price and strongest clean credit.", "disadv":"Land intensive and less reliable."},
    {"name":"Nuclear PPA", "price":0.042, "capex":2500000.0, "reliability":0.018, "clean":true, "offgrid":false, "adv":"Dense low-carbon baseload.", "disadv":"Very high entry cost."}
]

const PARTNERS: Array = [
    {"id":"utility", "name":"Cascadia Utility District", "sector":"UTILITY", "cost":35000.0, "boost":"Cheaper power + Utility PPA access"},
    {"id":"land", "name":"Harbor Land Authority", "sector":"REAL ESTATE", "cost":28000.0, "boost":"+10 acres + 15% cheaper future land"},
    {"id":"infra", "name":"Ironline Infrastructure", "sector":"INFRASTRUCTURE", "cost":45000.0, "boost":"+0.25 MW + cheaper future interconnect"},
    {"id":"semi", "name":"FoundryWorks Silicon", "sector":"SEMICONDUCTOR", "cost":52000.0, "boost":"+10 machines + 6% fleet efficiency + machine discount"},
    {"id":"finance", "name":"Meridian Finance Cooperative", "sector":"FINANCE", "cost":18000.0, "boost":"+$60K cash + better borrowing"},
    {"id":"food", "name":"QuickBite Services", "sector":"FOOD", "cost":30000.0, "boost":"+$6K recurring quarterly income"},
    {"id":"sports", "name":"Pro Circuit Sports", "sector":"SPORTS", "cost":55000.0, "boost":"+$10K recurring quarterly income"},
    {"id":"energy", "name":"BlueRiver Energy Authority", "sector":"ENERGY", "cost":90000.0, "boost":"Hydro access + stronger clean-power reward"},
    {"id":"treasury", "name":"Satoshi Treasury Network", "sector":"DIGITAL FINANCE", "cost":22000.0, "boost":"+20,000,000 sats"}
]

var company_idx: int = 0
var campaign_years: int = 4
var campaign_turns: int = 16
var turn: int = 1
var campaign_complete: bool = false

var player: Dictionary = {}
var rivals: Array = []
var entities: Array = []
var signed_partners: Dictionary = {}
var selected_entity_idx: int = -1
var merger_used: bool = false

var btc_price: float = 118000.0
var network_hashrate_th: float = 850000000.0
var block_subsidy_btc: float = 3.125
var average_fees_btc: float = 0.15
var federal_rate: float = 0.045
var land_price_per_acre: float = 8000.0
var energy_market_index: float = 1.0
var halvings_since_crash: int = 0
var last_market_event: String = "Normal market"

var rep_pos: Vector2 = Vector2(1500.0, 1060.0)
var click_target: Vector2 = Vector2.ZERO
var has_click_target: bool = false
var camera: Camera2D

var top_stats: Label
var company_stats: Label
var market_label: Label
var prompt_label: Label
var dialog_panel: Panel
var dialog_title: Label
var dialog_text: Label
var action_row: HBoxContainer
var quarter_button: Button

func _ready() -> void:
    _read_campaign_selection()
    _initialize_player()
    _initialize_rivals()
    _build_entities()
    _build_camera()
    _build_ui()
    _open_message("WELCOME TO THE TECH DISTRICT", "You are the company representative. Walk with WASD or arrow keys. Click a building or walk close and press E/Enter to talk. Strategic actions happen inside companies; use the current Day, Month, or Year turn control to advance the economy.")
    _refresh_ui()
    queue_redraw()

func _read_campaign_selection() -> void:
    if get_tree().has_meta("hashrace_company_idx"):
        company_idx = clampi(int(get_tree().get_meta("hashrace_company_idx")), 0, Profiles.PROFILES.size() - 1)
    if get_tree().has_meta("hashrace_campaign_years"):
        campaign_years = clampi(int(get_tree().get_meta("hashrace_campaign_years")), 1, MAX_CAMPAIGN_YEARS)
    if get_tree().has_meta("hashrace_campaign_turns"):
        campaign_turns = clampi(int(get_tree().get_meta("hashrace_campaign_turns")), 4, MAX_CAMPAIGN_YEARS * 12)
    else:
        campaign_turns = campaign_years * 4

func _initialize_player() -> void:
    var profile: Dictionary = Profiles.PROFILES[company_idx]
    player = {
        "name": String(profile["name"]),
        "strengths": String(profile["strengths"]),
        "cash": 85000.0 + float(profile["cash_bonus"]),
        "sats": float(profile["sats_bonus"]),
        "mw": 0.06 + float(profile["mw_bonus"]),
        "acres": 0.75 + float(profile["acres_bonus"]),
        "machines": 12 + int(profile["machine_bonus"]),
        "machine_tier": 0,
        "energy_idx": 0,
        "power_discount": float(profile["power_discount"]),
        "loan_bonus": float(profile["loan_bonus"]),
        "debt": 0.0,
        "debt_rate": 0.0,
        "debt_source": "No lender",
        "treasury_hold": 0.30,
        "recurring_income": 0.0,
        "machine_efficiency_bonus": 0.0,
        "machine_discount": 0.0,
        "land_discount": 0.0,
        "power_capex_discount": 0.0,
        "lender_spread_discount": 0.0,
        "clean_credit_bonus": 0.0,
        "utility_access": false,
        "hydro_access": false,
        "cooling_level": 0,
        "chip_level": 0,
        "last_profit": 0.0
    }
    if String(profile["energy"]) == "Utility PPA":
        player["energy_idx"] = 1
        player["utility_access"] = true

func _initialize_rivals() -> void:
    rivals.clear()
    for i in range(Profiles.PROFILES.size()):
        if i == company_idx:
            continue
        var profile: Dictionary = Profiles.PROFILES[i]
        var rival: Dictionary = {
            "profile_idx": i,
            "name": String(profile["name"]),
            "cash": 180000.0 + float(i) * 105000.0,
            "sats": 5000000.0 + float(i) * 3500000.0,
            "mw": 0.65 + float(i) * 0.38,
            "acres": 8.0 + float(i) * 5.5,
            "machines": 115 + i * 45,
            "merged": false
        }
        rivals.append(rival)

func _build_entities() -> void:
    entities.clear()
    entities.append({"name":String(player["name"]), "kind":"hq", "pos":Vector2(1500.0, 1120.0), "subtitle":"YOUR MINING HQ"})
    entities.append({"name":"HashWorks ASIC Exchange", "kind":"machines", "pos":Vector2(1050.0, 1120.0), "subtitle":"MINERS + HARDWARE"})
    entities.append({"name":"Gridline Power Office", "kind":"power", "pos":Vector2(1950.0, 1120.0), "subtitle":"MW + ENERGY"})
    entities.append({"name":"Local Joker Bank", "kind":"bank", "pos":Vector2(1500.0, 720.0), "subtitle":"LOANS + DEBT"})

    var partner_positions: Array = [
        Vector2(500.0, 520.0), Vector2(850.0, 520.0), Vector2(1200.0, 520.0),
        Vector2(1800.0, 520.0), Vector2(2150.0, 520.0), Vector2(2500.0, 520.0),
        Vector2(500.0, 1450.0), Vector2(850.0, 1450.0), Vector2(1200.0, 1450.0)
    ]
    for i in range(PARTNERS.size()):
        var partner: Dictionary = PARTNERS[i]
        entities.append({
            "name": String(partner["name"]),
            "kind": "partner",
            "pos": partner_positions[i],
            "subtitle": String(partner["sector"]),
            "partner_idx": i
        })

    var rival_positions: Array = [
        Vector2(285.0, 900.0), Vector2(285.0, 1190.0), Vector2(285.0, 1480.0),
        Vector2(2715.0, 900.0), Vector2(2715.0, 1190.0), Vector2(2715.0, 1480.0),
        Vector2(1550.0, 1650.0), Vector2(1980.0, 1650.0), Vector2(2410.0, 1650.0)
    ]
    for i in range(rivals.size()):
        var rival: Dictionary = rivals[i]
        entities.append({
            "name": String(rival["name"]),
            "kind": "rival",
            "pos": rival_positions[i],
            "subtitle": "BITCOIN MINING RIVAL",
            "rival_idx": i
        })

func _build_camera() -> void:
    camera = Camera2D.new()
    camera.position = rep_pos
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 8.0
    camera.limit_left = 0
    camera.limit_top = 0
    camera.limit_right = int(WORLD_SIZE.x)
    camera.limit_bottom = int(WORLD_SIZE.y)
    add_child(camera)
    camera.make_current()

func _build_ui() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    add_child(layer)

    var top: Panel = _panel(Vector2(12.0, 10.0), Vector2(1416.0, 66.0), Color("071018f4"), CYAN)
    layer.add_child(top)
    var title: Label = _label("HASH RACE // COMPANY OVERWORLD", Vector2(18.0, 10.0), Vector2(360.0, 42.0), 22, GREEN)
    top.add_child(title)
    top_stats = _label("", Vector2(380.0, 8.0), Vector2(1018.0, 46.0), 14, WHITE)
    top_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    top.add_child(top_stats)

    var side: Panel = _panel(Vector2(1038.0, 90.0), Vector2(390.0, 530.0), PANEL, Color("28596b"))
    layer.add_child(side)
    var side_title: Label = _label("YOUR COMPANY", Vector2(16.0, 12.0), Vector2(350.0, 30.0), 18, CYAN)
    side.add_child(side_title)
    company_stats = _label("", Vector2(16.0, 48.0), Vector2(355.0, 335.0), 13, WHITE)
    company_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    side.add_child(company_stats)
    quarter_button = Button.new()
    quarter_button.position = Vector2(16.0, 400.0)
    quarter_button.size = Vector2(355.0, 48.0)
    quarter_button.text = "END QUARTER"
    quarter_button.add_theme_font_size_override("font_size", 15)
    quarter_button.pressed.connect(_end_quarter)
    side.add_child(quarter_button)
    var help: Label = _label("MOVE: WASD / ARROWS   TALK: E / ENTER\nClick buildings to open them. Economy moves only when END QUARTER is pressed.", Vector2(16.0, 458.0), Vector2(355.0, 60.0), 11, Color("a9ccd7"))
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    side.add_child(help)

    prompt_label = _label("", Vector2(310.0, 94.0), Vector2(710.0, 40.0), 15, ORANGE)
    prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layer.add_child(prompt_label)

    var market: Panel = _panel(Vector2(12.0, 632.0), Vector2(1010.0, 62.0), Color("071018e8"), Color("204653"))
    layer.add_child(market)
    market_label = _label("", Vector2(14.0, 8.0), Vector2(980.0, 46.0), 12, Color("c1e8ef"))
    market_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    market.add_child(market_label)

    dialog_panel = _panel(Vector2(12.0, 708.0), Vector2(1010.0, 180.0), Color("061017f8"), WHITE)
    layer.add_child(dialog_panel)
    dialog_title = _label("", Vector2(18.0, 12.0), Vector2(970.0, 28.0), 17, GREEN)
    dialog_panel.add_child(dialog_title)
    dialog_text = _label("", Vector2(18.0, 44.0), Vector2(970.0, 72.0), 13, WHITE)
    dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialog_panel.add_child(dialog_text)
    action_row = HBoxContainer.new()
    action_row.position = Vector2(18.0, 124.0)
    action_row.size = Vector2(970.0, 44.0)
    action_row.add_theme_constant_override("separation", 10)
    dialog_panel.add_child(action_row)

func _panel(pos: Vector2, size_value: Vector2, bg: Color, border: Color) -> Panel:
    var panel: Panel = Panel.new()
    panel.position = pos
    panel.size = size_value
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg
    style.border_width_left = 2
    style.border_width_top = 2
    style.border_width_right = 2
    style.border_width_bottom = 2
    style.border_color = border
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    panel.add_theme_stylebox_override("panel", style)
    return panel

func _label(text_value: String, pos: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
    var label: Label = Label.new()
    label.position = pos
    label.size = size_value
    label.text = text_value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    return label

func _process(delta: float) -> void:
    var motion: Vector2 = Vector2.ZERO
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
        rep_pos += motion.normalized() * WALK_SPEED * delta
    elif has_click_target:
        rep_pos = rep_pos.move_toward(click_target, WALK_SPEED * delta)
        if rep_pos.distance_to(click_target) < 8.0:
            has_click_target = false
    rep_pos.x = clampf(rep_pos.x, 70.0, WORLD_SIZE.x - 70.0)
    rep_pos.y = clampf(rep_pos.y, 120.0, WORLD_SIZE.y - 70.0)
    camera.position = rep_pos
    _update_nearby_prompt()
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo and (key_event.keycode == KEY_E or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE):
            _interact_nearby()
            get_viewport().set_input_as_handled()
            return
    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
            var world_pos: Vector2 = get_global_mouse_position()
            var entity_idx: int = _entity_at(world_pos)
            if entity_idx >= 0:
                _open_entity(entity_idx)
                get_viewport().set_input_as_handled()
                return
            click_target = world_pos
            has_click_target = true

func _entity_at(world_pos: Vector2) -> int:
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var pos: Vector2 = entity["pos"]
        if pos.distance_to(world_pos) <= 105.0:
            return i
    return -1

func _nearest_entity() -> int:
    var best_idx: int = -1
    var best_distance: float = INTERACT_DISTANCE
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var pos: Vector2 = entity["pos"]
        var distance: float = rep_pos.distance_to(pos)
        if distance < best_distance:
            best_distance = distance
            best_idx = i
    return best_idx

func _update_nearby_prompt() -> void:
    var idx: int = _nearest_entity()
    if idx < 0:
        prompt_label.text = "Explore the district • walk to a company and press E"
        return
    var entity: Dictionary = entities[idx]
    prompt_label.text = "E / ENTER  •  TALK TO %s" % String(entity["name"])

func _interact_nearby() -> void:
    var idx: int = _nearest_entity()
    if idx < 0:
        _open_message("NO COMPANY NEARBY", "Walk closer to a building. Every named company in the district can be opened and interacted with.")
        return
    _open_entity(idx)

func _open_entity(idx: int) -> void:
    selected_entity_idx = idx
    var entity: Dictionary = entities[idx]
    var kind: String = String(entity["kind"])
    if kind == "hq":
        _open_hq(entity)
    elif kind == "machines":
        _open_machine_shop(entity)
    elif kind == "power":
        _open_power_office(entity)
    elif kind == "bank":
        _open_bank(entity)
    elif kind == "partner":
        _open_partner(entity)
    elif kind == "rival":
        _open_rival(entity)

func _open_message(title_text: String, body_text: String) -> void:
    dialog_title.text = title_text
    dialog_text.text = body_text
    _set_actions([])

func _set_actions(actions: Array) -> void:
    for child in action_row.get_children():
        child.queue_free()
    for raw_action in actions:
        var action: Dictionary = raw_action
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(190.0, 42.0)
        button.text = String(action["label"])
        button.add_theme_font_size_override("font_size", 12)
        var callback: Callable = action["call"]
        button.pressed.connect(callback)
        action_row.add_child(button)

func _open_hq(entity: Dictionary) -> void:
    dialog_title.text = String(entity["name"]) + " // YOUR HQ"
    dialog_text.text = "Strength: %s. Manage treasury, cooling and chip strategy here. The quarter will not move until you choose END QUARTER." % String(player["strengths"])
    _set_actions([
        {"label":"TREASURY HOLD", "call":Callable(self, "_cycle_treasury")},
        {"label":"UPGRADE COOLING", "call":Callable(self, "_upgrade_cooling")},
        {"label":"UPGRADE CHIPS", "call":Callable(self, "_upgrade_chips")}
    ])

func _open_machine_shop(entity: Dictionary) -> void:
    var machine: Dictionary = MACHINES[int(player["machine_tier"])]
    dialog_title.text = String(entity["name"])
    dialog_text.text = "Current platform: %s • %.0f TH/s • %.3f kW each. Buy miners when you have enough cash and energized MW, or unlock a stronger platform." % [String(machine["name"]), float(machine["th"]), float(machine["kw"])]
    _set_actions([
        {"label":"BUY 10 MACHINES", "call":Callable(self, "_buy_machines")},
        {"label":"UPGRADE PLATFORM", "call":Callable(self, "_upgrade_machine_tier")}
    ])

func _open_power_office(entity: Dictionary) -> void:
    var energy: Dictionary = ENERGIES[int(player["energy_idx"])]
    dialog_title.text = String(entity["name"])
    dialog_text.text = "Current energy: %s at about $%.3f/kWh. + %s  - %s" % [String(energy["name"]), _effective_power_cost(), String(energy["adv"]), String(energy["disadv"])]
    _set_actions([
        {"label":"BUY +0.25 MW", "call":Callable(self, "_buy_power")},
        {"label":"CHANGE ENERGY", "call":Callable(self, "_change_energy")}
    ])

func _open_bank(entity: Dictionary) -> void:
    var offer: Dictionary = _eligible_lender()
    dialog_title.text = String(entity["name"]) + " // FINANCE DISTRICT"
    if offer.is_empty():
        dialog_text.text = "No lender will approve new debt yet. Grow assets first. Local Joker Bank is the first and worst lender: small cap, high spread. Better companies unlock larger and cheaper lenders."
    else:
        var live_rate: float = _loan_rate(offer)
        dialog_text.text = "Best available lender: %s • %.2f%% live rate • up to $%d new room. Fed rate is %.2f%%, so debt prices move with the market." % [String(offer["name"]), live_rate * 100.0, int(_loan_room()), federal_rate * 100.0]
    _set_actions([
        {"label":"TAKE LOAN", "call":Callable(self, "_take_loan")},
        {"label":"REPAY DEBT", "call":Callable(self, "_repay_debt")}
    ])

func _open_partner(entity: Dictionary) -> void:
    var partner_idx: int = int(entity["partner_idx"])
    var partner: Dictionary = PARTNERS[partner_idx]
    var partner_id: String = String(partner["id"])
    var signed: bool = signed_partners.has(partner_id)
    dialog_title.text = "%s // %s" % [String(partner["name"]), String(partner["sector"])]
    dialog_text.text = "%s\nDeal cost: $%d • Status: %s" % [String(partner["boost"]), int(partner["cost"]), "SIGNED" if signed else "AVAILABLE"]
    if signed:
        _set_actions([])
    else:
        _set_actions([{"label":"STRIKE DEAL", "call":Callable(self, "_sign_partner").bind(partner_idx)}])

func _open_rival(entity: Dictionary) -> void:
    var rival_idx: int = int(entity["rival_idx"])
    var rival: Dictionary = rivals[rival_idx]
    dialog_title.text = String(rival["name"]) + " // MINING RIVAL"
    if bool(rival["merged"]):
        dialog_text.text = "This mining company has already been absorbed into your company."
        _set_actions([])
        return
    dialog_text.text = "Machines %d • %.2f MW • %.1f acres • Cash $%d. Mining companies compete independently, but your company can complete exactly one merger in a campaign." % [int(rival["machines"]), float(rival["mw"]), float(rival["acres"]), int(rival["cash"])]
    if merger_used:
        _set_actions([])
    else:
        _set_actions([{"label":"ATTEMPT ONE-TIME MERGER", "call":Callable(self, "_merge_rival").bind(rival_idx)}])

func _machine_load_kw() -> float:
    var machine: Dictionary = MACHINES[int(player["machine_tier"])]
    var efficiency_bonus: float = clampf(float(player["machine_efficiency_bonus"]), 0.0, 0.20)
    var cooling_overhead: float = [1.06, 1.04, 1.035][int(player["cooling_level"])]
    return float(player["machines"]) * float(machine["kw"]) * (1.0 - efficiency_bonus) * cooling_overhead

func _hashrate_th() -> float:
    var machine: Dictionary = MACHINES[int(player["machine_tier"])]
    return float(player["machines"]) * float(machine["th"])

func _effective_power_cost() -> float:
    var energy: Dictionary = ENERGIES[int(player["energy_idx"])]
    var base: float = float(energy["price"])
    var name: String = String(energy["name"])
    if name == "Grid" or name == "Natural Gas":
        base *= energy_market_index
    base -= float(player["power_discount"])
    if bool(energy["clean"]) and bool(energy["offgrid"]):
        base -= 0.003 + float(player["clean_credit_bonus"])
    elif bool(energy["clean"]):
        base -= 0.0015 + float(player["clean_credit_bonus"])
    return maxf(0.018, base)

func _uptime() -> float:
    var energy: Dictionary = ENERGIES[int(player["energy_idx"])]
    var cooling_bonus: float = [0.0, 0.012, 0.020][int(player["cooling_level"])]
    return clampf(0.955 + float(energy["reliability"]) + cooling_bonus, 0.80, 0.997)

func _btc_per_day() -> float:
    if network_hashrate_th <= 0.0:
        return 0.0
    return (_hashrate_th() / network_hashrate_th) * 144.0 * (block_subsidy_btc + average_fees_btc) * _uptime()

func _asset_value() -> float:
    var machine: Dictionary = MACHINES[int(player["machine_tier"])]
    var machine_book: float = float(player["machines"]) * float(machine["price"]) * 0.70
    var sats_value: float = float(player["sats"]) / SATS_PER_BTC * btc_price
    var land_value: float = float(player["acres"]) * land_price_per_acre
    var mw_value: float = float(player["mw"]) * 90000.0
    var tech_value: float = float(player["chip_level"]) * 500000.0
    return maxf(0.0, float(player["cash"])) + sats_value + machine_book + land_value + mw_value + tech_value

func _eligible_lender() -> Dictionary:
    var assets: float = _asset_value()
    var best: Dictionary = {}
    for raw_tier in Profiles.LOAN_TIERS:
        var tier: Dictionary = raw_tier
        if assets >= float(tier["min_assets"]):
            best = tier
    return best

func _loan_rate(offer: Dictionary) -> float:
    var spread: float = float(offer["spread"]) - float(player["lender_spread_discount"])
    return clampf(federal_rate + maxf(0.0025, spread), 0.02, 0.30)

func _loan_room() -> float:
    var offer: Dictionary = _eligible_lender()
    if offer.is_empty():
        return 0.0
    var ltv: float = minf(0.72, float(offer["ltv"]) + float(player["loan_bonus"])
    )
    var capacity: float = minf(float(offer["cap"]), _asset_value() * ltv)
    return maxf(0.0, capacity - float(player["debt"]))

func _buy_machines() -> void:
    var machine: Dictionary = MACHINES[int(player["machine_tier"])]
    var discount: float = clampf(float(player["machine_discount"]), 0.0, 0.25)
    var cost: float = float(machine["price"]) * 10.0 * (1.0 - discount)
    var extra_kw: float = float(machine["kw"]) * 10.0 * 1.06
    if float(player["cash"]) < cost:
        _feedback("Not enough cash. Need $%d for 10 × %s." % [int(cost), String(machine["name"])])
        return
    if _machine_load_kw() + extra_kw > float(player["mw"]) * 1000.0:
        _feedback("Not enough energized MW. Visit Gridline Power Office first.")
        return
    player["cash"] = float(player["cash"]) - cost
    player["machines"] = int(player["machines"]) + 10
    _feedback("Installed 10 × %s for $%d." % [String(machine["name"]), int(cost)])

func _upgrade_machine_tier() -> void:
    var tier: int = int(player["machine_tier"])
    if tier >= MACHINES.size() - 1:
        _feedback("Top machine platform is already unlocked.")
        return
    var costs: Array = [18000.0, 85000.0, 220000.0, 650000.0]
    var cost: float = float(costs[tier])
    if float(player["cash"]) < cost:
        _feedback("Need $%d for the next machine platform." % int(cost))
        return
    if tier == 3 and int(player["cooling_level"]) < 2:
        _feedback("Hydro-class miners require Hydro Cooling first.")
        return
    player["cash"] = float(player["cash"]) - cost
    player["machine_tier"] = tier + 1
    var machine: Dictionary = MACHINES[int(player["machine_tier"])]
    _feedback("Unlocked %s." % String(machine["name"]))

func _buy_power() -> void:
    var base_cost: float = 26000.0 + float(player["mw"]) * 42000.0
    var cost: float = base_cost * (1.0 - clampf(float(player["power_capex_discount"]), 0.0, 0.30))
    if float(player["cash"]) < cost:
        _feedback("Need $%d for +0.25 MW." % int(cost))
        return
    player["cash"] = float(player["cash"]) - cost
    player["mw"] = float(player["mw"]) + 0.25
    _feedback("Interconnect expanded to %.2f MW." % float(player["mw"]))

func _change_energy() -> void:
    var current: int = int(player["energy_idx"])
    var next_idx: int = (current + 1) % ENERGIES.size()
    var target: Dictionary = ENERGIES[next_idx]
    var name: String = String(target["name"])
    if name == "Utility PPA" and not bool(player["utility_access"]):
        _feedback("Utility PPA needs a Cascadia Utility District deal.")
        return
    if name == "Hydro" and not bool(player["hydro_access"]):
        _feedback("Hydro needs a BlueRiver Energy Authority deal.")
        return
    if name == "Solar + Storage" and float(player["acres"]) < 30.0:
        _feedback("Solar + Storage needs at least 30 acres.")
        return
    if name == "Nuclear PPA" and float(player["mw"]) < 10.0:
        _feedback("Nuclear PPA needs at least 10 MW of company scale.")
        return
    var capex: float = float(target["capex"])
    if float(player["cash"]) < capex:
        _feedback("Need $%d energy-project capex for %s." % [int(capex), name])
        return
    player["cash"] = float(player["cash"]) - capex
    player["energy_idx"] = next_idx
    _feedback("Energy changed to %s. + %s - %s" % [name, String(target["adv"]), String(target["disadv"])])

func _take_loan() -> void:
    var offer: Dictionary = _eligible_lender()
    if offer.is_empty():
        _feedback("No lender yet. Grow company assets first.")
        return
    var room: float = _loan_room()
    if room < 5000.0:
        _feedback("No useful new borrowing room right now.")
        return
    var amount: float = minf(room, maxf(10000.0, _asset_value() * 0.15))
    var rate: float = _loan_rate(offer)
    var old_debt: float = float(player["debt"])
    var old_rate: float = float(player["debt_rate"])
    var new_debt: float = old_debt + amount
    var blended: float = rate
    if old_debt > 0.0 and old_rate > 0.0:
        blended = ((old_debt * old_rate) + (amount * rate)) / new_debt
    player["cash"] = float(player["cash"]) + amount
    player["debt"] = new_debt
    player["debt_rate"] = blended
    player["debt_source"] = String(offer["name"])
    _feedback("%s lent $%d at %.2f%%. Debt is now $%d." % [String(offer["name"]), int(amount), rate * 100.0, int(new_debt)])

func _repay_debt() -> void:
    var debt: float = float(player["debt"])
    if debt <= 0.0:
        _feedback("Your company has no debt.")
        return
    var available: float = maxf(0.0, float(player["cash"]) - 10000.0)
    if available < 1000.0:
        _feedback("Keep at least $10,000 operating cash before repaying debt.")
        return
    var payment: float = minf(debt, minf(available, maxf(5000.0, debt * 0.25)))
    player["cash"] = float(player["cash"]) - payment
    player["debt"] = debt - payment
    if float(player["debt"]) <= 0.01:
        player["debt"] = 0.0
        player["debt_rate"] = 0.0
        player["debt_source"] = "No lender"
    _feedback("Paid $%d of debt. Remaining: $%d." % [int(payment), int(player["debt"])])

func _sign_partner(partner_idx: int) -> void:
    var partner: Dictionary = PARTNERS[partner_idx]
    var partner_id: String = String(partner["id"])
    if signed_partners.has(partner_id):
        _feedback("That partnership is already active.")
        return
    var cost: float = float(partner["cost"])
    if float(player["cash"]) < cost:
        _feedback("Need $%d to strike this deal." % int(cost))
        return
    player["cash"] = float(player["cash"]) - cost
    signed_partners[partner_id] = true
    if partner_id == "utility":
        player["power_discount"] = float(player["power_discount"]) + 0.012
        player["utility_access"] = true
    elif partner_id == "land":
        player["acres"] = float(player["acres"]) + 10.0
        player["land_discount"] = 0.15
    elif partner_id == "infra":
        player["mw"] = float(player["mw"]) + 0.25
        player["power_capex_discount"] = 0.12
    elif partner_id == "semi":
        player["machines"] = int(player["machines"]) + 10
        player["machine_efficiency_bonus"] = 0.06
        player["machine_discount"] = 0.05
    elif partner_id == "finance":
        player["cash"] = float(player["cash"]) + 60000.0
        player["loan_bonus"] = float(player["loan_bonus"]) + 0.10
        player["lender_spread_discount"] = 0.01
    elif partner_id == "food":
        player["recurring_income"] = float(player["recurring_income"]) + 6000.0
    elif partner_id == "sports":
        player["recurring_income"] = float(player["recurring_income"]) + 10000.0
    elif partner_id == "energy":
        player["hydro_access"] = true
        player["clean_credit_bonus"] = 0.001
    elif partner_id == "treasury":
        player["sats"] = float(player["sats"]) + 20000000.0
    _feedback("DEAL SIGNED with %s. %s" % [String(partner["name"]), String(partner["boost"])])
    _open_partner(entities[selected_entity_idx])

func _merge_rival(rival_idx: int) -> void:
    if merger_used:
        _feedback("Your one merger has already been used.")
        return
    var rival: Dictionary = rivals[rival_idx]
    if bool(rival["merged"]):
        _feedback("That rival has already been absorbed.")
        return
    var rival_assets: float = float(rival["cash"]) + float(rival["sats"]) / SATS_PER_BTC * btc_price + float(rival["mw"]) * 90000.0 + float(rival["acres"]) * land_price_per_acre + float(rival["machines"]) * 700.0
    if rival_assets > _asset_value() * 1.25:
        _feedback("Merger rejected. Grow to at least about 80% of this rival's asset size first.")
        return
    var price: float = maxf(100000.0, rival_assets * 0.70)
    if float(player["cash"]) < price:
        _feedback("Need $%d cash to close this merger." % int(price))
        return
    player["cash"] = float(player["cash"]) - price + float(rival["cash"]) * 0.50
    player["sats"] = float(player["sats"]) + float(rival["sats"])
    player["mw"] = float(player["mw"]) + float(rival["mw"])
    player["acres"] = float(player["acres"]) + float(rival["acres"])
    player["machines"] = int(player["machines"]) + int(rival["machines"])
    rival["merged"] = true
    rivals[rival_idx] = rival
    merger_used = true
    _feedback("ONE-TIME MERGER CLOSED: %s joined your company for $%d." % [String(rival["name"]), int(price)])
    queue_redraw()

func _cycle_treasury() -> void:
    var holds: Array = [0.0, 0.30, 0.60, 1.0]
    var current: float = float(player["treasury_hold"])
    var idx: int = holds.find(current)
    if idx < 0:
        idx = 0
    player["treasury_hold"] = float(holds[(idx + 1) % holds.size()])
    _feedback("Treasury will hold %.0f%% of newly mined BTC." % (float(player["treasury_hold"]) * 100.0))

func _upgrade_cooling() -> void:
    var level: int = int(player["cooling_level"])
    if level >= 2:
        _feedback("Hydro Cooling is already installed.")
        return
    var costs: Array = [160000.0, 650000.0]
    var cost: float = float(costs[level])
    if float(player["cash"]) < cost:
        _feedback("Need $%d for the next cooling system." % int(cost))
        return
    player["cash"] = float(player["cash"]) - cost
    player["cooling_level"] = level + 1
    _feedback("Cooling upgraded to %s." % (["Air", "Immersion", "Hydro Cooling"][int(player["cooling_level"])]))

func _upgrade_chips() -> void:
    var level: int = int(player["chip_level"])
    if level >= 3:
        _feedback("Captive chip manufacturing is already online.")
        return
    var costs: Array = [150000.0, 700000.0, 4000000.0]
    var names: Array = ["Strategic wafer deal", "Co-designed silicon", "Captive chip manufacturing"]
    var cost: float = float(costs[level])
    if float(player["cash"]) < cost:
        _feedback("Need $%d for %s." % [int(cost), String(names[level])])
        return
    player["cash"] = float(player["cash"]) - cost
    player["chip_level"] = level + 1
    player["machine_discount"] = maxf(float(player["machine_discount"]), [0.06, 0.12, 0.22][level])
    _feedback("Chip strategy advanced to %s." % String(names[level]))

func _feedback(message: String) -> void:
    dialog_text.text = message
    _refresh_ui()

func _end_quarter() -> void:
    if campaign_complete:
        _feedback("Campaign complete. Start a new campaign from the setup menu.")
        return
    var mined_btc: float = _btc_per_day() * QUARTER_DAYS
    var mined_sats: float = mined_btc * SATS_PER_BTC
    var held_sats: float = mined_sats * float(player["treasury_hold"])
    var sold_btc: float = mined_btc * (1.0 - float(player["treasury_hold"]))
    var revenue: float = sold_btc * btc_price + float(player["recurring_income"])
    var power_cost: float = _machine_load_kw() * 24.0 * QUARTER_DAYS * _effective_power_cost() * _uptime()
    var ops_cost: float = float(player["machines"]) * 0.38 * QUARTER_DAYS
    var debt_cost: float = float(player["debt"]) * float(player["debt_rate"]) * (QUARTER_DAYS / 365.0)
    var profit: float = revenue - power_cost - ops_cost - debt_cost
    player["sats"] = float(player["sats"]) + held_sats
    player["cash"] = float(player["cash"]) + profit
    player["last_profit"] = profit

    _simulate_rivals()
    var settled_turn: int = turn
    var halving_happened: bool = settled_turn % HALVING_TURNS == 0
    if halving_happened:
        block_subsidy_btc *= 0.5
    var market_note: String = _advance_market(halving_happened)

    if settled_turn >= campaign_turns:
        campaign_complete = true
        quarter_button.disabled = true
        quarter_button.text = "CAMPAIGN COMPLETE"
        _open_message("CAMPAIGN COMPLETE", "Finished %d turns. Final assets $%d • cash $%d • machines %d • %.2f MW • %.1f acres. %s" % [campaign_turns, int(_asset_value()), int(player["cash"]), int(player["machines"]), float(player["mw"]), float(player["acres"]), market_note])
        _refresh_ui()
        return

    turn += 1
    var note: String = "Quarter %d closed: mined %d sats • held %d • cash result $%d. %s" % [settled_turn, int(mined_sats), int(held_sats), int(profit), market_note]
    if halving_happened:
        note += " HALVING: subsidy is now %.4f BTC." % block_subsidy_btc
    _open_message("QUARTER SETTLEMENT", note)
    _refresh_ui()
    queue_redraw()

func _simulate_rivals() -> void:
    for i in range(rivals.size()):
        var rival: Dictionary = rivals[i]
        if bool(rival["merged"]):
            continue
        rival["cash"] = float(rival["cash"]) * randf_range(0.96, 1.08)
        if randf() < 0.55:
            rival["machines"] = int(rival["machines"]) + randi_range(5, 25)
        if randf() < 0.25:
            rival["mw"] = float(rival["mw"]) + 0.25
        if randf() < 0.16:
            rival["acres"] = float(rival["acres"]) + 5.0
        rivals[i] = rival

func _advance_market(halving_happened: bool) -> String:
    var rate_move: float = randf_range(-0.0035, 0.0035)
    if randf() < 0.12:
        rate_move += randf_range(-0.005, 0.005)
    federal_rate = clampf(federal_rate + rate_move, 0.005, 0.085)
    var rate_headwind: float = maxf(-0.02, federal_rate - 0.04)
    var btc_return: float = randf_range(-0.12, 0.18) - rate_headwind * 0.90
    var land_return: float = randf_range(-0.025, 0.040) - rate_headwind * 0.35
    btc_price = maxf(8000.0, btc_price * maxf(0.72, 1.0 + btc_return))
    land_price_per_acre = maxf(1800.0, land_price_per_acre * maxf(0.80, 1.0 + land_return))
    energy_market_index = clampf(energy_market_index * randf_range(0.94, 1.07), 0.72, 1.45)
    network_hashrate_th *= randf_range(0.985, 1.075)
    average_fees_btc = clampf(average_fees_btc * randf_range(0.72, 1.38), 0.04, 0.85)
    var note: String = "Fed %.2f%% • BTC $%d • land $%d/acre." % [federal_rate * 100.0, int(btc_price), int(land_price_per_acre)]
    last_market_event = "Normal market"
    if halving_happened:
        halvings_since_crash += 1
        var crash_due: bool = halvings_since_crash >= 3 or (halvings_since_crash >= 2 and randf() < 0.55)
        if crash_due:
            note += " " + _trigger_rare_crash()
            halvings_since_crash = 0
    return note

func _trigger_rare_crash() -> String:
    if randf() < 0.5:
        btc_price = maxf(6000.0, btc_price * randf_range(0.45, 0.62))
        land_price_per_acre = maxf(1500.0, land_price_per_acre * randf_range(0.92, 0.98))
        federal_rate = maxf(0.005, federal_rate - 0.010)
        last_market_event = "DOT-COM-STYLE TECH CRASH"
        return "%s: BTC took the main hit." % last_market_event
    land_price_per_acre = maxf(1500.0, land_price_per_acre * randf_range(0.60, 0.76))
    btc_price = maxf(6000.0, btc_price * randf_range(0.84, 0.95))
    energy_market_index = minf(1.55, energy_market_index * 1.12)
    federal_rate = maxf(0.005, federal_rate - 0.0075)
    last_market_event = "COVID-STYLE PROPERTY / LOGISTICS CRASH"
    return "%s: land took the main hit." % last_market_event

func _refresh_ui() -> void:
    var year: int = int((turn - 1) / TURNS_PER_YEAR) + 1
    var quarter: int = ((turn - 1) % TURNS_PER_YEAR) + 1
    var energy: Dictionary = ENERGIES[int(player["energy_idx"])]
    top_stats.text = "%s  |  Y%d Q%d  |  TURN %d/%d  |  Cash $%d  |  SATS %d" % [String(player["name"]), year, quarter, turn, campaign_turns, int(player["cash"]), int(player["sats"])]
    company_stats.text = "Strength: %s\n\nMachines: %d  •  %.2f PH/s\nPower: %.2f MW  •  load %.3f MW\nEnergy: %s  •  $%.3f/kWh\nLand: %.1f acres\nCooling: %s\nChip level: %d\n\nAssets: $%d\nDebt: $%d @ %.2f%%\nLender: %s\nPartners: %d/%d\nMerger: %s" % [
        String(player["strengths"]), int(player["machines"]), _hashrate_th() / 1000.0, float(player["mw"]), _machine_load_kw() / 1000.0,
        String(energy["name"]), _effective_power_cost(), float(player["acres"]), ["Air", "Immersion", "Hydro Cooling"][int(player["cooling_level"])],
        int(player["chip_level"]), int(_asset_value()), int(player["debt"]), float(player["debt_rate"]) * 100.0, String(player["debt_source"]),
        signed_partners.size(), PARTNERS.size(), "USED" if merger_used else "AVAILABLE ONCE"
    ]
    var halving_in: int = HALVING_TURNS - ((turn - 1) % HALVING_TURNS)
    market_label.text = "MARKET  BTC $%d  •  Land $%d/ac  •  Fed %.2f%%  •  Network %.0f EH/s  •  Subsidy %.4f BTC  •  Halving in %d turn%s  •  %s" % [
        int(btc_price), int(land_price_per_acre), federal_rate * 100.0, network_hashrate_th / 1000000.0, block_subsidy_btc,
        halving_in, "" if halving_in == 1 else "s", last_market_event
    ]

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), GRASS, true)
    _draw_world_grid()
    _draw_roads()
    _draw_decorations()
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        _draw_entity(entity, i)
    _draw_rep()
    draw_string(ThemeDB.fallback_font, Vector2(1080.0, 300.0), "HASH RACE TECH DISTRICT", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("b6f7ff"))
    draw_string(ThemeDB.fallback_font, Vector2(1080.0, 336.0), "WALK • TALK • DEAL • BUILD • ADVANCE TURN", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("6da7b2"))

func _draw_world_grid() -> void:
    for x in range(0, int(WORLD_SIZE.x), 64):
        draw_line(Vector2(float(x), 0.0), Vector2(float(x), WORLD_SIZE.y), Color("143630"), 1.0)
    for y in range(0, int(WORLD_SIZE.y), 64):
        draw_line(Vector2(0.0, float(y)), Vector2(WORLD_SIZE.x, float(y)), Color("143630"), 1.0)

func _draw_roads() -> void:
    draw_rect(Rect2(120.0, 890.0, 2760.0, 190.0), ROAD, true)
    draw_rect(Rect2(1380.0, 360.0, 240.0, 1320.0), ROAD, true)
    draw_rect(Rect2(360.0, 380.0, 2280.0, 150.0), ROAD.darkened(0.10), true)
    draw_rect(Rect2(360.0, 1450.0, 2280.0, 150.0), ROAD.darkened(0.10), true)
    for x in range(160, 2850, 110):
        draw_line(Vector2(float(x), 985.0), Vector2(float(x + 55), 985.0), Color("8c9ba0"), 3.0)
    for y in range(390, 1650, 100):
        draw_line(Vector2(1500.0, float(y)), Vector2(1500.0, float(y + 48)), Color("8c9ba0"), 3.0)

func _draw_decorations() -> void:
    for x in range(260, 2820, 180):
        draw_circle(Vector2(float(x), 250.0 + float((x / 180) % 2) * 35.0), 18.0, Color("1d5946"))
        draw_circle(Vector2(float(x), 1770.0 - float((x / 180) % 2) * 35.0), 18.0, Color("1d5946"))
    draw_rect(Rect2(2070.0, 250.0, 520.0, 90.0), Color("174258"), true)
    draw_string(ThemeDB.fallback_font, Vector2(2160.0, 305.0), "RIVER / HYDRO CORRIDOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("74d8ff"))

func _draw_entity(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var kind: String = String(entity["kind"])
    var body_color: Color = Color("17333d")
    var roof_color: Color = CYAN.darkened(0.45)
    if kind == "hq":
        body_color = Color("173a29")
        roof_color = GREEN.darkened(0.30)
    elif kind == "bank":
        body_color = Color("3a3020")
        roof_color = ORANGE.darkened(0.25)
    elif kind == "machines":
        body_color = Color("2f2540")
        roof_color = Color("be8cff")
    elif kind == "power":
        body_color = Color("3b3320")
        roof_color = Color("ffd36e")
    elif kind == "partner":
        body_color = Color("15313a")
        roof_color = Color("60c8dc")
    elif kind == "rival":
        body_color = Color("341e27")
        roof_color = RED.darkened(0.15)
        var rival_idx: int = int(entity["rival_idx"])
        if bool(rivals[rival_idx]["merged"]):
            body_color = Color("1b1b1b")
            roof_color = Color("555555")
    if idx == selected_entity_idx:
        draw_circle(pos, 114.0, GREEN, false, 4.0)
    draw_rect(Rect2(pos - Vector2(92.0, 66.0), Vector2(184.0, 118.0)), body_color, true)
    draw_colored_polygon(PackedVector2Array([pos + Vector2(-106.0, -66.0), pos + Vector2(0.0, -112.0), pos + Vector2(106.0, -66.0)]), roof_color)
    draw_rect(Rect2(pos + Vector2(-18.0, 8.0), Vector2(36.0, 44.0)), Color("071018"), true)
    draw_rect(Rect2(pos + Vector2(-68.0, -20.0), Vector2(32.0, 26.0)), Color("9ddceb"), true)
    draw_rect(Rect2(pos + Vector2(36.0, -20.0), Vector2(32.0, 26.0)), Color("9ddceb"), true)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-108.0, 82.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 216.0, 12, WHITE)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-108.0, 100.0), String(entity["subtitle"]), HORIZONTAL_ALIGNMENT_CENTER, 216.0, 10, roof_color)

func _draw_rep() -> void:
    draw_circle(rep_pos, 18.0, Color("071018"))
    draw_circle(rep_pos + Vector2(0.0, -10.0), 10.0, Color("d6a77f"))
    draw_rect(Rect2(rep_pos + Vector2(-10.0, 0.0), Vector2(20.0, 25.0)), GREEN, true)
    draw_line(rep_pos + Vector2(-8.0, 24.0), rep_pos + Vector2(-11.0, 38.0), WHITE, 4.0)
    draw_line(rep_pos + Vector2(8.0, 24.0), rep_pos + Vector2(11.0, 38.0), WHITE, 4.0)
    draw_string(ThemeDB.fallback_font, rep_pos + Vector2(-54.0, -31.0), "COMPANY REP", HORIZONTAL_ALIGNMENT_CENTER, 108.0, 10, GREEN)

func debug_world_ready() -> bool:
    return not player.is_empty() and entities.size() >= 20 and is_instance_valid(camera)

func debug_entity_count() -> int:
    return entities.size()

func debug_has_dialogue_ui() -> bool:
    return is_instance_valid(dialog_panel) and is_instance_valid(dialog_title) and is_instance_valid(action_row)

func debug_player_company() -> String:
    return String(player.get("name", ""))
