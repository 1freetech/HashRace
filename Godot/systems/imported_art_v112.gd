class_name HashRaceImportedArtV112
extends RefCounted

# Hash Race v0.112 imported-art registry.
# These paths are the canonical names for the user-supplied sprite sheets.
# Runtime code checks ResourceLoader.exists() so a missing optional sheet never
# breaks the playable world.

const ROOT := "res://art/imported/v112/"

const ASSETS := {
    "asic_air": ROOT + "asic_air.png",
    "asic_hydro": ROOT + "asic_hydro.png",
    "asic_immersion": ROOT + "asic_immersion.png",
    "bess": ROOT + "bess.png",
    "coal": ROOT + "coal.png",
    "command_center": ROOT + "command_center.png",
    "gas_turbine": ROOT + "gas_turbine.png",
    "grass_atlas": ROOT + "grass_atlas.png",
    "hydro_power": ROOT + "hydro_power.png",
    "lpg": ROOT + "lpg.png",
    "plane": ROOT + "plane.png",
    "road_asphalt_atlas": ROOT + "road_asphalt_atlas.png",
    "road_gravel_atlas": ROOT + "road_gravel_atlas.png",
    "transformer": ROOT + "transformer.png",
    "tree": ROOT + "tree.png",
    "char_greenalien": ROOT + "char_greenalien.png",
    "char_greenfinal": ROOT + "char_greenfinal.png",
    "char_labeled": ROOT + "char_labeled.png",
    "char_red": ROOT + "char_red.png",
    "char_whitegreen": ROOT + "char_whitegreen.png",
}

const CHARACTER_KEYS := [
    "char_greenfinal",
    "char_whitegreen",
    "char_red",
    "char_greenalien",
    "char_labeled",
]

const SITE_ENERGY_KEYS := [
    "gas_turbine",
    "hydro_power",
    "coal",
    "lpg",
    "bess",
]

static func path(asset_id: String) -> String:
    return String(ASSETS.get(asset_id, ""))

static func exists(asset_id: String) -> bool:
    var p := path(asset_id)
    return not p.is_empty() and ResourceLoader.exists(p)

static func load_texture(asset_id: String) -> Texture2D:
    var p := path(asset_id)
    if p.is_empty() or not ResourceLoader.exists(p):
        return null
    return load(p) as Texture2D

static func character_for_index(index: int) -> String:
    if CHARACTER_KEYS.is_empty():
        return ""
    return CHARACTER_KEYS[posmod(index, CHARACTER_KEYS.size())]

static func energy_for_index(index: int) -> String:
    if SITE_ENERGY_KEYS.is_empty():
        return ""
    return SITE_ENERGY_KEYS[posmod(index, SITE_ENERGY_KEYS.size())]

static func debug_ready() -> bool:
    return ASSETS.size() == 20 and CHARACTER_KEYS.size() == 5 and SITE_ENERGY_KEYS.size() == 5
