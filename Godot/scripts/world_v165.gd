extends "res://scripts/world_v164.gd"

# v0.165: make the existing validated diesel_generator atlas asset a real,
# deployable player-campus energy source. This is one asset integration only.
# Composition-first rule: diesel occupies the established power-side slot,
# upstream of transformer/distribution and opposite the mining load.
const V165_DIESEL_ASSET_ID := "diesel_generator"
const V165_DIESEL_REVISION := 1
var v165_diesel_drawn := false
var v165_diesel_rect := Rect2()
var v165_diesel_footprint := Rect2()

func _v114_primary_energy_id(center: Vector2) -> String:
    if center.distance_to(_player_hq_center()) <= 8.0     and infrastructure_inventory != null     and infrastructure_inventory.deployed_quantity(V165_DIESEL_ASSET_ID) > 0:
        return V165_DIESEL_ASSET_ID
    return super._v114_primary_energy_id(center)

func _v114_draw_energy_source(asset_id: String, pos: Vector2, capacity_mw: float, orientation: String = "up") -> void:
    if asset_id != V165_DIESEL_ASSET_ID:
        super._v114_draw_energy_source(asset_id, pos, capacity_mw, orientation)
        return

    # Reuse the already validated/decodeable authored energy atlas region rather
    # than procedural geometry. Keep a compact industrial footprint so it cannot
    # collide with the transformer, road, labels, or mining container.
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
    if grid_nav != null:
        grid_nav.block_rect(foot)
    draw_ellipse_shadow(pos + Vector2(0.0, side * 0.34), side * 0.30, side * 0.07)
    _v127_draw_region(v114_energy_texture, region, dest)

func debug_v165_diesel_ready() -> bool:
    return V165_DIESEL_REVISION == 1         and v165_diesel_drawn         and v165_diesel_rect.size.x >= 106.0         and v114_energy_texture != null         and grid_nav != null         and v165_diesel_footprint.size.x > 0.0         and not grid_nav.world_is_walkable(v165_diesel_footprint.get_center())
