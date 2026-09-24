extends SceneTree

# Stable-runtime validator. Release/version history belongs in GitHub, not the
# gameplay contract. This validates the actual world.tscn entry point and the
# current mining-campus loop without requiring retired vXXX debug layers.

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("HASH RACE WORLD FAIL: " + message)
    quit(1)

func _run() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("world.tscn did not load through Godot ResourceLoader")
        return

    var scene := packed.instantiate()
    if scene == null:
        _fail("world.tscn did not instantiate")
        return
    root.add_child(scene)
    for _frame in range(6):
        await process_frame

    for method_name in ["runtime_ready", "infrastructure_ready", "infrastructure_rect", "infrastructure_footprint", "move_player"]:
        if not scene.has_method(method_name):
            _fail("stable runtime method missing: %s" % method_name)
            return

    if not bool(scene.call("runtime_ready")):
        _fail("imported gameplay textures/navigation did not initialize")
        return
    if not bool(scene.call("infrastructure_ready", "wind")):
        _fail("wind texture dimensions or blocked ground footprint are invalid")
        return

    var camera := scene.get("camera") as Camera2D
    if camera == null or not camera.is_inside_tree():
        _fail("playable camera did not initialize")
        return

    var grid_nav = scene.get("grid_nav")
    if grid_nav == null or int(grid_nav.call("blocked_count")) < 5:
        _fail("five infrastructure collision footprints were not registered")
        return

    # Prove the current playable loop can move on open terrain while collision
    # remains authoritative. This is intentionally semantic, not release-numbered.
    var start: Vector2 = scene.get("rep_pos")
    scene.call("move_player", Vector2(12.0, 0.0))
    await process_frame
    var moved: Vector2 = scene.get("rep_pos")
    if moved.distance_to(start) < 1.0:
        _fail("player could not move through open terrain")
        return

    scene.queue_free()
    await process_frame
    print("HASH RACE WORLD OK: semantic runtime APIs, five collision footprints, camera and movement validated")
    quit(0)
