extends "res://scripts/world_overworld.gd"

# Futuristic top-down company RPG layer. It keeps the turn-based mining economy
# from world_overworld.gd, but makes the strategy happen in a visible world:
# walk between mining towns, talk to company representatives, visit partner
# firms, buy machines/land/power, finance growth, negotiate deals, and end the
# quarter only when the player is ready.

const TOWN_NAMES: Array = [
    "VantaGrid City",
    "Neon Forge Row",
    "ArcShift Junction",
    "IronVector Works",
    "Meridian Zero Exchange",
    "BlueNova Harbor",
    "SignalFlux Heights",
    "Parallax Ward",
    "Lattice Reach",
    "Epoch Port"
]

const COMPANY_REPS: Array = [
    {"name":"Mara Voss", "title":"Grid Strategy Lead", "scanner":"left"},
    {"name":"Juno Kade", "title":"Silicon Operations Lead", "scanner":"right"},
    {"name":"Imani Vale", "title":"Power Systems Lead", "scanner":"left"},
    {"name":"Rook Calder", "title":"Site Infrastructure Lead", "scanner":"right"},
    {"name":"Sera Quinn", "title":"Capital Strategy Lead", "scanner":"left"},
    {"name":"Niko Arlen", "title":"Energy Markets Lead", "scanner":"right"},
    {"name":"Aya Mercer", "title":"Fleet Operations Lead", "scanner":"left"},
    {"name":"Dax Rowan", "title":"Capacity Planning Lead", "scanner":"right"},
    {"name":"Talia Forge", "title":"Efficiency Engineering Lead", "scanner":"left"},
    {"name":"Kenzo Hart", "title":"Land and Treasury Lead", "scanner":"right"}
]

const PARTNER_REPS: Array = [
    {"name":"Reese Tan", "scanner":"right"},
    {"name":"Amina Cross", "scanner":"left"},
    {"name":"Cole Vey", "scanner":"right"},
    {"name":"Mika Sol", "scanner":"left"},
    {"name":"Nia Crest", "scanner":"right"},
    {"name":"Jax Perrin", "scanner":"left"},
    {"name":"Vale Ortiz", "scanner":"right"},
    {"name":"Eden Rhee", "scanner":"left"},
    {"name":"Zuri Knox", "scanner":"right"}
]

const COMPANY_ACCENTS: Array = [
    Color("00e7a9"), Color("c87dff"), Color("46dfff"), Color("ff9b54"), Color("f5d35f"),
    Color("3fa9ff"), Color("72ff87"), Color("ff66c4"), Color("b5ff4d"), Color("7e8cff")
]

const PARTNER_ACCENTS: Array = [
    Color("ffe06b"), Color("d5a06b"), Color("72c6ff"), Color("bd8cff"), Color("6effc0"),
    Color("ff9a6e"), Color("ff6f91"), Color("4df0ff"), Color("f2d45c")
]

const WORLD_GRASS: Color = Color("173f35")
const WORLD_GRASS_DARK: Color = Color("11342d")
const PAVEMENT: Color = Color("35464b")
const PAVEMENT_EDGE: Color = Color("71878c")
const WATER: Color = Color("176fa0")
const WATER_LIGHT: Color = Color("2bb8d8")

var town_zones: Array = []
var transit_button: Button
var transit_index: int = 0

func _ready() -> void:
    super._ready()
    _install_transit_button()
    var fallback: Node = get_node_or_null("BootFallback")
    if fallback != null:
        fallback.queue_free()
    var player_rep: Dictionary = COMPANY_REPS[company_idx]
    _open_message(
        "%s // %s" % [String(player_rep["name"]), String(player["name"])],
        "You are %s, %s for %s. Your single-eye scanner visor tracks market and infrastructure data. Walk the town network, meet rival mining reps, negotiate with partner companies, buy miners, land and power, then end the quarter when your strategy is ready." % [String(player_rep["name"]), String(player_rep["title"]), String(player["name"])]
    )
    _refresh_ui()
    queue_redraw()

