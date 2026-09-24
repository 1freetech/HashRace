extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-2d-detail.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE 2D DETAIL PROOF FAIL: " + message)
    quit(1)

func _capture() -> void:
    set_meta("hashrace_company_idx", 0)
    set_meta("hashrace_campaign_years", 4)
    set_meta("hashrace_campaign_turns", 16)
    set_meta("hashrace_character_skin_tone", 2)
    set_meta("hashrace_character_gender", 0)
    set_meta("hashrace_character_outfit", 0)

    var packed: PackedScene = load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("world.tscn did not load")
        return

    var scene: Node = packed.instantiate()
    if scene == null:
        _fail("world.tscn did not instantiate")
        return
    root.add_child(scene)

    for _frame in range(14):
        await process_frame
    await create_timer(0.25).timeout

    if scene.get_node_or_null("BootFallback") != null:
        _fail("loading fallback is still covering the game")
        return
    if not scene.has_method("debug_visual_detail_ready"):
        _fail("visual detail controller is not active")
        return
    if not bool(scene.call("debug_visual_detail_ready")):
        _fail("visual detail controller reported not ready")
        return
    if not scene.has_method("debug_character_detail_ready"):
        _fail("v0.053 character detail controller is not active")
        return
    if not bool(scene.call("debug_character_detail_ready")):
        _fail("character detail controller reported not ready")
        return
    if not scene.has_method("debug_v073_ready") or not bool(scene.call("debug_v073_ready")):
        _fail("v0.073 high-density reusable character renderer is not active")
        return
    if int(scene.call("debug_character_body_variant_count")) < 5:
        _fail("v0.073 character body library is too small")
        return
    var v073_poses: Array = scene.call("debug_character_pose_library")
    if "mining" not in v073_poses or "victory" not in v073_poses or "walk_left" not in v073_poses:
        _fail("v0.073 directional/action pose library is incomplete")
        return

    if not scene.has_method("debug_infrastructure_detail_ready"):
        _fail("v0.059 infrastructure detail controller is not active")
        return
    if not bool(scene.call("debug_infrastructure_detail_ready")):
        _fail("v0.059 infrastructure detail controller reported not ready")
        return

    # Remove HUD/dialog panels from this proof so the rendered game art itself
    # is visible. The normal release screenshot still proves the full HUD.
    for child in scene.get_children():
        if child is CanvasLayer:
            for ui_child in child.get_children():
                if ui_child is CanvasItem:
                    (ui_child as CanvasItem).visible = false

    var camera: Camera2D = root.get_camera_2d()
    if camera == null:
        _fail("world camera was not created")
        return
    camera.position_smoothing_enabled = false
    camera.position = Vector2(1500.0, 1215.0)
    camera.zoom = Vector2(2.0, 2.0)
    scene.queue_redraw()

    for _frame in range(8):
        await process_frame
    await create_timer(0.12).timeout

    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport produced no detail image")
        return

    var output_dir: String = ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var output_file: String = ProjectSettings.globalize_path(OUTPUT_PATH)
    var save_error: Error = image.save_png(output_file)
    if save_error != OK:
        _fail("could not save close-up PNG: %s" % error_string(save_error))
        return

    # Material-detail gate: count sampled colors and local contrast transitions.
    # This is intentionally stricter than the wide overworld proof. A scene made
    # of large flat rectangles can pass a color-count test but should fail here.
    var histogram: Dictionary = {}
    var transitions: int = 0
    var comparisons: int = 0
    var sample_step: int = 4
    var x0: int = int(image.get_width() * 0.14)
    var x1: int = int(image.get_width() * 0.86)
    var y0: int = int(image.get_height() * 0.10)
    var y1: int = int(image.get_height() * 0.90)

    for y in range(y0, y1 - sample_step, sample_step):
        for x in range(x0, x1 - sample_step, sample_step):
            var pixel: Color = image.get_pixel(x, y)
            histogram[pixel.to_html(false)] = int(histogram.get(pixel.to_html(false), 0)) + 1
            var right: Color = image.get_pixel(x + sample_step, y)
            var down: Color = image.get_pixel(x, y + sample_step)
            var luma: float = pixel.get_luminance()
            if absf(luma - right.get_luminance()) > 0.055:
                transitions += 1
            if absf(luma - down.get_luminance()) > 0.055:
                transitions += 1
            comparisons += 2

    var transition_ratio: float = float(transitions) / maxf(1.0, float(comparisons))
    if histogram.size() < 45:
        _fail("close-up still lacks color/detail variety: only %d sampled colors" % histogram.size())
        return
    if transition_ratio < 0.035:
        _fail("close-up still looks too flat: local contrast transition ratio %.3f" % transition_ratio)
        return

    print("HASH RACE 2D DETAIL PROOF PASS: %dx%d PNG, %d sampled colors, local contrast %.1f%%, visual detail revision %d, character detail revision %d. Saved %s" % [
        image.get_width(), image.get_height(), histogram.size(), transition_ratio * 100.0,
        int(scene.get_meta("hashrace_visual_detail_revision", 0)),
        int(scene.get_meta("hashrace_character_detail_revision", 0)), output_file
    ])
    quit(0)
