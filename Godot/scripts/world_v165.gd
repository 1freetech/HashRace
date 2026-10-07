extends "res://scripts/world_v164.gd"

# v0.165: preserve the full proven gameplay inheritance chain while making the
# existing validated diesel_generator atlas asset a deployable campus source.
# This head also owns dynamic energy collision cleanup and restores NPC visual
# identity without changing the approved player sprite-sheet path.
const V165_DIESEL_ASSET_ID := "diesel_generator"
const V165_DIESEL_REVISION := 2
const V165_CLEANUP_REVISION := 1
const V165_NPC_LABEL_DISTANCE := 300.0
const V165_RIVAL_RELATIONSHIP_REVISION := 1
const V165_RIVAL_CONTRACT_REVISION := 1

var v165_diesel_drawn := false
var v165_diesel_rect := Rect2()
var v165_diesel_footprint := Rect2()
# Track only cells that were open before diesel occupied them so undeployment
# can remove this layer's collision without carving through inherited buildings.
var v165_diesel_owned_blocked_cells: Array[Vector2i] = []
var v165_diesel_collision_rect := Rect2()

# v0.161 solar and v0.164 wind historically used raw block_rect() calls. The
# live head now wraps them with the same ownership-safe behavior as diesel so a
# source swap or capacity move cannot leave invisible blocked cells behind.
var v165_legacy_energy_owned_blocked_cells: Array[Vector2i] = []
var v165_legacy_energy_collision_rect := Rect2()
var v165_legacy_energy_asset_id := ""

func _ready() -> void:
    super._ready()
    if infrastructure_inventory != null \
        and not infrastructure_inventory.deployment_changed.is_connected(_v165_on_deployment_changed):
        infrastructure_inventory.deployment_changed.connect(_v165_on_deployment_changed)
    _v165_sync_diesel_state()
    set_meta("hashrace_v165_cleanup_revision", V165_CLEANUP_REVISION)
    set_meta("hashrace_v165_distinct_npc_renderer", true)

func _v165_on_deployment_changed() -> void:
    _v165_sync_diesel_state()
    queue_redraw()

func _v165_sync_diesel_state() -> void:
    var deployed := infrastructure_inventory != null \
        and infrastructure_inventory.deployed_quantity(V165_DIESEL_ASSET_ID) > 0
    if not deployed:
        _v165_clear_diesel_collision()
        v165_diesel_drawn = false
        v165_diesel_rect = Rect2()
        v165_diesel_footprint = Rect2()

func _v114_primary_energy_id(center: Vector2) -> String:
    if center.distance_to(_player_hq_center()) <= 8.0 \
        and infrastructure_inventory != null \
        and infrastructure_inventory.deployed_quantity(V165_DIESEL_ASSET_ID) > 0:
        return V165_DIESEL_ASSET_ID
    return super._v114_primary_energy_id(center)

func _v114_draw_energy_source(asset_id: String, pos: Vector2, capacity_mw: float, orientation: String = "up") -> void:
    if asset_id == V165_DIESEL_ASSET_ID:
        _v165_clear_legacy_energy_collision()
        _v165_draw_diesel(pos, capacity_mw, orientation)
        return

    var legacy_foot := _v165_legacy_energy_footprint(asset_id, pos, capacity_mw)
    var changed := legacy_foot.size != Vector2.ZERO and (
        asset_id != v165_legacy_energy_asset_id or legacy_foot != v165_legacy_energy_collision_rect
    )
    var pending_owned: Array[Vector2i] = []

    if legacy_foot.size == Vector2.ZERO:
        _v165_clear_legacy_energy_collision()
    elif changed:
        _v165_clear_legacy_energy_collision()
        if grid_nav != null:
            for cell in _v165_cells_for_rect(legacy_foot):
                if grid_nav.is_walkable(cell):
                    pending_owned.append(cell)

    # Preserve the proven v0.161/v0.164 renderers. Their first raw block_rect()
    # call is harmless because the live head records which cells were free first
    # and becomes the owner responsible for every later clear/rebind.
    super._v114_draw_energy_source(asset_id, pos, capacity_mw, orientation)

    if changed and grid_nav != null:
        v165_legacy_energy_asset_id = asset_id
        v165_legacy_energy_collision_rect = legacy_foot
        v165_legacy_energy_owned_blocked_cells = pending_owned
        for cell in v165_legacy_energy_owned_blocked_cells:
            grid_nav.set_blocked(cell, true)

