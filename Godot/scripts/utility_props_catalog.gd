extends RefCounted
class_name HashRaceUtilityPropsCatalog

const SHEET_PATH := "res://art/props/utility_props_sheet.png"

const REGIONS := {
    "power_pole_full": Rect2i(5, 8, 27, 39),
    "power_pole_small": Rect2i(34, 8, 26, 39),
    "transformer_pole": Rect2i(60, 8, 29, 39),
    "streetlight": Rect2i(92, 8, 29, 39),
    "fence": Rect2i(5, 52, 34, 20),
    "fence_gate": Rect2i(42, 52, 24, 20),
    "warning_fence": Rect2i(68, 52, 27, 20),
    "barbed_fence": Rect2i(98, 52, 25, 20),
    "barrier_plain": Rect2i(5, 77, 27, 15),
    "barrier_stripe": Rect2i(35, 77, 21, 15),
    "bollard": Rect2i(58, 77, 8, 15),
    "cone_small": Rect2i(67, 77, 9, 15),
    "cone_medium": Rect2i(76, 77, 9, 15),
    "cone_large": Rect2i(85, 77, 9, 15),
    "cone_stack": Rect2i(95, 77, 8, 15),
    "electrical_cabinet": Rect2i(105, 73, 18, 21),
    "sign_pickaxe": Rect2i(5, 98, 16, 21),
    "sign_speed_25": Rect2i(23, 98, 16, 21),
    "sign_dump": Rect2i(42, 98, 17, 21),
    "pallet": Rect2i(61, 100, 19, 18),
    "pallet_blocks": Rect2i(82, 100, 18, 18),
    "crate": Rect2i(101, 99, 13, 19),
    "case_stack": Rect2i(115, 98, 10, 21),
}

static func load_texture() -> Texture2D:
    if not ResourceLoader.exists(SHEET_PATH):
        return null
    return load(SHEET_PATH) as Texture2D

static func region(prop_name: String) -> Rect2i:
    return REGIONS.get(prop_name, REGIONS["cone_medium"])

static func debug_ready() -> bool:
    return REGIONS.size() >= 20 and ResourceLoader.exists(SHEET_PATH)
