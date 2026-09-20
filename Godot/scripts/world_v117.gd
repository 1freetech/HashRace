extends "res://scripts/world_v116.gd"

# Hash Race v0.117 complete energy-library wiring.
#
# The authored 13-system atlas is now a live gameplay renderer, not just source
# art. Every energy ItemResource can appear on the player's site when deployed.
# The module frame is selected from UP/DOWN/LEFT/RIGHT by the direction of the
# electrical bus/transformer.
#
# Scale contract:
#   0-2 MW      -> 2x2
#   >2-10 MW    -> 4x4
#   >10-25 MW   -> 6x6
#   >25-100 MW  -> 8x8
#   >100 MW     -> compressed 8x8 campus/district blocks through 1 TW
#
# Exact simulation MW stays exact. Only the world representation is compressed.

const V117_ENERGY_LIBRARY_REVISION := 1
const V117_MAX_VISIBLE_DISTRICTS := 10
const V117_ENERGY_IDS: Array[String] = [
    "battery",
    "solar_array",
    "wind_farm",
    "gas_turbine",
    "hydro_turbine",
    "oil_field",
    "coal_plant",
    "nuclear_smr",
    "methane_generator",
    "diesel_generator",
    "geothermal_generator",
    "lpg_generator",
    "hydrogen_fuel_cell",
]

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v117_energy_library_revision", V117_ENERGY_LIBRARY_REVISION)
    set_meta("hashrace_v117_energy_system_count", V117_ENERGY_IDS.size())
    set_meta("hashrace_v117_energy_atlas_loaded", v114_energy_texture != null)
    queue_redraw()

func _v117_deployed_energy_ids() -> Array[String]:
    var result: Array[String] = []
    for asset_id in V117_ENERGY_IDS:
        if infrastructure_inventory.deployed_quantity(asset_id) > 0:
            result.append(asset_id)

    # A new game still shows the selected contract source before the player has
    # bought an on-site plant. Once hardware is deployed, the real deployed set
    # replaces this fallback automatically.
    if result.is_empty():
        var fallback := _v114_primary_energy_id(_player_hq_center())
        if fallback in V117_ENERGY_IDS:
            result.append(fallback)
    return result

func _v117_energy_capacity_mw(asset_id: String) -> float:
    var count := maxi(1, infrastructure_inventory.deployed_quantity(asset_id))
    var resource = infrastructure_inventory.item_resource(asset_id)
    if resource == null:
        return 1.0

    # Grid Battery Container is a 4 MWh / 2 MW dispatch unit. It has no
    # power_output_mw field because it stores rather than generates energy.
    if asset_id == "battery":
        return 2.0 * float(count)

    return maxf(1.0, float(resource.get("power_output_mw")) * float(count))

func _v117_capacity_text(capacity_mw: float) -> String:
    if capacity_mw >= 1000000.0:
        return "%.2f TW" % (capacity_mw / 1000000.0)
    if capacity_mw >= 1000.0:
        return "%.2f GW" % (capacity_mw / 1000.0)
    if capacity_mw >= 100.0:
        return "%.0f MW" % capacity_mw
    return "%.1f MW" % capacity_mw

