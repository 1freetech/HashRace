extends "res://scripts/world_v164.gd"

# v0.165: preserve the full proven gameplay inheritance chain while making the
# existing validated diesel_generator atlas asset a deployable campus source.
# This head also owns dynamic energy collision cleanup and restores NPC visual
# identity without changing the approved player sprite-sheet path.
const V165_DIESEL_ASSET_ID := "diesel_generator"
const V165_DIESEL_REVISION := 2
const V165_CLEANUP_REVISION := 1
const V165_NPC_LABEL_DISTANCE := 300.0
const V165_NPC_CONTRACT_REVISION := 1

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
    var seed := absi(int(pos.x) * 17 + int(pos.y) * 31)
    var skins: Array[Color] = [Color("6f432d"), Color("9b6547"), Color("c48a65"), Color("e2b18a")]
    var skin := skins[seed % skins.size()]
    var jacket := accent.darkened(0.45)
    var panel := accent.lightened(0.12)
    var foot := VisualStack.snap_to_pixel(pos + Vector2(0.0, 43.0))

    draw_ellipse_shadow(foot + Vector2(0.0, 1.0), 18.0, 6.0)
    draw_rect(Rect2(foot + Vector2(-12.0, -21.0), Vector2(9.0, 22.0)), Color("111821"), true)
    draw_rect(Rect2(foot + Vector2(3.0, -21.0), Vector2(9.0, 22.0)), Color("111821"), true)
    draw_rect(Rect2(foot + Vector2(-15.0, -2.0), Vector2(13.0, 5.0)), jacket, true)
    draw_rect(Rect2(foot + Vector2(2.0, -2.0), Vector2(13.0, 5.0)), jacket, true)
    draw_rect(Rect2(foot + Vector2(-17.0, -55.0), Vector2(34.0, 35.0)), jacket, true)
    draw_rect(Rect2(foot + Vector2(-12.0, -49.0), Vector2(24.0, 12.0)), panel, true)
    draw_rect(Rect2(foot + Vector2(-22.0, -49.0), Vector2(7.0, 26.0)), jacket.darkened(0.10), true)
    draw_rect(Rect2(foot + Vector2(15.0, -49.0), Vector2(7.0, 26.0)), jacket.darkened(0.10), true)
    draw_rect(Rect2(foot + Vector2(-10.0, -73.0), Vector2(20.0, 18.0)), skin, true)
    draw_rect(Rect2(foot + Vector2(-12.0, -77.0), Vector2(24.0, 7.0)), Color("15181b"), true)

    var lens_x := -10.0 if scanner == "left" else 2.0
    var temple_x := -14.0 if scanner == "left" else 11.0
    draw_rect(Rect2(foot + Vector2(lens_x, -69.0), Vector2(9.0, 7.0)), Color(accent.r, accent.g, accent.b, 0.92), true)
    draw_rect(Rect2(foot + Vector2(temple_x, -71.0), Vector2(4.0, 12.0)), accent.darkened(0.18), true)
    draw_rect(Rect2(foot + Vector2(-3.0, -34.0), Vector2(6.0, 8.0)), accent, true)

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

# Partner representatives now use the same live negotiation economy as rival and
# computer-company deals. Relationship persists on the player company and feeds
# leverage, so repeated NPC encounters create progression rather than one-click buys.
func _v165_partner_relationship(partner_id: String) -> int:
    var relationships: Dictionary = player.get("partner_relationships", {})
    return clampi(int(relationships.get(partner_id, 50)), 0, 100)

func _v165_set_partner_relationship(partner_id: String, value: int) -> void:
    var relationships: Dictionary = player.get("partner_relationships", {}).duplicate(true)
    relationships[partner_id] = clampi(value, 0, 100)
    player["partner_relationships"] = relationships

func _open_partner_rep(entity: Dictionary) -> void:
    var partner_idx := int(entity.get("partner_idx", -1))
    if partner_idx < 0 or partner_idx >= PARTNERS.size():
        super._open_partner_rep(entity)
        return
    var partner: Dictionary = PARTNERS[partner_idx]
    var rep: Dictionary = PARTNER_REPS[partner_idx]
    var partner_id := String(partner["id"])
    var signed := signed_partners.has(partner_id)
    var relationship := _v165_partner_relationship(partner_id)
    dialog_title.text = "%s // %s" % [String(rep["name"]), String(partner["name"])]
    dialog_text.text = "%s represents %s. Contract: %s. Listed value $%d. Relationship %d/100. Status: %s." % [
        String(rep["name"]), String(partner["sector"]), String(partner["boost"]), int(partner["cost"]),
        relationship, "SIGNED" if signed else "AVAILABLE"
    ]
    if signed:
        dialog_text.text += "\n\nThis representative is now an active operating partner. The contract bonus is already feeding your company simulation."
        _set_actions([])
    else:
        dialog_text.text += "\n\nNegotiate price and terms. Reputation plus this representative relationship improve your leverage."
        _set_actions([{"label":"NEGOTIATE CONTRACT", "call":Callable(self, "_v165_start_partner_negotiation").bind(partner_idx)}])