func _build_entities() -> void:
    super._build_entities()
    town_zones.clear()

    # The central starting district always gives the player four obvious places
    # to visit immediately after leaving the new-campaign screen.
    entities.append({
        "name":"AcreX Land Market",
        "kind":"land",
        "pos":Vector2(1050.0, 720.0),
        "subtitle":"LAND + SITE EXPANSION"
    })

    if not entities.is_empty():
        var player_hq: Dictionary = entities[0]
        player_hq["profile_idx"] = company_idx
        player_hq["town"] = TOWN_NAMES[company_idx]
        player_hq["subtitle"] = "%s // YOUR HQ" % TOWN_NAMES[company_idx]
        entities[0] = player_hq
        town_zones.append({
            "profile_idx":company_idx,
            "center":player_hq["pos"],
            "town":TOWN_NAMES[company_idx],
            "company":String(player["name"]),
            "player":true
        })

    var partner_rep_entities: Array = []
    var rival_rep_entities: Array = []

    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind: String = String(entity["kind"])
        if kind == "partner":
            var partner_idx: int = int(entity["partner_idx"])
            var partner_rep: Dictionary = PARTNER_REPS[partner_idx]
            var partner_pos: Vector2 = entity["pos"]
            partner_rep_entities.append({
                "name":String(partner_rep["name"]),
                "kind":"partner_rep",
                "pos":partner_pos + Vector2(112.0 if partner_idx % 2 == 0 else -112.0, 82.0),
                "subtitle":"%s REP" % String(PARTNERS[partner_idx]["sector"]),
                "partner_idx":partner_idx,
                "scanner":String(partner_rep["scanner"]),
                "accent":PARTNER_ACCENTS[partner_idx]
            })
        elif kind == "rival":
            var rival_idx: int = int(entity["rival_idx"])
            var profile_idx: int = int(rivals[rival_idx]["profile_idx"])
            var rival_pos: Vector2 = entity["pos"]
            entity["profile_idx"] = profile_idx
            entity["town"] = TOWN_NAMES[profile_idx]
            entity["subtitle"] = "%s // MINING HQ" % TOWN_NAMES[profile_idx]
            entities[i] = entity
            town_zones.append({
                "profile_idx":profile_idx,
                "center":rival_pos,
                "town":TOWN_NAMES[profile_idx],
                "company":String(rivals[rival_idx]["name"]),
                "player":false
            })
            var rep: Dictionary = COMPANY_REPS[profile_idx]
            rival_rep_entities.append({
                "name":String(rep["name"]),
                "kind":"rival_rep",
                "pos":rival_pos + Vector2(116.0 if profile_idx % 2 == 0 else -116.0, 92.0),
                "subtitle":String(rep["title"]),
                "rival_idx":rival_idx,
                "profile_idx":profile_idx,
                "scanner":String(rep["scanner"]),
                "accent":COMPANY_ACCENTS[profile_idx]
            })

    for rep_entity in partner_rep_entities:
        entities.append(rep_entity)
    for rep_entity in rival_rep_entities:
        entities.append(rep_entity)

func _install_transit_button() -> void:
    var layer: CanvasLayer = CanvasLayer.new()
    layer.name = "TownTransitLayer"
    layer.layer = 9
    add_child(layer)
    transit_button = Button.new()
    transit_button.position = Vector2(18.0, 88.0)
    transit_button.size = Vector2(190.0, 42.0)
    transit_button.text = "TOWN TRANSIT  [T]"
    transit_button.add_theme_font_size_override("font_size", 12)
    transit_button.pressed.connect(_travel_next_town)
    layer.add_child(transit_button)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_T:
            _travel_next_town()
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)

func _travel_next_town() -> void:
    if town_zones.is_empty():
        return
    transit_index = (transit_index + 1) % town_zones.size()
    var zone: Dictionary = town_zones[transit_index]
    var center: Vector2 = zone["center"]
    rep_pos = center + Vector2(0.0, 165.0)
    click_target = rep_pos
    has_click_target = false
    if is_instance_valid(camera):
        camera.position = rep_pos
    _open_message(
        "TRANSIT // %s" % String(zone["town"]),
        "Arrived at %s, home of %s. Walk to the HQ or its representative to inspect the company, negotiate, or explore the surrounding route." % [String(zone["town"]), String(zone["company"])]
    )
    queue_redraw()

