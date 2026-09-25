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

    for method_name in ["runtime_ready", "infrastructure_ready", "infrastructure_rect", "infrastructure_footprint", "move_player", "player_animation_ready"]:
        if not scene.has_method(method_name):
            _fail("stable runtime method missing: %s" % method_name)
            return

    if not bool(scene.call("runtime_ready")):
        _fail("imported gameplay textures/navigation/player animation did not initialize")
        return
    for asset_id in ["container", "solar", "transformer", "asic", "wind"]:
        if not bool(scene.call("infrastructure_ready", asset_id)):
            _fail("%s texture decode or blocked ground footprint is invalid" % asset_id)
            return
    if not bool(scene.call("player_animation_ready")):
        _fail("live AnimatedSprite2D does not contain the verified walk frames")
        return

    var player_sprite := scene.get("player_sprite") as AnimatedSprite2D
    if player_sprite == null or not player_sprite.is_inside_tree():
        _fail("live AnimatedSprite2D player did not initialize")
        return
    for facing in ["down", "left", "right", "up"]:
        if player_sprite.sprite_frames.get_frame_count(StringName("walk_" + facing)) != 7:
            _fail("walk_%s does not have seven visually verified authored poses" % facing)
            return

    var camera := scene.get("camera") as Camera2D
    if camera == null or not camera.is_inside_tree():
        _fail("playable camera did not initialize")
        return

    var grid_nav = scene.get("grid_nav")
    if grid_nav == null or int(grid_nav.call("blocked_count")) < 5:
        _fail("five infrastructure collision footprints were not registered")
        return

    var infrastructure_sprites: Dictionary = scene.get("infrastructure_sprites")
    if infrastructure_sprites.size() != 5:
        _fail("five Y-sorted infrastructure Sprite2D nodes were not created")
        return
    for asset_id in ["container", "solar", "transformer", "asic", "wind"]:
        var infrastructure_sprite := infrastructure_sprites.get(asset_id) as Sprite2D
        if infrastructure_sprite == null or not infrastructure_sprite.is_inside_tree():
            _fail("Y-sorted infrastructure sprite missing: " + asset_id)
            return
        if infrastructure_sprite.texture == null:
            _fail("imported infrastructure texture missing from Sprite2D: " + asset_id)
            return

    # Prove the current playable loop can move on open terrain while collision
    # remains authoritative and switches the live sprite into a walk animation.
    var start: Vector2 = scene.get("rep_pos")
    scene.call("move_player", Vector2(12.0, 0.0))
    scene.call("_set_player_facing", Vector2.RIGHT)
    scene.call("_update_player_animation", true)
    await process_frame
    var moved: Vector2 = scene.get("rep_pos")
    if moved.distance_to(start) < 1.0:
        _fail("player could not move through open terrain")
        return
    if player_sprite.animation != &"walk_right" or not player_sprite.is_playing():
        _fail("movement did not activate the live right-walk animation")
        return

    scene.queue_free()
    await process_frame
    print("HASH RACE WORLD OK: semantic runtime APIs, imported infrastructure, live SpriteFrames walking, collision, camera and movement validated")
    quit(0)
