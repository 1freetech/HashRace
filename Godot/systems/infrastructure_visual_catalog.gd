class_name HashRaceInfrastructureVisualCatalog
extends RefCounted

## Brand-neutral visual infrastructure definitions used by mining-site maps.
## v0.117 locks the visual scale contract used by the live energy/mining renderer:
##   0-2 MW   -> 2x2 facility module
##   >2-10 MW -> 4x4 container yard
##   >10-25 MW -> 6x6 mining/power block
##   >25-100 MW -> 8x8 campus block
##   >100 MW -> compressed 8x8 district blocks through GW/TW scale
##
## The simulation keeps exact MW. The world renderer compresses that exact value
## into a readable number of district blocks rather than drawing literal physical
## container counts.

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

const CAPACITY_VISUAL_TIERS := [
    {
        "max_mw": 2.0,
        "tiles": 2,
        "block_capacity_mw": 2.0,
        "scale_name": "MICRO SITE",
        "compression_level": "FACILITY",
    },
    {
        "max_mw": 10.0,
        "tiles": 4,
        "block_capacity_mw": 10.0,
        "scale_name": "CONTAINER YARD",
        "compression_level": "FACILITY",
    },
    {
        "max_mw": 25.0,
        "tiles": 6,
        "block_capacity_mw": 25.0,
        "scale_name": "MINING BLOCK",
        "compression_level": "FACILITY",
    },
    {
        "max_mw": 100.0,
        "tiles": 8,
        "block_capacity_mw": 100.0,
        "scale_name": "POWER CAMPUS",
        "compression_level": "CAMPUS",
    },
    {
        "max_mw": 1000.0,
        "tiles": 8,
        "block_capacity_mw": 100.0,
        "scale_name": "GIGAWATT DISTRICT",
        "compression_level": "DISTRICT",
    },
    {
        "max_mw": 10000.0,
        "tiles": 8,
        "block_capacity_mw": 1000.0,
        "scale_name": "MULTI-GW REGION",
        "compression_level": "DISTRICT",
    },
    {
        "max_mw": 100000.0,
        "tiles": 8,
        "block_capacity_mw": 10000.0,
        "scale_name": "100-GW NETWORK",
        "compression_level": "REGION",
    },
    {
        "max_mw": 1000000.0,
        "tiles": 8,
        "block_capacity_mw": 100000.0,
        "scale_name": "TERAWATT NETWORK",
        "compression_level": "REGION",
    },
]

static func normalize_orientation(value: String) -> String:
    var orientation := value.to_lower()
    return orientation if orientation in ORIENTATIONS else "up"

static func electrical_orientation(from_position: Vector2, bus_position: Vector2) -> String:
    var delta := bus_position - from_position
    if absf(delta.x) >= absf(delta.y):
        return "right" if delta.x >= 0.0 else "left"
    return "down" if delta.y >= 0.0 else "up"

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

    # A town never draws hundreds or thousands of repeated blocks. Ten visible
    # blocks is the upper visual budget; each can represent more MW as the exact
    # simulation grows past the named compression tier.
    var visible_block_count := mini(10, block_count)
    var represented_mw_per_visible_block := safe_mw
    if visible_block_count > 0:
        represented_mw_per_visible_block = safe_mw / float(visible_block_count)

    return {
        "capacity_mw": safe_mw,
        "footprint": Vector2i(int(selected["tiles"]), int(selected["tiles"])),
        "block_capacity_mw": block_capacity_mw,
        "block_count": block_count,
        "visible_block_count": visible_block_count,
        "represented_mw_per_visible_block": represented_mw_per_visible_block,
        "scale_name": String(selected["scale_name"]),
        "compression_level": String(selected["compression_level"]),
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
    var one_mw := capacity_profile(1.0)
    var ten_mw := capacity_profile(10.0)
    var twenty_five_mw := capacity_profile(25.0)
    var hundred_mw := capacity_profile(100.0)
    var transformer := layout_plan("kva_transformer", 10.0, "right")
    var terawatt := capacity_profile(1000000.0)
    return INFRASTRUCTURE.size() == 13 \
        and Vector2i(one_mw.get("footprint", Vector2i.ZERO)) == Vector2i(2, 2) \
        and Vector2i(ten_mw.get("footprint", Vector2i.ZERO)) == Vector2i(4, 4) \
        and Vector2i(twenty_five_mw.get("footprint", Vector2i.ZERO)) == Vector2i(6, 6) \
        and Vector2i(hundred_mw.get("footprint", Vector2i.ZERO)) == Vector2i(8, 8) \
        and String(transformer.get("orientation", "")) == "right" \
        and int(terawatt.get("block_count", 0)) == 10 \
        and int(terawatt.get("visible_block_count", 0)) == 10 \
        and Vector2i(terawatt.get("footprint", Vector2i.ZERO)) == Vector2i(8, 8) \
        and electrical_orientation(Vector2.ZERO, Vector2(10.0, 0.0)) == "right"
