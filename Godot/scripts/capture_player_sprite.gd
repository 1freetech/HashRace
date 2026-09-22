extends SceneTree

const Sheet = preload("res://scripts/default_player_sprite_sheet.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE PLAYER RENDER FAIL: " + message)
    quit(1)

func _capture() -> void:
    set_meta("hashrace_company_idx", 0)
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live world did not load")
        return
    var scene := packed.instantiate() as Node2D
    root.add_child(scene)
    for index in range(16):
        await process_frame
    if not bool(scene.get_meta("hashrace_player_32frame_asset_live", false)):
        _fail("approved player binary is not live")
        return
    scene.process_mode = Node.PROCESS_MODE_DISABLED
    for child in scene.get_children():
        if child is CanvasLayer:
            child.hide()
    var camera := root.get_camera_2d()
    if camera == null:
        _fail("live world camera missing")
        return
    var player_position: Vector2 = scene.get("rep_pos")
    camera.position_smoothing_enabled = false
    camera.position = player_position
    camera.zoom = Vector2(2.0, 2.0)
    camera.force_update_scroll()
    var output := ProjectSettings.globalize_path("res://../visual-proof/player")
    DirAccess.make_dir_recursive_absolute(output)
    var hashes: Dictionary = {}
    for direction in ["down", "left", "right", "up"]:
        for frame in range(8):
            scene.set("rep_facing", direction)
            scene.set("rep_animation_state", direction + ("_idle" if frame == 0 else "_walk"))
            scene.set("rep_step_phase", 0.0 if frame == 0 else (float(frame) - 0.5) * TAU / 7.0)
            scene.queue_redraw()
            await process_frame
            await RenderingServer.frame_post_draw
            if int(scene.call("_v121_walk_frame", frame != 0)) != frame:
                _fail("live renderer selected the wrong walk phase")
                return
            var image := root.get_texture().get_image()
            if image == null or image.is_empty():
                _fail("empty viewport")
                return
            var screen_center := scene.get_global_transform_with_canvas() * player_position
            var bounds := Rect2i(Vector2i(screen_center) + Vector2i(-85, -170), Vector2i(170, 270))
            if not Rect2i(Vector2i.ZERO, image.get_size()).encloses(bounds):
                _fail("player is outside the actual viewport")
                return
            var crop := image.get_region(bounds)
            var digest := crop.get_data().hex_encode().sha256_text()
            if hashes.has(digest):
                _fail("two live poses produced identical pixels")
                return
            hashes[digest] = true
            if frame in [0, 3]:
                if image.save_png(output.path_join("%s-%s.png" % [direction, "idle" if frame == 0 else "walk"])) != OK:
                    _fail("could not save actual gameplay PNG")
                    return
    print("HASH RACE PLAYER RENDER PASS: 32 distinct actual gameplay poses; saved idle/walk proof for all four directions")
    quit(0)
