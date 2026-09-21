extends "res://scripts/world_v134.gd"

# Hash Race v0.135: enforce the league's Bitcoin-miner-only company model.
# External technology, energy, finance, real-estate, sports, and service firms
# remain partner NPCs; they are never selectable mining archetypes.

const V135_COMPANY_MODEL_REVISION := 1
const V135_MINING_COMPANIES := [
    "VantaGrid Mining",
    "NeonForge Mining",
    "ArcShift Mining",
    "IronVector Mining",
    "Meridian Zero Mining",
    "BlueNova Mining",
    "SignalFlux Mining",
    "Parallax Core Mining",
    "LatticeX Mining",
    "Epoch Vector Mining",
]

func _ready() -> void:
    # The inherited simulation is index-based, so replacing the ten display names
    # preserves balances/strengths while making the league model unambiguous.
    for i in range(mini(COMPANY_NAMES.size(), V135_MINING_COMPANIES.size())):
        COMPANY_NAMES[i] = V135_MINING_COMPANIES[i]
    super._ready()

func debug_v135_ready() -> bool:
    if V135_MINING_COMPANIES.size() != 10:
        return false
    for company_name in V135_MINING_COMPANIES:
        if not String(company_name).ends_with("Mining"):
            return false
    return V135_COMPANY_MODEL_REVISION == 1 and debug_v134_ready()
