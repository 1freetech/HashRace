extends RefCounted
class_name HashRaceDirtRoadCatalog

# Exact user-supplied dirt-road artwork, cleaned only to remove the light sheet
# background and reduced to a compact 128 px runtime atlas. The source artwork
# uses intentionally different-sized pieces, so each region is mapped explicitly.
const SHEET_PATH := "res://art/terrain/dirt_road_tilesheet.png"

const REGIONS := {
    "straight_v": Rect2i(4, 3, 21, 21),
    "straight_v_alt": Rect2i(28, 3, 21, 21),
    "straight_h": Rect2i(52, 3, 23, 21),
    "corner_ne": Rect2i(78, 3, 21, 21),
    "corner_nw": Rect2i(103, 3, 21, 21),

    "t_down": Rect2i(3, 27, 23, 24),
    "t_right": Rect2i(30, 27, 20, 24),
    "cross": Rect2i(52, 27, 24, 24),
    "t_left": Rect2i(78, 27, 20, 24),
    "t_up": Rect2i(102, 27, 23, 24),

    "end_down": Rect2i(6, 54, 17, 22),
    "end_up": Rect2i(29, 54, 17, 22),
    "end_right": Rect2i(51, 54, 24, 22),
    "end_left": Rect2i(101, 54, 24, 22),

    "shoulder_left": Rect2i(4, 79, 16, 20),
    "shoulder_left_heavy": Rect2i(24, 79, 17, 20),
    "shoulder_right": Rect2i(45, 79, 17, 20),
    "shoulder_right_light": Rect2i(66, 79, 17, 20),
    "shoulder_right_heavy": Rect2i(87, 79, 17, 20),

    "filler_clean": Rect2i(4, 102, 17, 20),
    "filler_dark": Rect2i(25, 102, 17, 20),
    "filler_ruts": Rect2i(45, 102, 17, 20),
    "filler_rocks": Rect2i(65, 102, 18, 20),
    "filler_tracks": Rect2i(86, 102, 18, 20),
    "filler_worn": Rect2i(107, 102, 17, 20),
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

static func region(tile_name: String) -> Rect2i:
    if not REGIONS.has(tile_name):
        return REGIONS["filler_clean"]
    return REGIONS[tile_name]

static func choose_tile(north: bool, east: bool, south: bool, west: bool) -> String:
    var count: int = int(north) + int(east) + int(south) + int(west)

    if count >= 4:
        return "cross"
    if count == 3:
        if not north:
            return "t_down"
        if not east:
            return "t_left"
        if not south:
            return "t_up"
        return "t_right"

    if count == 2:
        if north and south:
            return "straight_v"
        if east and west:
            return "straight_h"
        if north and east:
            return "corner_ne"
        if north and west:
            return "corner_nw"
        if south and east:
            return "corner_nw"
        if south and west:
            return "corner_ne"

    if count == 1:
        if north:
            return "end_up"
        if east:
            return "end_right"
        if south:
            return "end_down"
        return "end_left"

    return "filler_clean"

static func debug_ready() -> bool:
    return REGIONS.size() >= 20 and ResourceLoader.exists(SHEET_PATH)
