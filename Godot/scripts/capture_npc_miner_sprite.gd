extends SceneTree

const NpcMinerSheet = preload("res://scripts/npc_miner_sprite_sheet.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE NPC MINER RENDER FAIL: " + message)
    quit(1)

func _capture() -> void:
    set_meta("hashrace_company_idx", 0)
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live world did not load")
        return
    var scene := packed.instantiate() as Node2D
    root.add_child(scene)
    for _index in range(16):
        await process_frame
    if not bool(scene.get_meta("hashrace_npc_miner_asset_live", false)) or not bool(scene.call("debug_v145_ready")):
        _fail("committed NPC miner binary is not live")
        return
    var npc_position := Vector2.ZERO
    for raw_entity in scene.get("entities"):
        var entity: Dictionary = raw_entity
        if String(entity.get("kind", "")) in ["partner_rep", "rival_rep"]:
            npc_position = entity["pos"]
            break
    if npc_position == Vector2.ZERO:
        _fail("no live representative found")
        return
    for child in scene.get_children():
        if child is CanvasLayer:
            child.hide()
    var camera := root.get_camera_2d()
    if camera == null:
        _fail("live world camera missing")
        return
    camera.position_smoothing_enabled = false
    # The NPC renderer anchors the 128px atlas frame at pos + (0, 39).
    # Center the proof camera on that same ground-contact foot point so the
    # entire 2x sprite stays inside the viewport instead of centering on the
    # entity origin above it.
    var npc_foot := npc_position + Vector2(0.0, 39.0)
    camera.position = npc_foot
    camera.zoom = Vector2(2.0, 2.0)
    camera.force_update_scroll()
    await process_frame
    var output := ProjectSettings.globalize_path("res://../visual-proof/npc-miner")
    DirAccess.make_dir_recursive_absolute(output)
    var hashes: Dictionary = {}
    for facing in ["down", "left", "right", "up"]:
        for frame in range(4):
            scene.set("v145_debug_npc_facing", facing)
            scene.set("v145_debug_npc_frame", frame)
            scene.queue_redraw()
            await process_frame
            await RenderingServer.frame_post_draw
            var image := root.get_texture().get_image()
            if image == null or image.is_empty():
                _fail("empty viewport")
                return
            var screen_foot := scene.get_global_transform_with_canvas() * npc_foot
            var scaled_frame := Vector2i(NpcMinerSheet.FRAME_SIZE) * 2
            var scaled_anchor := Vector2i(NpcMinerSheet.FOOT_ANCHOR) * 2
            var bounds := Rect2i(Vector2i(screen_foot) - scaled_anchor, scaled_frame)
            if not Rect2i(Vector2i.ZERO, image.get_size()).encloses(bounds):
                _fail("actual NPC frame is outside the proof viewport")
                return
            var crop := image.get_region(bounds)
            var digest := crop.get_data().hex_encode().sha256_text()
            if hashes.has(digest):
                _fail("two live NPC poses produced identical pixels")
                return
            hashes[digest] = true
            var pose := "idle" if frame == 0 else "walk-%02d" % frame
            if crop.save_png(output.path_join("%s-%s.png" % [facing, pose])) != OK:
                _fail("could not save actual NPC gameplay pose")
                return
            if facing == "down" and frame == 0:
                var proof_path := ProjectSettings.globalize_path("res://../visual-proof/npc-miner-runtime.png")
                if crop.save_png(proof_path) != OK:
                    _fail("could not save NPC runtime screenshot")
                    return
    print("HASH RACE NPC MINER RENDER PASS: 16 distinct poses rendered through the actual world path")
    quit(0)