func _v165_draw_diesel(pos: Vector2, capacity_mw: float, orientation: String) -> void:
    if v114_energy_texture == null:
        return
    var region := EnergyVisualCatalog.source_region(V165_DIESEL_ASSET_ID, orientation)
    if region.size == Vector2.ZERO:
        return
    var side := clampf(86.0 + float(_v114_footprint_tiles(capacity_mw)) * 10.0, 106.0, 150.0)
    var size_value := Vector2(side, side)
    var dest := Rect2(VisualStack.snap_to_pixel(pos - size_value * Vector2(0.5, 0.58)), size_value)
    var foot := Rect2(
        Vector2(dest.position.x + dest.size.x * 0.18, dest.position.y + dest.size.y * 0.72),
        Vector2(dest.size.x * 0.64, dest.size.y * 0.20)
    )
    v165_diesel_drawn = true
    v165_diesel_rect = dest
    v165_diesel_footprint = foot
    _v165_block_diesel_collision(foot)
    draw_ellipse_shadow(pos + Vector2(0.0, side * 0.34), side * 0.30, side * 0.07)
    _v127_draw_region(v114_energy_texture, region, dest)

func _v165_legacy_energy_footprint(asset_id: String, pos: Vector2, capacity_mw: float) -> Rect2:
    if asset_id == "solar_array" and V161Solar.valid_texture(v161_solar_texture):
        var solar_dest := V161Solar.destination(pos, _v114_footprint_tiles(capacity_mw))
        return V161Solar.ground_contact(solar_dest)
    if asset_id == "wind_farm" and v164_wind_texture != null:
        var footprint_tiles := _v114_footprint_tiles(capacity_mw)
        var side := clampf(72.0 + float(footprint_tiles) * 14.0, 100.0, 184.0)
        var wind_dest := Rect2(VisualStack.snap_to_pixel(pos - Vector2(side, side) * 0.5), Vector2(side, side))
        return Rect2(
            Vector2(wind_dest.position.x + wind_dest.size.x * 0.27, wind_dest.position.y + wind_dest.size.y * 0.72),
            Vector2(wind_dest.size.x * 0.46, wind_dest.size.y * 0.20)
        )
    return Rect2()

func _v165_clear_legacy_energy_collision() -> void:
    if grid_nav != null:
        for cell in v165_legacy_energy_owned_blocked_cells:
            grid_nav.set_blocked(cell, false)
    v165_legacy_energy_owned_blocked_cells.clear()
    v165_legacy_energy_collision_rect = Rect2()
    v165_legacy_energy_asset_id = ""

func _v165_block_diesel_collision(foot: Rect2) -> void:
    if grid_nav == null or foot.size == Vector2.ZERO:
        return
    # If capacity/placement moves the generator, release only cells previously
    # owned by this layer before registering the new footprint.
    if not v165_diesel_owned_blocked_cells.is_empty() and v165_diesel_collision_rect != foot:
        _v165_clear_diesel_collision()
    if not v165_diesel_owned_blocked_cells.is_empty():
        return
    v165_diesel_collision_rect = foot
    for cell in _v165_cells_for_rect(foot):
        if grid_nav.is_walkable(cell):
            v165_diesel_owned_blocked_cells.append(cell)
            grid_nav.set_blocked(cell, true)

func _v165_clear_diesel_collision() -> void:
    if grid_nav != null:
        for cell in v165_diesel_owned_blocked_cells:
            grid_nav.set_blocked(cell, false)
    v165_diesel_owned_blocked_cells.clear()
    v165_diesel_collision_rect = Rect2()

