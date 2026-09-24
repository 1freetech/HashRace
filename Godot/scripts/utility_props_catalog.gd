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

# Normalized ground-contact footprints. These deliberately cover only the base
# that touches the ground, never the full visible sprite. World collision/Y-sort
# integration can use the same authored footprint without blocking players on
# poles, lamps, signs, or other transparent/overhanging pixels.
const GROUND_CONTACT := {
    "power_pole_full": Rect2(0.38, 0.88, 0.24, 0.12),
    "power_pole_small": Rect2(0.38, 0.88, 0.24, 0.12),
    "transformer_pole": Rect2(0.32, 0.84, 0.36, 0.16),
    "streetlight": Rect2(0.40, 0.88, 0.20, 0.12),
    "fence": Rect2(0.04, 0.76, 0.92, 0.24),
    "fence_gate": Rect2(0.04, 0.76, 0.92, 0.24),
    "warning_fence": Rect2(0.04, 0.76, 0.92, 0.24),
    "barbed_fence": Rect2(0.04, 0.76, 0.92, 0.24),
    "barrier_plain": Rect2(0.06, 0.70, 0.88, 0.30),
    "barrier_stripe": Rect2(0.06, 0.70, 0.88, 0.30),
    "bollard": Rect2(0.25, 0.76, 0.50, 0.24),
    "cone_small": Rect2(0.18, 0.76, 0.64, 0.24),
    "cone_medium": Rect2(0.18, 0.76, 0.64, 0.24),
    "cone_large": Rect2(0.18, 0.76, 0.64, 0.24),
    "cone_stack": Rect2(0.14, 0.72, 0.72, 0.28),
    "electrical_cabinet": Rect2(0.10, 0.72, 0.80, 0.28),
    "sign_pickaxe": Rect2(0.30, 0.82, 0.40, 0.18),
    "sign_speed_25": Rect2(0.30, 0.82, 0.40, 0.18),
    "sign_dump": Rect2(0.30, 0.82, 0.40, 0.18),
    "pallet": Rect2(0.06, 0.68, 0.88, 0.32),
    "pallet_blocks": Rect2(0.06, 0.68, 0.88, 0.32),
    "crate": Rect2(0.08, 0.68, 0.84, 0.32),
    "case_stack": Rect2(0.08, 0.72, 0.84, 0.28),
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

static func region(prop_name: String) -> Rect2i:
    return REGIONS.get(prop_name, REGIONS["cone_medium"])

static func ground_contact(prop_name: String, destination: Rect2) -> Rect2:
    var normalized: Rect2 = GROUND_CONTACT.get(prop_name, Rect2(0.15, 0.75, 0.70, 0.25))
    return Rect2(
        destination.position + destination.size * normalized.position,
        destination.size * normalized.size
    )

static func sort_y(prop_name: String, destination: Rect2) -> float:
    return ground_contact(prop_name, destination).end.y

static func debug_ready() -> bool:
    if REGIONS.size() < 20 or GROUND_CONTACT.size() != REGIONS.size() or not ResourceLoader.exists(SHEET_PATH):
        return false
    for prop_name in REGIONS:
        var footprint: Rect2 = GROUND_CONTACT.get(prop_name, Rect2())
        if footprint.size.x <= 0.0 or footprint.size.y <= 0.0 or footprint.end.x > 1.0 or footprint.end.y > 1.0:
            return false
    return true
