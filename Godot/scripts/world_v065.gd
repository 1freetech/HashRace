extends "res://scripts/world_v059.gd"

# Hash Race v0.065 energy-campus and deployment pass.
# Adds a visible mining-energy yard, buy/deploy energy sources, animated power
# flow, average-output grid simulation, thermal feedback, and warehouse-vs-live
# infrastructure separation without cluttering the map with permanent labels.

const ENERGY_VISUAL_REVISION: int = 1
const ENERGY_DETAIL_RADIUS: float = 920.0
const ENERGY_GREEN := Color("39ff75")
const ENERGY_YELLOW := Color("ffd05a")
const ENERGY_RED := Color("ff6b6b")
const ENERGY_BLUE := Color("55b8ff")
const ENERGY_DARK := Color("0a1519")
const ENERGY_STEEL := Color("43555d")
const SOLAR_BLUE := Color("2f67a8")
const SOLAR_HI := Color("70c9ff")
const WIND_WHITE := Color("d8e3e5")
const COAL_DARK := Color("24282a")
const OIL_ORANGE := Color("c77731")
const NUCLEAR_CYAN := Color("70f1d2")

var energy_button: Button
var energy_status_label: Label
var energy_anim_phase: float = 0.0
var energy_redraw_accum: float = 0.0
var energy_market_note: String = ""

func _ready() -> void:
    super._ready()
    _install_energy_controls()
    infrastructure_inventory.inventory_changed.connect(_on_infrastructure_state_changed)
    infrastructure_inventory.deployment_changed.connect(_on_infrastructure_state_changed)
    set_meta("hashrace_energy_visual_revision", ENERGY_VISUAL_REVISION)
    queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)
    energy_anim_phase = fmod(energy_anim_phase + delta, TAU * 100.0)
    energy_redraw_accum += delta
    if energy_redraw_accum >= 0.12:
        energy_redraw_accum = 0.0
        _refresh_energy_status()
        queue_redraw()

func _install_energy_controls() -> void:
    if inventory_button == null:
        return
    var parent: Node = inventory_button.get_parent()

    energy_button = Button.new()
    energy_button.name = "EnergyMarketButton"
    energy_button.position = Vector2(1238.0, 88.0)
    energy_button.size = Vector2(124.0, 42.0)
    energy_button.text = "ENERGY"
    energy_button.tooltip_text = "Buy and deploy generation that adds usable site power."
    energy_button.add_theme_font_size_override("font_size", 11)
    energy_button.pressed.connect(_open_energy_market)
    parent.add_child(energy_button)

    energy_status_label = Label.new()
    energy_status_label.name = "EnergyStatus"
    energy_status_label.position = Vector2(1030.0, 136.0)
    energy_status_label.size = Vector2(332.0, 24.0)
    energy_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    energy_status_label.add_theme_font_size_override("font_size", 11)
    energy_status_label.add_theme_color_override("font_color", ENERGY_GREEN)
    parent.add_child(energy_status_label)
    _refresh_energy_status()

func _on_infrastructure_state_changed() -> void:
    _refresh_energy_status()
    _refresh_ui()
    queue_redraw()

func _refresh_energy_status() -> void:
    if energy_status_label == null or player.is_empty():
        return
    var load_mw: float = _machine_load_kw() / 1000.0
    var available_mw: float = _effective_available_mw()
    var temp_c: float = _facility_temperature_c()
    var stability: float = _grid_stability_ratio()
    energy_status_label.text = "PWR %.1f / %.1f MW   |   %.0f C" % [load_mw, available_mw, temp_c]
    var status_color: Color = ENERGY_GREEN
    if stability < 1.0 or temp_c >= 60.0:
        status_color = ENERGY_YELLOW
    if stability < 0.85 or temp_c >= 78.0:
        status_color = ENERGY_RED
    energy_status_label.add_theme_color_override("font_color", status_color)

func _hashrate_th() -> float:
    return super._hashrate_th() + infrastructure_inventory.total_deployed_hashrate_ph() * 1000.0

