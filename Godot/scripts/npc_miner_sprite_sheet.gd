extends RefCounted
class_name HashRaceNpcMinerSpriteSheet

const SHEET_PATH := "res://art/characters/npc_miner_sheet.png"
const SHEET_SIZE := Vector2i(512, 512)
const FRAME_SIZE := Vector2i(128, 128)
const FOOT_ANCHOR := Vector2i(64, 120)
const SHEET_SHA256 := "519fa3a2b9b9d861da1acad119c7ebe991c182bc46e8e1dd95c0ec13deedb3f7"
const WALK_FRAME_COUNT := 3
const WALK_FPS := 7.0
const ROWS := {"down": 0, "left": 1, "right": 2, "up": 3}

static func load_texture() -> Texture2D:
    if ResourceLoader.exists(SHEET_PATH):
        var imported := load(SHEET_PATH) as Texture2D
        if imported != null and Vector2i(imported.get_size()) == SHEET_SIZE:
            return imported
    var image := Image.new()
    if image.load(ProjectSettings.globalize_path(SHEET_PATH)) != OK or image.get_size() != SHEET_SIZE:
        return null
    return ImageTexture.create_from_image(image)

static func frame_region(facing: String, frame: int) -> Rect2i:
    var safe_facing := facing if ROWS.has(facing) else "down"
    return Rect2i(clampi(frame, 0, 3) * FRAME_SIZE.x, int(ROWS[safe_facing]) * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)

static func walk_frame(moving: bool, step_phase: float) -> int:
    if not moving:
        return 0
    return 1 + mini(int(floor(fposmod(step_phase, TAU) / TAU * WALK_FRAME_COUNT)), WALK_FRAME_COUNT - 1)

static func build_frames() -> SpriteFrames:
    var texture := load_texture()
    if texture == null:
        return null
    var frames := SpriteFrames.new()
    if frames.has_animation(&"default"):
        frames.remove_animation(&"default")
    for facing in ["down", "left", "right", "up"]:
        _add_animation(frames, StringName("idle_" + facing), texture, [0], 1.0)
        _add_animation(frames, StringName("walk_" + facing), texture, [1, 2, 3], WALK_FPS)
    return frames

static func _add_animation(frames: SpriteFrames, name: StringName, texture: Texture2D, indices: Array, fps: float) -> void:
    frames.add_animation(name)
    frames.set_animation_speed(name, fps)
    frames.set_animation_loop(name, true)
    var facing := String(name).trim_prefix("idle_").trim_prefix("walk_")
    for index in indices:
        var atlas := AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = frame_region(facing, int(index))
        atlas.filter_clip = true
        frames.add_frame(name, atlas)

static func debug_ready() -> bool:
    var texture := load_texture()
    return texture != null and Vector2i(texture.get_size()) == SHEET_SIZE and ROWS.size() == 4