func _v117_draw_energy_module(
    asset_id: String,
    pos: Vector2,
    capacity_mw: float,
    bus_pos: Vector2,
    compact: bool = false
) -> void:
    if v114_energy_texture == null:
        return

    var orientation := InfrastructureVisualCatalog.electrical_orientation(pos, bus_pos)
    var region := EnergyVisualCatalog.source_region(asset_id, orientation)
    if region.size == Vector2.ZERO:
        return

    var profile := InfrastructureVisualCatalog.capacity_profile(capacity_mw)
    var footprint := Vector2i(profile.get("footprint", Vector2i(2, 2)))
    var tile_span := float(footprint.x)
    var side := 66.0 + tile_span * 10.0
    if compact:
        side *= 0.78
    side = clampf(side, 80.0, 146.0)

    # Draw the electrical path first so the module sits visually on top of it.
    var line_end := pos.move_toward(bus_pos, side * 0.34)
    draw_line(line_end, bus_pos, Color(0.27, 0.86, 0.93, 0.36), 3.0)
    draw_circle(bus_pos, 4.0, Color("45dff2"))

    draw_ellipse_shadow(pos + Vector2(0.0, side * 0.37), side * 0.31, side * 0.075)
    var dest := Rect2(pos - Vector2(side, side) * Vector2(0.5, 0.58), Vector2(side, side))
    draw_texture_rect_region(v114_energy_texture, dest, region)

    var label := String(EnergyVisualCatalog.visual_definition(asset_id).get("label", asset_id)).to_upper()
    draw_string(
        ThemeDB.fallback_font,
        pos + Vector2(-side * 0.58, side * 0.55),
        "%s • %s • %dx%d" % [label, _v117_capacity_text(capacity_mw), footprint.x, footprint.y],
        HORIZONTAL_ALIGNMENT_CENTER,
        side * 1.16,
        9,
        Color("d7e1e3")
    )

func _v117_draw_energy_fleet(origin: Vector2, bus_pos: Vector2, max_width: float) -> int:
    var systems := _v117_deployed_energy_ids()
    var count := systems.size()
    if count <= 0:
        return 0

    var columns := mini(5, count)
    var rows := int(ceil(float(count) / float(columns)))
    var spacing_x := minf(160.0, max_width / maxf(1.0, float(columns)))
    var spacing_y := 112.0
    var start_x := origin.x - (float(columns - 1) * spacing_x) * 0.5
    var start_y := origin.y - (float(rows - 1) * spacing_y) * 0.5
    var compact := count > 5

    for i in range(count):
        var col := i % columns
        var row := int(i / columns)
        var pos := Vector2(
            start_x + float(col) * spacing_x,
            start_y + float(row) * spacing_y
        )
        var asset_id := systems[i]
        _v117_draw_energy_module(
            asset_id,
            pos,
            _v117_energy_capacity_mw(asset_id),
            bus_pos,
            compact
        )
    return rows

func _v117_draw_district_block(pos: Vector2, represented_mw: float, accent: Color, index: int) -> void:
    var w := 126.0
    var h := 66.0
    var rect := Rect2(pos - Vector2(w, h) * Vector2(0.5, 0.52), Vector2(w, h))
    draw_ellipse_shadow(pos + Vector2(0.0, h * 0.45), w * 0.40, 7.0)
    draw_rect(rect.grow(3.0), Color("091015"), true)
    draw_rect(rect, Color("c6d0d3"), true)
    draw_rect(Rect2(rect.position + Vector2(5.0, 5.0), Vector2(rect.size.x - 10.0, 11.0)), Color("eef2f3"), true)
    draw_rect(Rect2(rect.position + Vector2(5.0, 20.0), Vector2(rect.size.x - 10.0, rect.size.y - 25.0)), Color("aebbc0"), true)
    draw_rect(Rect2(rect.position + Vector2(0.0, 20.0), Vector2(rect.size.x, 4.0)), accent.darkened(0.12), true)

    for fan in range(4):
        var fx := rect.position.x + 23.0 + float(fan) * 27.0
        var fy := rect.position.y + 42.0
        draw_circle(Vector2(fx, fy), 8.0, Color("182226"))
        draw_circle(Vector2(fx, fy), 5.0, Color("53646b"), false, 1.0)

    draw_string(
        ThemeDB.fallback_font,
        pos + Vector2(-w * 0.46, -h * 0.08),
        "8x8 DISTRICT %02d • %s" % [index + 1, _v117_capacity_text(represented_mw)],
        HORIZONTAL_ALIGNMENT_CENTER,
        w * 0.92,
        8,
        Color("172126")
    )

