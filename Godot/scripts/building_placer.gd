extends RefCounted
class_name HashRaceBuildingPlacer

# Keeps large interactive buildings visually separated inside the existing
# 3000x1900 world. Representatives are positioned by the world controller so
# they remain attached to their owning company after the building is moved.

const MIN_TARGET_SPACING: float = 300.0

const PLAYER_HQ := Vector2(1500.0, 980.0)
const MACHINE_MARKET := Vector2(900.0, 980.0)
const POWER_OFFICE := Vector2(2100.0, 980.0)
const BANK := Vector2(1500.0, 680.0)
const LAND_MARKET := Vector2(1500.0, 1300.0)

const PARTNER_POSITIONS: Array[Vector2] = [
    Vector2(350.0, 360.0),
    Vector2(875.0, 360.0),
    Vector2(1400.0, 360.0),
    Vector2(1925.0, 360.0),
    Vector2(2450.0, 360.0),
    Vector2(520.0, 1390.0),
    Vector2(1120.0, 1390.0),
    Vector2(1880.0, 1390.0),
    Vector2(2480.0, 1390.0)
]

const RIVAL_POSITIONS: Array[Vector2] = [
    Vector2(260.0, 800.0),
    Vector2(260.0, 1200.0),
    Vector2(260.0, 1600.0),
    Vector2(2490.0, 800.0),
    Vector2(2490.0, 1200.0),
    Vector2(2490.0, 1600.0),
    Vector2(800.0, 1650.0),
    Vector2(1500.0, 1650.0),
    Vector2(2200.0, 1650.0)
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
