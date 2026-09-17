extends RefCounted

# Hash Race RPG movement helper.
# Direction-state and axis-separated collision ideas are adapted from the CC0
# Python-Monsters entity/player implementation by Clear Code Projects:
# https://github.com/clear-code-projects/Python-Monsters

const MAX_COLLISION_STEP: float = 16.0

static func normalized_input(raw: Vector2) -> Vector2:
    # Prevent diagonal keyboard movement from being ~41% faster than cardinal movement.
    # Analog inputs below full magnitude keep their strength for controller precision.
    if raw.length_squared() > 1.0:
        return raw.normalized()
    return raw

static func facing_from_motion(motion: Vector2, previous: String = "down") -> String:
    if motion.length_squared() <= 0.0001:
        return previous
    if absf(motion.x) > absf(motion.y):
        return "right" if motion.x > 0.0 else "left"
    return "down" if motion.y > 0.0 else "up"

static func animation_state(facing: String, moving: bool) -> String:
    return facing if moving else "%s_idle" % facing

static func face_target(origin: Vector2, target: Vector2, previous: String = "down") -> String:
    var relation: Vector2 = target - origin
    if relation.length_squared() <= 0.0001:
        return previous
    if absf(relation.y) < absf(relation.x):
        return "right" if relation.x > 0.0 else "left"
    return "down" if relation.y > 0.0 else "up"

static func resolve_axis_motion(nav, origin: Vector2, requested_delta: Vector2) -> Vector2:
    # Split unusually large frame movement into small collision probes. This keeps
    # the representative from tunnelling through a thin wall or water boundary
    # after a frame hitch while preserving the existing axis-slide feel.
    if nav == null:
        return origin
    var distance: float = requested_delta.length()
    if distance <= 0.001:
        return origin
    var steps: int = maxi(1, int(ceil(distance / MAX_COLLISION_STEP)))
    var step_delta: Vector2 = requested_delta / float(steps)
    var result: Vector2 = origin
    for _step in range(steps):
        if absf(step_delta.x) > 0.001:
            var x_candidate: Vector2 = Vector2(result.x + step_delta.x, result.y)
            if nav.world_is_walkable(x_candidate):
                result.x = x_candidate.x
        if absf(step_delta.y) > 0.001:
            var y_candidate: Vector2 = Vector2(result.x, result.y + step_delta.y)
            if nav.world_is_walkable(y_candidate):
                result.y = y_candidate.y
    return result

static func is_moving(motion: Vector2) -> bool:
    return motion.length_squared() > 0.0001

static func debug_equal_speed() -> bool:
    var cardinal: Vector2 = normalized_input(Vector2(1.0, 0.0))
    var diagonal: Vector2 = normalized_input(Vector2(1.0, 1.0))
    return absf(cardinal.length() - diagonal.length()) < 0.001

static func debug_collision_substeps() -> bool:
    return MAX_COLLISION_STEP > 0.0 and int(ceil(65.0 / MAX_COLLISION_STEP)) >= 5
