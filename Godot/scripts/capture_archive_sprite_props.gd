extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-archive-sprite-props.png"
const PROOF_CENTER := Vector2(900.0, 1015.0)

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("ARCHIVE SPRITE PROOF FAIL: " + message)
    quit(1)

func _capture() -> void:
    var packed: PackedScene = load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("world.tscn did not load")
        return
    var scene: Node = packed.instantiate()
    if scene == null:
        _fail("world.tscn did not instantiate")
        return
    root.add_child(scene)

    for _frame in range(16):
        await process_frame

    var props: Node = scene.get_node_or_null("ArchiveSpriteProps")
    if props == null:
        _fail("ArchiveSpriteProps node is missing from the live world")
        return
    if not props.has_method("debug_ready") or not bool(props.call("debug_ready")):
        _fail("archive sprite layer did not validate all promoted sheets and cells")
        return
    if int(props.call("live_sheet_count")) != 11 or int(props.call("live_sprite_count")) != 33:
        _fail("expected 11 live sheets and 33 live atlas sprites")
        return
    var survey: Node = props.get_node_or_null("EquipmentSurvey")
    if survey == null or not survey.has_method("debug_ready") or not bool(survey.call("debug_ready")):
        _fail("live equipment survey/reliability gameplay is missing or invalid")
        return

    scene.set("rep_pos", PROOF_CENTER)
    var player_sprite := scene.get("player_sprite") as AnimatedSprite2D
    if player_sprite != null:
        player_sprite.position = PROOF_CENTER
    var camera := scene.get("camera") as Camera2D
    if camera == null:
        _fail("live camera is missing")
        return
    camera.position_smoothing_enabled = false
    camera.position = PROOF_CENTER
    scene.queue_redraw()

    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout

    var nearest_name := String(survey.call("nearest_equipment_name"))
    if nearest_name.is_empty():
        _fail("equipment survey did not acquire a nearby promoted prop")
        return
    var inspect_prompt := survey.get_node_or_null("EquipmentInspectPrompt") as Label
    if inspect_prompt == null or not inspect_prompt.visible or "[E/F] INSPECT" not in inspect_prompt.text:
        _fail("equipment survey prompt is not visibly rendered near the player")
        return

    var uptime_before := float(scene.call("_uptime_without_grid_penalty"))
    if not survey.has_method("debug_force_fault") or not bool(survey.call("debug_force_fault", nearest_name, 1)):
        _fail("could not force the nearby surveyed equipment into a major fault")
        return
    for _frame in range(8):
        await process_frame

    if String(survey.call("active_fault_name")) != nearest_name:
        _fail("forced equipment fault did not persist on the promoted prop")
        return
    if inspect_prompt == null or not inspect_prompt.visible or "[R] REPAIR" not in inspect_prompt.text or "MAJOR" not in inspect_prompt.text:
        _fail("live repair prompt is not visibly rendered on the failed equipment")
        return
    var player_value: Variant = scene.get("player")
    if not player_value is Dictionary or float(player_value.get("equipment_uptime_penalty", 0.0)) <= 0.0:
        _fail("equipment fault did not persist a mining-uptime penalty in live player state")
        return
    var uptime_after := float(scene.call("_uptime_without_grid_penalty"))
    if uptime_after >= uptime_before - 0.02:
        _fail("equipment fault did not materially lower the live mining uptime")
        return

    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport produced no image")
        return

    var output_dir: String = ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var output_file: String = ProjectSettings.globalize_path(OUTPUT_PATH)
    var save_error: Error = image.save_png(output_file)
    if save_error != OK:
        _fail("could not save proof PNG: %s" % error_string(save_error))
        return

    var histogram: Dictionary = {}
    var sampled: int = 0
    var step_x: int = maxi(1, int(image.get_width() / 90.0))
    var step_y: int = maxi(1, int(image.get_height() / 56.0))
    for y in range(0, image.get_height(), step_y):
        for x in range(0, image.get_width(), step_x):
            var pixel: Color = image.get_pixel(x, y)
            var key: String = pixel.to_html(false)
            histogram[key] = int(histogram.get(key, 0)) + 1
            sampled += 1
    var dominant_count: int = 0
    for raw_count in histogram.values():
        dominant_count = maxi(dominant_count, int(raw_count))
    var dominant_ratio: float = float(dominant_count) / maxf(1.0, float(sampled))
    if histogram.size() < 20 or dominant_ratio > 0.88:
        _fail("proof frame is visually empty or dominated by one color")
        return

    print("ARCHIVE SPRITE PROOF PASS: 11 exact sheets, 33 grounded live props, tuned layout, visible inspection + repair gameplay, and a material uptime penalty on failed equipment (%s %.3f -> %.3f); %dx%d PNG saved %s" % [nearest_name, uptime_before, uptime_after, image.get_width(), image.get_height(), output_file])
    quit(0)
