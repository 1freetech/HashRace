extends "res://scripts/world_v113.gd"

# Hash Race v0.114 live energy-site art + capacity-footprint pass.
# The authored 13-system energy atlas is now used by the actual overworld.
# Mining-site scale follows the agreed visual contract:
#   ~1 MW   -> 2x2 tile module
#   ~10 MW  -> 4x4 tile yard
#   ~100 MW -> 8x8 tile campus
# Larger GW/TW tiers reuse compressed 8x8 district blocks so the map remains readable.

const EnergyVisualCatalog = preload("res://systems/energy_visual_catalog.gd")

const V114_ENERGY_SITE_REVISION := 1
const V114_WORLD_TILE := 48.0
const V114_MIN_SITE_MW := 1.0
const V114_DEFAULT_CONTAINER_ORIENTATION := "down"

var v114_energy_texture: Texture2D

func _ready() -> void:
    v114_energy_texture = EnergyVisualCatalog.master_texture()
    super._ready()
    set_meta("hashrace_v114_energy_site_revision", V114_ENERGY_SITE_REVISION)
    set_meta("hashrace_v114_energy_atlas_loaded", v114_energy_texture != null)
    queue_redraw()

func _v114_capacity_mw_for_site(center: Vector2) -> float:
    if center.distance_to(_player_hq_center()) <= 8.0:
        return maxf(V114_MIN_SITE_MW, maxf(_effective_available_mw(), _machine_load_kw() / 1000.0))
    # Rival sites use their live MW values when available; otherwise the visible
    # company district still starts at the 1 MW representation.
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        if String(entity.get("kind", "")) != "rival":
            continue
        if Vector2(entity.get("pos", Vector2.ZERO)).distance_to(center) > 8.0:
            continue
        var rival_idx := int(entity.get("rival_idx", -1))
        if rival_idx >= 0 and rival_idx < rivals.size():
            return maxf(V114_MIN_SITE_MW, float(rivals[rival_idx].get("mw", 1.0)))
    return V114_MIN_SITE_MW

func _v114_footprint_tiles(capacity_mw: float) -> int:
    var profile := InfrastructureVisualCatalog.capacity_profile(maxf(V114_MIN_SITE_MW, capacity_mw))
    return int(Vector2i(profile.get("footprint", Vector2i(2, 2))).x)

func _v114_sprite_size(capacity_mw: float, max_pixels: float = 384.0) -> Vector2:
    var tiles := _v114_footprint_tiles(capacity_mw)
    var pixels := minf(max_pixels, float(tiles) * V114_WORLD_TILE)
    return Vector2(pixels, pixels)

func _v114_primary_energy_id(center: Vector2) -> String:
    if center.distance_to(_player_hq_center()) <= 8.0:
        var deployed_order: Array[String] = [
            "nuclear_smr",
            "hydro_turbine",
            "gas_turbine",
            "coal_plant",
            "solar_array",
            "wind_farm",
            "oil_field",
            "battery",
        ]
        for item_id in deployed_order:
            if infrastructure_inventory.deployed_quantity(item_id) > 0:
                return item_id

        var base_name := String(ENERGIES[int(player.get("energy_idx", 0))]["name"])
        match base_name:
            "Natural Gas": return "gas_turbine"
            "Hydro": return "hydro_turbine"
            "Solar + Storage": return "solar_array"
            "Nuclear PPA": return "nuclear_smr"
            _: return "battery"

    # Deterministic rival diversity so every company site visibly has power.
    var pool: Array[String] = [
        "gas_turbine",
        "hydro_turbine",
        "coal_plant",
        "nuclear_smr",
        "geothermal_generator",
        "lpg_generator",
        "diesel_generator",
        "hydrogen_fuel_cell",
    ]
    return pool[posmod(absi(int(center.x / 48.0) + int(center.y / 48.0)), pool.size())]

func _v114_draw_energy_source(asset_id: String, pos: Vector2, capacity_mw: float, orientation: String = "up") -> void:
    if v114_energy_texture == null:
        return
    var region := EnergyVisualCatalog.source_region(asset_id, orientation)
    if region.size == Vector2.ZERO:
        return
    var size_value := _v114_sprite_size(capacity_mw, 300.0)
    # Energy plants are intentionally capped below the 8x8 mining-container
    # footprint so the energy source and compute facility remain distinct.
    draw_ellipse_shadow(pos + Vector2(0.0, size_value.y * 0.38), size_value.x * 0.34, size_value.y * 0.09)
    var dest := Rect2(pos - size_value * Vector2(0.5, 0.58), size_value)
    draw_texture_rect_region(v114_energy_texture, dest, region)