func _current_town_name() -> String:
    var best_name: String = "INTERCITY ROUTE"
    var best_distance: float = 999999.0
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = zone["center"]
        var distance: float = rep_pos.distance_to(center)
        if distance < best_distance:
            best_distance = distance
            best_name = String(zone["town"])
    if best_distance > 360.0:
        return "INTERCITY ROUTE"
    return best_name

func _update_nearby_prompt() -> void:
    if not is_instance_valid(prompt_label):
        return
    var idx: int = _nearest_entity()
    var area: String = _current_town_name()
    if idx < 0:
        prompt_label.text = "%s  •  T: TRANSIT  •  Walk to a company and press E" % area
        return
    var entity: Dictionary = entities[idx]
    prompt_label.text = "%s  •  E: TALK TO %s  •  T: TRANSIT" % [area, String(entity["name"])]

func _open_entity(idx: int) -> void:
    selected_entity_idx = idx
    var entity: Dictionary = entities[idx]
    var kind: String = String(entity["kind"])
    if kind == "rival_rep":
        _open_rival_rep(entity)
        return
    if kind == "partner_rep":
        _open_partner_rep(entity)
        return
    if kind == "land":
        _open_land_market(entity)
        return
    super._open_entity(idx)

func _open_land_market(entity: Dictionary) -> void:
    var discount: float = clampf(float(player["land_discount"]), 0.0, 0.35)
    var parcel_cost: float = land_price_per_acre * 5.0 * (1.0 - discount) + 5000.0
    dialog_title.text = "%s // LIVE LAND MARKET" % String(entity["name"])
    dialog_text.text = "Land trades at about $%d/acre this quarter. A 5-acre parcel costs $%d including site/legal work. Land value moves with the market and increases asset-backed borrowing." % [int(land_price_per_acre), int(parcel_cost)]
    _set_actions([{"label":"BUY 5 ACRES", "call":Callable(self, "_buy_land")}])

func _buy_land() -> void:
    var discount: float = clampf(float(player["land_discount"]), 0.0, 0.35)
    var cost: float = land_price_per_acre * 5.0 * (1.0 - discount) + 5000.0
    if float(player["cash"]) < cost:
        _feedback("Need $%d for the next 5-acre parcel." % int(cost))
        return
    player["cash"] = float(player["cash"]) - cost
    player["acres"] = float(player["acres"]) + 5.0
    _feedback("Bought 5 acres for $%d. Company land is now %.1f acres." % [int(cost), float(player["acres"])])

func _open_rival_rep(entity: Dictionary) -> void:
    var rival_idx: int = int(entity["rival_idx"])
    var profile_idx: int = int(entity["profile_idx"])
    var rival: Dictionary = rivals[rival_idx]
    var rep: Dictionary = COMPANY_REPS[profile_idx]
    dialog_title.text = "%s // %s" % [String(rep["name"]), String(rival["name"])]
    if bool(rival["merged"]):
        dialog_text.text = "%s now represents a division inside your company after the merger." % String(rep["name"])
        _set_actions([])
        return
    dialog_text.text = "%s is %s for %s in %s. Scanner readout: %d machines, %.2f MW, %.1f acres and about $%d cash. Mining companies compete independently; exactly one merger may be completed in a campaign." % [
        String(rep["name"]), String(rep["title"]), String(rival["name"]), TOWN_NAMES[profile_idx],
        int(rival["machines"]), float(rival["mw"]), float(rival["acres"]), int(rival["cash"])
    ]
    var actions: Array = [{"label":"VIEW RIVAL COMPANY", "call":Callable(self, "_open_rival").bind(entity)}]
    if not merger_used:
        actions.append({"label":"PROPOSE MERGER", "call":Callable(self, "_merge_rival").bind(rival_idx)})
    _set_actions(actions)