func _v165_start_partner_negotiation(partner_idx: int) -> Node:
    if partner_idx < 0 or partner_idx >= PARTNERS.size():
        return null
    if not is_instance_valid(negotiation_manager):
        _install_negotiation_manager()
    if not is_instance_valid(negotiation_manager) or _negotiation_is_active():
        return null
    var partner: Dictionary = PARTNERS[partner_idx]
    var rep: Dictionary = PARTNER_REPS[partner_idx]
    var partner_id := String(partner["id"])
    if signed_partners.has(partner_id):
        _feedback("That partnership is already active.")
        return null
    var profile := _player_offer_profile()
    var relationship := _v165_partner_relationship(partner_id)
    var relationship_leverage := clampi(int(roundf((float(relationship) - 50.0) * 0.45)), -22, 22)
    var effective_cost := float(partner["cost"]) * _partner_cost_multiplier()
    var context := {
        "deal_type":"partner_contract",
        "source_kind":"partner_rep",
        "partner_idx":partner_idx,
        "partner_id":partner_id,
        "opponent_name":String(rep["name"]),
        "opponent_company":String(partner["name"]),
        "player_company":String(player.get("name", "Player Mining Co.")),
        "opponent_power":clampi(42 + partner_idx * 5, 35, 82),
        "opponent_greed":clampi(36 + partner_idx * 4, 30, 78),
        "player_reputation":int(profile["reputation"]),
        "player_leverage":clampi(int(profile["leverage"]) + relationship_leverage, 0, 100),
        "deal_value_usd":maxf(1.0, effective_cost),
        "player_cash_usd":maxf(0.0, float(player.get("cash", 0.0))),
        "reward_mw":0.0,
        "deal_label":"STRATEGIC PARTNER CONTRACT",
        "target_asset_label":String(partner["boost"])
    }
    company_news = "%s opened contract talks with your company." % String(rep["name"])
    _feedback(company_news)
    return negotiation_manager.call("launch", self, context) as Node

func _on_negotiation_resolved(result: Dictionary) -> void:
    if String(result.get("deal_type", "")) != "partner_contract":
        super._on_negotiation_resolved(result)
        return
    negotiation_last_result = result.duplicate(true)
    var partner_idx := int(result.get("partner_idx", -1))
    # NegotiationScene preserves generic reward fields, so recover the partner
    # identity from the active manager context for this contract type.
    if partner_idx < 0 and is_instance_valid(negotiation_manager):
        var active_context: Dictionary = negotiation_manager.get("active_context")
        partner_idx = int(active_context.get("partner_idx", -1))
    if partner_idx < 0 or partner_idx >= PARTNERS.size():
        _feedback("Partner contract result could not be resolved.")
        return
    var partner: Dictionary = PARTNERS[partner_idx]
    var partner_id := String(partner["id"])
    var relationship := _v165_partner_relationship(partner_id)
    if not bool(result.get("success", false)):
        if String(result.get("outcome", "")) != "walked_away":
            _v165_set_partner_relationship(partner_id, relationship - 2)
        company_news = "Contract talks with %s ended without a deal." % String(partner["name"])
        _feedback(company_news)
        _refresh_ui()
        return
    var final_cost := maxf(0.0, float(result.get("final_cost_usd", 0.0)))
    if float(player.get("cash", 0.0)) < final_cost:
        _feedback("Terms were accepted, but available cash is no longer sufficient.")
        return
    # Reuse the inherited partner activation path so every established sector
    # bonus remains intact; neutralize its normal price and apply negotiated cost.
    var activation_cost := float(partner["cost"]) * _partner_cost_multiplier()
    player["cash"] = float(player.get("cash", 0.0)) + activation_cost
    var before := signed_partners.size()
    _sign_partner(partner_idx)
    if signed_partners.size() <= before:
        player["cash"] = float(player.get("cash", 0.0)) - activation_cost
        return
    player["cash"] = float(player.get("cash", 0.0)) - final_cost
    _v165_set_partner_relationship(partner_id, relationship + 8)
    company_news = "CONTRACT CLOSED with %s for $%d • relationship %d/100 • %s" % [
        String(partner["name"]), int(roundf(final_cost)), _v165_partner_relationship(partner_id), String(partner["boost"])
    ]
    _feedback(company_news)
    _refresh_ui()

func debug_v165_npc_contract_ready() -> bool:
    return V165_NPC_CONTRACT_REVISION == 1 \
        and has_method("_v165_start_partner_negotiation") \
        and has_method("_v165_partner_relationship") \
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
        "npc_contracts": debug_v165_npc_contract_ready(),
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
