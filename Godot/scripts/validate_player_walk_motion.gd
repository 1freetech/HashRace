extends SceneTree

# Test the LIVE walking settings, not a separately tuned animation preview.
# At 144 px/s a four-pose walk at 8 FPS advances 18 actual pixels per
# displayed pose; one full walk cycle therefore spans exactly 72 pixels.
const Sheet = preload("res://scripts/default_player_sprite_sheet.gd")
const Movement = preload("res://scripts/rpg_movement.gd")
const World = preload("res://scripts/world_overworld.gd")

var failures: Array[String] = []

func _require(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        push_error("HASH RACE WALK MOTION FAIL: " + message)

func _initialize() -> void:
    call_deferred("_validate")

func _validate() -> void:
    _require(is_equal_approx(World.WALK_SPEED, 144.0), "live overworld must walk at 144 px/s")
    _require(Sheet.WALK_FRAME_COUNT == 4 and is_equal_approx(Sheet.WALK_FPS, 8.0), "four walk frames at 8 FPS")
    _require(Sheet.EFFECTIVE_FRAME_COUNT == 20 and Sheet.EFFECTIVE_SOURCE_INDICES == [0, 1, 3, 5, 7], "approved source must supply four authored walk poses plus idle")
    _require(is_equal_approx(Movement.WALK_CYCLE_DISTANCE, 72.0), "walking cycle must span 72 traveled pixels")

    var frames: SpriteFrames = Sheet.build_frames()
    _require(frames != null, "approved transparent PNG must build live SpriteFrames")
    if frames == null:
        quit(1)
        return
    var travel_per_pose: float = World.WALK_SPEED / Sheet.WALK_FPS
    _require(is_equal_approx(travel_per_pose, Movement.WALK_CYCLE_DISTANCE / float(Sheet.WALK_FRAME_COUNT)), "travel per pose must match distance-based runtime walk phases")

    for facing in ["down", "left", "right", "up"]:
        var animation := StringName("walk_" + facing)
        _require(frames.get_frame_count(animation) == 4, facing + " must have four walking poses")
        _require(is_equal_approx(frames.get_animation_speed(animation), Sheet.WALK_FPS), facing + " animation must play at 8 FPS")
        var phase: float = 0.0
        var visited: Dictionary = {}
        # Sample at the center of successive 0.125s frames instead of on
        # floating-point phase boundaries. Movement is actual distance,
        # exactly as world_rpg_strategy.gd advances the runtime phase.
        for step in range(4):
            var distance: float = travel_per_pose * (0.5 if step == 0 else 1.0)
            phase = Movement.advance_step_phase(phase, Vector2(distance, 0.0))
            var selected: int = Sheet.walk_frame(true, phase)
            _require(selected == step + 1, facing + ": walk image must follow actual displacement")
            _require(Sheet.frame_region(facing, selected) == Sheet.FRAME_REGIONS[facing][int(Sheet.EFFECTIVE_SOURCE_INDICES[step + 1])], facing + ": wrong approved source crop")
            visited[selected] = true
        _require(visited.size() == 4, facing + ": every walk pose must be reached")
        phase = Movement.settled_step_phase(Vector2.ZERO, phase)
        _require(is_zero_approx(phase) and Sheet.walk_frame(false, phase) == 0, facing + ": stopping must hold idle, never slide")
    _require(Movement.debug_distance_synced_walk(), "existing distance-based stride regression")
    _require(Movement.debug_idle_reset(), "idle phase must reset")
    _require(Movement.debug_equal_speed(), "diagonal movement must remain normalized")
    _require(Movement.debug_collision_substeps(), "collision sampling must be preserved")

    if not failures.is_empty():
        quit(1)
        return
    print("HASH RACE WALK MOTION PASS: live 144 px/s; 4 walk frames per direction; 8 FPS; 72 px cycle; real-distance phases; 4-direction idle reset")
    quit(0)
