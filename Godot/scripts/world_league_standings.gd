extends "res://scripts/world_company_effects.gd"

# v0.044: keep the playfield readable. League data lives behind one compact
# menu button instead of permanently occupying the map HUD.

var league_button: Button

func _ready() -> void:
    super._ready()
    _install_league_ui()

func _install_league_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "LeagueStandingsLayer"
    layer.layer = 13
    add_child(layer)

    league_button = Button.new()
    league_button.position = Vector2(914.0, 88.0)
    league_button.size = Vector2(158.0, 42.0)
    league_button.text = "☰ LEAGUE"
    league_button.tooltip_text = "Open the Bitcoin mining league standings."
    league_button.add_theme_font_size_override("font_size", 12)
    league_button.pressed.connect(_open_league_standings)
    layer.add_child(league_button)

func _rival_asset_value(rival: Dictionary) -> float:
    return maxf(0.0, float(rival["cash"])) + float(rival["sats"]) / SATS_PER_BTC * btc_price + float(rival["mw"]) * 90000.0 + float(rival["acres"]) * land_price_per_acre + float(rival["machines"]) * 700.0

func _league_rows() -> Array:
    var rows: Array = [{"name": String(player["name"]), "assets": _asset_value(), "player": true, "merged": false}]
    for rival_raw in rivals:
        var rival: Dictionary = rival_raw
        rows.append({"name": String(rival["name"]), "assets": _rival_asset_value(rival), "player": false, "merged": bool(rival["merged"])})
    for i in range(rows.size()):
        var best_idx: int = i
        for j in range(i + 1, rows.size()):
            if float(rows[j]["assets"]) > float(rows[best_idx]["assets"]):
                best_idx = j
        if best_idx != i:
            var swap_row: Dictionary = rows[i]
            rows[i] = rows[best_idx]
            rows[best_idx] = swap_row
    return rows

func _player_league_rank() -> int:
    var rows: Array = _league_rows()
    for i in range(rows.size()):
        if bool(rows[i]["player"]):
            return i + 1
    return rows.size()

func _open_league_standings() -> void:
    var rows: Array = _league_rows()
    var lines: Array[String] = []
    for i in range(rows.size()):
        var row: Dictionary = rows[i]
        var marker: String = "YOU" if bool(row["player"]) else ("MERGED" if bool(row["merged"]) else "RIVAL")
        lines.append("%d. %s\n    $%d assets  •  %s" % [i + 1, String(row["name"]), int(row["assets"]), marker])
    dialog_title.text = "BITCOIN MINING LEAGUE // #%d OF 10" % _player_league_rank()
    dialog_text.text = "Ten Bitcoin mining companies. Rankings stay here so the map stays readable.\n\n" + "\n".join(lines) + "\n\nBuild hash rate, infrastructure, land, treasury value, and financial strength to climb the league."
    _set_actions([])

func debug_league_standings_ready() -> bool:
    var rows: Array = _league_rows()
    return rows.size() == 10 and _player_league_rank() >= 1 and _player_league_rank() <= 10