func _machine_load_kw() -> float:
    var load_kw: float = super._machine_load_kw() + infrastructure_inventory.total_deployed_miner_load_mw() * 1000.0
    var efficiency_multiplier: float = clampf(float(player.get("inventory_efficiency_multiplier", 1.0)), 0.70, 1.0)
    return load_kw * efficiency_multiplier

func _effective_power_cost() -> float:
    var base: float = super._effective_power_cost()
    var legacy_discount: float = float(player.get("inventory_power_discount", 0.0))
    return maxf(0.012, base + legacy_discount + infrastructure_inventory.deployed_power_cost_delta())

func _uptime() -> float:
    var base: float = super._uptime() + infrastructure_inventory.deployed_uptime_bonus()
    var grid_penalty: float = maxf(0.0, 1.0 - _grid_stability_ratio()) * 0.10
    var temp_c: float = _facility_temperature_c()
    var thermal_penalty: float = 0.0
    if temp_c > 60.0:
        thermal_penalty = minf(0.08, (temp_c - 60.0) * 0.003)
    return clampf(base - grid_penalty - thermal_penalty, 0.72, 0.999)

func _effective_available_mw() -> float:
    var nominal_inventory_mw: float = infrastructure_inventory.nominal_energy_capacity_mw()
    var base_grid_mw: float = maxf(0.0, float(player.get("mw", 0.0)) - nominal_inventory_mw)
    return base_grid_mw + infrastructure_inventory.current_energy_output_mw()

func _grid_stability_ratio() -> float:
    var load_mw: float = _machine_load_kw() / 1000.0
    if load_mw <= 0.001:
        return 1.0
    return clampf(_effective_available_mw() / load_mw, 0.0, 1.0)

func _facility_temperature_c() -> float:
    var base_heat_mw: float = (super._machine_load_kw() / 1000.0) * 0.92
    var inventory_heat_mw: float = infrastructure_inventory.total_deployed_heat_mw()
    var built_in_cooling: float = [0.20, 0.85, 1.45][int(player.get("cooling_level", 0))]
    var cooling_mw: float = built_in_cooling + infrastructure_inventory.total_cooling_capacity_mw()
    var excess_heat_mw: float = maxf(0.0, base_heat_mw + inventory_heat_mw - cooling_mw)
    return clampf(25.0 + excess_heat_mw * 5.2, 25.0, 95.0)

func _open_infrastructure_inventory() -> void:
    var lines: Array[String] = []
    var categories: Array[String] = ["MINERS", "POWER", "ENERGY", "COOLING", "FACILITY", "NETWORK", "MAINTENANCE", "RESILIENCE", "STRATEGIC"]
    for category in categories:
        var available: Array[Dictionary] = infrastructure_inventory.by_category(category)
        if available.is_empty():
            continue
        lines.append("\n" + category)
        for prototype in available:
            var id: String = String(prototype["id"])
            var owned_count: int = infrastructure_inventory.quantity(id)
            var deployed_count: int = infrastructure_inventory.deployed_quantity(id)
            var stored_count: int = infrastructure_inventory.stored_quantity(id)
            lines.append("%s  O:%d D:%d W:%d  |  $%d  |  %s %s" % [String(prototype["name"]), owned_count, deployed_count, stored_count, int(prototype["price"]), String(prototype["effect"]), String(prototype["unit"])])
    dialog_title.text = "INFRASTRUCTURE // WAREHOUSE VS DEPLOYED"
    dialog_text.text = "Only deployed equipment changes live hashrate, MW, cooling, uptime, or operating cost. W = warehouse stock. D = deployed.\n" + "\n".join(lines)
    _set_actions([{"label":"ENERGY MARKET", "call":Callable(self, "_open_energy_market")}])

func _open_energy_market() -> void:
    _open_energy_page(["solar_array", "wind_farm", "gas_turbine"], true)

func _open_energy_market_more() -> void:
    _open_energy_page(["hydro_turbine", "oil_field", "coal_plant", "nuclear_smr"], false)

