extends RefCounted
class_name HashRaceBuildingPlacer

# Roadside placement contract for the live 3000x1900 overworld.
# Interactive buildings are snapped to parcels beside the road network instead
# of being centered on asphalt. Positions stay on the 48 px world grid so the
# building footprints, lots, navigation and pixel-art roads share one geometry.

const WorldScale = preload("res://scripts/world_scale_rules.gd")

const MIN_TARGET_SPACING: float = 300.0

# These rectangles mirror the TILE_ROAD brush geometry in world_gbc.gd.
const ROAD_RECTS: Array[Rect2] = [
    Rect2(96.0, 912.0, 2904.0, 192.0),
    Rect2(1392.0, 336.0, 288.0, 1564.0),
    Rect2(336.0, 432.0, 2304.0, 144.0),
    Rect2(336.0, 1392.0, 2304.0, 144.0)
]

const WATER_RECTS: Array[Rect2] = [
    Rect2(0.0, 1776.0, 3000.0, 124.0),
    Rect2(2592.0, 0.0, 408.0, 768.0)
]

# The player begins in a central roadside district. All four public services and
# every partner/rival site use the same curb-side parcel logic.
const PLAYER_HQ := Vector2(1872.0, 768.0)
const MACHINE_MARKET := Vector2(720.0, 1296.0)
const POWER_OFFICE := Vector2(2064.0, 288.0)
const BANK := Vector2(2832.0, 1248.0)
const LAND_MARKET := Vector2(2400.0, 1680.0)

const PARTNER_POSITIONS: Array[Vector2] = [
    Vector2(384.0, 1248.0),
    Vector2(1056.0, 1248.0),
    Vector2(1824.0, 1248.0),
    Vector2(2448.0, 1296.0),
    Vector2(192.0, 1680.0),
    Vector2(720.0, 1680.0),
    Vector2(1248.0, 1680.0),
    Vector2(1968.0, 1680.0),
    Vector2(2832.0, 1680.0)
]

const RIVAL_POSITIONS: Array[Vector2] = [
    Vector2(480.0, 288.0),
    Vector2(816.0, 288.0),
    Vector2(1152.0, 288.0),
    Vector2(1776.0, 192.0),
    Vector2(2400.0, 288.0),
    Vector2(192.0, 768.0),
    Vector2(720.0, 768.0),
    Vector2(1200.0, 768.0),
    Vector2(2352.0, 768.0)
]

static func desired_position(entity: Dictionary) -> Vector2:
    var fallback: Vector2 = entity.get("pos", Vector2.ZERO)
    var kind: String = String(entity.get("kind", ""))
    match kind:
        "hq":
            return PLAYER_HQ
        "machines":
            return MACHINE_MARKET
        "power":
            return POWER_OFFICE
        "bank":
            return BANK
        "land":
            return LAND_MARKET
        "partner":
            var partner_idx: int = int(entity.get("partner_idx", -1))
            if partner_idx >= 0 and partner_idx < PARTNER_POSITIONS.size():
                return PARTNER_POSITIONS[partner_idx]
        "rival":
            var rival_idx: int = int(entity.get("rival_idx", -1))
            if rival_idx >= 0 and rival_idx < RIVAL_POSITIONS.size():
                return RIVAL_POSITIONS[rival_idx]
    return fallback

static func minimum_building_spacing(entities: Array) -> float:
    var positions: Array[Vector2] = []
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        var kind: String = String(entity.get("kind", ""))
        if kind == "rival_rep" or kind == "partner_rep":
            continue
        positions.append(entity.get("pos", Vector2.ZERO))
    if positions.size() < 2:
        return 999999.0
    var minimum: float = 999999.0
    for i in range(positions.size()):
        for j in range(i + 1, positions.size()):
            minimum = minf(minimum, positions[i].distance_to(positions[j]))
    return minimum

static func road_overlap_count(entities: Array) -> int:
    var overlaps: int = 0
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        var kind: String = String(entity.get("kind", ""))
        if not WorldScale.is_building_kind(kind):
            continue
        var rect: Rect2 = WorldScale.collision_rect(kind, entity.get("pos", Vector2.ZERO))
        for road in ROAD_RECTS:
            if rect.intersects(road, true):
                overlaps += 1
                break
    return overlaps

static func water_overlap_count(entities: Array) -> int:
    var overlaps: int = 0
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        var kind: String = String(entity.get("kind", ""))
        if not WorldScale.is_building_kind(kind):
            continue
        var rect: Rect2 = WorldScale.collision_rect(kind, entity.get("pos", Vector2.ZERO))
        for water in WATER_RECTS:
            if rect.intersects(water, true):
                overlaps += 1
                break
    return overlaps

static func all_buildings_clear_of_roads(entities: Array) -> bool:
    return road_overlap_count(entities) == 0

static func all_buildings_clear_of_water(entities: Array) -> bool:
    return water_overlap_count(entities) == 0
