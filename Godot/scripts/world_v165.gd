extends "res://scripts/world_v164.gd"

# v0.165: preserve the full proven gameplay inheritance chain while making the
# existing validated diesel_generator atlas asset a deployable campus source.
const V165_DIESEL_ASSET_ID := "diesel_generator"
const V165_DIESEL_REVISION := 2
var v165_diesel_drawn := false
var v165_diesel_rect := Rect2()
var v165_diesel_footprint := Rect2()
# Track only cells that were open before diesel occupied them so undeployment
# can remove this layer's collision without carving through inherited buildings.
var v165_diesel_owned_blocked_cells: Array[Vector2i] = []
var v165_diesel_collision_rect := Rect2()

func _ready() -> void:
    super._ready()
    if infrastructure_inventory != null \
        and not infrastructure_inventory.deployment_changed.is_connected(_v165_on_deployment_changed):
        infrastructure_inventory.deployment_changed.connect(_v165_on_deployment_changed)
    _v165_sync_diesel_state()

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
    if asset_id != V165_DIESEL_ASSET_ID:
        super._v114_draw_energy_source(asset_id, pos, capacity_mw, orientation)
        return

    if v114_energy_texture == null:
        return
    var region := EnergyVisualCatalog.source_region(asset_id, orientation)
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

# Current-world readiness is intentionally independent of whether diesel or wind
# is selected right now. It validates the actual live v0.165 chain, native
# navigation/inventory, the inherited v0.163 physical world, and v0.164's asset
# and visual-cleanup contracts without demanding mutually exclusive generators.
func debug_v165_runtime_ready() -> bool:
    return V165_DIESEL_REVISION == 2 \
        and infrastructure_inventory != null \
        and infrastructure_inventory.debug_resource_catalog_ready() \
        and grid_nav != null \
        and grid_nav.debug_native_astar_ready() \
        and not player.is_empty() \
        and _equipment_uptime_penalty() == 0.0 \
        and V164Wind.debug_ready() \
        and bool(get_meta("hashrace_v164_player_underfoot_decor_removed", false)) \
        and debug_v163_ready()

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
        and bool(get_meta("hashrace_v164_player_underfoot_decor_removed", false)) \
        and debug_v163_ready()
