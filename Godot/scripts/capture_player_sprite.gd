extends SceneTree

const Sheet = preload("res://scripts/default_player_sprite_sheet.gd")
const OUTPUT := "res://../visual-proof/player"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE PLAYER RENDER FAIL: " + message)
    quit(1)

func _save() -> Image:
    for _frame in range(3):
        await process_frame
    var image := root.get_texture().get_image()
    return image

func _capture() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live scene missing")
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _frame in range(12):
        await process_frame
    if not scene.has_method("runtime_ready") or not scene.call("runtime_ready"):
        _fail("current world is not ready")
        return
    var sprite: AnimatedSprite2D = scene.get("player_sprite")
    var camera: Camera2D = scene.get("camera")
    if sprite == null or camera == null:
        _fail("live sprite or camera missing")
        return
    # Freeze the world for deterministic authored-pose inspection. The separate
    # screenshot and overworld validators exercise ordinary input-driven motion.
    scene.process_mode = Node.PROCESS_MODE_DISABLED
    var origin := Vector2(900, 760)
    scene.set("rep_pos", origin)
    sprite.position = origin
    camera.position_smoothing_enabled = false
    camera.position = origin
    camera.zoom = Vector2(2, 2)
    camera.force_update_scroll()
    var output := ProjectSettings.globalize_path(OUTPUT)
    DirAccess.make_dir_recursive_absolute(output)
    var hashes := {}
    var directions := {"down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT, "up": Vector2.UP}
    var travel_per_pose: float = scene.PLAYER_SPEED / Sheet.WALK_FPS
    if not is_equal_approx(travel_per_pose * Sheet.WALK_FRAME_COUNT, scene.WALK_CYCLE_DISTANCE):
        _fail("actual world speed/cadence disagree")
        return
    for facing in directions:
        for pose in range(5):
            sprite.animation = StringName(("idle_" if pose == 0 else "walk_") + facing)
            sprite.stop()
            sprite.frame = 0 if pose == 0 else pose - 1
            var image: Image = await _save()
            if image == null or image.is_empty():
                _fail("empty viewport")
                return
            var center: Vector2 = scene.get_global_transform_with_canvas() * origin
            var bounds := Rect2i(Vector2i(center) + Vector2i(-85, -195), Vector2i(170, 240))
            if not Rect2i(Vector2i.ZERO, image.get_size()).encloses(bounds):
                _fail("player crop outside viewport")
                return
            var digest := image.get_region(bounds).get_data().hex_encode().sha256_text()
            if hashes.has(digest):
                _fail("two authored poses produced identical pixels")
                return
            hashes[digest] = true
            var name := "idle" if pose == 0 else "walk-%02d" % pose
            if image.save_png(output.path_join("%s-%s.png" % [facing, name])) != OK:
                _fail("pose save failed")
                return
        scene.set("rep_pos", origin)
        sprite.position = origin
        for step in range(Sheet.WALK_FRAME_COUNT):
            if not scene.call("move_player", directions[facing] * travel_per_pose):
                _fail("actual motion was blocked")
                return
            scene.call("_set_player_facing", directions[facing])
            scene.call("_update_player_animation", true, scene.PLAYER_SPEED)
            sprite.stop()
            sprite.frame = step
            var motion_image: Image = await _save()
            if motion_image == null or motion_image.is_empty() or motion_image.save_png(output.path_join("motion-%s-%02d.png" % [facing, step])) != OK:
                _fail("motion save failed")
                return
        scene.set("rep_pos", origin)
        sprite.position = origin
    print("HASH RACE PLAYER RENDER PASS: 20 distinct actual SpriteFrames poses and 16 controlled-distance live-world frames")
    quit(0)
