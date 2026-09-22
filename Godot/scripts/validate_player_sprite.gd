extends SceneTree

const Sheet = preload("res://scripts/default_player_sprite_sheet.gd")
const Energy = preload("res://systems/energy_visual_catalog.gd")
const Visual = preload("res://scripts/default_player_visual.gd")
var failures: Array[String] = []

func _require(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        push_error("HASH RACE PLAYER VALIDATION FAIL: " + message)

func _decode_tree(path: String) -> int:
    var count := 0
    for file_name in DirAccess.get_files_at(path):
        var full_path := path.path_join(file_name)
        var extension := file_name.get_extension().to_lower()
        if extension not in ["png", "jpg", "jpeg", "webp"]:
            continue
        var bytes := FileAccess.get_file_as_bytes(full_path)
        var image := Image.new()
        var error := ERR_FILE_UNRECOGNIZED
        if extension == "png":
            _require(bytes.slice(0, 8).hex_encode() == "89504e470d0a1a0a", "PNG signature: " + full_path)
            error = image.load_png_from_buffer(bytes)
        elif extension == "webp":
            error = image.load_webp_from_buffer(bytes)
        else:
            _require(bytes.slice(0, 2).hex_encode() == "ffd8", "JPEG signature: " + full_path)
            error = image.load_jpg_from_buffer(bytes)
        _require(error == OK and not image.is_empty(), "full source decode: " + full_path)
        count += 1
    for directory in DirAccess.get_directories_at(path):
        if not directory.begins_with("."):
            count += _decode_tree(path.path_join(directory))
    return count

func _initialize() -> void:
    call_deferred("_validate")

func _validate() -> void:
    var decoded := _decode_tree("res://art") + _decode_tree("res://assets")
    _require(Energy.master_texture() != null, "embedded energy atlas must fully decode")
    _require(FileAccess.get_sha256(Sheet.SHEET_PATH) == Sheet.SHEET_SHA256, "committed player bytes must match the approved atlas")
    var image := Image.new()
    _require(image.load_png_from_buffer(FileAccess.get_file_as_bytes(Sheet.SHEET_PATH)) == OK and image.get_size() == Sheet.SHEET_SIZE, "player PNG dimensions/decode")
    if image.is_empty():
        quit(1)
        return
    _require(image.detect_alpha() != Image.ALPHA_NONE, "player requires real transparency")
    var frames := Sheet.build_frames()
    _require(frames != null, "SpriteFrames must build from the actual PNG")
    if frames == null:
        quit(1)
        return
    var seen_regions: Array[Rect2i] = []
    var frame_hashes: Dictionary = {}
    for direction in ["down", "left", "right", "up"]:
        _require(frames.get_frame_count("idle_" + direction) == 1, direction + " needs one idle pose")
        _require(frames.get_frame_count("walk_" + direction) == 7, direction + " needs seven walk poses")
        for index in range(8):
            var region: Rect2i = Sheet.frame_region(direction, index)
            _require(Rect2i(Vector2i.ZERO, image.get_size()).encloses(region), "frame outside PNG: %s/%d" % [direction, index])
            for previous in seen_regions:
                _require(not previous.intersects(region), "overlapping source frames")
            seen_regions.append(region)
            var crop := image.get_region(region)
            var used := crop.get_used_rect()
            _require(used.has_area(), "blank frame: %s/%d" % [direction, index])
            var solid := 0
            var clear := 0
            for y in range(crop.get_height()):
                for x in range(crop.get_width()):
                    var alpha := crop.get_pixel(x, y).a
                    if alpha > 0.9:
                        solid += 1
                    elif alpha < 0.05:
                        clear += 1
            _require(solid > 3000 and clear > 500, "frame needs opaque character and clear background")
            var digest := crop.get_data().hex_encode().sha256_text()
            _require(not frame_hashes.has(digest), "duplicate pose data")
            frame_hashes[digest] = true
            var animation: String = "idle_" + direction if index == 0 else "walk_" + direction
            var animation_index := 0 if index == 0 else index - 1
            var atlas := frames.get_frame_texture(animation, animation_index) as AtlasTexture
            _require(atlas != null and Vector2i(atlas.get_size()) == Sheet.FRAME_SIZE, "logical canvas changed")
            _require(int(atlas.margin.position.y) + region.size.y == Sheet.FOOT_ANCHOR.y, "foot anchor drift")
    var walked: Dictionary = {}
    for index in range(70):
        var selected := Sheet.walk_frame(true, TAU * float(index) / 70.0)
        _require(selected >= 1 and selected <= 7, "walking must exclude idle")
        walked[selected] = true
    _require(walked.size() == 7 and Sheet.walk_frame(false, 1.9) == 0, "walk cycle must visit every phase then hold idle")
    var visual := Visual.new()
    root.add_child(visual)
    for direction in ["down", "left", "right", "up"]:
        visual.update_from_world_state(direction, direction + "_walk")
        _require(visual.animation == StringName("walk_" + direction), "walking direction transition")
        visual.update_from_world_state(direction, direction + "_idle")
        _require(visual.animation == StringName("idle_" + direction), "idle preserves facing")
    visual.queue_free()
    if not failures.is_empty():
        quit(1)
        return
    print("HASH RACE PLAYER VALIDATION PASS: %d image binaries + energy atlas, 32 distinct poses, 4 idle/7-phase walk cycles, alpha, bounds and foot anchors" % decoded)
    quit(0)