func _open_partner_rep(entity: Dictionary) -> void:
    var partner_idx: int = int(entity["partner_idx"])
    var partner: Dictionary = PARTNERS[partner_idx]
    var rep: Dictionary = PARTNER_REPS[partner_idx]
    var signed: bool = signed_partners.has(String(partner["id"]))
    dialog_title.text = "%s // %s" % [String(rep["name"]), String(partner["name"])]
    dialog_text.text = "%s represents %s. Offer: %s. Deal cost $%d. Status: %s." % [
        String(rep["name"]), String(partner["sector"]), String(partner["boost"]), int(partner["cost"]), "SIGNED" if signed else "AVAILABLE"
    ]
    if signed:
        _set_actions([])
    else:
        _set_actions([{"label":"NEGOTIATE DEAL", "call":Callable(self, "_sign_partner").bind(partner_idx)}])

func _draw() -> void:
    # Bright enough to read like a top-down RPG, dark enough to remain a
    # futuristic mining/energy world instead of copying another game's art.
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), WORLD_GRASS, true)
    _draw_ground_texture()
    _draw_waterways()
    _draw_route_network()
    _draw_town_zones()
    _draw_world_props()
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        _draw_entity(entity, i)
    _draw_rep()
    draw_string(ThemeDB.fallback_font, Vector2(1110.0, 278.0), "HASH RACE // TECH CORRIDOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 29, Color("d5fbff"))
    draw_string(ThemeDB.fallback_font, Vector2(1110.0, 310.0), "MINING TOWNS • PARTNER FIRMS • CAPITAL • ENERGY", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("77b9c4"))

func _draw_ground_texture() -> void:
    for x in range(0, int(WORLD_SIZE.x), 48):
        for y in range(0, int(WORLD_SIZE.y), 48):
            if (x / 48 + y / 48) as int % 2 == 0:
                draw_rect(Rect2(float(x), float(y), 48.0, 48.0), WORLD_GRASS_DARK, true)
    for x in range(90, 2920, 170):
        draw_circle(Vector2(float(x), 210.0 + float((x / 170) as int % 3) * 24.0), 16.0, Color("24694f"))
        draw_rect(Rect2(float(x) - 4.0, 222.0, 8.0, 22.0), Color("4a5b45"), true)

func _draw_waterways() -> void:
    draw_rect(Rect2(0.0, 1770.0, WORLD_SIZE.x, 130.0), WATER, true)
    draw_rect(Rect2(2600.0, 0.0, 400.0, 760.0), WATER.darkened(0.08), true)
    for x in range(0, 3000, 72):
        draw_line(Vector2(float(x), 1794.0), Vector2(float(x + 36), 1794.0), WATER_LIGHT, 3.0)
        draw_line(Vector2(float(x + 22), 1832.0), Vector2(float(x + 58), 1832.0), WATER_LIGHT, 2.0)
    for y in range(32, 740, 58):
        draw_line(Vector2(2630.0, float(y)), Vector2(2690.0, float(y)), WATER_LIGHT, 2.0)

func _draw_route_network() -> void:
    draw_rect(Rect2(120.0, 885.0, 2760.0, 205.0), PAVEMENT, true)
    draw_rect(Rect2(1360.0, 335.0, 280.0, 1395.0), PAVEMENT, true)
    draw_rect(Rect2(350.0, 390.0, 2220.0, 178.0), PAVEMENT.darkened(0.06), true)
    draw_rect(Rect2(350.0, 1380.0, 2220.0, 180.0), PAVEMENT.darkened(0.06), true)
    draw_line(Vector2(120.0, 885.0), Vector2(2880.0, 885.0), PAVEMENT_EDGE, 5.0)
    draw_line(Vector2(120.0, 1090.0), Vector2(2880.0, 1090.0), PAVEMENT_EDGE, 5.0)
    draw_line(Vector2(1360.0, 335.0), Vector2(1360.0, 1730.0), PAVEMENT_EDGE, 5.0)
    draw_line(Vector2(1640.0, 335.0), Vector2(1640.0, 1730.0), PAVEMENT_EDGE, 5.0)
    for x in range(160, 2860, 118):
        draw_line(Vector2(float(x), 988.0), Vector2(float(x + 58), 988.0), Color("b9c7c9"), 3.0)
    for y in range(370, 1710, 108):
        draw_line(Vector2(1500.0, float(y)), Vector2(1500.0, float(y + 52)), Color("b9c7c9"), 3.0)
    # Fiber/data line running beside the road.
    draw_line(Vector2(150.0, 1110.0), Vector2(2850.0, 1110.0), Color("39e9ff80"), 2.0)
    for x in range(180, 2820, 190):
        draw_circle(Vector2(float(x), 1110.0), 4.0, CYAN)

func _draw_town_zones() -> void:
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = zone["center"]
        var profile_idx: int = int(zone["profile_idx"])
        var accent: Color = COMPANY_ACCENTS[profile_idx]
        var rect: Rect2 = Rect2(center - Vector2(160.0, 150.0), Vector2(320.0, 300.0))
        draw_rect(rect, Color(accent.r * 0.10, accent.g * 0.10, accent.b * 0.10, 0.92), true)
        draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.70), false, 3.0)
        draw_rect(Rect2(center - Vector2(160.0, 150.0), Vector2(320.0, 36.0)), Color("071018e6"), true)
        draw_string(ThemeDB.fallback_font, center + Vector2(-148.0, -126.0), String(zone["town"]), HORIZONTAL_ALIGNMENT_CENTER, 296.0, 15, accent)
        # Utility pads make each mining town read as infrastructure, not houses.
        for j in range(3):
            var pad_x: float = center.x - 135.0 + float(j) * 92.0
            draw_rect(Rect2(pad_x, center.y + 92.0, 62.0, 26.0), Color("101c22"), true)
            draw_line(Vector2(pad_x + 8.0, center.y + 98.0), Vector2(pad_x + 52.0, center.y + 98.0), accent.darkened(0.25), 2.0)