func _v165_cells_for_rect(rect: Rect2) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if grid_nav == null or rect.size == Vector2.ZERO:
        return result
    var min_cell: Vector2i = grid_nav.world_to_cell(rect.position)
    var max_cell: Vector2i = grid_nav.world_to_cell(rect.end - Vector2.ONE)
    for y in range(min_cell.y, max_cell.y + 1):
        for x in range(min_cell.x, max_cell.x + 1):
            result.append(Vector2i(x, y))
    return result

# v0.157 intentionally reused the approved player sheet for every stationary
# representative. Keep that sheet exclusively for the player; NPCs use a small
# deterministic field-tech renderer keyed by their existing accent/scanner data.
func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if is_player:
        super._draw_tech_rep(pos, accent, scanner, true)
        return
    _v165_draw_npc_rep(pos, accent, scanner)

func _v165_draw_npc_rep(pos: Vector2, accent: Color, scanner: String) -> void:
    # Compact pixel-art field rep: readable at gameplay zoom without competing
    # with the approved player sprite. Feet remain anchored to the entity pos.
    var seed := absi(int(pos.x) * 17 + int(pos.y) * 31)
    var skins: Array[Color] = [Color("6f432d"), Color("9b6547"), Color("c48a65"), Color("e2b18a")]
    var skin := skins[seed % skins.size()]
    var skin_shadow := skin.darkened(0.22)
    var jacket := accent.darkened(0.52)
    var jacket_mid := accent.darkened(0.24)
    var safety := accent.lightened(0.16)
    var pants := Color("18232c")
    var boot := Color("090d11")
    var foot := VisualStack.snap_to_pixel(pos + Vector2(0.0, 43.0))

    draw_ellipse_shadow(foot + Vector2(0.0, 2.0), 17.0, 5.0)

    # Boots/legs: separated silhouettes make the NPC read as a character.
    draw_rect(Rect2(foot + Vector2(-11.0, -20.0), Vector2(8.0, 18.0)), pants, true)
    draw_rect(Rect2(foot + Vector2(3.0, -20.0), Vector2(8.0, 18.0)), pants.lightened(0.05), true)
    draw_rect(Rect2(foot + Vector2(-13.0, -4.0), Vector2(11.0, 6.0)), boot, true)
    draw_rect(Rect2(foot + Vector2(2.0, -4.0), Vector2(12.0, 6.0)), boot, true)

    # Jacket, safety vest and arms.
    draw_rect(Rect2(foot + Vector2(-16.0, -53.0), Vector2(32.0, 34.0)), Color("0a0f13"), true)
    draw_rect(Rect2(foot + Vector2(-14.0, -51.0), Vector2(28.0, 30.0)), jacket, true)
    draw_rect(Rect2(foot + Vector2(-9.0, -49.0), Vector2(18.0, 25.0)), jacket_mid, true)
    draw_rect(Rect2(foot + Vector2(-9.0, -47.0), Vector2(4.0, 22.0)), safety, true)
    draw_rect(Rect2(foot + Vector2(5.0, -47.0), Vector2(4.0, 22.0)), safety, true)
    draw_rect(Rect2(foot + Vector2(-9.0, -37.0), Vector2(18.0, 3.0)), safety, true)
    draw_rect(Rect2(foot + Vector2(-21.0, -48.0), Vector2(7.0, 23.0)), jacket_mid, true)
    draw_rect(Rect2(foot + Vector2(14.0, -48.0), Vector2(7.0, 23.0)), jacket_mid, true)
    draw_rect(Rect2(foot + Vector2(-22.0, -27.0), Vector2(8.0, 7.0)), skin, true)
    draw_rect(Rect2(foot + Vector2(14.0, -27.0), Vector2(8.0, 7.0)), skin, true)

    # Neck/head/hair with face pixels; deliberately more character-like than
    # the previous block mannequin while remaining deterministic and logo-free.
    draw_rect(Rect2(foot + Vector2(-5.0, -58.0), Vector2(10.0, 8.0)), skin_shadow, true)
    draw_rect(Rect2(foot + Vector2(-11.0, -76.0), Vector2(22.0, 20.0)), Color("080b0e"), true)
    draw_rect(Rect2(foot + Vector2(-9.0, -74.0), Vector2(18.0, 17.0)), skin, true)
    draw_rect(Rect2(foot + Vector2(-9.0, -74.0), Vector2(18.0, 5.0)), Color("111317"), true)
    draw_rect(Rect2(foot + Vector2(-7.0, -66.0), Vector2(3.0, 3.0)), Color("101317"), true)
    draw_rect(Rect2(foot + Vector2(4.0, -66.0), Vector2(3.0, 3.0)), Color("101317"), true)
    draw_rect(Rect2(foot + Vector2(-2.0, -59.0), Vector2(5.0, 2.0)), skin_shadow, true)

    # Scanner/tablet gives every rep a clear gameplay role.
    var lens_x := -10.0 if scanner == "left" else 2.0
    var temple_x := -13.0 if scanner == "left" else 10.0
    draw_rect(Rect2(foot + Vector2(lens_x, -68.0), Vector2(8.0, 6.0)), Color(accent.r, accent.g, accent.b, 0.95), true)
    draw_rect(Rect2(foot + Vector2(temple_x, -69.0), Vector2(3.0, 9.0)), accent, true)
    draw_rect(Rect2(foot + Vector2(15.0, -42.0), Vector2(9.0, 12.0)), Color("0d171c"), true)
    draw_rect(Rect2(foot + Vector2(17.0, -40.0), Vector2(5.0, 7.0)), safety, true)

