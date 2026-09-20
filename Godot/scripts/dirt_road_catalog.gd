extends RefCounted
class_name HashRaceDirtRoadCatalog

# Exact user-supplied dirt-road artwork, cleaned only for transparent background
# and reduced to a game-ready 400 px atlas. Regions are explicit because the
# source sheet intentionally uses different-sized pieces rather than a uniform
# editor grid.
const SHEET_PATH := "res://art/terrain/dirt_road_tilesheet.png"

const REGIONS := {
    "straight_v": Rect2i(15, 10, 61, 65),
    "straight_v_alt": Rect2i(89, 10, 62, 65),
    "straight_h": Rect2i(164, 10, 70, 65),
    "corner_ne": Rect2i(245, 10, 64, 65),
    "corner_nw": Rect2i(322, 10, 64, 65),

    "t_down": Rect2i(11, 86, 70, 72),
    "t_right": Rect2i(94, 86, 61, 72),
    "cross": Rect2i(164, 86, 72, 72),
    "t_left": Rect2i(245, 86, 60, 72),
    "t_up": Rect2i(319, 86, 71, 72),

    "end_down": Rect2i(21, 169, 50, 68),
    "end_up": Rect2i(93, 169, 49, 68),
    "end_right": Rect2i(159, 169, 75, 68),
    "end_left": Rect2i(316, 169, 72, 68),

    "shoulder_left": Rect2i(14, 250, 49, 59),
    "shoulder_left_heavy": Rect2i(76, 250, 50, 59),
    "shoulder_right": Rect2i(142, 250, 50, 59),
    "shoulder_right_light": Rect2i(209, 250, 49, 59),
    "shoulder_right_heavy": Rect2i(273, 250, 50, 59),

    "filler_clean": Rect2i(13, 319, 52, 62),
    "filler_dark": Rect2i(78, 319, 52, 62),
    "filler_ruts": Rect2i(142, 319, 51, 62),
    "filler_rocks": Rect2i(206, 319, 52, 62),
    "filler_tracks": Rect2i(270, 319, 52, 62),
    "filler_worn": Rect2i(335, 319, 52, 62),
}

static func load_texture() -> Texture2D:
    if not ResourceLoader.exists(SHEET_PATH):
        return null
    return load(SHEET_PATH) as Texture2D

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
        # The supplied first-row corner pair covers the two authored turn
        # silhouettes. Mirroring is deliberately avoided so the rock shoulders
        # remain hand-authored rather than mechanically flipped.
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
