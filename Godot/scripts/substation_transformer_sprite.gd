extends RefCounted
class_name HashRaceSubstationTransformerSprite

# Actual HashRace Library artwork: "HASHRACE Infrastructure Units Blueprint.png"
# Lower-center electrical substation, rear elevation (crop 607,714–813,898).
# Isolated transparent 80x72 24-color PNG; no concept image drawn in the world.
const TEXTURE_PATH := "res://art/electrical/substation_transformer_rear.png"
const PNG_SHA256 := "4f1ece23333d48181085c3d0e22e7730181a45beaf7f6a80ed1fd254a1e16059"
const SOURCE_SHA256 := "9ce939d30aa44b91755d52958aabb0b1405089847a0410938a7bb8de3bc83762"
const PIXEL_SIZE := Vector2i(80, 72)
const GROUND_CONTACT := Rect2(0.12, 0.82, 0.76, 0.18)

static func texture() -> Texture2D:
    if not ResourceLoader.exists(TEXTURE_PATH):
        return null
    return load(TEXTURE_PATH) as Texture2D

static func draw_size(footprint_tiles: int) -> Vector2:
    # Keep the inherited 2/4/6/8-tile footprint contract; it controls scale
    # without stretching the actual 80:72 isolated sprite.
    var visual_scale := clampf(float(footprint_tiles) / 4.0, 0.86, 1.40)
    var width := 88.0 * visual_scale
    return Vector2(width, width * float(PIXEL_SIZE.y) / float(PIXEL_SIZE.x))

static func destination(ground_center: Vector2, footprint_tiles: int) -> Rect2:
    var size_value := draw_size(footprint_tiles)
    # Lower edge lies slightly below the site foundation center.
    return Rect2(
        (ground_center - Vector2(size_value.x * 0.5, size_value.y * 0.58)).round(),
        size_value.round()
    )

static func ground_contact(dest: Rect2) -> Rect2:
    return Rect2(
        dest.position + dest.size * GROUND_CONTACT.position,
        dest.size * GROUND_CONTACT.size
    )

static func sort_y(dest: Rect2) -> float:
    return ground_contact(dest).end.y

static func valid_texture(image: Texture2D) -> bool:
    return image != null and image.get_width() == PIXEL_SIZE.x and image.get_height() == PIXEL_SIZE.y

static func debug_ready() -> bool:
    return ResourceLoader.exists(TEXTURE_PATH) \
        and GROUND_CONTACT.end.x <= 1.0 and GROUND_CONTACT.end.y <= 1.0 \
        and draw_size(2).x < draw_size(4).x \
        and draw_size(4).x < draw_size(6).x \
        and draw_size(6).x <= draw_size(8).x
