class_name HashRaceEnergyVisualCatalog
extends RefCounted

## Hash Race authored energy visual atlas.
## One compressed source atlas contains 13 brand-neutral energy systems.
## Each system owns four gameplay orientations: UP, DOWN, LEFT, RIGHT.
##
## Atlas layout:
## - master texture: 512 x 512
## - system tile: 128 x 128
## - orientation frame: 64 x 64
## - four system tiles per row
## - local frames:
##     UP    = (0, 0)
##     DOWN  = (64, 0)
##     LEFT  = (0, 64)
##     RIGHT = (64, 64)
##
## The WebP bytes are stored as base64 source chunks so the complete authored
## image set lives in the repository without depending on external URLs.

const ORIENTATIONS := ["up", "right", "down", "left"]
const MASTER_SIZE := Vector2i(512, 512)
const SYSTEM_TILE := Vector2i(128, 128)
const ORIENTATION_CELL := Vector2i(64, 64)
const ATLAS_COLUMNS := 4

const ATLAS_PARTS := [
    "res://assets/energy/atlas_parts/energy_master_00.b64",
    "res://assets/energy/atlas_parts/energy_master_01.b64",
    "res://assets/energy/atlas_parts/energy_master_02.b64",
    "res://assets/energy/atlas_parts/energy_master_03.b64",
    "res://assets/energy/atlas_parts/energy_master_04.b64",
    "res://assets/energy/atlas_parts/energy_master_05.b64",
    "res://assets/energy/atlas_parts/energy_master_06.b64",
    "res://assets/energy/atlas_parts/energy_master_07.b64",
]

const ENERGY_VISUALS := {
    "battery": {
        "label": "Battery Storage",
        "atlas_index": 0,
        "category": "storage",
        "connection": "power",
    },
    "solar_array": {
        "label": "Solar Array",
        "atlas_index": 1,
        "category": "generation",
        "connection": "power",
    },
    "wind_farm": {
        "label": "Wind Turbine",
        "atlas_index": 2,
        "category": "generation",
        "connection": "power",
    },
    "gas_turbine": {
        "label": "Gas Turbine",
        "atlas_index": 3,
        "category": "generation",
        "connection": "fuel",
    },
    "hydro_turbine": {
        "label": "Hydro Turbine",
        "atlas_index": 4,
        "category": "generation",
        "connection": "power",
    },
    "oil_field": {
        "label": "Oil Pumpjack",
        "atlas_index": 5,
        "category": "energy_supply",
        "connection": "fuel",
    },
    "coal_plant": {
        "label": "Coal Power",
        "atlas_index": 6,
        "category": "generation",
        "connection": "fuel",
    },
    "nuclear_smr": {
        "label": "Nuclear SMR",
        "atlas_index": 7,
        "category": "generation",
        "connection": "power",
    },
    "methane_generator": {
        "label": "Methane Gas-to-Power",
        "atlas_index": 8,
        "category": "generation",
        "connection": "fuel",
    },
    "diesel_generator": {
        "label": "Diesel Generator",
        "atlas_index": 9,
        "category": "generation",
        "connection": "fuel",
    },
    "geothermal_generator": {
        "label": "Geothermal Generator",
        "atlas_index": 10,
        "category": "generation",
        "connection": "power",
    },
    "lpg_generator": {
        "label": "LPG / Propane Generator",
        "atlas_index": 11,
        "category": "generation",
        "connection": "fuel",
    },
    "hydrogen_fuel_cell": {
        "label": "Hydrogen Fuel Cell",
        "atlas_index": 12,
        "category": "generation",
        "connection": "fuel",
    },
}

static var _cached_master_texture: Texture2D

static func normalize_orientation(value: String) -> String:
    var orientation := value.to_lower()
    return orientation if orientation in ORIENTATIONS else "up"

static func visual_definition(asset_id: String) -> Dictionary:
    if not ENERGY_VISUALS.has(asset_id):
        return {}
    return Dictionary(ENERGY_VISUALS[asset_id]).duplicate(true)

static func source_region(asset_id: String, orientation: String = "up") -> Rect2:
    var definition := visual_definition(asset_id)
    if definition.is_empty():
        return Rect2()

    var index := int(definition["atlas_index"])
    var tile_x := (index % ATLAS_COLUMNS) * SYSTEM_TILE.x
    var tile_y := int(index / ATLAS_COLUMNS) * SYSTEM_TILE.y
    var local_x := 0
    var local_y := 0

    match normalize_orientation(orientation):
        "down":
            local_x = ORIENTATION_CELL.x
        "left":
            local_y = ORIENTATION_CELL.y
        "right":
            local_x = ORIENTATION_CELL.x
            local_y = ORIENTATION_CELL.y
        _:
            pass

    return Rect2(
        Vector2(tile_x + local_x, tile_y + local_y),
        Vector2(ORIENTATION_CELL)
    )

static func master_atlas_base64() -> String:
    var encoded := ""
    for path in ATLAS_PARTS:
        if not FileAccess.file_exists(path):
            return ""
        encoded += FileAccess.get_file_as_string(path).strip_edges()
    return encoded

static func master_texture() -> Texture2D:
    if _cached_master_texture != null:
        return _cached_master_texture

    var encoded := master_atlas_base64()
    if encoded.is_empty():
        return null

    var raw := Marshalls.base64_to_raw(encoded)
    var image := Image.new()
    if image.load_webp_from_buffer(raw) != OK:
        return null
    if image.get_size() != MASTER_SIZE:
        return null

    _cached_master_texture = ImageTexture.create_from_image(image)
    return _cached_master_texture

static func visual_plan(asset_id: String, orientation: String = "up") -> Dictionary:
    var definition := visual_definition(asset_id)
    if definition.is_empty():
        return {}
    definition["orientation"] = normalize_orientation(orientation)
    definition["source_region"] = source_region(asset_id, orientation)
    return definition

static func all_asset_ids() -> Array[String]:
    var ids: Array[String] = []
    for asset_id in ENERGY_VISUALS.keys():
        ids.append(String(asset_id))
    return ids

static func debug_ready() -> bool:
    var smr_right := source_region("nuclear_smr", "right")
    var battery_up := source_region("battery", "up")
    return ENERGY_VISUALS.size() == 13 \
        and ATLAS_PARTS.size() == 8 \
        and smr_right.size == Vector2(64.0, 64.0) \
        and battery_up.position == Vector2.ZERO \
        and not master_atlas_base64().is_empty()
