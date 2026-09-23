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
    for direction in ["down", "left", "right", "up"]:
        _require(frames.get_frame_count("idle_" + direction) == 1, direction + " needs one idle pose")
        _require(frames.get_frame_count("walk_" + direction) == 4, direction + " needs four walk poses")
        for effective_index in range(5):
            var region: Rect2i = Sheet.frame_region(direction, effective_index)
            _require(Rect2i(Vector2i.ZERO, image.get_size()).encloses(region), "frame outside PNG")
            var crop := image.get_region(region)
            _require(crop.get_used_rect().has_area(), "blank effective frame")
            var source_index: int = int(Sheet.EFFECTIVE_SOURCE_INDICES[effective_index])
            _require(region == Sheet.FRAME_REGIONS[direction][source_index], "effective frame mapping drift")
    var walked: Dictionary = {}
    for index in range(30):
        var selected := Sheet.walk_frame(true, TAU * float(index) / 30.0)
        _require(selected >= 1 and selected <= 4, "walking must exclude idle")
        walked[selected] = true
    _require(walked.size() == 4 and Sheet.walk_frame(false, 1.9) == 0, "walk cycle must visit four phases then hold idle")
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
    print("HASH RACE PLAYER VALIDATION PASS: %d image binaries; exact 32-pose PNG source; effective 20-pose runtime cycle" % decoded)
    quit(0)
