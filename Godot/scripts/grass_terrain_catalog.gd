extends RefCounted
class_name HashRaceGrassTerrainCatalog

const SHEET_PATH := "res://art/terrain/grass_terrain_tilesheet.png"

const REGIONS := {
    "grass_plain": Rect2i(2, 2, 7, 7),
    "grass_light": Rect2i(10, 2, 7, 7),
    "grass_dark": Rect2i(18, 2, 7, 7),
    "grass_white_flowers": Rect2i(26, 2, 7, 7),
    "grass_yellow_flowers": Rect2i(34, 2, 7, 7),
    "grass_rocks": Rect2i(42, 2, 7, 7),
    "grass_bushes": Rect2i(50, 2, 7, 7),
    "grass_mixed": Rect2i(57, 2, 6, 7),
    "edge_bottom": Rect2i(2, 11, 7, 6),
    "corner_bottom_left": Rect2i(10, 11, 7, 6),
    "corner_bottom_right": Rect2i(18, 11, 7, 6),
    "edge_left": Rect2i(26, 11, 7, 6),
    "edge_right": Rect2i(34, 11, 7, 6),
    "inner_bottom_left": Rect2i(42, 11, 7, 6),
    "inner_bottom_right": Rect2i(50, 11, 7, 6),
    "edge_bottom_alt": Rect2i(57, 11, 6, 6),
    "path_horizontal": Rect2i(2, 52, 8, 7),
    "path_vertical": Rect2i(10, 52, 8, 7),
    "path_cross": Rect2i(18, 52, 8, 7),
    "path_turn_ne": Rect2i(26, 52, 8, 7),
    "path_turn_nw": Rect2i(34, 52, 8, 7),
    "path_turn_se": Rect2i(42, 52, 8, 7),
    "path_turn_sw": Rect2i(50, 52, 8, 7),
    "path_patch": Rect2i(58, 52, 5, 7),
}

const VARIANTS := [
    "grass_plain", "grass_plain", "grass_plain",
    "grass_light", "grass_dark",
    "grass_white_flowers", "grass_yellow_flowers",
    "grass_rocks", "grass_bushes", "grass_mixed",
]

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
    var region: Rect2i = REGIONS.get(tile_name, REGIONS["grass_plain"])
    # Healthy source is 512px; map the catalog's original preview coordinates.
    return Rect2i(region.position * 8, region.size * 8)

static func variant_for_cell(cell: Vector2i) -> String:
    var hash_value: int = abs(cell.x * 37 + cell.y * 71 + cell.x * cell.y * 11)
    return VARIANTS[hash_value % VARIANTS.size()]

static func debug_ready() -> bool:
    return REGIONS.size() >= 20 and ResourceLoader.exists(SHEET_PATH)
