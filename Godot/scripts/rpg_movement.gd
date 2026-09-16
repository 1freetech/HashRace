extends RefCounted

# Hash Race RPG movement helper.
# Direction-state and axis-separated collision ideas are adapted from the CC0
# Python-Monsters entity/player implementation by Clear Code Projects:
# https://github.com/clear-code-projects/Python-Monsters
# The original code is CC0 and explicitly permits commercial reuse.

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
    # Match the classic RPG approach used by Python-Monsters: resolve one axis,
    # then the other. The Godot navigation grid is the collision authority.
    var result: Vector2 = origin
    if absf(requested_delta.x) > 0.001:
        var x_candidate: Vector2 = Vector2(origin.x + requested_delta.x, origin.y)
        if nav != null and nav.world_is_walkable(x_candidate):
            result.x = x_candidate.x
    if absf(requested_delta.y) > 0.001:
        var y_candidate: Vector2 = Vector2(result.x, origin.y + requested_delta.y)
        if nav != null and nav.world_is_walkable(y_candidate):
            result.y = y_candidate.y
    return result

static func is_moving(motion: Vector2) -> bool:
    return motion.length_squared() > 0.0001
