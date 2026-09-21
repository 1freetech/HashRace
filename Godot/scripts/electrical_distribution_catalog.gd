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
    return load(SHEET_PATH) as Texture2D

static func region(id: String) -> Rect2i:
    return REGIONS.get(id, REGIONS["switchgear"])
