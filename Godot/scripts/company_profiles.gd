extends RefCounted

# Ten fictional Bitcoin-mining competitors. Every company is a miner. The
# differences are starting strengths, operating culture, controversy history,
# and 0-100 strategic ratings that can evolve during a campaign.
const PROFILES := [
    {
        "name":"VantaGrid Mining",
        "strengths":"POWER COST + PROFIT",
        "posture":"Aggressive",
        "background":"VantaGrid was started by energy-market traders who learned to place modular Bitcoin mines beside underused generation. It grew by moving into power markets before slower operators could secure capacity.",
        "controversy":"Its first large rural site expanded before the full noise-mitigation plan was finished. Residents pushed back, forcing VantaGrid to add sound walls, curtailment rules, and community payments.",
        "affinity":"Energy",
        "aggression":78, "risk":72, "growth":82, "research":55, "treasury":48, "operations":67, "reputation":56,
        "power_discount":0.012, "cash_bonus":10000.0, "mw_bonus":0.0, "machine_bonus":0, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00
    },
    {
        "name":"NeonForge Mining",
        "strengths":"MACHINES + CASH",
        "posture":"Aggressive",
        "background":"NeonForge was built by hardware wholesalers who turned an equipment-distribution business into a miner. Its culture prizes fleet size, fast deployments, and buying hardware when competitors hesitate.",
        "controversy":"A debt-heavy machine purchase left the company overexposed when Bitcoin prices fell. NeonForge survived through refinancing and asset sales, but critics still question its appetite for rapid expansion.",
        "affinity":"Semiconductor",
        "aggression":90, "risk":84, "growth":94, "research":68, "treasury":35, "operations":58, "reputation":44,
        "power_discount":0.0, "cash_bonus":22000.0, "mw_bonus":0.0, "machine_bonus":8, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00
    },
    {
        "name":"ArcShift Mining",
        "strengths":"MW + POWER COST",
        "posture":"Moderate",
        "background":"ArcShift came from industrial electrical contractors who understood substations, interconnects, and flexible loads. It usually expands only after power infrastructure and curtailment economics are modeled.",
        "controversy":"One early interconnect project ran far over budget after management underestimated utility upgrade work. The miss made ArcShift slower to approve new sites and much more demanding about engineering reviews.",
        "affinity":"Infrastructure",
        "aggression":55, "risk":48, "growth":63, "research":66, "treasury":74, "operations":80, "reputation":70,
        "power_discount":0.008, "cash_bonus":0.0, "mw_bonus":0.10, "machine_bonus":0, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00
    },
    {
        "name":"IronVector Mining",
        "strengths":"ACRES + MW",
        "posture":"Conservative",
        "background":"IronVector began as a land-and-infrastructure owner that leased space to miners before operating its own fleet. It prefers owned land, oversized electrical infrastructure, and low leverage.",
        "controversy":"Shareholders criticized IronVector for sitting on large undeveloped parcels during a strong Bitcoin market. Management accepted slower growth rather than rush permitting and construction.",
        "affinity":"Real Estate",
        "aggression":34, "risk":30, "growth":46, "research":44, "treasury":86, "operations":88, "reputation":77,
        "power_discount":0.0, "cash_bonus":0.0, "mw_bonus":0.10, "machine_bonus":0, "acres_bonus":4.25, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00
    },
    {
        "name":"Meridian Zero Mining",
        "strengths":"CASH + FINANCING",
        "posture":"Moderate",
        "background":"Meridian Zero was founded by project-finance specialists who treat mining sites like infrastructure investments. It mixes debt, equipment financing, treasury management, and selective acquisitions.",
        "controversy":"A complex financing package obscured how much short-term refinancing risk the company carried. The board later simplified its debt structure and added stricter liquidity targets.",
        "affinity":"Finance",
        "aggression":62, "risk":61, "growth":70, "research":52, "treasury":81, "operations":65, "reputation":58,
        "power_discount":0.0, "cash_bonus":30000.0, "mw_bonus":0.0, "machine_bonus":0, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.05
    },
    {
        "name":"BlueNova Mining",
        "strengths":"ENERGY + PROFIT",
        "posture":"Conservative",
        "background":"BlueNova grew around long-duration utility contracts and hydro-heavy regions. It prioritizes stable power, high uptime, and profitable operation before adding large amounts of new hash rate.",
        "controversy":"A dry season forced deeper curtailment than management had forecast and undermined earlier marketing that implied renewable power was always available. BlueNova changed its disclosures and planning assumptions.",
        "affinity":"Energy",
        "aggression":28, "risk":25, "growth":40, "research":58, "treasury":88, "operations":91, "reputation":79,
        "power_discount":0.006, "cash_bonus":10000.0, "mw_bonus":0.0, "machine_bonus":0, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Utility PPA", "loan_bonus":0.00
    },
    {
        "name":"SignalFlux Mining",
        "strengths":"MACHINES + ENERGY",
        "posture":"Moderate",
        "background":"SignalFlux was formed by operations engineers who focused on telemetry, maintenance, firmware discipline, and energy controls. It wins by keeping a large percentage of its installed fleet online.",
        "controversy":"A rushed monitoring-system migration produced false alarms and unnecessary shutdowns across a major site. The company recovered by adopting staged deployments and stronger rollback procedures.",
        "affinity":"Telecom",
        "aggression":50, "risk":43, "growth":60, "research":72, "treasury":68, "operations":92, "reputation":73,
        "power_discount":0.004, "cash_bonus":0.0, "mw_bonus":0.0, "machine_bonus":6, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00
    },
    {
        "name":"Parallax Core Mining",
        "strengths":"MACHINES + MW",
        "posture":"Aggressive",
        "background":"Parallax Core was created by former capacity planners who believe scale protects margins. It signs power and orders machines well ahead of demand, aiming to keep construction and fleet growth moving at the same time.",
        "controversy":"A large pre-purchase of next-generation miners arrived months late, leaving new electrical capacity idle. The write-down hurt its reputation but did not change management's scale-first philosophy.",
        "affinity":"Infrastructure",
        "aggression":82, "risk":79, "growth":90, "research":74, "treasury":42, "operations":63, "reputation":49,
        "power_discount":0.0, "cash_bonus":0.0, "mw_bonus":0.08, "machine_bonus":6, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00
    },
    {
        "name":"LatticeX Mining",
        "strengths":"POWER COST + MACHINES",
        "posture":"Moderate",
        "background":"LatticeX was founded by firmware and silicon engineers who believed tuning and hardware efficiency could extend the life of older mining fleets. It spends unusually heavily on diagnostics and chip research.",
        "controversy":"An experimental firmware release caused instability and a warranty dispute with a supplier. LatticeX moved to canary fleets and formal validation before pushing changes to production machines.",
        "affinity":"Semiconductor",
        "aggression":47, "risk":45, "growth":58, "research":93, "treasury":67, "operations":84, "reputation":75,
        "power_discount":0.010, "cash_bonus":0.0, "mw_bonus":0.0, "machine_bonus":5, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00
    },
    {
        "name":"Epoch Vector Mining",
        "strengths":"CASH + ACRES",
        "posture":"Conservative",
        "background":"Epoch Vector built its business by buying land and distressed infrastructure during weak mining markets, then developing only the best sites. It keeps more cash than most rivals and waits for favorable entry points.",
        "controversy":"Its distressed-site acquisitions included sharp contractor cuts and abrupt operating changes that angered local vendors. Epoch Vector later created a slower integration process, but the company remains known for hard negotiations.",
        "affinity":"Real Estate",
        "aggression":38, "risk":35, "growth":52, "research":50, "treasury":94, "operations":78, "reputation":72,
        "power_discount":0.0, "cash_bonus":25000.0, "mw_bonus":0.0, "machine_bonus":0, "acres_bonus":4.25, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.02
    }
]

