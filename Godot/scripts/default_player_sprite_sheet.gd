extends RefCounted
class_name HashRaceDefaultPlayerSpriteSheet

const SHEET_PATH := "res://art/characters/default_player_sheet.png"
const FRAME_SIZE := Vector2i(56, 56)

# Runtime atlas derived from the exact uploaded 4x4 source image.
# Row 0 = down/front, row 1 = up/back, row 2 = left, row 3 = right.
const FRAME_REGIONS := {
    "down": [
        Rect2i(0, 0, 56, 56),
        Rect2i(56, 0, 56, 56),
        Rect2i(112, 0, 56, 56),
        Rect2i(168, 0, 56, 56),
    ],
    "up": [
        Rect2i(0, 56, 56, 56),
        Rect2i(56, 56, 56, 56),
        Rect2i(112, 56, 56, 56),
        Rect2i(168, 56, 56, 56),
    ],
    "left": [
        Rect2i(0, 112, 56, 56),
        Rect2i(56, 112, 56, 56),
        Rect2i(112, 112, 56, 56),
        Rect2i(168, 112, 56, 56),
    ],
    "right": [
        Rect2i(0, 168, 56, 56),
        Rect2i(56, 168, 56, 56),
        Rect2i(112, 168, 56, 56),
        Rect2i(168, 168, 56, 56),
    ],
}

static func load_texture() -> Texture2D:
    if ResourceLoader.exists(SHEET_PATH):
        var imported := load(SHEET_PATH) as Texture2D
        if imported != null:
            return imported
    var absolute_path := ProjectSettings.globalize_path(SHEET_PATH)
    if not FileAccess.file_exists(absolute_path):
        return null
    var image := Image.new()
    if image.load(absolute_path) != OK or image.is_empty():
        return null
    return ImageTexture.create_from_image(image)

static func build_frames() -> SpriteFrames:
    var texture := load_texture()
    if texture == null:
        return null

    var frames := SpriteFrames.new()
    if frames.has_animation(&"default"):
        frames.remove_animation(&"default")

    _add_animation(frames, &"idle_down", texture, [FRAME_REGIONS["down"][0]], 1.0, true)
    _add_animation(frames, &"idle_up", texture, [FRAME_REGIONS["up"][0]], 1.0, true)
    _add_animation(frames, &"idle_left", texture, [FRAME_REGIONS["left"][0]], 1.0, true)
    _add_animation(frames, &"idle_right", texture, [FRAME_REGIONS["right"][0]], 1.0, true)

    _add_animation(frames, &"walk_down", texture, FRAME_REGIONS["down"], 10.0, true)
    _add_animation(frames, &"walk_up", texture, FRAME_REGIONS["up"], 10.0, true)
    _add_animation(frames, &"walk_left", texture, FRAME_REGIONS["left"], 10.0, true)
    _add_animation(frames, &"walk_right", texture, FRAME_REGIONS["right"], 10.0, true)

    return frames

static func frame_region(facing: String, frame: int) -> Rect2i:
    var safe_facing := facing if FRAME_REGIONS.has(facing) else "down"
    var regions: Array = FRAME_REGIONS[safe_facing]
    return regions[clampi(frame, 0, regions.size() - 1)]

static func _add_animation(
    frames: SpriteFrames,
    name: StringName,
    texture: Texture2D,
    regions: Array,
    fps: float,
    loop: bool
) -> void:
    frames.add_animation(name)
    frames.set_animation_speed(name, fps)
    frames.set_animation_loop(name, loop)

    for region in regions:
        var atlas := AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = region
        atlas.filter_clip = true
        frames.add_frame(name, atlas)