func _open_energy_page(ids: Array[String], first_page: bool) -> void:
    var lines: Array[String] = []
    if not energy_market_note.is_empty():
        lines.append(energy_market_note)
        lines.append("")
    lines.append("Cash $%d" % int(player.get("cash", 0.0)))
    lines.append("Load %.1f MW  |  Available %.1f MW  |  Grid %.0f%%  |  Thermal %.0f C" % [_machine_load_kw() / 1000.0, _effective_available_mw(), _grid_stability_ratio() * 100.0, _facility_temperature_c()])
    lines.append("")
    lines.append("BUY + DEPLOY adds the source to the visible energy yard and to live site capacity. Average output reflects capacity factor; solar and wind are less firm than gas, hydro, coal, or SMR.")
    lines.append("")

    var actions: Array = []
    for item_id in ids:
        var prototype: Dictionary = infrastructure_inventory.item(item_id)
        if prototype.is_empty():
            continue
        var mw: float = float(prototype.get("energy_output_mw", 0.0))
        var cf: float = float(prototype.get("capacity_factor", 1.0))
        lines.append("%s  |  %.0f MW nameplate  |  %.0f%% avg  |  $%d  |  D:%d" % [String(prototype["name"]), mw, cf * 100.0, int(prototype["price"]), infrastructure_inventory.deployed_quantity(item_id)])
        actions.append({"label":_energy_action_label(item_id, mw), "call":Callable(self, "_buy_and_deploy_energy").bind(item_id)})

    if first_page:
        actions.append({"label":"MORE SOURCES", "call":Callable(self, "_open_energy_market_more")})
    else:
        actions.append({"label":"BACK", "call":Callable(self, "_open_energy_market")})

    dialog_title.text = "ENERGY MARKET // OWN + DEPLOY GENERATION"
    dialog_text.text = "\n".join(lines)
    _set_actions(actions)

func _energy_action_label(item_id: String, mw: float) -> String:
    match item_id:
        "solar_array": return "SOLAR %.0f MW" % mw
        "wind_farm": return "WIND %.0f MW" % mw
        "gas_turbine": return "GAS %.0f MW" % mw
        "hydro_turbine": return "HYDRO %.0f MW" % mw
        "oil_field": return "OIL %.0f MW" % mw
        "coal_plant": return "COAL %.0f MW" % mw
        "nuclear_smr": return "SMR %.0f MW" % mw
        _: return "BUY %.0f MW" % mw

func _buy_and_deploy_energy(item_id: String) -> void:
    var prototype: Dictionary = infrastructure_inventory.item(item_id)
    if prototype.is_empty():
        energy_market_note = "Unknown energy asset."
        _open_energy_market()
        return
    var cost: float = float(prototype["price"])
    if float(player.get("cash", 0.0)) < cost:
        energy_market_note = "Not enough cash for %s." % String(prototype["name"])
        _open_energy_market()
        return
    if infrastructure_inventory.purchase_and_deploy(item_id, player, 1):
        energy_market_note = "DEPLOYED: %s. Site nameplate capacity increased." % String(prototype["name"])
    else:
        energy_market_note = "Deployment failed. Check inventory and site state."
    _refresh_ui()
    _refresh_energy_status()
    queue_redraw()
    if item_id in ["hydro_turbine", "oil_field", "coal_plant", "nuclear_smr"]:
        _open_energy_market_more()
    else:
        _open_energy_market()

func _draw_world_props_pixel() -> void:
    super._draw_world_props_pixel()
    if player.is_empty() or town_zones.is_empty():
        return
    var origin: Vector2 = _energy_campus_origin()
    if rep_pos.distance_to(origin) > ENERGY_DETAIL_RADIUS:
        return
    _draw_energy_campus(origin)

func _player_hq_center() -> Vector2:
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        if bool(zone.get("player", false)):
            return zone["center"]
    return entities[0]["pos"] if not entities.is_empty() else Vector2(1500.0, 950.0)