# Loan pricing is Fed rate + lender spread. Small lenders are expensive and
# capped; larger asset bases unlock progressively larger, cheaper capital.
const LOAN_TIERS := [
    {"name":"Local Joker Bank", "kind":"Local Bank", "min_assets":25000.0, "ltv":0.15, "spread":0.120, "rate":0.165, "cap":50000.0, "min_stage":0},
    {"name":"Main Street Business Bank", "kind":"Bank", "min_assets":100000.0, "ltv":0.24, "spread":0.080, "rate":0.125, "cap":250000.0, "min_stage":0},
    {"name":"Regional Commercial Bank", "kind":"Bank", "min_assets":500000.0, "ltv":0.34, "spread":0.050, "rate":0.095, "cap":1500000.0, "min_stage":1},
    {"name":"Infrastructure Capital Bank", "kind":"Bank", "min_assets":2000000.0, "ltv":0.44, "spread":0.030, "rate":0.075, "cap":7500000.0, "min_stage":1},
    {"name":"State Development Fund", "kind":"Government", "min_assets":8000000.0, "ltv":0.55, "spread":0.015, "rate":0.060, "cap":30000000.0, "min_stage":2},
    {"name":"Federal Strategic Infrastructure Program", "kind":"Government", "min_assets":30000000.0, "ltv":0.65, "spread":0.0075, "rate":0.0525, "cap":100000000.0, "min_stage":3}
]
