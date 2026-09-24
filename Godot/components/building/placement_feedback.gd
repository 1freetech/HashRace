extends RefCounted
class_name HashRacePlacementFeedback
## Builder-style placement helpers adapted from GDQuest's EntityPlacer ideas.

const VALID := Color(0.23, 1.0, 0.50, 0.62)
const INVALID := Color(1.0, 0.28, 0.28, 0.62)
const HOVER := Color(0.38, 0.78, 1.0, 0.75)

static func snap_to_grid(world_position: Vector2, grid_size: Vector2i = Vector2i(32, 32)) -> Vector2:
    var gx: int = maxi(1, grid_size.x)
    var gy: int = maxi(1, grid_size.y)
    return Vector2(
        round(world_position.x / float(gx)) * float(gx),
        round(world_position.y / float(gy)) * float(gy)
    )

static func within_work_distance(origin: Vector2, target: Vector2, maximum_distance: float = 400.0) -> bool:
    return origin.distance_to(target) <= maximum_distance

static func ghost_color(valid: bool) -> Color:
    return VALID if valid else INVALID

static func cell_is_free(candidate: Rect2, occupied: Array[Rect2], clearance: float = 6.0) -> bool:
    var padded: Rect2 = candidate.grow(clearance)
    for rect in occupied:
        if padded.intersects(rect):
            return false
    return true