func _draw_world_props() -> void:
    # Solar array.
    for row in range(2):
        for col in range(4):
            var p: Vector2 = Vector2(2140.0 + float(col) * 62.0, 250.0 + float(row) * 42.0)
            draw_rect(Rect2(p, Vector2(48.0, 28.0)), Color("173b68"), true)
            draw_line(p + Vector2(24.0, 0.0), p + Vector2(24.0, 28.0), Color("4e8ad1"), 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(2140.0, 350.0), "SOLAR + STORAGE FIELD", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("7cc8ff"))
    # Cooling loop / hydro infrastructure.
    draw_circle(Vector2(2390.0, 1260.0), 54.0, Color("0d5169"))
    draw_circle(Vector2(2390.0, 1260.0), 40.0, Color("35b7d1"), false, 5.0)
    draw_line(Vector2(2390.0, 1205.0), Vector2(2390.0, 1160.0), Color("62ddef"), 7.0)
    draw_string(ThemeDB.fallback_font, Vector2(2290.0, 1335.0), "HYDRO COOLING LOOP", HORIZONTAL_ALIGNMENT_CENTER, 200.0, 11, Color("62ddef"))
    # Substation towers.
    for x in [660.0, 760.0, 1760.0, 1860.0]:
        draw_line(Vector2(x, 780.0), Vector2(x, 700.0), Color("a2b0b6"), 5.0)
        draw_line(Vector2(x - 20.0, 726.0), Vector2(x + 20.0, 726.0), Color("a2b0b6"), 4.0)
        draw_circle(Vector2(x - 17.0, 729.0), 4.0, ORANGE)
        draw_circle(Vector2(x + 17.0, 729.0), 4.0, ORANGE)

