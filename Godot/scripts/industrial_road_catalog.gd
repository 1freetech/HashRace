extends RefCounted
class_name HashRaceIndustrialRoadCatalog

const SHEET_PATH := "res://art/terrain/industrial_road_tilesheet.png"

const REGIONS := {
    "straight_v": Rect2i(5, 5, 20, 20),
    "straight_h": Rect2i(33, 5, 27, 20),
    "straight_v_marked": Rect2i(67, 5, 20, 20),
    "straight_h_marked": Rect2i(95, 5, 27, 20),
    "corner_ne": Rect2i(5, 30, 24, 23),
    "corner_nw": Rect2i(34, 30, 24, 23),
    "corner_se": Rect2i(67, 30, 24, 23),
    "corner_sw": Rect2i(96, 30, 24, 23),
    "t_up": Rect2i(7, 56, 25, 24),
    "t_right": Rect2i(38, 56, 24, 24),
    "t_left": Rect2i(67, 56, 24, 24),
    "cross": Rect2i(97, 56, 25, 24),
    "dead_end_v": Rect2i(6, 84, 17, 20),
    "dead_end_h": Rect2i(31, 84, 27, 20),
    "barrier_v": Rect2i(69, 84, 17, 20),
    "barrier_h": Rect2i(95, 84, 27, 20),
    "gravel_left": Rect2i(4, 106, 14, 16),
    "gravel_right": Rect2i(23, 106, 14, 16),
    "gravel_bottom": Rect2i(43, 106, 17, 16),
    "gravel_top": Rect2i(66, 106, 17, 16),
    "gravel_dark": Rect2i(88, 106, 17, 16),
    "gravel_ruts": Rect2i(108, 106, 16, 16),
}

static func load_texture() -> Texture2D:
    if not ResourceLoader.exists(SHEET_PATH):
        return null
    return load(SHEET_PATH) as Texture2D

static func region(tile_name: String) -> Rect2i:
    return REGIONS.get(tile_name, REGIONS["straight_h"])

static func choose_tile(north: bool, east: bool, south: bool, west: bool) -> String:
    var count: int = int(north) + int(east) + int(south) + int(west)
    if count >= 4:
        return "cross"
    if count == 3:
        if not north:
            return "t_up"
        if not east:
            return "t_left"
        if not west:
            return "t_right"
        return "t_up"
    if count == 2:
        if north and south:
            return "straight_v_marked"
        if east and west:
            return "straight_h_marked"
        if north and east:
            return "corner_ne"
        if north and west:
            return "corner_nw"
        if south and east:
            return "corner_se"
        return "corner_sw"
    if count == 1:
        return "dead_end_v" if north or south else "dead_end_h"
    return "gravel_dark"

static func debug_ready() -> bool:
    return REGIONS.size() >= 20 and ResourceLoader.exists(SHEET_PATH)
