extends "res://scripts/world_overworld.gd"

# RPG presentation layer inspired by classic top-down town exploration.
# All characters, company towns, clothing, scanner visors, buildings, names,
# and visuals are original Hash Race designs.

const TOWN_NAMES: Array = [
    "Emberline Basin",
    "Helix Row",
    "ArcCurrent Junction",
    "StoneGrid Works",
    "Meridian Exchange",
    "BlueLoop Harbor",
    "SignalPeak Heights",
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
    Color("ff7a45"), Color("b68cff"), Color("59e6ff"), Color("d2a56e"), Color("ffd166"),
    Color("4dd8ff"), Color("76ff9f"), Color("ff73d0"), Color("9dff5a"), Color("75a6ff")
]

const PARTNER_ACCENTS: Array = [
    Color("ffe06b"), Color("d5a06b"), Color("72c6ff"), Color("bd8cff"), Color("6effc0"),
    Color("ff9a6e"), Color("ff6f91"), Color("4df0ff"), Color("f2d45c")
]

var town_zones: Array = []

func _ready() -> void:
    super._ready()
    var player_rep: Dictionary = COMPANY_REPS[company_idx]
    _open_message(
        "%s // %s" % [String(player_rep["name"]), String(player["name"])],
        "You are %s, %s for %s. Your scanner visor tracks company, market and infrastructure data. Travel between company towns, talk to rival representatives, visit partner reps, strike deals, buy infrastructure, and end the quarter only when your strategy is ready." % [String(player_rep["name"]), String(player_rep["title"]), String(player["name"])]
    )
    _refresh_ui()

func _build_entities() -> void:
    super._build_entities()
    town_zones.clear()

    if not entities.is_empty():
        var player_hq: Dictionary = entities[0]
        player_hq["town"] = TOWN_NAMES[company_idx]
        player_hq["subtitle"] = "%s // YOUR HQ" % TOWN_NAMES[company_idx]
        entities[0] = player_hq
        town_zones.append({
            "profile_idx": company_idx,
            "center": player_hq["pos"],
            "town": TOWN_NAMES[company_idx],
            "company": String(player["name"]),
            "player": true
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
                "name": String(partner_rep["name"]),
                "kind": "partner_rep",
                "pos": partner_pos + Vector2(112.0 if partner_idx % 2 == 0 else -112.0, 82.0),
                "subtitle": "%s REP" % String(PARTNERS[partner_idx]["sector"]),
                "partner_idx": partner_idx,
                "scanner": String(partner_rep["scanner"]),
                "accent": PARTNER_ACCENTS[partner_idx]
            })
        elif kind == "rival":
            var rival_idx: int = int(entity["rival_idx"])
            var profile_idx: int = int(rivals[rival_idx]["profile_idx"])
            var rival_pos: Vector2 = entity["pos"]
            entity["town"] = TOWN_NAMES[profile_idx]
            entity["subtitle"] = "%s // MINING HQ" % TOWN_NAMES[profile_idx]
            entities[i] = entity
            town_zones.append({
                "profile_idx": profile_idx,
                "center": rival_pos,
                "town": TOWN_NAMES[profile_idx],
                "company": String(rivals[rival_idx]["name"]),
                "player": false
            })
            var rep: Dictionary = COMPANY_REPS[profile_idx]
            rival_rep_entities.append({
                "name": String(rep["name"]),
                "kind": "rival_rep",
                "pos": rival_pos + Vector2(116.0 if profile_idx % 2 == 0 else -116.0, 92.0),
                "subtitle": String(rep["title"]),
                "rival_idx": rival_idx,
                "profile_idx": profile_idx,
                "scanner": String(rep["scanner"]),
                "accent": COMPANY_ACCENTS[profile_idx]
            })

    for rep_entity in partner_rep_entities:
        entities.append(rep_entity)
    for rep_entity in rival_rep_entities:
        entities.append(rep_entity)

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
    super._open_entity(idx)

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
    dialog_text.text = "%s, %s. Based in %s. Their visor reports %d machines, %.2f MW, %.1f acres and about $%d cash. You can inspect the rival or attempt your one allowed merger when your company is large enough." % [
        String(rep["name"]), String(rep["title"]), TOWN_NAMES[profile_idx], int(rival["machines"]), float(rival["mw"]), float(rival["acres"]), int(rival["cash"])
    ]
    var actions: Array = [
        {"label":"VIEW RIVAL COMPANY", "call":Callable(self, "_open_rival").bind(entity)}
    ]
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

func _draw_world_grid() -> void:
    super._draw_world_grid()
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = zone["center"]
        var profile_idx: int = int(zone["profile_idx"])
        var accent: Color = COMPANY_ACCENTS[profile_idx]
        var rect := Rect2(center - Vector2(150.0, 150.0), Vector2(300.0, 300.0))
        draw_rect(rect, Color(accent.r * 0.10, accent.g * 0.10, accent.b * 0.10, 0.72), true)
        draw_rect(rect, Color(accent.r, accent.g, accent.b, 0.50), false, 3.0)
        draw_rect(Rect2(center - Vector2(150.0, 150.0), Vector2(300.0, 34.0)), Color("061015d9"), true)
        draw_string(ThemeDB.fallback_font, center + Vector2(-140.0, -127.0), String(zone["town"]), HORIZONTAL_ALIGNMENT_CENTER, 280.0, 15, accent)