func _energy_campus_origin() -> Vector2:
    var hq: Vector2 = _player_hq_center()
    var candidates: Array[Vector2] = [
        hq + Vector2(360.0, 230.0), hq + Vector2(-360.0, 230.0),
        hq + Vector2(360.0, -230.0), hq + Vector2(-360.0, -230.0)
    ]
    var best: Vector2 = candidates[0]
    var best_score: float = -1.0
    for raw_candidate in candidates:
        var candidate: Vector2 = raw_candidate
        candidate.x = clampf(candidate.x, 220.0, WORLD_SIZE.x - 220.0)
        candidate.y = clampf(candidate.y, 180.0, WORLD_SIZE.y - 180.0)
        var nearest: float = 99999.0
        for raw_entity in entities:
            var entity: Dictionary = raw_entity
            var kind: String = String(entity.get("kind", ""))
            if kind == "partner_rep" or kind == "rival_rep":
                continue
            nearest = minf(nearest, candidate.distance_to(Vector2(entity.get("pos", Vector2.ZERO))))
        if nearest > best_score:
            best_score = nearest
            best = candidate
    return VisualStack.snap_to_pixel(best)

func _draw_energy_campus(origin: Vector2) -> void:
    var pad := Rect2(origin + Vector2(-176.0, -106.0), Vector2(352.0, 212.0))
    draw_rect(Rect2(pad.position + Vector2(5.0, 7.0), pad.size), Color(0.01, 0.02, 0.025, 0.46), true)
    draw_rect(pad, Color("25363b"), true)
    draw_rect(Rect2(pad.position + Vector2(4.0, 4.0), pad.size - Vector2(8.0, 8.0)), Color("172a27"), true)
    for x in range(0, 12):
        var px: float = pad.position.x + 8.0 + float(x) * 30.0
        draw_rect(Rect2(px, pad.position.y - 5.0, 2.0, 9.0), Color("718087"), true)
        draw_rect(Rect2(px, pad.end.y - 4.0, 2.0, 9.0), Color("718087"), true)
    draw_line(pad.position + Vector2(6.0, 2.0), Vector2(pad.end.x - 6.0, pad.position.y + 2.0), Color("4d5f65"), 2.0)
    draw_line(Vector2(pad.position.x + 6.0, pad.end.y - 2.0), pad.end - Vector2(6.0, 2.0), Color("4d5f65"), 2.0)

    var hq: Vector2 = _player_hq_center()
    _draw_energy_power_flow(origin, hq)
    _draw_substation(origin + Vector2(-126.0, -58.0))
    _draw_current_energy_feed(origin + Vector2(-86.0, 42.0))

    var visuals: Array[Dictionary] = [
        {"id":"solar_array", "pos":origin + Vector2(42.0, -58.0), "type":"solar"},
        {"id":"wind_farm", "pos":origin + Vector2(124.0, -52.0), "type":"wind"},
        {"id":"gas_turbine", "pos":origin + Vector2(38.0, 40.0), "type":"gas"},
        {"id":"hydro_turbine", "pos":origin + Vector2(112.0, 42.0), "type":"hydro"},
        {"id":"oil_field", "pos":origin + Vector2(38.0, 78.0), "type":"oil"},
        {"id":"coal_plant", "pos":origin + Vector2(104.0, 78.0), "type":"coal"},
        {"id":"nuclear_smr", "pos":origin + Vector2(146.0, 36.0), "type":"smr"}
    ]
    for entry in visuals:
        var count: int = infrastructure_inventory.deployed_quantity(String(entry["id"]))
        if count <= 0:
            continue
        _draw_energy_source_icon(String(entry["type"]), entry["pos"], count)

    var battery_count: int = infrastructure_inventory.deployed_quantity("battery")
    if battery_count > 0:
        _draw_battery_bank(origin + Vector2(-132.0, 60.0), battery_count)

    var cooling_count: int = infrastructure_inventory.deployed_visual_count("cooling")
    if cooling_count > 0:
        _draw_cooling_skid(origin + Vector2(-34.0, -66.0), cooling_count)

    _draw_heat_exhaust(origin + Vector2(-12.0, -78.0))