func _draw_neon_character_name(pos: Vector2, character_name: String) -> void:
    # The player already has a dedicated HUD identity. Show NPC names only when
    # the player is close enough to interact, or when that representative is selected.
    if pos.distance_to(rep_pos) <= 2.0:
        return
    var entity_idx := -1
    var accent := Color("39ff75")
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind := String(entity.get("kind", ""))
        if kind != "partner_rep" and kind != "rival_rep":
            continue
        if Vector2(entity.get("pos", Vector2.ZERO)).distance_to(pos) <= 2.0:
            entity_idx = i
            accent = entity.get("accent", accent)
            break
    if entity_idx < 0:
        return
    if entity_idx != selected_entity_idx and rep_pos.distance_to(pos) > V165_NPC_LABEL_DISTANCE:
        return
    var width := 170.0
    var base := VisualStack.snap_to_pixel(pos + Vector2(-width * 0.5, -92.0))
    var plate := Rect2(base + Vector2(18.0, -14.0), Vector2(width - 36.0, 20.0))
    draw_rect(plate, Color("020609d8"), true)
    draw_line(Vector2(plate.position.x + 7.0, plate.end.y - 2.0), Vector2(plate.end.x - 7.0, plate.end.y - 2.0), accent, 1.0)
    draw_string(ThemeDB.fallback_font, base + Vector2(1.0, 1.0), character_name, HORIZONTAL_ALIGNMENT_CENTER, width, 12, Color("020609"))
    draw_string(ThemeDB.fallback_font, base, character_name, HORIZONTAL_ALIGNMENT_CENTER, width, 12, Color("eaffef"))

# Rival representatives now maintain campaign relationship history and expose
# economically distinct negotiations instead of routing every meeting to MW access.
func _v165_rival_relationship(rival_idx: int) -> int:
    var relationships: Dictionary = player.get("rival_relationships", {})
    return clampi(int(relationships.get(str(rival_idx), 50)), 0, 100)

func _v165_set_rival_relationship(rival_idx: int, value: int) -> void:
    var relationships: Dictionary = player.get("rival_relationships", {}).duplicate(true)
    relationships[str(rival_idx)] = clampi(value, 0, 100)
    player["rival_relationships"] = relationships

