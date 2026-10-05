extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-screenshot.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE SCREENSHOT CAPTURE FAIL: " + message)
    quit(1)

func _capture() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("world.tscn did not load")
        return
    var scene := packed.instantiate()
    if scene == null:
        _fail("world.tscn did not instantiate")
        return
    root.add_child(scene)

    # Let the real v0.165 campaign, imported textures, navigation, UI and camera settle.
    for _frame in range(14):
        await process_frame

    var live_script := scene.get_script() as Script
    if live_script == null or live_script.resource_path != "res://scripts/world_v165.gd":
        _fail("full v0.165 gameplay world is not live")
        return
    for method_name in [
        "debug_grid_navigation_ready",
        "debug_grid_path_exists",
        "debug_league_standings_ready",
        "debug_life_ops_ready",
        "debug_burnout_ready",
    ]:
        if not scene.has_method(method_name) or not bool(scene.call(method_name)):
            _fail("gameplay subsystem is not ready: %s" % method_name)
            return

    var camera := scene.get("camera") as Camera2D
    var grid_nav = scene.get("grid_nav")
    var inventory = scene.get("infrastructure_inventory")
    if camera == null or grid_nav == null or inventory == null:
        _fail("camera/navigation/inventory did not initialize")
        return

    var archive_props := scene.get_node_or_null("ArchiveSpriteProps")
    if archive_props == null or not archive_props.has_method("debug_ready") or not bool(archive_props.call("debug_ready")):
        _fail("compact promoted sprite props are not loaded at their live-map scale")
        return
    if int(archive_props.call("live_sprite_count")) != 33:
        _fail("expected 33 compact promoted sprite cells")
        return

    # Actual movement/cadence is validated by validate_player_walk_motion.gd in
    # the preceding CI step. Screenshot proof should render the real live-world
    # canvas player without trying to synthesize keyboard input in the capture harness.
    var rep_pos: Vector2 = scene.get("rep_pos")
    if rep_pos == Vector2.ZERO or not bool(grid_nav.call("world_is_walkable", rep_pos)):
        _fail("player representative is not on a playable tile")
        return
    scene.set("rep_facing", "right")
    scene.set("rep_animation_state", "right_walk")
    scene.set("rep_step_phase", TAU * 0.25)
    scene.queue_redraw()

    for _frame in range(12):
        await process_frame
    await create_timer(0.20).timeout

    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport produced no image")
        return

    var output_dir := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var output_file := ProjectSettings.globalize_path(OUTPUT_PATH)
    var save_error := image.save_png(output_file)
    if save_error != OK:
        _fail("could not save screenshot PNG: %s" % error_string(save_error))
        return

    var histogram: Dictionary = {}
    var sampled := 0
    var step_x := maxi(1, int(image.get_width() / 90.0))
    var step_y := maxi(1, int(image.get_height() / 56.0))
    for y in range(0, image.get_height(), step_y):
        for x in range(0, image.get_width(), step_x):
            var key := image.get_pixel(x, y).to_html(false)
            histogram[key] = int(histogram.get(key, 0)) + 1
            sampled += 1

    var dominant_count := 0
    for raw_count in histogram.values():
        dominant_count = maxi(dominant_count, int(raw_count))
    var dominant_ratio := float(dominant_count) / maxf(1.0, float(sampled))
    if histogram.size() < 18:
        _fail("screenshot is too visually empty: only %d sampled colors" % histogram.size())
        return
    if dominant_ratio > 0.88:
        _fail("screenshot is dominated by one color: %.1f%%" % (dominant_ratio * 100.0))
        return

    print("HASH RACE SCREENSHOT CAPTURE PASS: full v0.165 gameplay; 33 compact sprite cells; authored live-world walk pose; %dx%d PNG; %d sampled colors; dominant %.1f%%. Saved %s" % [image.get_width(), image.get_height(), histogram.size(), dominant_ratio * 100.0, output_file])
    quit(0)
