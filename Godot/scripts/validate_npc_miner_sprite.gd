extends SceneTree

const Sheet = preload("res://scripts/npc_miner_sprite_sheet.gd")
var failures: Array[String] = []

func _require(ok: bool, message: String) -> void:
    if not ok:
        failures.append(message)
        push_error("HASH RACE NPC MINER VALIDATION FAIL: " + message)

func _initialize() -> void:
    call_deferred("_validate")

func _validate() -> void:
    var bytes := FileAccess.get_file_as_bytes(Sheet.SHEET_PATH)
    _require(bytes.slice(0, 8).hex_encode() == "89504e470d0a1a0a", "PNG signature")
    _require(FileAccess.get_sha256(Sheet.SHEET_PATH) == Sheet.SHEET_SHA256, "committed binary SHA-256")
    var image := Image.new()
    _require(image.load_png_from_buffer(bytes) == OK and image.get_size() == Sheet.SHEET_SIZE, "full PNG decode and dimensions")
    if image.is_empty():
        quit(1)
        return
    _require(image.detect_alpha() != Image.ALPHA_NONE, "transparent RGBA atlas")
    var frames := Sheet.build_frames()
    _require(frames != null, "SpriteFrames build from committed PNG")
    if frames != null:
        for facing in ["down", "left", "right", "up"]:
            _require(frames.get_frame_count("idle_" + facing) == 1, facing + " idle frame")
            _require(frames.get_frame_count("walk_" + facing) == 3, facing + " walk frames")
            for frame in range(4):
                var region := Sheet.frame_region(facing, frame)
                _require(image.get_region(region).get_used_rect().has_area(), "%s frame %d is nonblank" % [facing, frame])
                var used := image.get_region(region).get_used_rect()
                _require(abs((used.position.y + used.size.y) - Sheet.FOOT_ANCHOR.y) <= 1, "%s frame %d foot anchor" % [facing, frame])
    if not failures.is_empty():
        quit(1)
        return
    print("HASH RACE NPC MINER VALIDATION PASS: exact PNG SHA; 16 decoded transparent directional poses; consistent foot anchors")
    quit(0)
