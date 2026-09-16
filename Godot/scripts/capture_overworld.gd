extends SceneTree

const OUTPUT_PATH := "res://../visual-proof/hashrace-overworld.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("HASH RACE VISUAL PROOF FAIL: " + message)
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

    var image: Image = root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport produced no image")
        return

    var output_dir: String = ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var output_file: String = ProjectSettings.globalize_path(OUTPUT_PATH)
    var save_error: Error = image.save_png(output_file)
    if save_error != OK:
        _fail("could not save visual proof PNG: %s" % error_string(save_error))
        return

    # Sample the actual rendered pixels. A blank gray-screen build has one
    # sampled color; a real town scene has ground, roads, water, buildings,
    # representatives, labels, panels and neon accents.
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
        _fail("render is too visually empty: only %d sampled colors" % histogram.size())
        return
    if dominant_ratio > 0.88:
        _fail("render is dominated by one color: %.1f%%" % (dominant_ratio * 100.0))
        return

    print("HASH RACE VISUAL PROOF PASS: %dx%d PNG, %d sampled colors, dominant color %.1f%%. Saved %s" % [
        image.get_width(), image.get_height(), histogram.size(), dominant_ratio * 100.0, output_file
    ])
    quit(0)