func _v114_draw_container(pos: Vector2, capacity_mw: float, accent: Color) -> void:
    # The exact 2x2 / 4x4 / 8x8 footprint contract is enforced here. If the
    # authored container PNG is added later, only this renderer changes; scale
    # and placement remain stable.
    var tiles := _v114_footprint_tiles(capacity_mw)
    var size_value := _v114_sprite_size(capacity_mw, 384.0)
    var w := size_value.x
    var h := maxf(72.0, size_value.y * 0.46)
    var rect := Rect2(pos + Vector2(-w * 0.5, -h * 0.52), Vector2(w, h))
    draw_ellipse_shadow(pos + Vector2(0.0, h * 0.46), w * 0.40, maxf(10.0, h * 0.08))
    draw_rect(rect.grow(4.0), Color("091015"), true)
    draw_rect(rect, Color("d6dde0"), true)
    draw_rect(Rect2(rect.position + Vector2(5.0, 5.0), Vector2(rect.size.x - 10.0, 12.0)), Color("eef2f3"), true)
    draw_rect(Rect2(rect.position + Vector2(5.0, 21.0), Vector2(rect.size.x - 10.0, rect.size.y - 26.0)), Color("b9c2c6"), true)
    draw_rect(Rect2(rect.position + Vector2(0.0, 21.0), Vector2(rect.size.x, 5.0)), accent.darkened(0.15), true)

    # Cooling-fan bank: one visible bank represents the capacity tier rather
    # than drawing one fan or one ASIC per real machine.
    var fan_count := clampi(tiles, 2, 8)
    var fan_radius := clampf((w - 34.0) / float(fan_count) * 0.28, 6.0, 18.0)
    for i in range(fan_count):
        var fx := rect.position.x + 17.0 + float(i) * ((rect.size.x - 34.0) / maxf(1.0, float(fan_count - 1)))
        var fy := rect.position.y + rect.size.y * 0.62
        draw_circle(Vector2(fx, fy), fan_radius, Color("172126"))
        draw_circle(Vector2(fx, fy), fan_radius * 0.68, Color("26353d"), false, 2.0)
        draw_line(Vector2(fx - fan_radius * 0.6, fy), Vector2(fx + fan_radius * 0.6, fy), Color("819097"), 1.0)
        draw_line(Vector2(fx, fy - fan_radius * 0.6), Vector2(fx, fy + fan_radius * 0.6), Color("819097"), 1.0)

    # Capacity plate proves the sprite is a tier representation, not a literal
    # one-container-per-unit count.
    var label := "%d MW CLASS • %dx%d" % [int(round(capacity_mw)), tiles, tiles]
    draw_string(
        ThemeDB.fallback_font,
        pos + Vector2(-w * 0.46, -h * 0.09),
        label,
        HORIZONTAL_ALIGNMENT_CENTER,
        w * 0.92,
        10,
        Color("152027")
    )

func _v114_draw_transformer(pos: Vector2, capacity_mw: float) -> void:
    var tiles := _v114_footprint_tiles(capacity_mw)
    var scale := clampf(float(tiles) / 4.0, 0.65, 1.35)
    var body := Vector2(62.0, 58.0) * scale
    draw_ellipse_shadow(pos + Vector2(0.0, body.y * 0.46), body.x * 0.40, 7.0 * scale)
    draw_rect(Rect2(pos - body * Vector2(0.5, 0.55), body), Color("516245"), true)
    draw_rect(Rect2(pos + Vector2(-body.x * 0.40, -body.y * 0.36), Vector2(body.x * 0.80, body.y * 0.52)), Color("64785a"), true)
    for i in range(3):
        var x := pos.x - body.x * 0.28 + float(i) * body.x * 0.28
        draw_line(Vector2(x, pos.y - body.y * 0.48), Vector2(x, pos.y - body.y * 0.76), Color("20272a"), 3.0 * scale)
        draw_circle(Vector2(x, pos.y - body.y * 0.80), 4.0 * scale, Color("20272a"))

func _draw_mining_campus(center: Vector2, accent: Color) -> void:
    var capacity_mw := _v114_capacity_mw_for_site(center)
    var site_size := _v114_sprite_size(capacity_mw)
    var half := site_size.x * 0.5

    # Four essentials only: mining container, energy, transformer, command.
    # Wide offsets preserve negative space as the footprint grows.
    _v114_draw_container(center + Vector2(-half * 0.55, 92.0), capacity_mw, accent)

    var energy_id := _v114_primary_energy_id(center)
    _v114_draw_energy_source(energy_id, center + Vector2(half * 0.58 + 105.0, 72.0), capacity_mw, "up")

    _v114_draw_transformer(center + Vector2(half * 0.60 + 118.0, -105.0), capacity_mw)

    # Command/control stays compact at every tier.
    var command_pos := center + Vector2(-half * 0.58 - 100.0, -104.0)
    var command_size := Vector2(94.0, 64.0)
    draw_ellipse_shadow(command_pos + Vector2(0.0, 28.0), 38.0, 8.0)
    draw_rect(Rect2(command_pos - command_size * Vector2(0.5, 0.52), command_size), Color("17242b"), true)
    draw_rect(Rect2(command_pos + Vector2(-34.0, -20.0), Vector2(68.0, 31.0)), Color("071016"), true)
    draw_rect(Rect2(command_pos + Vector2(-27.0, -14.0), Vector2(54.0, 17.0)), Color("164653"), true)
    draw_line(command_pos + Vector2(-22.0, -4.0), command_pos + Vector2(20.0, -10.0), Color("45dff2"), 2.0)

    if center.distance_to(_player_hq_center()) <= 8.0:
        _v107_draw_site_marker(center + Vector2(half + 155.0, 132.0), accent)

func debug_v114_ready() -> bool:
    var one_mw := _v114_footprint_tiles(1.0)
    var ten_mw := _v114_footprint_tiles(10.0)
    var hundred_mw := _v114_footprint_tiles(100.0)
    return V114_ENERGY_SITE_REVISION == 1         and one_mw == 2         and ten_mw == 4         and hundred_mw == 8         and EnergyVisualCatalog.debug_ready()         and debug_v113_ready()
