extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-screenshot.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE SCREENSHOT CAPTURE FAIL: " + message)
    quit(1)

func _capture() -> void:
    set_meta("hashrace_company_idx", 0)
    set_meta("hashrace_campaign_years", 4)
    set_meta("hashrace_campaign_turns", 16)

    var packed: PackedScene = load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("world.tscn did not load")
        return

    var scene: Node = packed.instantiate()
    if scene == null:
        _fail("world.tscn did not instantiate")
        return
    root.add_child(scene)

    for _frame in range(10):
        await process_frame
    await create_timer(0.20).timeout

    if scene.get_node_or_null("BootFallback") != null:
        _fail("loading fallback is still covering the game")
        return
    if int(scene.get_meta("hashrace_v124_visual_target_revision", 0)) != 1:
        _fail("v0.124 visual-target layer is not live beneath v0.130")
        return
    if int(scene.get_meta("hashrace_v130_library_overview_revision", 0)) != 1:
        _fail("v0.130 Library-overview layer is not live")
        return
    if not bool(scene.get_meta("hashrace_v130_library_overview_live", false)):
        _fail("v0.130 Library overview image did not load into the live scene")
        return
    if not scene.has_method("debug_v130_ready") or not bool(scene.call("debug_v130_ready")):
        _fail("v0.130 Library-overview runtime contract failed")
        return
    if int(scene.get_meta("hashrace_v128_road_cleanup_revision", 0)) != 1:
        _fail("v0.128 road/container cleanup layer is not live")
        return
    if not bool(scene.get_meta("hashrace_v128_container_asset_live", false)):
        _fail("v0.128 C-01 container asset did not load into the live scene")
        return
    if not bool(scene.get_meta("hashrace_v128_single_road_stack", false)):
        _fail("v0.128 single-road-stack contract is not active")
        return
    if int(scene.get_meta("hashrace_v127_asset_bundle_revision", 0)) != 1:
        _fail("v0.127 asset-bundle layer is not live")
        return
    for key in [
        "hashrace_industrial_road_live",
        "hashrace_utility_props_live",
        "hashrace_wind_turbine_live",
        "hashrace_asic_air_live",
    ]:
        if not bool(scene.get_meta(key, false)):
            _fail("%s did not load into the live scene" % key)
            return
    if int(scene.get_meta("hashrace_v126_grass_terrain_revision", 0)) != 1:
        _fail("v0.126 grass-terrain layer is not live")
        return
    if int(scene.get_meta("hashrace_v125_dirt_road_revision", 0)) != 1:
        _fail("v0.125 dirt-road layer is not live beneath v0.126")
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
        _fail("could not save screenshot PNG: %s" % error_string(save_error))
        return

    # Reject blank or nearly blank captures so every published release gets a
    # real gameplay screenshot rather than a loading/fallback frame.
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

    if histogram.size() < 18:
        _fail("screenshot is too visually empty: only %d sampled colors" % histogram.size())
        return
    if dominant_ratio > 0.88:
        _fail("screenshot is dominated by one color: %.1f%%" % (dominant_ratio * 100.0))
        return

    print("HASH RACE SCREENSHOT CAPTURE PASS: %dx%d PNG, %d sampled colors, dominant color %.1f%%. Saved %s" % [
        image.get_width(), image.get_height(), histogram.size(), dominant_ratio * 100.0, output_file
    ])
    quit(0)
