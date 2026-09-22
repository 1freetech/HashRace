extends RefCounted
class_name HashRaceDefaultPlayerSpriteSheet

const SHEET_PATH := "res://art/characters/default_player_sheet.png"
const FRAME_SIZE := Vector2i(32, 40)
const WALK_FPS := 10.0

# 8 columns x 4 rows.
# Row 0 = down/front, row 1 = left/west, row 2 = right/east, row 3 = up/back.
# Column 0 = idle/stand; columns 1-7 = the seven walk frames.
const ROW_BY_FACING := {
    "down": 0,
    "left": 1,
    "right": 2,
    "up": 3,
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
    for facing in ["down", "up", "left", "right"]:
        var row: int = int(ROW_BY_FACING[facing])
        _add_animation(frames, StringName("idle_" + facing), texture, [_region(0, row)], 1.0, true)
        var walk_regions: Array = []
        for column in range(1, 8):
            walk_regions.append(_region(column, row))
        _add_animation(frames, StringName("walk_" + facing), texture, walk_regions, WALK_FPS, true)
    return frames

static func frame_region(facing: String, frame: int) -> Rect2i:
    var safe_facing := facing if ROW_BY_FACING.has(facing) else "down"
    var row: int = int(ROW_BY_FACING[safe_facing])
    if frame <= 0:
        return _region(0, row)
    return _region(clampi(frame, 1, 7), row)

static func _region(column: int, row: int) -> Rect2i:
    return Rect2i(column * FRAME_SIZE.x, row * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)

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
