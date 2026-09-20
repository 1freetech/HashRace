extends "res://scripts/world_v110.gd"

# Hash Race v0.111 site-growth and infrastructure-layout pass.
# Mining expansion becomes visible as the fleet grows without one-object-per-ASIC
# clutter. Brand-neutral infrastructure plans support four-way orientation and
# compressed GW/TW visual blocks for company town maps.

const InfrastructureVisualCatalog = preload("res://systems/infrastructure_visual_catalog.gd")

const V111_SITE_GROWTH_REVISION := 2
const SITE_GROWTH_MILESTONES := [
    {"name": "STARTER SITE", "min_mw": 0.0, "next_mw": 2.0},
    {"name": "CONTAINER YARD", "min_mw": 2.0, "next_mw": 10.0},
    {"name": "MINING FACILITY", "min_mw": 10.0, "next_mw": 25.0},
    {"name": "POWER CAMPUS", "min_mw": 25.0, "next_mw": 50.0},
    {"name": "INDUSTRIAL CAMPUS", "min_mw": 50.0, "next_mw": 100.0},
    {"name": "MEGASITE", "min_mw": 100.0, "next_mw": 1000.0},
    {"name": "GIGAWATT DISTRICT", "min_mw": 1000.0, "next_mw": 10000.0},
    {"name": "MULTI-GW REGION", "min_mw": 10000.0, "next_mw": 100000.0},
    {"name": "100-GW NETWORK", "min_mw": 100000.0, "next_mw": 1000000.0},
    {"name": "TERAWATT NETWORK", "min_mw": 1000000.0, "next_mw": -1.0},
]

func _site_growth_state(load_mw: float = -1.0) -> Dictionary:
    var active_load_mw := load_mw
    if active_load_mw < 0.0:
        active_load_mw = maxf(0.0, _machine_load_kw() / 1000.0)
    var state: Dictionary = SITE_GROWTH_MILESTONES[0].duplicate(true)
    for milestone in SITE_GROWTH_MILESTONES:
        if active_load_mw >= float(milestone["min_mw"]):
            state = milestone.duplicate(true)
    state["load_mw"] = active_load_mw
    var next_mw := float(state["next_mw"])
    state["mw_to_next"] = maxf(0.0, next_mw - active_load_mw) if next_mw > 0.0 else 0.0
    return state

func site_growth_summary() -> String:
    var state := _site_growth_state()
    if float(state["next_mw"]) <= 0.0:
        return "SITE: %s | %.1f MW deployed | maximum visual tier" % [String(state["name"]), float(state["load_mw"])]
    return "SITE: %s | %.1f MW deployed | +%.1f MW to %s" % [String(state["name"]), float(state["load_mw"]), float(state["mw_to_next"]), _next_site_growth_name(float(state["next_mw"]))]

func _next_site_growth_name(next_mw: float) -> String:
    for milestone in SITE_GROWTH_MILESTONES:
        if is_equal_approx(float(milestone["min_mw"]), next_mw):
            return String(milestone["name"])
    return "NEXT SITE TIER"

func infrastructure_visual_plan(asset_id: String, capacity_mw: float, orientation: String = "up") -> Dictionary:
    return InfrastructureVisualCatalog.layout_plan(asset_id, capacity_mw, orientation)

func debug_v111_ready() -> bool:
    var starter := _site_growth_state(1.0)
    var campus := _site_growth_state(60.0)
    var gigawatt := _site_growth_state(1000.0)
    var terawatt := _site_growth_state(1000000.0)
    var transformer := infrastructure_visual_plan("kva_transformer", 10.0, "right")
    var tw_plan := infrastructure_visual_plan("cooling_container", 1000000.0, "up")
    return V111_SITE_GROWTH_REVISION == 2 \
        and String(starter["name"]) == "STARTER SITE" \
        and is_equal_approx(float(starter["mw_to_next"]), 1.0) \
        and String(campus["name"]) == "INDUSTRIAL CAMPUS" \
        and String(gigawatt["name"]) == "GIGAWATT DISTRICT" \
        and String(terawatt["name"]) == "TERAWATT NETWORK" \
        and String(transformer.get("orientation", "")) == "right" \
        and int(tw_plan.get("block_count", 0)) == 10 \
        and InfrastructureVisualCatalog.debug_ready() \
        and debug_v110_ready()
