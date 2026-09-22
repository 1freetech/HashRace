extends RefCounted
class_name HashRaceDefaultPlayerSpriteSheet

const SHEET_PATH := "res://art/characters/default_player_sheet.png"
const SHEET_SIZE := Vector2i(1536, 1024)
# Logical canvas shared by every pose; AtlasTexture margins align the feet.
const FRAME_SIZE := Vector2i(160, 240)
const FOOT_ANCHOR := Vector2i(80, 232)
const WALK_FRAME_COUNT := 7
const SHEET_SHA256 := "2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211"

# Exact regions in the approved transparent derivative. The source has small
# spacing variations, so do not divide its width/height into guessed cells.
# Rows: down, left, right, up. Column 0 is idle; columns 1-7 are walking.
const FRAME_REGIONS := {
    "down": [Rect2i(58,41,125,216), Rect2i(250,40,125,219), Rect2i(434,41,125,217), Rect2i(618,40,124,218), Rect2i(803,41,124,217), Rect2i(983,40,125,218), Rect2i(1167,40,124,219), Rect2i(1354,40,124,218)],
    "left": [Rect2i(60,273,131,221), Rect2i(251,273,128,221), Rect2i(436,273,131,221), Rect2i(618,273,135,221), Rect2i(803,274,131,221), Rect2i(988,273,130,221), Rect2i(1170,274,133,220), Rect2i(1354,274,128,220)],
    "right": [Rect2i(54,511,132,225), Rect2i(246,511,133,225), Rect2i(432,511,133,225), Rect2i(614,511,133,225), Rect2i(802,511,134,225), Rect2i(985,511,137,225), Rect2i(1161,511,142,225), Rect2i(1355,511,133,225)],
    "up": [Rect2i(56,745,131,222), Rect2i(245,745,130,225), Rect2i(431,745,128,225), Rect2i(614,745,130,225), Rect2i(798,745,129,225), Rect2i(979,745,131,225), Rect2i(1163,745,133,225), Rect2i(1354,745,130,222)],
}

static func load_texture() -> Texture2D:
    if ResourceLoader.exists(SHEET_PATH):
        var imported := load(SHEET_PATH) as Texture2D
        if imported != null and Vector2i(imported.get_size()) == SHEET_SIZE:
            return imported
    var absolute_path := ProjectSettings.globalize_path(SHEET_PATH)
    if not FileAccess.file_exists(absolute_path):
        return null
    var image := Image.new()
    if image.load(absolute_path) != OK or image.is_empty() or image.get_size() != SHEET_SIZE:
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
    _add_animation(frames, &"walk_down", texture, FRAME_REGIONS["down"].slice(1), 10.0, true)
    _add_animation(frames, &"walk_up", texture, FRAME_REGIONS["up"].slice(1), 10.0, true)
    _add_animation(frames, &"walk_left", texture, FRAME_REGIONS["left"].slice(1), 10.0, true)
    _add_animation(frames, &"walk_right", texture, FRAME_REGIONS["right"].slice(1), 10.0, true)
    return frames

static func frame_region(facing: String, frame: int) -> Rect2i:
    var safe_facing := facing if FRAME_REGIONS.has(facing) else "down"
    var regions: Array = FRAME_REGIONS[safe_facing]
    return regions[clampi(frame, 0, regions.size() - 1)]

static func walk_frame(moving: bool, step_phase: float) -> int:
    if not moving:
        return 0
    return 1 + mini(int(floor(fposmod(step_phase, TAU) / TAU * WALK_FRAME_COUNT)), WALK_FRAME_COUNT - 1)

static func frame_offset(region: Rect2i) -> Vector2:
    return Vector2(floor((FRAME_SIZE.x - region.size.x) * 0.5), FOOT_ANCHOR.y - region.size.y)

static func debug_ready() -> bool:
    var texture := load_texture()
    return texture != null and Vector2i(texture.get_size()) == SHEET_SIZE and FRAME_REGIONS.size() == 4 and FRAME_REGIONS["down"].size() == 8

static func _add_animation(frames: SpriteFrames, name: StringName, texture: Texture2D, regions: Array, fps: float, loop: bool) -> void:
    frames.add_animation(name)
    frames.set_animation_speed(name, fps)
    frames.set_animation_loop(name, loop)
    for region in regions:
        var atlas := AtlasTexture.new()
        atlas.atlas = texture
        atlas.region = region
        atlas.margin = Rect2(frame_offset(region), Vector2(FRAME_SIZE - region.size))
        atlas.filter_clip = true
        frames.add_frame(name, atlas)
