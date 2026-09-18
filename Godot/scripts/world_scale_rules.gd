extends RefCounted
class_name HashRaceWorldScaleRules

# Hash Race v0.088 spatial contract.
# The existing overworld uses a 48 px navigation/art cell. Characters occupy
# roughly two cells vertically, while interactive buildings use larger
# footprints so doors, streets and characters read at believable proportions.

const WORLD_TILE: float = 48.0
const CHARACTER_VISUAL_HEIGHT: float = 100.0
const DOOR_VISUAL_HEIGHT: float = 112.0
const DOOR_VISUAL_WIDTH: float = 48.0
const BUILDING_MARGIN: float = 16.0
const FRONT_APRON: float = 54.0

const HQ_SIZE := Vector2(304.0, 216.0)
const PARTNER_SIZE := Vector2(248.0, 176.0)
const SERVICE_SIZE := Vector2(264.0, 184.0)

static func is_building_kind(kind: String) -> bool:
    return kind in ["hq", "rival", "partner", "machines", "power", "bank", "land"]

static func size_for_kind(kind: String) -> Vector2:
    match kind:
        "hq", "rival":
            return HQ_SIZE
        "partner":
            return PARTNER_SIZE
        "machines", "power", "bank", "land":
            return SERVICE_SIZE
        _:
            return SERVICE_SIZE

static func visual_rect(kind: String, pos: Vector2) -> Rect2:
    var size := size_for_kind(kind)
    var top_left := pos + Vector2(-size.x * 0.5, -size.y * 0.62)
    return Rect2(top_left, size)

static func collision_rect(kind: String, pos: Vector2) -> Rect2:
    var rect := visual_rect(kind, pos)
    return rect.grow(BUILDING_MARGIN)

static func front_door_world_pos(kind: String, pos: Vector2) -> Vector2:
    var size := size_for_kind(kind)
    return Vector2(pos.x, pos.y + size.y * 0.38 + FRONT_APRON)

static func depth_y(kind: String, pos: Vector2) -> float:
    var size := size_for_kind(kind)
    return pos.y + size.y * 0.38

static func selection_radius(kind: String) -> float:
    var size := size_for_kind(kind)
    return maxf(size.x, size.y) * 0.52

static func proportions_ready() -> bool:
    return WORLD_TILE == 48.0 and HQ_SIZE.y >= CHARACTER_VISUAL_HEIGHT * 2.0 and DOOR_VISUAL_HEIGHT >= CHARACTER_VISUAL_HEIGHT
