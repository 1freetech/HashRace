extends "res://scripts/world_v110.gd"

# Hash Race v0.111 site-growth milestones.
# Mining expansion should become visible as the fleet grows, without requiring
# a literal one-object-per-ASIC representation. These load milestones are the
# gameplay contract that future site-map visuals can use to spawn containers,
# transformer yards, cooling blocks, and campus infrastructure.

const V111_SITE_GROWTH_REVISION := 1
const SITE_GROWTH_MILESTONES := [
    {"name": "STARTER SITE", "min_mw": 0.0, "next_mw": 2.0},
    {"name": "CONTAINER YARD", "min_mw": 2.0, "next_mw": 10.0},
    {"name": "MINING FACILITY", "min_mw": 10.0, "next_mw": 25.0},
    {"name": "POWER CAMPUS", "min_mw": 25.0, "next_mw": 50.0},
    {"name": "INDUSTRIAL CAMPUS", "min_mw": 50.0, "next_mw": 100.0},
    {"name": "MEGASITE", "min_mw": 100.0, "next_mw": -1.0},
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

func debug_v111_ready() -> bool:
    var starter := _site_growth_state(1.0)
    var campus := _site_growth_state(60.0)
    var mega := _site_growth_state(125.0)
    return V111_SITE_GROWTH_REVISION == 1 and String(starter["name"]) == "STARTER SITE" and is_equal_approx(float(starter["mw_to_next"]), 1.0) and String(campus["name"]) == "INDUSTRIAL CAMPUS" and String(mega["name"]) == "MEGASITE" and debug_v110_ready()
