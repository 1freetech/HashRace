extends "res://scripts/world_v105.gd"

# Hash Race v0.106 power-risk clarity + terrain edge optimization.
# This layer keeps the v0.105 blackout recovery fix while making power risk
# mathematically bounded and reducing duplicate terrain-edge drawing.

const V106_QUALITY_REVISION := 1

func _service_pct(power_pct: float) -> float:
    return clampf(power_pct, 0.0, 100.0)

func _curtailed_hashrate_th_for(power_pct: float, fleet_hashrate_th: float) -> float:
    var safe_hashrate := maxf(0.0, fleet_hashrate_th)
    var service := _service_pct(power_pct)
    if service >= 99.5 or safe_hashrate <= 0.0:
        return 0.0
    return safe_hashrate * (1.0 - service / 100.0)

func _output_at_risk_pct(power_pct: float) -> float:
    return clampf(100.0 - _service_pct(power_pct), 0.0, 100.0)

func _power_priority(power_pct: float) -> String:
    var risk := _output_at_risk_pct(power_pct)
    if risk >= 50.0:
        return "CRITICAL"
    if risk >= 20.0:
        return "HIGH"
    if risk >= 5.0:
        return "WATCH"
    return "READY"

func _turn_action_hint(power_pct: float, ending_cash: float, power_cost: float) -> String:
    var base_hint := super._turn_action_hint(_service_pct(power_pct), ending_cash, power_cost)
    var risk := _output_at_risk_pct(power_pct)
    if risk < 0.5:
        return base_hint
    return "%s | OUTPUT AT RISK: %.0f%% | %s" % [base_hint, risk, _power_priority(power_pct)]

func _v106_same_terrain_family(a: int, b: int) -> bool:
    if a == b:
        return true
    return a in [TILE_GRASS, TILE_GRASS_DARK] and b in [TILE_GRASS, TILE_GRASS_DARK]

# Draw each shared boundary once (top/left ownership) instead of once from each
# adjacent tile. Grass shade variation is texture, not a terrain boundary, so it
# no longer receives a seam. This cuts transition overdraw on dense maps.
func _v103_draw_terrain_transitions(cell: Vector2i, tile_id: int) -> void:
    var p := VisualStack.snap_to_pixel(Vector2(float(cell.x) * ART_TILE_SIZE, float(cell.y) * ART_TILE_SIZE))
    var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT]
    for direction in directions:
        var neighbor := int(art_cells.get(cell + direction, tile_id))
        if _v106_same_terrain_family(tile_id, neighbor):
            continue
        if tile_id in [TILE_GRASS, TILE_GRASS_DARK]:
            _v103_transition_strip(p, direction, 5.0, V103_GRASS_FRINGE)
            _v103_transition_dither(p, cell, direction, V103_GRASS_HIGHLIGHT)
        elif tile_id in [TILE_PLAZA, TILE_LOT] and neighbor in [TILE_GRASS, TILE_GRASS_DARK]:
            _v103_transition_strip(p, direction, 3.0, V103_PATH_BLEND)
        elif tile_id == TILE_WATER and neighbor != TILE_WATER:
            _v103_transition_strip(p, direction, 5.0, V103_WATER_BLEND)
            _v103_transition_strip(p, direction, 2.0, V103_WATER_GLEAM)

func debug_v106_ready() -> bool:
    return (
        V106_QUALITY_REVISION == 1
        and debug_v105_ready()
        and _service_pct(-10.0) == 0.0
        and _service_pct(120.0) == 100.0
        and is_equal_approx(_curtailed_hashrate_th_for(80.0, 100000.0), 20000.0)
        and _curtailed_hashrate_th_for(50.0, -1.0) == 0.0
        and _output_at_risk_pct(80.0) == 20.0
        and _power_priority(100.0) == "READY"
        and _power_priority(90.0) == "WATCH"
        and _power_priority(75.0) == "HIGH"
        and _power_priority(40.0) == "CRITICAL"
        and _v106_same_terrain_family(TILE_GRASS, TILE_GRASS_DARK)
    )
