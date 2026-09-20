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
    if not ResourceLoader.exists(SHEET_PATH):
        return null
    return load(SHEET_PATH) as Texture2D

static func region(direction: String) -> Rect2i:
    return REGIONS.get(direction, REGIONS["up"])

static func debug_ready() -> bool:
    return REGIONS.size() == 4 and ResourceLoader.exists(SHEET_PATH)