func _open_rival_rep(entity: Dictionary) -> void:
    var rival_idx := int(entity.get("rival_idx", -1))
    if rival_idx < 0 or rival_idx >= rivals.size():
        super._open_rival_rep(entity)
        return
    var rival: Dictionary = rivals[rival_idx]
    if bool(rival.get("merged", false)):
        super._open_rival_rep(entity)
        return
    var relationship := _v165_rival_relationship(rival_idx)
    super._open_rival_rep(entity)
    var contract_count := _v165_rival_contract_count(rival_idx)
    dialog_text.text += "\n\nRELATIONSHIP %d/100 • ACTIVE CONTRACTS %d\nBetter history improves deal leverage and merger positioning. Choose the resource you actually need." % [relationship, contract_count]
    var actions: Array = [
        {"label":"HOSTING CONTRACT", "call":Callable(self, "_v165_start_rival_deal").bind(rival_idx, "hosting")},
        {"label":"POWER CONTRACT", "call":Callable(self, "_v165_start_rival_deal").bind(rival_idx, "power")},
        {"label":"BUY ASIC LOT", "call":Callable(self, "_v165_start_rival_deal").bind(rival_idx, "asics")},
        {"label":"CAPACITY SWAP", "call":Callable(self, "_v165_start_rival_deal").bind(rival_idx, "capacity")},
        {"label":"VIEW COMPANY", "call":Callable(self, "_open_rival").bind(entity)}
    ]
    if not merger_used:
        actions.append({"label":"PROPOSE MERGER", "call":Callable(self, "_merge_rival").bind(rival_idx)})
    _set_actions(actions)

func _v165_rival_contract_count(rival_idx: int) -> int:
    var count := 0
    var contracts: Array = player.get("rival_contracts", [])
    for raw_contract in contracts:
        var contract: Dictionary = raw_contract
        if int(contract.get("rival_idx", -1)) == rival_idx:
            count += 1
    return count

func _v165_record_rival_contract(result: Dictionary) -> void:
    if String(result.get("deal_type", "")) == "rival_asics":
        return
    var contracts: Array = player.get("rival_contracts", []).duplicate(true)
    contracts.append({
        "rival_idx": int(result.get("rival_idx", -1)),
        "deal_type": String(result.get("deal_type", "")),
        "label": String(result.get("deal_label", "RIVAL CONTRACT")),
        "term_months": 24 if String(result.get("deal_type", "")) == "rival_power" else 12
    })
    player["rival_contracts"] = contracts