func _v117_draw_compute_scale(origin: Vector2, capacity_mw: float, accent: Color, max_width: float) -> void:
    var profile := InfrastructureVisualCatalog.capacity_profile(capacity_mw)
    var visible_blocks := mini(
        V117_MAX_VISIBLE_DISTRICTS,
        int(profile.get("visible_block_count", 1))
    )

    # Facility/campus scale keeps the exact 2x2 -> 4x4 -> 6x6 -> 8x8 sprite
    # progression. Above 100 MW the same 8x8 grammar becomes district blocks.
    if capacity_mw <= 100.0:
        _v114_draw_container(origin, capacity_mw, accent)
        return

    var columns := mini(5, visible_blocks)
    var rows := int(ceil(float(visible_blocks) / float(columns)))
    var spacing_x := minf(150.0, max_width / maxf(1.0, float(columns)))
    var spacing_y := 86.0
    var start_x := origin.x - (float(columns - 1) * spacing_x) * 0.5
    var start_y := origin.y - (float(rows - 1) * spacing_y) * 0.5
    var per_block := float(profile.get("represented_mw_per_visible_block", capacity_mw))

    for i in range(visible_blocks):
        var pos := Vector2(
            start_x + float(i % columns) * spacing_x,
            start_y + float(int(i / columns)) * spacing_y
        )
        _v117_draw_district_block(pos, per_block, accent, i)

func _v115_draw_live_site(origin: Vector2) -> void:
    var capacity_mw := _v114_capacity_mw_for_site(_player_hq_center())
    var profile := InfrastructureVisualCatalog.capacity_profile(capacity_mw)
    var accent: Color = COMPANY_ACCENTS[company_idx]
    var energy_ids := _v117_deployed_energy_ids()
    var energy_count := energy_ids.size()
    var energy_columns := mini(5, maxi(1, energy_count))
    var energy_rows := int(ceil(float(maxi(1, energy_count)) / float(energy_columns)))

    var pad_w := clampf(620.0 + float(energy_columns - 1) * 92.0, 620.0, 1010.0)
    var pad_h := clampf(390.0 + float(energy_rows - 1) * 104.0, 390.0, 650.0)
    if capacity_mw > 100.0:
        pad_h = minf(690.0, pad_h + 120.0)

    var pad := Rect2(origin - Vector2(pad_w, pad_h) * 0.5, Vector2(pad_w, pad_h))
    draw_rect(Rect2(pad.position + Vector2(8.0, 10.0), pad.size), Color(0.0, 0.0, 0.0, 0.24), true)
    draw_rect(pad, Color("1d292d"), true)
    draw_rect(pad.grow(-7.0), Color("263438"), true)

    # Main bus separates generation from compute. Every energy sprite faces this
    # bus via InfrastructureVisualCatalog.electrical_orientation().
    var bus_pos := origin + Vector2(0.0, -pad_h * 0.08)
    draw_rect(Rect2(bus_pos + Vector2(-54.0, -22.0), Vector2(108.0, 44.0)), Color("17242b"), true)
    draw_rect(Rect2(bus_pos + Vector2(-43.0, -13.0), Vector2(86.0, 25.0)), Color("071016"), true)
    draw_line(bus_pos + Vector2(-34.0, 3.0), bus_pos + Vector2(32.0, -5.0), Color("45dff2"), 2.0)
    draw_circle(bus_pos + Vector2(39.0, 11.0), 3.0, Color("39ff75"))

    var transformer_pos := bus_pos + Vector2(92.0, 0.0)
    _v114_draw_transformer(transformer_pos, capacity_mw)

    var energy_center := origin + Vector2(0.0, -pad_h * 0.31)
    _v117_draw_energy_fleet(energy_center, bus_pos, pad_w * 0.90)

    var compute_center := origin + Vector2(0.0, pad_h * 0.25)
    _v117_draw_compute_scale(compute_center, capacity_mw, accent, pad_w * 0.90)

    var footprint := Vector2i(profile.get("footprint", Vector2i(2, 2)))
    var scale_name := String(profile.get("scale_name", "SITE"))
    var compression := String(profile.get("compression_level", "FACILITY"))
    draw_string(
        ThemeDB.fallback_font,
        origin + Vector2(-pad_w * 0.46, -pad_h * 0.44),
        "%s • %s • %s" % [scale_name, _v117_capacity_text(capacity_mw), compression],
        HORIZONTAL_ALIGNMENT_LEFT,
        pad_w * 0.92,
        12,
        accent.lightened(0.15)
    )
    draw_string(
        ThemeDB.fallback_font,
        origin + Vector2(-pad_w * 0.46, pad_h * 0.46),
        "ENERGY MODULES %d/13 • COMPUTE %dx%d • ORIENTED TO ELECTRICAL BUS" % [energy_count, footprint.x, footprint.y],
        HORIZONTAL_ALIGNMENT_CENTER,
        pad_w * 0.92,
        10,
        Color("cbd6d8")
    )

