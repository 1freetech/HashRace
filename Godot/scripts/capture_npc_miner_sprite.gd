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
    if not bool(scene.get_meta("hashrace_npc_miner_asset_live", false)) or not bool(scene.call("debug_v147_ready")):
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
    # The live NPC renderer anchors the 128px atlas frame at pos + (0, 39).
    # Center the camera on that exact ground-contact point. Godot Camera2D zoom
    # enlarges world pixels on screen, but the proof crop stays tied to the
    # atlas frame and its authored foot anchor.
    var npc_foot := npc_position + Vector2(0.0, 39.0)
    camera.position = npc_foot
    camera.zoom = Vector2(2.0, 2.0)
    camera.force_update_scroll()
    await process_frame

    # Decode the committed PNG again for the render proof. Some authored source
    # poses can intentionally share identical pixels. The runtime proof must
    # preserve the source equivalence relation instead of inventing a false
    # requirement that all 16 source cells be unique.
    var source := Image.new()
    if source.load(ProjectSettings.globalize_path(NpcMinerSheet.SHEET_PATH)) != OK or source.get_size() != NpcMinerSheet.SHEET_SIZE:
        _fail("could not decode committed NPC atlas for render comparison")
        return

    var output := ProjectSettings.globalize_path("res://../visual-proof/npc-miner")
    DirAccess.make_dir_recursive_absolute(output)
    var live_hashes: Dictionary = {}
    var source_hashes: Dictionary = {}
    var pose_keys: Array[String] = []
    for facing in ["down", "left", "right", "up"]:
        for frame in range(4):
            scene.set("v147_debug_npc_facing", facing)
            scene.set("v147_debug_npc_frame", frame)
            scene.queue_redraw()
            await process_frame
            await RenderingServer.frame_post_draw
            var image := root.get_texture().get_image()
            if image == null or image.is_empty():
                _fail("empty viewport")
                return
            # Because the camera is centered on npc_foot, the ground-contact
            # anchor is exactly the viewport center. This avoids mixing world,
            # canvas, and viewport coordinate spaces when Camera2D zoom is live.
            var screen_foot := Vector2(image.get_size()) * 0.5
            var scaled_frame := Vector2i(NpcMinerSheet.FRAME_SIZE) * 2
            var scaled_anchor := Vector2i(NpcMinerSheet.FOOT_ANCHOR) * 2
            var bounds := Rect2i(Vector2i(screen_foot) - scaled_anchor, scaled_frame)
            if not Rect2i(Vector2i.ZERO, image.get_size()).encloses(bounds):
                _fail("actual NPC frame is outside the proof viewport")
                return
            var crop := image.get_region(bounds)
            var live_digest := crop.get_data().hex_encode().sha256_text()
            var source_region := source.get_region(NpcMinerSheet.frame_region(facing, frame))
            var source_digest := source_region.get_data().hex_encode().sha256_text()
            var pose_key := "%s:%d" % [facing, frame]

            # For every previously rendered pose, runtime equality must match
            # source equality. This catches wrong direction/frame mapping while
            # allowing deliberate duplicate source cells.
            for previous_key in pose_keys:
                var source_same: bool = String(source_hashes[previous_key]) == source_digest
                var live_same: bool = String(live_hashes[previous_key]) == live_digest
                if source_same != live_same:
                    _fail("live pose mapping diverged from source atlas: %s vs %s" % [previous_key, pose_key])
                    return
            source_hashes[pose_key] = source_digest
            live_hashes[pose_key] = live_digest
            pose_keys.append(pose_key)

            var pose := "idle" if frame == 0 else "walk-%02d" % frame
            if crop.save_png(output.path_join("%s-%s.png" % [facing, pose])) != OK:
                _fail("could not save actual NPC gameplay pose")
                return
            if facing == "down" and frame == 0:
                var proof_path := ProjectSettings.globalize_path("res://../visual-proof/npc-miner-runtime.png")
                if crop.save_png(proof_path) != OK:
                    _fail("could not save NPC runtime screenshot")
                    return
    print("HASH RACE NPC MINER RENDER PASS: 16 live poses preserve exact source direction/frame mapping")
    quit(0)