func _v165_start_rival_deal(rival_idx: int, deal_type: String) -> Node:
    if rival_idx < 0 or rival_idx >= rivals.size():
        return null
    if not is_instance_valid(negotiation_manager):
        _install_negotiation_manager()
    if not is_instance_valid(negotiation_manager) or _negotiation_is_active():
        return null
    var rival: Dictionary = rivals[rival_idx]
    if bool(rival.get("merged", false)):
        return null
    var personality: Dictionary = rival.get("personality", {}) if rival.get("personality", {}) is Dictionary else {}
    var profile := _player_offer_profile()
    var relationship := _v165_rival_relationship(rival_idx)
    var leverage := clampi(int(profile["leverage"]) + int(roundf((relationship - 50) * 0.40)), 0, 100)
    var tech := maxi(0, int(rival.get("tech_level", 0)))
    var rival_cash := maxf(0.0, float(rival.get("cash", 0.0)))
    var context := {
        "deal_type":"rival_" + deal_type,
        "source_kind":"rival_rep",
        "rival_idx":rival_idx,
        "opponent_name":String(rival.get("name", "Rival Miner")),
        "opponent_company":String(rival.get("name", "Rival Mining Co.")),
        "player_company":String(player.get("name", "Player Mining Co.")),
        "opponent_power":clampi(int(personality.get("operations", 50)), 0, 100),
        "opponent_greed":clampi(int(personality.get("aggression", 50)), 0, 100),
        "player_reputation":int(profile["reputation"]),
        "player_leverage":leverage,
        "player_cash_usd":maxf(0.0, float(player.get("cash", 0.0))),
        "reward_mw":0.0,
        "reward_machines":0,
        "deal_label":"RIVAL CONTRACT",
        "target_asset_label":"RESOURCE ACCESS"
    }
    match deal_type:
        "hosting":
            var machines := clampi(6 + tech * 2, 6, 16)
            context["deal_value_usd"] = clampf(7000.0 + rival_cash * 0.008, 7000.0, 18000.0)
            context["reward_machines"] = machines
            context["deal_label"] = "HOSTING CONTRACT"
            context["target_asset_label"] = "%d HOSTED ASIC SLOTS" % machines
        "power":
            var mw := clampf(0.04 + tech * 0.01, 0.04, 0.09)
            context["deal_value_usd"] = clampf(5500.0 + rival_cash * 0.006, 5500.0, 15000.0)
            context["reward_mw"] = mw
            context["deal_label"] = "POWER PURCHASE AGREEMENT"
            context["target_asset_label"] = "%.2f MW CONTRACT POWER" % mw
        "asics":
            var machines := clampi(4 + tech * 2, 4, 12)
            context["deal_value_usd"] = clampf(float(machines) * 1150.0, 4600.0, 13800.0)
            context["reward_machines"] = machines
            context["deal_label"] = "ASIC LOT PURCHASE"
            context["target_asset_label"] = "%d RIVAL ASICs" % machines
        _:
            var mw := clampf(0.03 + tech * 0.008, 0.03, 0.07)
            context["deal_value_usd"] = clampf(4000.0 + rival_cash * 0.004, 4000.0, 11000.0)
            context["reward_mw"] = mw
            context["deal_label"] = "CAPACITY SWAP"
            context["target_asset_label"] = "%.2f MW FLEX CAPACITY" % mw
    company_news = "%s opened %s talks. Relationship %d/100." % [String(rival.get("name", "Rival")), String(context["deal_label"]), relationship]
    _feedback(company_news)
    return negotiation_manager.call("launch", self, context) as Node

func _on_negotiation_resolved(result: Dictionary) -> void:
    var deal_type := String(result.get("deal_type", ""))
    if not deal_type.begins_with("rival_"):
        super._on_negotiation_resolved(result)
        return
    negotiation_last_result = result.duplicate(true)
    var rival_idx := int(result.get("rival_idx", -1))
    if rival_idx < 0 or rival_idx >= rivals.size():
        return
    var relationship := _v165_rival_relationship(rival_idx)
    if not bool(result.get("success", false)):
        if String(result.get("outcome", "")) != "walked_away":
            _v165_set_rival_relationship(rival_idx, relationship - 3)
        company_news = "Talks with %s ended without a deal. Relationship %d/100." % [String(rivals[rival_idx].get("name", "rival")), _v165_rival_relationship(rival_idx)]
        _feedback(company_news)
        _refresh_ui()
        return
    var cost := maxf(0.0, float(result.get("final_cost_usd", 0.0)))
    if float(player.get("cash", 0.0)) < cost:
        _feedback("Agreed rival terms exceed available cash.")
        return
    var reward_mw := maxf(0.0, float(result.get("reward_mw", 0.0)))
    var reward_machines := maxi(0, int(result.get("reward_machines", 0)))
    player["cash"] = float(player.get("cash", 0.0)) - cost
    player["mw"] = float(player.get("mw", 0.0)) + reward_mw
    player["machines"] = int(player.get("machines", 0)) + reward_machines
    var rival: Dictionary = rivals[rival_idx]
    rival["cash"] = float(rival.get("cash", 0.0)) + cost
    if deal_type == "rival_asics" and reward_machines > 0:
        rival["machines"] = maxi(0, int(rival.get("machines", 0)) - reward_machines)
    rivals[rival_idx] = rival
    _v165_set_rival_relationship(rival_idx, relationship + 7)
    _v165_record_rival_contract(result)
    company_news = "DEAL CLOSED with %s: %s for $%d • relationship %d/100." % [String(rival.get("name", "rival")), String(result.get("target_asset_label", "contract")), int(roundf(cost)), _v165_rival_relationship(rival_idx)]
    _feedback(company_news)
    _refresh_ui()

