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

# Load the committed project image through Godot's imported-resource pipeline so
# the same res:// path works in editor, CI, and exported builds. The authored
# sheet contains a flat gray source matte; remove only pixels near that known
# color from a copy of the imported texture image before creating the runtime
# transparent texture. The repository binary itself remains unchanged.
static func load_texture() -> Texture2D:
    if not ResourceLoader.exists(SHEET_PATH, "Texture2D"):
        return null
    var imported := ResourceLoader.load(SHEET_PATH, "Texture2D") as Texture2D
    if imported == null:
        return null
    var image := imported.get_image()
    if image == null or image.is_empty():
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
    return REGIONS.size() == 4 and ResourceLoader.exists(SHEET_PATH, "Texture2D")
