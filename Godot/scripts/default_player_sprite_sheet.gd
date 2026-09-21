extends RefCounted
class_name HashRaceDefaultPlayerSpriteSheet

const SHEET_PATH := "res://art/characters/default_player_sheet.png"
const FRAME_SIZE := Vector2i(16, 16)

# Runtime atlas: fresh valid-binary 4x4 pixel-art sheet.
# Row 0 = down/front, row 1 = up/back, row 2 = left, row 3 = right.
const FRAME_REGIONS := {
    "down": [Rect2i(0, 0, 16, 16), Rect2i(16, 0, 16, 16), Rect2i(32, 0, 16, 16), Rect2i(48, 0, 16, 16)],
    "up": [Rect2i(0, 16, 16, 16), Rect2i(16, 16, 16, 16), Rect2i(32, 16, 16, 16), Rect2i(48, 16, 16, 16)],
    "left": [Rect2i(0, 32, 16, 16), Rect2i(16, 32, 16, 16), Rect2i(32, 32, 16, 16), Rect2i(48, 32, 16, 16)],
    "right": [Rect2i(0, 48, 16, 16), Rect2i(16, 48, 16, 16), Rect2i(32, 48, 16, 16), Rect2i(48, 48, 16, 16)],
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

static func _add_animation(frames: SpriteFrames, name: StringName, texture: Texture2D, regions: Array, fps: float, loop: bool) -> void:
    frames.add_animation(name)
    frames.set_animation_speed(name, fps)
    frames.set_animation_loop(name, loop)
    for region in regions:
        var atlas := AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = region
        atlas.filter_clip = true
        frames.add_frame(name, atlas)
