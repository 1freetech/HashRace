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
    return root.get_texture().get_image()

func _capture() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live scene missing")
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _frame in range(14):
        await process_frame

    var live_script := scene.get_script() as Script
    if live_script == null or live_script.resource_path != "res://scripts/world_v165.gd":
        _fail("full v0.165 gameplay world is not live")
        return
    if not scene.has_method("debug_v144_ready") or not bool(scene.call("debug_v144_ready")):
        _fail("approved customized player renderer is not ready in the gameplay chain")
        return

    var camera: Camera2D = scene.get("camera")
    if camera == null:
        _fail("live gameplay camera missing")
        return

    # Freeze simulation but keep drawing. The v0.144+ player is drawn directly
    # by the real world canvas renderer rather than a stripped AnimatedSprite2D
    # fixture, so pose proof drives the same rep_facing/rep_step_phase state the
    # live RPG movement code uses.
    scene.process_mode = Node.PROCESS_MODE_DISABLED
    var origin: Vector2 = scene.get("rep_pos")
    camera.position_smoothing_enabled = false
    camera.position = origin
    camera.zoom = Vector2(2.0, 2.0)
    camera.force_update_scroll()

    var output := ProjectSettings.globalize_path(OUTPUT)
    DirAccess.make_dir_recursive_absolute(output)
    var hashes := {}
    var directions := {
        "down": Vector2.DOWN,
        "left": Vector2.LEFT,
        "right": Vector2.RIGHT,
        "up": Vector2.UP,
    }
    var travel_per_pose: float = 144.0 / Sheet.WALK_FPS
    if not is_equal_approx(travel_per_pose * Sheet.WALK_FRAME_COUNT, 72.0):
        _fail("approved walk speed/cadence disagree")
        return

    for facing in directions:
        for pose in range(5):
            scene.set("rep_pos", origin)
            scene.set("rep_facing", facing)
            if pose == 0:
                scene.set("rep_animation_state", facing + "_idle")
                scene.set("rep_step_phase", 0.0)
            else:
                scene.set("rep_animation_state", facing + "_walk")
                scene.set("rep_step_phase", (float(pose - 1) / float(Sheet.WALK_FRAME_COUNT)) * TAU)
            scene.queue_redraw()
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
                _fail("two authored gameplay poses produced identical pixels")
                return
            hashes[digest] = true
            var name := "idle" if pose == 0 else "walk-%02d" % pose
            if image.save_png(output.path_join("%s-%s.png" % [facing, name])) != OK:
                _fail("pose save failed")
                return

        # Controlled-distance proof uses the real canvas renderer and the same
        # 18 px/pose cadence implied by 144 px/s at 8 FPS.
        scene.set("rep_facing", facing)
        scene.set("rep_animation_state", facing + "_walk")
        for step in range(Sheet.WALK_FRAME_COUNT):
            scene.set("rep_pos", origin + directions[facing] * travel_per_pose * float(step + 1))
            scene.set("rep_step_phase", (float(step) / float(Sheet.WALK_FRAME_COUNT)) * TAU)
            scene.queue_redraw()
            var motion_image: Image = await _save()
            if motion_image == null or motion_image.is_empty() or motion_image.save_png(output.path_join("motion-%s-%02d.png" % [facing, step])) != OK:
                _fail("motion save failed")
                return
        scene.set("rep_pos", origin)

    print("HASH RACE PLAYER RENDER PASS: 20 distinct full-gameplay authored poses and 16 controlled-distance live-world frames")
    quit(0)
