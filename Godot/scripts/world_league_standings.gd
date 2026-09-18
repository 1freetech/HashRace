extends "res://scripts/world_company_effects.gd"

# v0.044 release-safe league standings. The compact UI hides this legacy layer
# during normal play and opens the same ten-miner standings on demand.

var league_button: Button
var league_rank_label: Label

func _ready() -> void:
    super._ready()
    _install_league_ui()
    _refresh_league_ui()

func _install_league_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "LeagueStandingsLayer"
    layer.layer = 13
    add_child(layer)

    league_rank_label = Label.new()
    league_rank_label.position = Vector2(760.0, 92.0)
    league_rank_label.size = Vector2(150.0, 34.0)
    league_rank_label.add_theme_font_size_override("font_size", 12)
    league_rank_label.add_theme_color_override("font_color", Color("ffcf72"))
    layer.add_child(league_rank_label)

    league_button = Button.new()
    league_button.position = Vector2(914.0, 88.0)
    league_button.size = Vector2(158.0, 42.0)
    league_button.text = "STANDINGS"
    league_button.tooltip_text = "Compare all ten Bitcoin mining companies using the five headline real-unit metrics."
    league_button.add_theme_font_size_override("font_size", 12)
    league_button.pressed.connect(_open_league_standings)
    layer.add_child(league_button)

func _rival_asset_value(rival: Dictionary) -> float:
    return maxf(0.0, float(rival["cash"])) + float(rival["sats"]) / SATS_PER_BTC * btc_price + float(rival["mw"]) * 90000.0 + float(rival["acres"]) * land_price_per_acre + float(rival["machines"]) * 700.0

func _headline_metrics(company: Dictionary, is_player: bool) -> Dictionary:
    var machines: float = float(company["machines"])
    var machine: Dictionary = MACHINES[int(player["machine_tier"])] if is_player else MACHINES[0]
    var hashrate_ph: float = (_hashrate_th() if is_player else machines * float(machine["th"])) / 1000.0
    var efficiency_jth: float = float(machine["kw"]) * 1000.0 / float(machine["th"])
    return {
        "hashrate_ph": hashrate_ph,
        "mw": float(company["mw"]),
        "efficiency_jth": efficiency_jth,
        "cash": float(company["cash"]),
        "profit": float(company.get("last_profit", 0.0))
    }

func _league_rows() -> Array:
    var player_metrics: Dictionary = _headline_metrics(player, true)
    var rows: Array = [{"name": String(player["name"]), "assets": _asset_value(), "metrics": player_metrics, "player": true, "merged": false}]
    for rival_raw in rivals:
        var rival: Dictionary = rival_raw
        rows.append({
            "name": String(rival["name"]),
            "assets": _rival_asset_value(rival),
            "metrics": _headline_metrics(rival, false),
            "player": false,
            "merged": bool(rival["merged"])
        })
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
        var m: Dictionary = row["metrics"]
        lines.append("%d. %s • %.2f PH/s • %.2f MW • %.1f J/TH • Cash $%d • Profit $%d • %s" % [i + 1, String(row["name"]), float(m["hashrate_ph"]), float(m["mw"]), float(m["efficiency_jth"]), int(m["cash"]), int(m["profit"]), marker])
    dialog_title.text = "BITCOIN MINING LEAGUE // STANDINGS"
    dialog_text.text = "Ten Bitcoin mining companies. Five headline metrics stay in real units: HASHRATE • MW • J/TH • CASH • PROFIT. Deeper operating metrics still remain in the simulation.\n\n" + "\n".join(lines) + "\n\nLeague order still uses company asset value while the five-metric card makes each miner easy to compare."
    _set_actions([])

func _refresh_league_ui() -> void:
    if is_instance_valid(league_rank_label) and not player.is_empty():
        league_rank_label.text = "LEAGUE #%d / 10" % _player_league_rank()

func _refresh_ui() -> void:
    super._refresh_ui()
    _refresh_league_ui()

func debug_league_standings_ready() -> bool:
    var rows: Array = _league_rows()
    return rows.size() == 10 and _player_league_rank() >= 1 and _player_league_rank() <= 10
