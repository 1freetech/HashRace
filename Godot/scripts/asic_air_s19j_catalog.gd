extends RefCounted
class_name HashRaceAsicAirDirectionalCatalog

const SHEET_PATH := "res://art/machines/asic_air_s19j_directional.png"
const REGIONS := {
    "up": Rect2i(0, 0, 64, 64),
    "down": Rect2i(64, 0, 64, 64),
    "left": Rect2i(0, 64, 64, 64),
    "right": Rect2i(64, 64, 64, 64),
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

static func region(direction: String) -> Rect2i:
    return REGIONS.get(direction, REGIONS["up"])

static func debug_ready() -> bool:
    return REGIONS.size() == 4 and ResourceLoader.exists(SHEET_PATH)
