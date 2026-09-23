extends RefCounted
class_name HashRaceSolarOverviewSprite

# Extracted from the newly generated transparent 2D overview solar artwork.
# A cropped, 64-color, nearest-neighbor 128x136 PNG is committed as game art.
const TEXTURE_PATH := "res://art/energy/solar_array_overview.png"
const PNG_SHA256 := "06b542233279854dea18a10cf10e16b32772057add0bec8f896fc2a282ab407f"
const PIXEL_SIZE := Vector2i(128, 136)
# The art contains its own lower-right contact shadow. Do not draw a second one.
const CONTACT := Rect2(0.18, 0.77, 0.64, 0.20)

static func texture() -> Texture2D:
    if not ResourceLoader.exists(TEXTURE_PATH):
        return null
    return load(TEXTURE_PATH) as Texture2D

static func valid_texture(value: Texture2D) -> bool:
    return value != null and value.get_width() == PIXEL_SIZE.x and value.get_height() == PIXEL_SIZE.y

static func draw_size(tiles: int) -> Vector2:
    var width := minf(192.0, 88.0 + float(tiles) * 13.0)
    return Vector2(roundf(width), roundf(width * float(PIXEL_SIZE.y) / float(PIXEL_SIZE.x)))

static func destination(world_ground: Vector2, tiles: int) -> Rect2:
    var size_value := draw_size(tiles)
    return Rect2(
        (world_ground - Vector2(size_value.x * 0.5, size_value.y * 0.77)).round(),
        size_value
    )

static func ground_contact(dest: Rect2) -> Rect2:
    return Rect2(dest.position + dest.size * CONTACT.position, dest.size * CONTACT.size)

static func sort_y(dest: Rect2) -> float:
    return ground_contact(dest).end.y

static func debug_ready() -> bool:
    return ResourceLoader.exists(TEXTURE_PATH) \
        and CONTACT.end.x <= 1.0 and CONTACT.end.y <= 1.0 \
        and draw_size(2).x < draw_size(4).x \
        and draw_size(4).x < draw_size(6).x \
        and draw_size(6).x < draw_size(8).x
