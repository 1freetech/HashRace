extends RefCounted
class_name HashRaceDefaultPlayerSpriteSheet

const SHEET_PATH := "res://art/characters/default_player_sheet.png"
const SHEET_SIZE := Vector2i(1536, 1024)
const FRAME_SIZE := Vector2i(160, 240)
const FOOT_ANCHOR := Vector2i(80, 232)
const WALK_FRAME_COUNT := 7
const EFFECTIVE_FRAME_COUNT := 32
const WALK_FPS := 8.0
const SHEET_SHA256 := "2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211"

# Keep the exact approved 32-pose source binary from current main. Runtime uses
# eight authored poses per direction (one idle + seven visually distinct walk poses) at 8 FPS.
const FRAME_REGIONS := {
    "down": [Rect2i(58,41,125,216), Rect2i(250,40,125,219), Rect2i(434,41,125,217), Rect2i(618,40,124,218), Rect2i(803,41,124,217), Rect2i(983,40,125,218), Rect2i(1167,40,124,219), Rect2i(1354,40,124,218)],
    "left": [Rect2i(60,273,131,221), Rect2i(251,273,128,221), Rect2i(436,273,131,221), Rect2i(618,273,135,221), Rect2i(803,274,131,221), Rect2i(988,273,130,221), Rect2i(1170,274,133,220), Rect2i(1354,274,128,220)],
    "right": [Rect2i(54,511,132,225), Rect2i(246,511,133,225), Rect2i(432,511,133,225), Rect2i(614,511,133,225), Rect2i(802,511,134,225), Rect2i(985,511,137,225), Rect2i(1161,511,142,225), Rect2i(1355,511,133,225)],
    "up": [Rect2i(56,745,131,222), Rect2i(245,745,130,225), Rect2i(431,745,128,225), Rect2i(614,745,130,225), Rect2i(798,745,129,225), Rect2i(979,745,131,225), Rect2i(1163,745,133,225), Rect2i(1354,745,130,222)],
}
const EFFECTIVE_SOURCE_INDICES := [0, 1, 2, 3, 4, 5, 6, 7]

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

static func build_customized_texture(skin: Color, suit: Color, scouter: Color) -> Texture2D:
    var source_texture := load_texture()
    if source_texture == null:
        return null
    var image := source_texture.get_image()
    if image == null or image.is_empty() or image.get_size() != SHEET_SIZE:
        return null

    # Work only inside the 32 exact source regions. This keeps transparent
    # spacing and every pixel outside a character crop visually untouched. The
    # runtime uses all eight authored poses per direction, so all 32 regions need
    # a derived palette texture.
    for facing in ["down", "left", "right", "up"]:
        var regions: Array = FRAME_REGIONS[facing]
        for source_index in EFFECTIVE_SOURCE_INDICES:
            var region: Rect2i = regions[int(source_index)]
            for y in range(region.position.y, region.end.y):
                for x in range(region.position.x, region.end.x):
                    var pixel := image.get_pixel(x, y)
                    if pixel.a < 0.55:
                        continue
                    var local_y := y - region.position.y
                    if _is_scouter_pixel(pixel, local_y, region.size.y):
                        image.set_pixel(x, y, _retint(pixel, scouter, 0.82))
                    elif _is_suit_pixel(pixel):
                        image.set_pixel(x, y, _retint(pixel, suit, 0.88))
                    elif _is_skin_pixel(pixel, local_y, region.size.y):
                        image.set_pixel(x, y, _retint(pixel, skin, 0.48))
    return ImageTexture.create_from_image(image)

static func _is_suit_pixel(pixel: Color) -> bool:
    return pixel.h >= 0.025 and pixel.h <= 0.115 and pixel.s >= 0.78 and pixel.v >= 0.48

static func _is_skin_pixel(pixel: Color, local_y: int, frame_height: int) -> bool:
    return local_y < int(float(frame_height) * 0.48) \
        and pixel.h >= 0.025 and pixel.h <= 0.115 \
        and pixel.s >= 0.34 and pixel.s < 0.78 \
        and pixel.v >= 0.20 and pixel.v <= 0.78

static func _is_scouter_pixel(pixel: Color, local_y: int, frame_height: int) -> bool:
    return local_y < int(float(frame_height) * 0.48) \
        and pixel.h >= 0.22 and pixel.h <= 0.48 \
        and pixel.s >= 0.45 and pixel.v >= 0.28

static func _retint(source: Color, target: Color, reference_value: float) -> Color:
    var shade := clampf(source.v / reference_value, 0.28, 1.22)
    var value := clampf(target.v * shade, 0.0, 1.0)
    return Color.from_hsv(target.h, target.s, value, source.a)

static func build_frames() -> SpriteFrames:
    var texture := load_texture()
    if texture == null:
        return null
    var frames := SpriteFrames.new()
    if frames.has_animation(&"default"):
        frames.remove_animation(&"default")
    for facing in ["down", "left", "right", "up"]:
        var regions: Array = FRAME_REGIONS[facing]
        _add_animation(frames, StringName("idle_" + facing), texture, [regions[0]], 1.0, true)
        var walk_regions: Array = [regions[1], regions[2], regions[3], regions[4], regions[5], regions[6], regions[7]]
        _add_animation(frames, StringName("walk_" + facing), texture, walk_regions, WALK_FPS, true)
    return frames

static func frame_region(facing: String, frame: int) -> Rect2i:
    var safe_facing := facing if FRAME_REGIONS.has(facing) else "down"
    var regions: Array = FRAME_REGIONS[safe_facing]
    var effective_index := clampi(frame, 0, EFFECTIVE_SOURCE_INDICES.size() - 1)
    return regions[int(EFFECTIVE_SOURCE_INDICES[effective_index])]

static func walk_frame(moving: bool, step_phase: float) -> int:
    if not moving:
        return 0
    return 1 + mini(int(floor(fposmod(step_phase, TAU) / TAU * WALK_FRAME_COUNT)), WALK_FRAME_COUNT - 1)

static func frame_offset(region: Rect2i) -> Vector2:
    return Vector2(floor((FRAME_SIZE.x - region.size.x) * 0.5), FOOT_ANCHOR.y - region.size.y)

static func debug_ready() -> bool:
    var texture := load_texture()
    return texture != null and Vector2i(texture.get_size()) == SHEET_SIZE \
        and FRAME_REGIONS.size() == 4 and FRAME_REGIONS["down"].size() == 8 \
        and EFFECTIVE_SOURCE_INDICES.size() * FRAME_REGIONS.size() == EFFECTIVE_FRAME_COUNT

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