func _draw_entity(entity: Dictionary, idx: int) -> void:
    var kind: String = String(entity["kind"])
    if kind == "rival_rep" or kind == "partner_rep":
        if idx == selected_entity_idx:
            var selected_pos: Vector2 = entity["pos"]
            draw_circle(selected_pos, 42.0, GREEN, false, 3.0)
        _draw_stationary_rep(entity)
        return
    if kind == "hq" or kind == "rival":
        _draw_mining_hq(entity, idx)
        return
    if kind == "partner":
        _draw_partner_building(entity, idx)
        return
    if kind == "machines":
        _draw_machine_market(entity, idx)
        return
    if kind == "power":
        _draw_power_building(entity, idx)
        return
    if kind == "bank":
        _draw_bank_building(entity, idx)
        return
    if kind == "land":
        _draw_land_building(entity, idx)
        return
    super._draw_entity(entity, idx)

func _selection_ring(pos: Vector2, idx: int, radius: float) -> void:
    if idx == selected_entity_idx:
        draw_circle(pos, radius, GREEN, false, 4.0)

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var profile_idx: int = int(entity.get("profile_idx", company_idx))
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    var merged: bool = false
    if String(entity["kind"]) == "rival":
        var rival_idx: int = int(entity["rival_idx"])
        merged = bool(rivals[rival_idx]["merged"])
    if merged:
        accent = Color("60666b")
    _selection_ring(pos, idx, 126.0)
    draw_ellipse_shadow(pos + Vector2(0.0, 64.0), 102.0, 19.0)
    draw_rect(Rect2(pos - Vector2(106.0, 72.0), Vector2(212.0, 128.0)), Color("10212a"), true)
    draw_rect(Rect2(pos - Vector2(106.0, 72.0), Vector2(212.0, 18.0)), accent, true)
    draw_colored_polygon(PackedVector2Array([
        pos + Vector2(-106.0, -72.0), pos + Vector2(-58.0, -112.0),
        pos + Vector2(88.0, -112.0), pos + Vector2(106.0, -72.0)
    ]), accent.darkened(0.48))
    draw_rect(Rect2(pos + Vector2(-24.0, 4.0), Vector2(48.0, 52.0)), Color("071018"), true)
    for w in range(3):
        draw_rect(Rect2(pos + Vector2(-82.0 + float(w) * 62.0, -36.0), Vector2(34.0, 26.0)), Color(accent.r, accent.g, accent.b, 0.72), true)
    # Antenna + hash status mast.
    draw_line(pos + Vector2(72.0, -108.0), pos + Vector2(72.0, -145.0), accent, 4.0)
    draw_circle(pos + Vector2(72.0, -150.0), 7.0, accent)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 82.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 12, WHITE)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-118.0, 100.0), String(entity["subtitle"]), HORIZONTAL_ALIGNMENT_CENTER, 236.0, 9, accent)

func _draw_partner_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var partner_idx: int = int(entity["partner_idx"])
    var accent: Color = PARTNER_ACCENTS[partner_idx]
    _selection_ring(pos, idx, 108.0)
    draw_ellipse_shadow(pos + Vector2(0.0, 60.0), 90.0, 17.0)
    draw_rect(Rect2(pos - Vector2(88.0, 64.0), Vector2(176.0, 118.0)), Color("122630"), true)
    draw_rect(Rect2(pos - Vector2(88.0, 64.0), Vector2(176.0, 14.0)), accent, true)
    draw_rect(Rect2(pos + Vector2(-58.0, -26.0), Vector2(116.0, 34.0)), Color("071018"), true)
    draw_rect(Rect2(pos + Vector2(-22.0, 10.0), Vector2(44.0, 44.0)), accent.darkened(0.55), true)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-102.0, 78.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 204.0, 11, WHITE)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-98.0, 96.0), String(entity["subtitle"]), HORIZONTAL_ALIGNMENT_CENTER, 196.0, 9, accent)

func _draw_machine_market(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent: Color = Color("bd8cff")
    _selection_ring(pos, idx, 110.0)
    draw_rect(Rect2(pos - Vector2(94.0, 62.0), Vector2(188.0, 116.0)), Color("1e1830"), true)
    draw_rect(Rect2(pos - Vector2(94.0, 62.0), Vector2(188.0, 15.0)), accent, true)
    for col in range(4):
        draw_rect(Rect2(pos + Vector2(-72.0 + float(col) * 40.0, -30.0), Vector2(28.0, 58.0)), Color("0a1118"), true)
        for row in range(4):
            draw_circle(pos + Vector2(-58.0 + float(col) * 40.0, -20.0 + float(row) * 13.0), 3.0, GREEN)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 78.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 11, WHITE)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 96.0), String(entity["subtitle"]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 9, accent)