func _draw_current_energy_feed(pos: Vector2) -> void:
    var energy_name: String = String(ENERGIES[int(player.get("energy_idx", 0))]["name"])
    match energy_name:
        "Natural Gas": _draw_gas_unit(pos, false)
        "Hydro": _draw_hydro_unit(pos)
        "Solar + Storage":
            _draw_solar_unit(pos)
            _draw_battery_bank(pos + Vector2(0.0, 35.0), 1)
        "Nuclear PPA": _draw_smr_unit(pos)
        _:
            _draw_grid_feed(pos)

func _draw_energy_source_icon(kind: String, pos: Vector2, count: int) -> void:
    match kind:
        "solar": _draw_solar_unit(pos)
        "wind": _draw_wind_unit(pos)
        "gas": _draw_gas_unit(pos, true)
        "hydro": _draw_hydro_unit(pos)
        "oil": _draw_oil_unit(pos)
        "coal": _draw_coal_unit(pos)
        "smr": _draw_smr_unit(pos)
    if count > 1:
        _draw_count_ticks(pos + Vector2(-12.0, 24.0), mini(count, 6), ENERGY_GREEN)

func _draw_grid_feed(pos: Vector2) -> void:
    draw_rect(Rect2(pos + Vector2(-18.0, -14.0), Vector2(36.0, 28.0)), Color("304047"), true)
    draw_rect(Rect2(pos + Vector2(-14.0, -10.0), Vector2(28.0, 20.0)), Color("56666d"), true)
    for i in range(3):
        var x: float = pos.x - 10.0 + float(i) * 10.0
        draw_line(Vector2(x, pos.y - 10.0), Vector2(x, pos.y - 23.0), Color("c7d3d5"), 2.0)
        draw_circle(Vector2(x, pos.y - 24.0), 2.0, ENERGY_YELLOW)

func _draw_substation(pos: Vector2) -> void:
    draw_rect(Rect2(pos + Vector2(-25.0, -24.0), Vector2(50.0, 48.0)), Color("1c272c"), true)
    for i in range(3):
        var x: float = pos.x - 16.0 + float(i) * 16.0
        draw_rect(Rect2(x - 5.0, pos.y - 8.0, 10.0, 25.0), ENERGY_STEEL, true)
        draw_line(Vector2(x, pos.y - 8.0), Vector2(x, pos.y - 20.0), Color("d7e0e1"), 2.0)
        draw_circle(Vector2(x, pos.y - 21.0), 2.0, ENERGY_YELLOW)
    draw_rect(Rect2(pos + Vector2(-19.0, 15.0), Vector2(38.0, 3.0)), ENERGY_GREEN.darkened(0.35), true)

func _draw_solar_unit(pos: Vector2) -> void:
    var sunlight: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(energy_anim_phase * 0.22))
    for row in range(2):
        for col in range(3):
            var p: Vector2 = pos + Vector2(float(col) * 17.0 - 17.0, float(row) * 14.0 - 8.0)
            draw_rect(Rect2(p + Vector2(-7.0, -5.0), Vector2(14.0, 10.0)), Color("111a25"), true)
            draw_rect(Rect2(p + Vector2(-6.0, -4.0), Vector2(12.0, 8.0)), SOLAR_BLUE.lerp(SOLAR_HI, sunlight * 0.55), true)
            draw_line(p + Vector2(0.0, -4.0), p + Vector2(0.0, 4.0), Color("9dd8ff"), 1.0)
            draw_line(p + Vector2(-6.0, 0.0), p + Vector2(6.0, 0.0), Color("17365f"), 1.0)

