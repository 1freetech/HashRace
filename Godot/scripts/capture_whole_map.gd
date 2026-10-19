extends SceneTree

# Whole-map visual proof for the active full HashRace campaign. This is separate
# from the normal gameplay screenshot so composition can be judged at a real
# overhead scale without a close camera hiding empty, duplicate, or awkward areas.
const OUTPUT_PATH := "res://../visual-proof/hashrace-whole-map.png"
const PLAYABLE_WORLD_SIZE := Vector2(3000.0, 1900.0)
const FIT_MARGIN := 0.94

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE WHOLE MAP PROOF FAIL: " + message)
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

    # Let the real campaign build terrain, facilities, NPCs, navigation and UI.
    for _frame in range(16):
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
    if camera == null:
        _fail("live gameplay camera is missing")
        return

    # Fit the complete live world inside the real 1440x900 capture viewport.
    # A small margin makes world edges visible instead of clipping at the frame.
    var viewport_size := root.get_visible_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        _fail("capture viewport has no usable size")
        return
    var fit_zoom := minf(
        viewport_size.x / PLAYABLE_WORLD_SIZE.x,
        viewport_size.y / PLAYABLE_WORLD_SIZE.y
    ) * FIT_MARGIN
    if fit_zoom <= 0.0:
        _fail("whole-map camera zoom was invalid")
        return
    camera.position_smoothing_enabled = false
    camera.position = PLAYABLE_WORLD_SIZE * 0.5
    camera.zoom = Vector2.ONE * fit_zoom
    camera.force_update_scroll()
    scene.queue_redraw()

    for _frame in range(12):
        await process_frame
    await create_timer(0.20).timeout

    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport produced no image")
        return

    var covered_world := Vector2(
        float(image.get_width()) / camera.zoom.x,
        float(image.get_height()) / camera.zoom.y
    )
    if covered_world.x + 1.0 < PLAYABLE_WORLD_SIZE.x or covered_world.y + 1.0 < PLAYABLE_WORLD_SIZE.y:
        _fail("camera does not include the whole playable map: %.0fx%.0f visible" % [covered_world.x, covered_world.y])
        return

    var sampled_colors: Dictionary = {}
    var sampled := 0
    var step_x := maxi(1, int(image.get_width() / 120.0))
    var step_y := maxi(1, int(image.get_height() / 76.0))
    for y in range(0, image.get_height(), step_y):
        for x in range(0, image.get_width(), step_x):
            var key := image.get_pixel(x, y).to_html(false)
            sampled_colors[key] = int(sampled_colors.get(key, 0)) + 1
            sampled += 1
    var dominant_count := 0
    for count in sampled_colors.values():
        dominant_count = maxi(dominant_count, int(count))
    var dominant_ratio := float(dominant_count) / maxf(1.0, float(sampled))
    if sampled_colors.size() < 24:
        _fail("whole-map image is too visually empty: only %d sampled colors" % sampled_colors.size())
        return
    if dominant_ratio > 0.92:
        _fail("whole-map image is too visually dominated by one color: %.1f%%" % (dominant_ratio * 100.0))
        return

    var output_dir := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var output_file := ProjectSettings.globalize_path(OUTPUT_PATH)
    if image.save_png(output_file) != OK:
        _fail("could not save whole-map PNG")
        return

    print("HASH RACE WHOLE MAP PROOF PASS: %dx%d PNG; camera covers %.0fx%.0f world; %d sampled colors; dominant %.1f%%. Saved %s" % [
        image.get_width(), image.get_height(), covered_world.x, covered_world.y,
        sampled_colors.size(), dominant_ratio * 100.0, output_file
    ])
    quit(0)
