class_name HashRaceInfrastructureVisualCatalog
extends RefCounted

## Brand-neutral visual infrastructure definitions used by mining-site maps.
## The art layer can swap sprites later without changing the placement contract.

const ORIENTATIONS := ["up", "right", "down", "left"]

const INFRASTRUCTURE := {
    "cooling_container": {"label": "Cooling Container", "category": "cooling", "base_tiles": [2, 2], "connection": "power"},
    "fuel_tank": {"label": "Fuel Tank", "category": "energy_storage", "base_tiles": [2, 2], "connection": "fuel"},
    "pumpjack": {"label": "Oil Pumpjack", "category": "energy_supply", "base_tiles": [3, 3], "connection": "fuel"},
    "manufacturing_center": {"label": "Mining Manufacturing Center", "category": "facility", "base_tiles": [6, 6], "connection": "road"},
    "solar_array": {"label": "Solar Array", "category": "generation", "base_tiles": [2, 2], "connection": "power"},
    "diesel_generator": {"label": "Diesel Generator", "category": "generation", "base_tiles": [2, 2], "connection": "fuel"},
    "wind_turbine": {"label": "Wind Turbine", "category": "generation", "base_tiles": [2, 2], "connection": "power"},
    "geothermal_generator": {"label": "Geothermal Generator", "category": "generation", "base_tiles": [3, 3], "connection": "power"},
    "kva_transformer": {"label": "KVA Transformer", "category": "distribution", "base_tiles": [2, 2], "connection": "power"},
    "lpg_generator": {"label": "LPG Generator", "category": "generation", "base_tiles": [2, 2], "connection": "fuel"},
    "coal_generator": {"label": "Coal Generator", "category": "generation", "base_tiles": [3, 3], "connection": "fuel"},
    "methane_generator": {"label": "Methane Generator", "category": "generation", "base_tiles": [2, 2], "connection": "fuel"},
    "compute_rack": {"label": "Compute Rack", "category": "strategic_supply", "base_tiles": [2, 2], "connection": "power"},
}

## 1 MW, 10 MW, and 100 MW grow the actual footprint. Above 100 MW,
## Hash Race compresses scale into a small number of 8x8 campus/district blocks
## so a town can still represent GW, 100 GW, and 1 TW operations cleanly.
const CAPACITY_VISUAL_TIERS := [
    {"max_mw": 1.0, "tiles": 2, "block_capacity_mw": 1.0, "scale_name": "MODULE"},
    {"max_mw": 10.0, "tiles": 4, "block_capacity_mw": 10.0, "scale_name": "YARD"},
    {"max_mw": 100.0, "tiles": 8, "block_capacity_mw": 100.0, "scale_name": "CAMPUS"},
    {"max_mw": 1000.0, "tiles": 8, "block_capacity_mw": 100.0, "scale_name": "GIGAWATT DISTRICT"},
    {"max_mw": 10000.0, "tiles": 8, "block_capacity_mw": 1000.0, "scale_name": "MULTI-GW REGION"},
    {"max_mw": 100000.0, "tiles": 8, "block_capacity_mw": 10000.0, "scale_name": "100-GW NETWORK"},
    {"max_mw": 1000000.0, "tiles": 8, "block_capacity_mw": 100000.0, "scale_name": "TERAWATT NETWORK"},
]

static func normalize_orientation(value: String) -> String:
    var orientation := value.to_lower()
    return orientation if orientation in ORIENTATIONS else "up"

static func asset_definition(asset_id: String) -> Dictionary:
    if not INFRASTRUCTURE.has(asset_id):
        return {}
    return Dictionary(INFRASTRUCTURE[asset_id]).duplicate(true)

static func capacity_profile(capacity_mw: float) -> Dictionary:
    var safe_mw := maxf(0.0, capacity_mw)
    var selected: Dictionary = CAPACITY_VISUAL_TIERS[CAPACITY_VISUAL_TIERS.size() - 1]
    for tier in CAPACITY_VISUAL_TIERS:
        if safe_mw <= float(tier["max_mw"]):
            selected = tier
            break
    var block_capacity_mw := maxf(1.0, float(selected["block_capacity_mw"]))
    var block_count := 1
    if safe_mw > 0.0:
        block_count = maxi(1, int(ceil(safe_mw / block_capacity_mw)))
    return {
        "capacity_mw": safe_mw,
        "footprint": Vector2i(int(selected["tiles"]), int(selected["tiles"])),
        "block_capacity_mw": block_capacity_mw,
        "block_count": block_count,
        "scale_name": String(selected["scale_name"]),
    }

static func layout_plan(asset_id: String, capacity_mw: float, orientation: String = "up") -> Dictionary:
    var asset := asset_definition(asset_id)
    if asset.is_empty():
        return {}
    var profile := capacity_profile(capacity_mw)
    profile["asset_id"] = asset_id
    profile["label"] = String(asset["label"])
    profile["category"] = String(asset["category"])
    profile["connection"] = String(asset["connection"])
    profile["orientation"] = normalize_orientation(orientation)
    profile["base_tiles"] = Vector2i(int(asset["base_tiles"][0]), int(asset["base_tiles"][1]))
    return profile

static func debug_ready() -> bool:
    var transformer := layout_plan("kva_transformer", 10.0, "right")
    var terawatt := capacity_profile(1000000.0)
    return INFRASTRUCTURE.size() == 13 \
        and String(transformer.get("orientation", "")) == "right" \
        and Vector2i(transformer.get("footprint", Vector2i.ZERO)) == Vector2i(4, 4) \
        and int(terawatt.get("block_count", 0)) == 10 \
        and Vector2i(terawatt.get("footprint", Vector2i.ZERO)) == Vector2i(8, 8)