func _draw_wind_unit(pos: Vector2) -> void:
    var hub := pos + Vector2(0.0, -8.0)
    draw_line(pos + Vector2(0.0, 20.0), hub, ENERGY_STEEL, 4.0)
    draw_circle(hub, 3.0, WIND_WHITE)
    var angle: float = energy_anim_phase * 2.2
    for blade in range(3):
        var a: float = angle + float(blade) * TAU / 3.0
        var tip := hub + Vector2(cos(a), sin(a)) * 17.0
        draw_line(hub, tip, WIND_WHITE, 3.0)

func _draw_gas_unit(pos: Vector2, live: bool) -> void:
    draw_rect(Rect2(pos + Vector2(-21.0, -11.0), Vector2(42.0, 24.0)), Color("4c5556"), true)
    draw_rect(Rect2(pos + Vector2(-17.0, -7.0), Vector2(28.0, 15.0)), Color("28343a"), true)
    draw_rect(Rect2(pos + Vector2(12.0, -18.0), Vector2(6.0, 25.0)), Color("6a7375"), true)
    if live:
        var pulse: float = 0.45 + 0.35 * sin(energy_anim_phase * 4.0)
        draw_circle(pos + Vector2(15.0, -21.0), 3.0 + pulse, Color(1.0, 0.45, 0.15, 0.55))
    draw_circle(pos + Vector2(-12.0, 0.0), 5.0, ENERGY_DARK)
    draw_circle(pos + Vector2(-12.0, 0.0), 3.0, ENERGY_BLUE)

func _draw_hydro_unit(pos: Vector2) -> void:
    draw_rect(Rect2(pos + Vector2(-20.0, -10.0), Vector2(40.0, 24.0)), Color("3d5964"), true)
    draw_rect(Rect2(pos + Vector2(-15.0, -5.0), Vector2(30.0, 14.0)), Color("233740"), true)
    draw_circle(pos, 8.0, Color("13252d"))
    draw_circle(pos, 6.0, ENERGY_BLUE, false, 2.0)
    for i in range(3):
        var y: float = pos.y + 16.0 + float(i) * 3.0
        draw_line(Vector2(pos.x - 18.0, y), Vector2(pos.x + 18.0, y), Color(0.25, 0.70, 0.95, 0.45), 2.0)

func _draw_oil_unit(pos: Vector2) -> void:
    draw_line(pos + Vector2(-14.0, 14.0), pos + Vector2(0.0, -14.0), OIL_ORANGE, 4.0)
    draw_line(pos + Vector2(14.0, 14.0), pos + Vector2(0.0, -14.0), OIL_ORANGE, 4.0)
    var bob: float = sin(energy_anim_phase * 1.8) * 4.0
    draw_line(pos + Vector2(-8.0, -7.0 + bob), pos + Vector2(13.0, -7.0 - bob), Color("c99863"), 4.0)
    draw_line(pos + Vector2(12.0, -7.0 - bob), pos + Vector2(17.0, 7.0), Color("c99863"), 3.0)
    draw_rect(Rect2(pos + Vector2(-18.0, 14.0), Vector2(36.0, 4.0)), Color("2f2925"), true)

func _draw_coal_unit(pos: Vector2) -> void:
    draw_rect(Rect2(pos + Vector2(-20.0, -11.0), Vector2(40.0, 26.0)), COAL_DARK, true)
    draw_rect(Rect2(pos + Vector2(-16.0, -7.0), Vector2(25.0, 17.0)), Color("465157"), true)
    draw_rect(Rect2(pos + Vector2(11.0, -24.0), Vector2(7.0, 34.0)), Color("5d676b"), true)
    draw_circle(pos + Vector2(14.0, -27.0), 5.0, Color(0.42, 0.45, 0.47, 0.30))

func _draw_smr_unit(pos: Vector2) -> void:
    draw_rect(Rect2(pos + Vector2(-18.0, -13.0), Vector2(36.0, 28.0)), Color("36494d"), true)
    draw_rect(Rect2(pos + Vector2(-13.0, -8.0), Vector2(26.0, 18.0)), Color("203236"), true)
    draw_circle(pos + Vector2(0.0, -8.0), 7.0, Color("9db9b5"))
    draw_circle(pos + Vector2(0.0, -8.0), 4.0, NUCLEAR_CYAN)
    draw_rect(Rect2(pos + Vector2(-17.0, 12.0), Vector2(34.0, 3.0)), NUCLEAR_CYAN.darkened(0.35), true)

