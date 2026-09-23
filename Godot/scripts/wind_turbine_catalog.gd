extends RefCounted
class_name HashRaceWindTurbineCatalog

const SHEET_PATH := "res://art/energy/wind_turbine_directional_sheet.png"
const REGIONS := {
    "up": Rect2i(0, 0, 64, 64),
    "down": Rect2i(64, 0, 64, 64),
    "left": Rect2i(0, 64, 64, 64),
    "right": Rect2i(64, 64, 64, 64),
}
const SOURCE_MATTE := Color8(109, 109, 110, 255)
const MATTE_TOLERANCE := 8

# The authored sheet contains a flat gray source matte. Preserve the validated
# repository binary, decode it through Godot, then remove only pixels near the
# known matte color before creating the runtime texture. This prevents the
# square source background from appearing as a world object.
static func load_texture() -> Texture2D:
    var absolute_path := ProjectSettings.globalize_path(SHEET_PATH)
    if not FileAccess.file_exists(absolute_path):
        return null
    var image := Image.new()
    if image.load(absolute_path) != OK or image.is_empty():
        return null
    image.convert(Image.FORMAT_RGBA8)
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            var pixel := image.get_pixel(x, y)
            if abs(pixel.r8 - SOURCE_MATTE.r8) <= MATTE_TOLERANCE \
            and abs(pixel.g8 - SOURCE_MATTE.g8) <= MATTE_TOLERANCE \
            and abs(pixel.b8 - SOURCE_MATTE.b8) <= MATTE_TOLERANCE:
                image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
    return ImageTexture.create_from_image(image)

static func region(direction: String) -> Rect2i:
    return REGIONS.get(direction, REGIONS["down"])

static func debug_ready() -> bool:
    return REGIONS.size() == 4 and FileAccess.file_exists(ProjectSettings.globalize_path(SHEET_PATH))
