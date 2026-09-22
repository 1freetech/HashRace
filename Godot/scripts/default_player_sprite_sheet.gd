extends RefCounted
class_name HashRaceDefaultPlayerSpriteSheet

const SHEET_PATH := "res://art/characters/default_player_sheet.png"
const FRAME_SIZE := Vector2i(32, 40)
const SHEET_SIZE := Vector2i(256, 160)

# Keep the validated 8x4 source PNG already integrated in Hash Race, but use
# four evenly spaced poses from each directional row. This gives the live
# character an effective 16-frame atlas (4 directions x 4 poses) instead of
# stepping through only the first half of the 8-frame row.
const EFFECTIVE_FRAME_COUNT := 16
const WALK_FRAME_COUNT := 4
const WALK_FPS := 6.0
const EFFECTIVE_WALK_COLUMNS := [0, 2, 4, 6]

# Source row order in the committed player sheet.
# Row 0 = down/front, row 1 = right/east, row 2 = up/back, row 3 = left/west.
const ROW_BY_FACING := {
    "down": 0,
    "right": 1,
    "up": 2,
    "left": 3,
}

static func load_texture() -> Texture2D:
    if ResourceLoader.exists(SHEET_PATH):
        var imported := load(SHEET_PATH) as Texture2D
        if imported != null:
            return imported

    # Fresh-checkout fallback: decode the committed PNG directly when the
    # Godot import cache has not been generated yet.
    var absolute_path := ProjectSettings.globalize_path(SHEET_PATH)
    if not FileAccess.file_exists(absolute_path):
        return null
    var image := Image.new()
    if image.load(absolute_path) != OK or image.is_empty():
        return null
    if image.get_size() != SHEET_SIZE:
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
        var walk_regions: Array = []
        for column in EFFECTIVE_WALK_COLUMNS:
            walk_regions.append(_region(int(column), row))

        # The first effective pose is also the standing pose. Keeping idle and
        # walk on the same foot-contact frame removes the visual snap on stop.
        _add_animation(
            frames,
            StringName("idle_" + facing),
            texture,
            [walk_regions[0]],
            1.0,
            true
        )
        _add_animation(
            frames,
            StringName("walk_" + facing),
            texture,
            walk_regions,
            WALK_FPS,
            true
        )

    return frames

static func frame_region(facing: String, frame: int) -> Rect2i:
    var safe_facing := facing if ROW_BY_FACING.has(facing) else "down"
    var row: int = int(ROW_BY_FACING[safe_facing])
    var effective_index := clampi(frame, 0, WALK_FRAME_COUNT - 1)
    var source_column: int = int(EFFECTIVE_WALK_COLUMNS[effective_index])
    return _region(source_column, row)

static func walk_frame_count() -> int:
    return WALK_FRAME_COUNT

static func _region(column: int, row: int) -> Rect2i:
    return Rect2i(
        column * FRAME_SIZE.x,
        row * FRAME_SIZE.y,
        FRAME_SIZE.x,
        FRAME_SIZE.y
    )

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

static func debug_ready() -> bool:
    return FRAME_SIZE == Vector2i(32, 40) \
        and SHEET_SIZE == Vector2i(256, 160) \
        and ROW_BY_FACING.size() == 4 \
        and EFFECTIVE_WALK_COLUMNS.size() == WALK_FRAME_COUNT \
        and EFFECTIVE_FRAME_COUNT == ROW_BY_FACING.size() * WALK_FRAME_COUNT \
        and ResourceLoader.exists(SHEET_PATH)
