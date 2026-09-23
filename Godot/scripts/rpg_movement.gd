extends RefCounted

# Hash Race RPG movement helper.
# Direction-state and axis-separated collision ideas are adapted from the CC0
# Python-Monsters entity/player implementation by Clear Code Projects:
# https://github.com/clear-code-projects/Python-Monsters

const MAX_COLLISION_STEP: float = 16.0
const WALK_CYCLE_DISTANCE: float = 126.0
const INPUT_DEADZONE: float = 0.12

static func normalized_input(raw: Vector2) -> Vector2:
    # Ignore tiny analog/controller drift so the representative stays visually
    # idle when the player is not intentionally moving. Full diagonal inputs are
    # normalized so they cannot move ~41% faster than cardinal movement.
    if raw.length() < INPUT_DEADZONE:
        return Vector2.ZERO
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

static func advance_step_phase(current_phase: float, actual_motion: Vector2) -> float:
    # Tie the seven-frame walk cycle to real distance travelled. Collision
    # clipping and variable path speeds no longer make the character's feet
    # animate while the representative barely moves.
    if not is_moving(actual_motion):
        return current_phase
    var radians_per_pixel := TAU / WALK_CYCLE_DISTANCE
    return fposmod(current_phase + actual_motion.length() * radians_per_pixel, TAU)

static func settled_step_phase(actual_motion: Vector2, current_phase: float) -> float:
    # Returning to idle also returns the next walk to the first authored pose.
    # This prevents a new movement burst from resuming mid-stride after standing.
    return advance_step_phase(current_phase, actual_motion) if is_moving(actual_motion) else 0.0

static func debug_distance_synced_walk() -> bool:
    var still := advance_step_phase(1.25, Vector2.ZERO)
    var half_cycle := advance_step_phase(0.0, Vector2(WALK_CYCLE_DISTANCE * 0.5, 0.0))
    return is_equal_approx(still, 1.25) and absf(half_cycle - PI) < 0.001

static func debug_idle_reset() -> bool:
    return is_zero_approx(settled_step_phase(Vector2.ZERO, 4.2)) \
        and settled_step_phase(Vector2(8.0, 0.0), 0.0) > 0.0

static func debug_input_deadzone() -> bool:
    return normalized_input(Vector2(INPUT_DEADZONE * 0.5, 0.0)) == Vector2.ZERO \
        and normalized_input(Vector2(1.0, 1.0)).is_normalized()

static func debug_equal_speed() -> bool:
    var cardinal: Vector2 = normalized_input(Vector2(1.0, 0.0))
    var diagonal: Vector2 = normalized_input(Vector2(1.0, 1.0))
    return absf(cardinal.length() - diagonal.length()) < 0.001

static func debug_collision_substeps() -> bool:
    return MAX_COLLISION_STEP > 0.0 and int(ceil(65.0 / MAX_COLLISION_STEP)) >= 5
