extends RefCounted
class_name ElectricalDistributionCatalog

const SHEET_PATH := "res://art/electrical/electrical_distribution_set.svg"
const CELL := Vector2i(128, 128)
const REGIONS := {
    "switchgear": Rect2i(0, 0, 128, 128),
    "pdu": Rect2i(128, 0, 128, 128),
    "junction_box": Rect2i(256, 0, 128, 128),
    "cable_tray": Rect2i(384, 0, 128, 128),
}

static func texture() -> Texture2D:
    # ResourceLoader.exists() avoids emitting a hard loader error when a
    # mislabeled/corrupt imported sheet is present. world_v129 already has a
    # procedural electrical fallback, so returning null is the safe contract.
    if not ResourceLoader.exists(SHEET_PATH, "Texture2D"):
        return null
    return ResourceLoader.load(SHEET_PATH, "Texture2D") as Texture2D

static func region(id: String) -> Rect2i:
    return REGIONS.get(id, REGIONS["switchgear"])
