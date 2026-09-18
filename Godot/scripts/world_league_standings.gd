extends "res://scripts/world_company_effects.gd"

const InfrastructureInventory = preload("res://scripts/infrastructure_inventory.gd")
var infrastructure_inventory = InfrastructureInventory.new()
var inventory_button: Button
var inventory_item_idx: int = 0

# Ten-company Bitcoin mining league plus playable infrastructure inventory.
var league_button: Button
var league_rank_label: Label

func _ready() -> void:
    super._ready()
    _install_league_ui()
    _install_inventory_ui()
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

func _install_inventory_ui() -> void:
    inventory_button = Button.new()
    inventory_button.position = Vector2(1080.0, 88.0)
    inventory_button.size = Vector2(150.0, 42.0)
    inventory_button.text = "INFRASTRUCTURE"
    inventory_button.tooltip_text = "Buy, store, deploy, and undeploy mining infrastructure."
    inventory_button.add_theme_font_size_override("font_size", 11)
    inventory_button.pressed.connect(_open_infrastructure_inventory)
    league_button.get_parent().add_child(inventory_button)

func _selected_inventory_item() -> Dictionary:
    inventory_item_idx = clampi(inventory_item_idx, 0, InfrastructureInventory.CATALOG.size() - 1)
    return InfrastructureInventory.CATALOG[inventory_item_idx]

func _open_infrastructure_inventory() -> void:
    var prototype: Dictionary = _selected_inventory_item()
    var id: String = String(prototype["id"])
    var owned: int = infrastructure_inventory.quantity(id)
    var stored: int = infrastructure_inventory.stored_quantity(id)
    var deployed: int = infrastructure_inventory.deployed_quantity(id)
    dialog_title.text = "INFRASTRUCTURE // %d OF %d" % [inventory_item_idx + 1, InfrastructureInventory.CATALOG.size()]
    dialog_text.text = "%s\n%s • $%d\nBenefit: %s %s\n\nCash: $%d\nOwned: %d • Stored: %d • Deployed: %d\n\nBuying puts equipment in storage. Deploying activates its company benefit. Undeploying returns it to storage." % [String(prototype["name"]), String(prototype["category"]), int(prototype["price"]), String(prototype["effect"]), String(prototype["unit"]), int(player["cash"]), owned, stored, deployed]
    var actions: Array = [
        {"label":"< PREV", "call":Callable(self, "_inventory_prev")},
        {"label":"NEXT >", "call":Callable(self, "_inventory_next")},
        {"label":"BUY 1", "call":Callable(self, "_inventory_buy")}
    ]
    if bool(prototype.get("deployable", true)) and stored > 0:
        actions.append({"label":"DEPLOY 1", "call":Callable(self, "_inventory_deploy")})
    if bool(prototype.get("deployable", true)) and deployed > 0:
        actions.append({"label":"STORE 1", "call":Callable(self, "_inventory_undeploy")})
    _set_actions(actions)

func _inventory_prev() -> void:
    inventory_item_idx = (inventory_item_idx - 1 + InfrastructureInventory.CATALOG.size()) % InfrastructureInventory.CATALOG.size()
    _open_infrastructure_inventory()

func _inventory_next() -> void:
    inventory_item_idx = (inventory_item_idx + 1) % InfrastructureInventory.CATALOG.size()
    _open_infrastructure_inventory()

func _inventory_buy() -> void:
    var prototype: Dictionary = _selected_inventory_item()
    var id: String = String(prototype["id"])
    if not infrastructure_inventory.purchase(id, player, 1):
        _feedback("Cannot buy %s. You need $%d cash." % [String(prototype["name"]), int(prototype["price"])])
        return
    _open_infrastructure_inventory()
    _refresh_ui()

func _inventory_deploy() -> void:
    var prototype: Dictionary = _selected_inventory_item()
    if not infrastructure_inventory.deploy(String(prototype["id"]), player, 1):
        _feedback("No stored %s is ready to deploy." % String(prototype["name"]))
        return
    _open_infrastructure_inventory()
    _refresh_ui()