func _draw_battery_bank(pos: Vector2, count: int) -> void:
    var shown: int = mini(count, 3)
    for i in range(shown):
        var p: Vector2 = pos + Vector2(float(i) * 14.0, 0.0)
        draw_rect(Rect2(p + Vector2(-5.0, -11.0), Vector2(10.0, 22.0)), Color("2b3940"), true)
        draw_rect(Rect2(p + Vector2(-3.0, -8.0), Vector2(6.0, 14.0)), ENERGY_GREEN.darkened(0.45), true)
        draw_rect(Rect2(p + Vector2(-2.0, -6.0), Vector2(4.0, 5.0)), ENERGY_GREEN, true)

func _draw_cooling_skid(pos: Vector2, count: int) -> void:
    draw_rect(Rect2(pos + Vector2(-24.0, -10.0), Vector2(48.0, 22.0)), Color("34454b"), true)
    var shown: int = mini(count, 3)
    for i in range(shown):
        var p: Vector2 = pos + Vector2(-14.0 + float(i) * 14.0, 0.0)
        draw_circle(p, 6.0, Color("11191d"))
        var a: float = energy_anim_phase * 4.0 + float(i)
        draw_line(p + Vector2(cos(a), sin(a)) * 1.0, p + Vector2(cos(a), sin(a)) * 5.0, ENERGY_BLUE, 2.0)
        draw_line(p + Vector2(cos(a + PI * 0.5), sin(a + PI * 0.5)) * 1.0, p + Vector2(cos(a + PI * 0.5), sin(a + PI * 0.5)) * 5.0, ENERGY_BLUE, 2.0)

func _draw_energy_power_flow(from: Vector2, to: Vector2) -> void:
    var points := PackedVector2Array([from, from.lerp(to, 0.5) + Vector2(0.0, 34.0), to])
    draw_polyline(points, Color("0b1012"), 6.0, false)
    draw_polyline(points, Color(0.95, 0.80, 0.25, 0.62), 2.0, false)
    var pulse_t: float = fmod(energy_anim_phase * 0.35, 1.0)
    var pulse_pos: Vector2
    if pulse_t < 0.5:
        pulse_pos = points[0].lerp(points[1], pulse_t * 2.0)
    else:
        pulse_pos = points[1].lerp(points[2], (pulse_t - 0.5) * 2.0)
    draw_circle(pulse_pos, 4.0, ENERGY_YELLOW)
    draw_circle(pulse_pos, 2.0, Color("fff6b5"))

func _draw_heat_exhaust(pos: Vector2) -> void:
    var temp_c: float = _facility_temperature_c()
    if temp_c < 43.0:
        return
    var strength: float = clampf((temp_c - 43.0) / 40.0, 0.18, 1.0)
    for i in range(4):
        var phase: float = energy_anim_phase * 2.0 + float(i) * 1.4
        var x: float = pos.x - 18.0 + float(i) * 12.0 + sin(phase) * 4.0
        var y: float = pos.y - 10.0 - fmod(energy_anim_phase * 15.0 + float(i) * 11.0, 34.0)
        draw_circle(Vector2(x, y), 2.0 + strength * 2.0, Color(1.0, 0.36, 0.10, 0.10 + strength * 0.20))

func _draw_count_ticks(pos: Vector2, count: int, color: Color) -> void:
    for i in range(count):
        draw_rect(Rect2(pos + Vector2(float(i) * 4.0, 0.0), Vector2(2.0, 4.0)), color, true)

func debug_energy_visuals_ready() -> bool:
    return ENERGY_VISUAL_REVISION >= 1 and infrastructure_inventory.debug_deployment_separation_ready() and infrastructure_inventory.item("nuclear_smr").has("energy_output_mw")