func _draw_mining_campus(center: Vector2, accent: Color) -> void:
    # Rival and background campuses keep a compact four-object composition, but
    # their energy art now also faces the transformer instead of hardcoding UP.
    var capacity_mw := _v114_capacity_mw_for_site(center)
    var site_size := _v114_sprite_size(capacity_mw)
    var half := site_size.x * 0.5
    var container_pos := center + Vector2(-half * 0.55, 92.0)
    var energy_pos := center + Vector2(half * 0.58 + 105.0, 72.0)
    var transformer_pos := center + Vector2(half * 0.60 + 118.0, -105.0)
    var energy_id := _v114_primary_energy_id(center)

    _v114_draw_container(container_pos, minf(capacity_mw, 100.0), accent)
    _v117_draw_energy_module(energy_id, energy_pos, minf(capacity_mw, 100.0), transformer_pos)
    _v114_draw_transformer(transformer_pos, capacity_mw)

    if center.distance_to(_player_hq_center()) <= 8.0:
        _v107_draw_site_marker(center + Vector2(half + 155.0, 132.0), accent)

func debug_v117_ready() -> bool:
    var one_mw := InfrastructureVisualCatalog.capacity_profile(1.0)
    var ten_mw := InfrastructureVisualCatalog.capacity_profile(10.0)
    var twenty_five_mw := InfrastructureVisualCatalog.capacity_profile(25.0)
    var hundred_mw := InfrastructureVisualCatalog.capacity_profile(100.0)
    var one_gw := InfrastructureVisualCatalog.capacity_profile(1000.0)
    var one_tw := InfrastructureVisualCatalog.capacity_profile(1000000.0)

    if V117_ENERGY_IDS.size() != 13:
        return false
    for asset_id in V117_ENERGY_IDS:
        if EnergyVisualCatalog.visual_definition(asset_id).is_empty():
            return false
        if infrastructure_inventory.item_resource(asset_id) == null:
            return false

    return V117_ENERGY_LIBRARY_REVISION == 1 \
        and Vector2i(one_mw.get("footprint", Vector2i.ZERO)) == Vector2i(2, 2) \
        and Vector2i(ten_mw.get("footprint", Vector2i.ZERO)) == Vector2i(4, 4) \
        and Vector2i(twenty_five_mw.get("footprint", Vector2i.ZERO)) == Vector2i(6, 6) \
        and Vector2i(hundred_mw.get("footprint", Vector2i.ZERO)) == Vector2i(8, 8) \
        and int(one_gw.get("visible_block_count", 0)) == 10 \
        and int(one_tw.get("visible_block_count", 0)) == 10 \
        and InfrastructureVisualCatalog.electrical_orientation(Vector2.ZERO, Vector2(10.0, 0.0)) == "right" \
        and EnergyVisualCatalog.debug_ready() \
        and debug_v116_ready()