func _draw_entity(entity: Dictionary, idx: int) -> void:
    var kind: String = String(entity["kind"])
    if kind == "rival_rep" or kind == "partner_rep":
        if idx == selected_entity_idx:
            var selected_pos: Vector2 = entity["pos"]
            draw_circle(selected_pos, 40.0, GREEN, false, 3.0)
        _draw_stationary_rep(entity)
        return
    super._draw_entity(entity, idx)

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
    draw_string(ThemeDB.fallback_font, rep_pos + Vector2(-72.0, -46.0), String(rep["name"]), HORIZONTAL_ALIGNMENT_CENTER, 144.0, 11, accent)
    draw_string(ThemeDB.fallback_font, rep_pos + Vector2(-88.0, -31.0), "%s REP" % String(player["name"]), HORIZONTAL_ALIGNMENT_CENTER, 176.0, 9, WHITE)

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    # Compact original pixel-style techwear figure.
    draw_ellipse_shadow(pos + Vector2(0.0, 32.0), 22.0, 8.0)

    # Boots / legs.
    draw_rect(Rect2(pos + Vector2(-11.0, 19.0), Vector2(8.0, 18.0)), Color("111821"), true)
    draw_rect(Rect2(pos + Vector2(3.0, 19.0), Vector2(8.0, 18.0)), Color("111821"), true)
    draw_rect(Rect2(pos + Vector2(-14.0, 34.0), Vector2(11.0, 5.0)), accent.darkened(0.35), true)
    draw_rect(Rect2(pos + Vector2(3.0, 34.0), Vector2(11.0, 5.0)), accent.darkened(0.35), true)

    # Jacket and illuminated seam.
    draw_rect(Rect2(pos + Vector2(-17.0, -8.0), Vector2(34.0, 31.0)), Color("182531"), true)
    draw_rect(Rect2(pos + Vector2(-13.0, -5.0), Vector2(26.0, 23.0)), accent.darkened(0.55), true)
    draw_line(pos + Vector2(0.0, -5.0), pos + Vector2(0.0, 18.0), accent, 2.0)
    draw_rect(Rect2(pos + Vector2(-22.0, -5.0), Vector2(6.0, 24.0)), Color("253845"), true)
    draw_rect(Rect2(pos + Vector2(16.0, -5.0), Vector2(6.0, 24.0)), Color("253845"), true)

    # Head and dark tech collar.
    draw_rect(Rect2(pos + Vector2(-10.0, -24.0), Vector2(20.0, 18.0)), Color("d6a77f"), true)
    draw_rect(Rect2(pos + Vector2(-12.0, -27.0), Vector2(24.0, 6.0)), Color("16202a"), true)
    draw_rect(Rect2(pos + Vector2(-14.0, -11.0), Vector2(28.0, 5.0)), Color("0b1219"), true)

    # Original single-eye digital scanner visor: compact translucent lens + temple sensor.
    var lens_x: float = -10.0 if scanner == "left" else 2.0
    var temple_x: float = -14.0 if scanner == "left" else 11.0
    draw_rect(Rect2(pos + Vector2(lens_x, -20.0), Vector2(9.0, 7.0)), Color(accent.r, accent.g, accent.b, 0.82), true)
    draw_rect(Rect2(pos + Vector2(temple_x, -22.0), Vector2(4.0, 11.0)), accent.darkened(0.20), true)
    if scanner == "left":
        draw_line(pos + Vector2(-1.0, -17.0), pos + Vector2(-13.0, -17.0), accent, 2.0)
    else:
        draw_line(pos + Vector2(2.0, -17.0), pos + Vector2(14.0, -17.0), accent, 2.0)

    if is_player:
        draw_circle(pos + Vector2(0.0, 8.0), 25.0, accent, false, 2.0)

func draw_ellipse_shadow(center: Vector2, radius_x: float, radius_y: float) -> void:
    var points := PackedVector2Array()
    for i in range(20):
        var angle: float = TAU * float(i) / 20.0
        points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
    draw_colored_polygon(points, Color("00000066"))

func debug_company_rep_count() -> int:
    var count: int = 1 # controllable player representative
    for entity in entities:
        var kind: String = String(entity["kind"])
        if kind == "rival_rep":
            count += 1
    return count

func debug_partner_rep_count() -> int:
    var count: int = 0
    for entity in entities:
        if String(entity["kind"]) == "partner_rep":
            count += 1
    return count

func debug_town_count() -> int:
    return town_zones.size()

func debug_player_rep_name() -> String:
    return String(COMPANY_REPS[company_idx]["name"])