func _draw_power_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent: Color = Color("ffd36e")
    _selection_ring(pos, idx, 110.0)
    draw_rect(Rect2(pos - Vector2(92.0, 58.0), Vector2(184.0, 110.0)), Color("302a18"), true)
    draw_rect(Rect2(pos - Vector2(92.0, 58.0), Vector2(184.0, 14.0)), accent, true)
    for x in [-54.0, 0.0, 54.0]:
        draw_circle(pos + Vector2(x, -5.0), 18.0, Color("101820"))
        draw_circle(pos + Vector2(x, -5.0), 12.0, accent.darkened(0.25), false, 4.0)
    draw_line(pos + Vector2(-70.0, 28.0), pos + Vector2(70.0, 28.0), accent, 4.0)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 78.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 11, WHITE)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 96.0), String(entity["subtitle"]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 9, accent)

func _draw_bank_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent: Color = ORANGE
    _selection_ring(pos, idx, 106.0)
    draw_rect(Rect2(pos - Vector2(86.0, 58.0), Vector2(172.0, 112.0)), Color("352b1a"), true)
    draw_colored_polygon(PackedVector2Array([pos + Vector2(-96.0, -58.0), pos + Vector2(0.0, -102.0), pos + Vector2(96.0, -58.0)]), accent.darkened(0.25))
    for x in [-52.0, -17.0, 18.0, 53.0]:
        draw_rect(Rect2(pos + Vector2(x - 5.0, -40.0), Vector2(10.0, 70.0)), Color("b08a48"), true)
    draw_rect(Rect2(pos + Vector2(-24.0, 6.0), Vector2(48.0, 48.0)), Color("101018"), true)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 78.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 11, WHITE)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-110.0, 96.0), "SMALL LOANS • HIGH RATE", HORIZONTAL_ALIGNMENT_CENTER, 220.0, 9, accent)

func _draw_land_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent: Color = Color("8ed06c")
    _selection_ring(pos, idx, 105.0)
    draw_rect(Rect2(pos - Vector2(84.0, 55.0), Vector2(168.0, 108.0)), Color("173123"), true)
    draw_rect(Rect2(pos - Vector2(84.0, 55.0), Vector2(168.0, 14.0)), accent, true)
    draw_rect(Rect2(pos + Vector2(-56.0, -24.0), Vector2(112.0, 58.0)), Color("0d1d16"), true)
    for x in range(3):
        for y in range(2):
            draw_rect(Rect2(pos + Vector2(-46.0 + float(x) * 34.0, -14.0 + float(y) * 26.0), Vector2(24.0, 16.0)), accent.darkened(0.45), false, 2.0)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-106.0, 77.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 212.0, 11, WHITE)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-106.0, 95.0), String(entity["subtitle"]), HORIZONTAL_ALIGNMENT_CENTER, 212.0, 9, accent)

func _draw_stationary_rep(entity: Dictionary) -> void:
    var pos: Vector2 = entity["pos"]
    var accent: Color = entity.get("accent", CYAN)
    var scanner: String = String(entity.get("scanner", "left"))
    _draw_tech_rep(pos, accent, scanner, false)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-80.0, 50.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, 160.0, 11, WHITE)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-90.0, 66.0), String(entity["subtitle"]), HORIZONTAL_ALIGNMENT_CENTER, 180.0, 9, accent)

