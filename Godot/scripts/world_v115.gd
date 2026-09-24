extends "res://scripts/world_v114.gd"

# Hash Race v0.115 direct mining-site placement pass.
# v0.114 defined the energy/container renderers; v0.115 mounts them directly
# into the live world-prop draw stack so every running game actually shows a
# readable player mining site near HQ instead of relying on an older campus hook.

const V115_DIRECT_SITE_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v115_direct_site_revision", V115_DIRECT_SITE_REVISION)
    queue_redraw()

func _draw_world_props_pixel() -> void:
    super._draw_world_props_pixel()
    if player.is_empty() or town_zones.is_empty():
        return
    var origin := _energy_campus_origin()
    if rep_pos.distance_to(origin) > 1100.0:
        return
    _v115_draw_live_site(origin)

func _v115_draw_live_site(origin: Vector2) -> void:
    var capacity_mw := _v114_capacity_mw_for_site(_player_hq_center())
    var tiles := _v114_footprint_tiles(capacity_mw)
    var accent: Color = COMPANY_ACCENTS[company_idx]
    var energy_id := _v114_primary_energy_id(_player_hq_center())

    # Quiet industrial pad gives the imported energy sprite and scaled compute
    # module a single readable composition instead of scattering props.
    var pad_w := clampf(float(tiles) * V114_WORLD_TILE + 300.0, 430.0, 760.0)
    var pad_h := clampf(float(tiles) * V114_WORLD_TILE * 0.65 + 180.0, 300.0, 520.0)
    var pad := Rect2(origin - Vector2(pad_w, pad_h) * 0.5, Vector2(pad_w, pad_h))
    draw_rect(Rect2(pad.position + Vector2(8.0, 10.0), pad.size), Color(0.0, 0.0, 0.0, 0.22), true)
    draw_rect(pad, Color("1f2a2d"), true)
    draw_rect(pad.grow(-7.0), Color("263438"), true)

    # Four essentials: container, generation, transformer, command/control.
    var container_pos := origin + Vector2(-pad_w * 0.18, 58.0)
    var energy_pos := origin + Vector2(pad_w * 0.27, 52.0)
    var transformer_pos := origin + Vector2(pad_w * 0.28, -pad_h * 0.28)
    var command_pos := origin + Vector2(-pad_w * 0.28, -pad_h * 0.28)

    _v114_draw_container(container_pos, capacity_mw, accent)
    _v114_draw_energy_source(energy_id, energy_pos, capacity_mw, "up")
    _v114_draw_transformer(transformer_pos, capacity_mw)

    var command_size := Vector2(108.0, 72.0)
    draw_ellipse_shadow(command_pos + Vector2(0.0, 31.0), 44.0, 8.0)
    draw_rect(Rect2(command_pos - command_size * Vector2(0.5, 0.52), command_size), Color("15242c"), true)
    draw_rect(Rect2(command_pos + Vector2(-40.0, -24.0), Vector2(80.0, 36.0)), Color("061016"), true)
    draw_rect(Rect2(command_pos + Vector2(-33.0, -17.0), Vector2(66.0, 20.0)), Color("164b59"), true)
    draw_line(command_pos + Vector2(-27.0, -4.0), command_pos + Vector2(25.0, -11.0), Color("45dff2"), 2.0)
    draw_circle(command_pos + Vector2(33.0, 21.0), 3.0, Color("39ff75"))

    # Minimal labels only on the pad.
    var scale_name := String(InfrastructureVisualCatalog.capacity_profile(capacity_mw).get("scale_name", "SITE"))
    draw_string(
        ThemeDB.fallback_font,
        origin + Vector2(-pad_w * 0.45, -pad_h * 0.42),
        "%s • %.1f MW" % [scale_name, capacity_mw],
        HORIZONTAL_ALIGNMENT_LEFT,
        pad_w * 0.9,
        12,
        accent.lightened(0.15)
    )
    draw_string(
        ThemeDB.fallback_font,
        origin + Vector2(-pad_w * 0.45, pad_h * 0.44),
        "%s  |  CONTAINER %dx%d  |  TRANSFORMER  |  COMMAND" % [String(EnergyVisualCatalog.visual_definition(energy_id).get("label", energy_id)).to_upper(), tiles, tiles],
        HORIZONTAL_ALIGNMENT_CENTER,
        pad_w * 0.9,
        10,
        Color("cbd6d8")
    )

func debug_v115_ready() -> bool:
    return V115_DIRECT_SITE_REVISION == 1         and _v114_footprint_tiles(1.0) == 2         and _v114_footprint_tiles(10.0) == 4         and _v114_footprint_tiles(100.0) == 8         and debug_v114_ready()
