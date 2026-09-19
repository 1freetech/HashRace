extends "res://scripts/world_v104.gd"

# Hash Race v0.105 quality pass: clearer power decisions plus cheaper, cleaner
# terrain boundaries. Keep the inherited simulation authoritative.
const V105_QUALITY_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v105_quality_revision", V105_QUALITY_REVISION)

# Defensive normalization keeps preview math readable even if a future data
# source briefly supplies an out-of-range service percentage.
func _v105_service_pct(power_pct: float) -> float:
    if is_nan(power_pct) or is_inf(power_pct):
        return 0.0
    return clampf(power_pct, 0.0, 100.0)

func _v105_curtailment_pct(power_pct: float) -> float:
    return 100.0 - _v105_service_pct(power_pct)

func _v105_power_priority(power_pct: float) -> String:
    var curtailed := _v105_curtailment_pct(power_pct)
    if curtailed >= 25.0:
        return "CRITICAL"
    if curtailed >= 10.0:
        return "HIGH"
    if curtailed >= 0.5:
        return "WATCH"
    return "READY"

func _curtailed_hashrate_th_for(power_pct: float, fleet_hashrate_th: float) -> float:
    var safe_pct := _v105_service_pct(power_pct)
    return super._curtailed_hashrate_th_for(safe_pct, maxf(0.0, fleet_hashrate_th))

# Turn guidance now answers three questions in one scan: what to do, how much
# mining output is constrained, and how urgent the constraint is.
func _turn_action_hint(power_pct: float, ending_cash: float, power_cost: float) -> String:
    var safe_pct := _v105_service_pct(power_pct)
    var base_hint := super._turn_action_hint(safe_pct, ending_cash, power_cost)
    var curtailed_pct := _v105_curtailment_pct(safe_pct)
    if curtailed_pct < 0.5:
        return base_hint
    return "%s | OUTPUT AT RISK: %.1f%% | PRIORITY: %s" % [
        base_hint,
        curtailed_pct,
        _v105_power_priority(safe_pct),
    ]

# v0.103 drew transition overlays from both sides of many tile boundaries and
# also treated light/dark grass variation as a biome edge. That created seams
# and unnecessary draw calls. Render only semantically meaningful boundaries.
func _v103_draw_terrain_transitions(cell: Vector2i, tile_id: int) -> void:
    var p := VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
    for direction in directions:
        var neighbor := int(art_cells.get(cell + direction, tile_id))
        if neighbor == tile_id:
            continue

        var grass_here := tile_id == TILE_GRASS or tile_id == TILE_GRASS_DARK
        var grass_there := neighbor == TILE_GRASS or neighbor == TILE_GRASS_DARK
        if grass_here and grass_there:
            continue

        # Grass owns land-edge blending; plaza/lot no longer paint a second
        # overlay back onto the same boundary.
        if grass_here:
            _v103_transition_strip(p, direction, 5.0, V103_GRASS_FRINGE)
            _v103_transition_dither(p, cell, direction, V103_GRASS_HIGHLIGHT)
        elif tile_id == TILE_WATER and neighbor != TILE_WATER:
            _v103_transition_strip(p, direction, 5.0, V103_WATER_BLEND)
            _v103_transition_strip(p, direction, 2.0, V103_WATER_GLEAM)

func debug_v105_ready() -> bool:
    return (
        V105_QUALITY_REVISION == 1
        and debug_v104_ready()
        and _v105_service_pct(-12.0) == 0.0
        and _v105_service_pct(140.0) == 100.0
        and is_equal_approx(_v105_curtailment_pct(80.0), 20.0)
        and _v105_power_priority(70.0) == "CRITICAL"
        and _v105_power_priority(85.0) == "HIGH"
        and _v105_power_priority(99.0) == "WATCH"
        and _v105_power_priority(100.0) == "READY"
        and is_equal_approx(_curtailed_hashrate_th_for(80.0, 100000.0), 20000.0)
    )