func _draw_rep() -> void:
    var rep: Dictionary = COMPANY_REPS[company_idx]
    var accent: Color = COMPANY_ACCENTS[company_idx]
    _draw_tech_rep(rep_pos, accent, String(rep["scanner"]), true)
    draw_string(ThemeDB.fallback_font, rep_pos + Vector2(-72.0, -48.0), String(rep["name"]), HORIZONTAL_ALIGNMENT_CENTER, 144.0, 11, accent)
    draw_string(ThemeDB.fallback_font, rep_pos + Vector2(-92.0, -33.0), "%s REP" % String(player["name"]), HORIZONTAL_ALIGNMENT_CENTER, 184.0, 9, WHITE)

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    draw_ellipse_shadow(pos + Vector2(0.0, 34.0), 23.0, 8.0)
    # Futuristic boots and tapered dark pants.
    draw_rect(Rect2(pos + Vector2(-12.0, 17.0), Vector2(9.0, 19.0)), Color("111821"), true)
    draw_rect(Rect2(pos + Vector2(3.0, 17.0), Vector2(9.0, 19.0)), Color("111821"), true)
    draw_rect(Rect2(pos + Vector2(-15.0, 34.0), Vector2(12.0, 5.0)), accent.darkened(0.35), true)
    draw_rect(Rect2(pos + Vector2(3.0, 34.0), Vector2(12.0, 5.0)), accent.darkened(0.35), true)
    # Techwear jacket.
    draw_rect(Rect2(pos + Vector2(-18.0, -9.0), Vector2(36.0, 30.0)), Color("182531"), true)
    draw_rect(Rect2(pos + Vector2(-14.0, -6.0), Vector2(28.0, 23.0)), accent.darkened(0.58), true)
    draw_line(pos + Vector2(0.0, -6.0), pos + Vector2(0.0, 17.0), accent, 2.0)
    draw_rect(Rect2(pos + Vector2(-23.0, -5.0), Vector2(6.0, 24.0)), Color("253845"), true)
    draw_rect(Rect2(pos + Vector2(17.0, -5.0), Vector2(6.0, 24.0)), Color("253845"), true)
    # Head / collar.
    draw_rect(Rect2(pos + Vector2(-10.0, -25.0), Vector2(20.0, 18.0)), Color("d5a37c"), true)
    draw_rect(Rect2(pos + Vector2(-12.0, -28.0), Vector2(24.0, 6.0)), Color("16202a"), true)
    draw_rect(Rect2(pos + Vector2(-14.0, -12.0), Vector2(28.0, 5.0)), Color("0b1219"), true)
    # Original single-eye scanner: left/right lens, small temple sensor and HUD line.
    var lens_x: float = -10.0 if scanner == "left" else 2.0
    var temple_x: float = -14.0 if scanner == "left" else 11.0
    draw_rect(Rect2(pos + Vector2(lens_x, -21.0), Vector2(9.0, 7.0)), Color(accent.r, accent.g, accent.b, 0.86), true)
    draw_rect(Rect2(pos + Vector2(temple_x, -23.0), Vector2(4.0, 12.0)), accent.darkened(0.20), true)
    if scanner == "left":
        draw_line(pos + Vector2(-1.0, -18.0), pos + Vector2(-14.0, -18.0), accent, 2.0)
    else:
        draw_line(pos + Vector2(2.0, -18.0), pos + Vector2(15.0, -18.0), accent, 2.0)
    if is_player:
        draw_circle(pos + Vector2(0.0, 7.0), 26.0, accent, false, 2.0)
        draw_circle(pos + Vector2(0.0, 7.0), 31.0, Color(accent.r, accent.g, accent.b, 0.25), false, 2.0)

func draw_ellipse_shadow(center: Vector2, radius_x: float, radius_y: float) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i in range(20):
        var angle: float = TAU * float(i) / 20.0
        points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
    draw_colored_polygon(points, Color("00000066"))

func debug_company_rep_count() -> int:
    var count: int = 1
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        if String(entity["kind"]) == "rival_rep":
            count += 1
    return count

func debug_partner_rep_count() -> int:
    var count: int = 0
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        if String(entity["kind"]) == "partner_rep":
            count += 1
    return count

func debug_town_count() -> int:
    return town_zones.size()

func debug_player_rep_name() -> String:
    return String(COMPANY_REPS[company_idx]["name"])

func debug_has_land_market() -> bool:
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        if String(entity["kind"]) == "land":
            return true
    return false