func _merger_acceptance_chance(rival: Dictionary, offer_price: float) -> float:
    var base := super._merger_acceptance_chance(rival, offer_price)
    var rival_idx := rivals.find(rival)
    if rival_idx < 0:
        return base
    var relationship := _v165_rival_relationship(rival_idx)
    return clampf(base + (float(relationship) - 50.0) * 0.20, 1.0, 99.0)

func debug_v165_rival_relationship_ready() -> bool:
    return V165_RIVAL_RELATIONSHIP_REVISION == 1 \
        and has_method("_v165_start_rival_deal") \
        and has_method("_v165_rival_relationship") \
        and is_instance_valid(negotiation_manager)

# Equipment reliability is authored by the live ArchiveSpriteProps interaction
# layer through player["equipment_uptime_penalty"]. Applying it here means the
# existing v0.090 turn/dispatch economics automatically reduce mined BTC and
# revenue while a physical campus fault remains unresolved.
func _equipment_uptime_penalty() -> float:
    if player.is_empty():
        return 0.0
    return clampf(float(player.get("equipment_uptime_penalty", 0.0)), 0.0, 0.12)

func _uptime_without_grid_penalty() -> float:
    var base := super._uptime_without_grid_penalty()
    return clampf(base - _equipment_uptime_penalty(), 0.60, 0.999)

func debug_v165_npc_identity_ready() -> bool:
    var names: Dictionary = {}
    var accents: Dictionary = {}
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        var kind := String(entity.get("kind", ""))
        if kind != "partner_rep" and kind != "rival_rep":
            continue
        names[str(entity.get("name", ""))] = true
        accents[str(entity.get("accent", Color.WHITE))] = true
    return bool(get_meta("hashrace_v165_distinct_npc_renderer", false)) \
        and names.size() >= 2 \
        and accents.size() >= 2

# Current-world readiness is semantic rather than a chain of historical visual
# proof functions. Dedicated v0.163/v0.164 workflows still validate their exact
# render contracts; this state answers whether the actual live v0.165 gameplay
# world is initialized and safe to exercise.
func debug_v165_runtime_state() -> Dictionary:
    return {
        "revision": V165_DIESEL_REVISION == 2 and V165_CLEANUP_REVISION == 1,
        "inventory": infrastructure_inventory != null,
        "catalog": infrastructure_inventory != null and infrastructure_inventory.debug_resource_catalog_ready(),
        "navigation": grid_nav != null and grid_nav.debug_native_astar_ready(),
        "player": not player.is_empty(),
        "camera": camera != null and camera.is_inside_tree(),
        "entities": not entities.is_empty(),
        "energy_atlas": v114_energy_texture != null,
        "wind_asset": V164Wind.debug_ready(),
        "v164_cleanup": bool(get_meta("hashrace_v164_player_underfoot_decor_removed", false)),
        "npc_identity": debug_v165_npc_identity_ready(),
        "rival_relationships": debug_v165_rival_relationship_ready(),
        "clean_equipment_uptime": _equipment_uptime_penalty() == 0.0,
    }

func debug_v165_runtime_ready() -> bool:
    var state := debug_v165_runtime_state()
    for ready in state.values():
        if not bool(ready):
            return false
    return true

func debug_v165_diesel_ready() -> bool:
    if infrastructure_inventory == null or infrastructure_inventory.deployed_quantity(V165_DIESEL_ASSET_ID) <= 0:
        return false
    return V165_DIESEL_REVISION == 2 \
        and v165_diesel_drawn \
        and v165_diesel_rect.size.x >= 106.0 \
        and v165_diesel_footprint.size.x > 0.0 \
        and v114_energy_texture != null \
        and grid_nav != null \
        and not v165_diesel_owned_blocked_cells.is_empty() \
        and not grid_nav.world_is_walkable(v165_diesel_footprint.get_center()) \
        and V164Wind.debug_ready() \
        and bool(get_meta("hashrace_v164_player_underfoot_decor_removed", false))