func _inventory_undeploy() -> void:
    var prototype: Dictionary = _selected_inventory_item()
    if not infrastructure_inventory.undeploy(String(prototype["id"]), player, 1):
        _feedback("No deployed %s can be returned to storage." % String(prototype["name"]))
        return
    _open_infrastructure_inventory()
    _refresh_ui()

func _rival_asset_value(rival: Dictionary) -> float:
    return maxf(0.0, float(rival["cash"])) + float(rival["sats"]) / SATS_PER_BTC * btc_price + float(rival["mw"]) * 90000.0 + float(rival["acres"]) * land_price_per_acre + float(rival["machines"]) * 700.0

func _headline_metrics(company: Dictionary, is_player: bool) -> Dictionary:
    var machines: float = float(company["machines"])
    var machine: Dictionary = MACHINES[int(player["machine_tier"])] if is_player else MACHINES[0]
    var hashrate_ph: float = (_hashrate_th() if is_player else machines * float(machine["th"])) / 1000.0
    if is_player:
        hashrate_ph += float(company.get("inventory_hashrate_ph", 0.0))
    var efficiency_jth: float = float(machine["kw"]) * 1000.0 / float(machine["th"])
    if is_player:
        efficiency_jth *= float(company.get("inventory_efficiency_multiplier", 1.0))
    return {"hashrate_ph":hashrate_ph,"mw":float(company["mw"]),"efficiency_jth":efficiency_jth,"cash":float(company["cash"]),"profit":float(company.get("last_profit",0.0))}

func _league_rows() -> Array:
    var rows: Array = [{"name":String(player["name"]),"assets":_asset_value(),"metrics":_headline_metrics(player,true),"player":true,"merged":false}]
    for rival_raw in rivals:
        var rival: Dictionary = rival_raw
        rows.append({"name":String(rival["name"]),"assets":_rival_asset_value(rival),"metrics":_headline_metrics(rival,false),"player":false,"merged":bool(rival["merged"])})
    for i in range(rows.size()):
        var best_idx: int = i
        for j in range(i + 1, rows.size()):
            if float(rows[j]["assets"]) > float(rows[best_idx]["assets"]): best_idx = j
        if best_idx != i:
            var swap_row: Dictionary = rows[i]
            rows[i] = rows[best_idx]
            rows[best_idx] = swap_row
    return rows

func _player_league_rank() -> int:
    var rows: Array = _league_rows()
    for i in range(rows.size()):
        if bool(rows[i]["player"]): return i + 1
    return rows.size()

func _open_league_standings() -> void:
    var rows: Array = _league_rows()
    var lines: Array[String] = []
    for i in range(rows.size()):
        var row: Dictionary = rows[i]
        var marker: String = "YOU" if bool(row["player"]) else ("MERGED" if bool(row["merged"]) else "RIVAL")
        var m: Dictionary = row["metrics"]
        lines.append("%d. %s • %.2f PH/s • %.2f MW • %.1f J/TH • Cash $%d • Profit $%d • %s" % [i + 1,String(row["name"]),float(m["hashrate_ph"]),float(m["mw"]),float(m["efficiency_jth"]),int(m["cash"]),int(m["profit"]),marker])
    dialog_title.text = "BITCOIN MINING LEAGUE // STANDINGS"
    dialog_text.text = "Ten Bitcoin mining companies. Five headline metrics stay in real units: HASHRATE • MW • J/TH • CASH • PROFIT.\n\n" + "\n".join(lines)
    _set_actions([])

func _refresh_league_ui() -> void:
    if is_instance_valid(league_rank_label) and not player.is_empty(): league_rank_label.text = "LEAGUE #%d / 10" % _player_league_rank()

func _refresh_ui() -> void:
    super._refresh_ui()
    _refresh_league_ui()

func debug_league_standings_ready() -> bool:
    var rows: Array = _league_rows()
    return rows.size() == 10 and _player_league_rank() >= 1 and _player_league_rank() <= 10
