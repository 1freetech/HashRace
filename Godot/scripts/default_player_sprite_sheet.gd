extends RefCounted
class_name HashRaceDefaultPlayerSpriteSheet

const SHEET_PATH := "res://art/characters/default_player_sheet.png"
const FRAME_SIZE := Vector2i(40, 62)
const SHEET_SIZE := Vector2i(160, 248)

# Exact 4x4 game atlas cropped from the user-supplied player sheet.
# The gray background and editor grid are removed from the PNG itself.
# Row 0 = down/front, row 1 = up/back, row 2 = left, row 3 = right.
const FRAME_REGIONS := {
    "down": [Rect2i(0, 0, 40, 62), Rect2i(40, 0, 40, 62), Rect2i(80, 0, 40, 62), Rect2i(120, 0, 40, 62)],
    "up": [Rect2i(0, 62, 40, 62), Rect2i(40, 62, 40, 62), Rect2i(80, 62, 40, 62), Rect2i(120, 62, 40, 62)],
    "left": [Rect2i(0, 124, 40, 62), Rect2i(40, 124, 40, 62), Rect2i(80, 124, 40, 62), Rect2i(120, 124, 40, 62)],
    "right": [Rect2i(0, 186, 40, 62), Rect2i(40, 186, 40, 62), Rect2i(80, 186, 40, 62), Rect2i(120, 186, 40, 62)],
}

static func load_texture() -> Texture2D:
    if not ResourceLoader.exists(SHEET_PATH):
        return null
    return load(SHEET_PATH) as Texture2D

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

static func debug_ready() -> bool:
    return FRAME_SIZE == Vector2i(40, 62) and SHEET_SIZE == Vector2i(160, 248) and FRAME_REGIONS.size() == 4 and ResourceLoader.exists(SHEET_PATH)
