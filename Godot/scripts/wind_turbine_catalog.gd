extends RefCounted
class_name HashRaceWindTurbineCatalog

const SHEET_PATH := "res://art/energy/wind_turbine_directional_sheet.png"
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
    return REGIONS.get(direction, REGIONS["down"])

static func debug_ready() -> bool:
    return REGIONS.size() == 4 and ResourceLoader.exists(SHEET_PATH)
