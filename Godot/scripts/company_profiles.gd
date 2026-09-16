extends RefCounted

const PROFILES := [
    {"name":"Emberline Compute", "strengths":"POWER COST + PROFIT", "power_discount":0.012, "cash_bonus":10000.0, "mw_bonus":0.0, "machine_bonus":0, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00},
    {"name":"Helix Circuit Labs", "strengths":"MACHINES + CASH", "power_discount":0.0, "cash_bonus":22000.0, "mw_bonus":0.0, "machine_bonus":8, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00},
    {"name":"ArcCurrent Systems", "strengths":"MW + POWER COST", "power_discount":0.008, "cash_bonus":0.0, "mw_bonus":0.10, "machine_bonus":0, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00},
    {"name":"StoneGrid Infrastructure", "strengths":"ACRES + MW", "power_discount":0.0, "cash_bonus":0.0, "mw_bonus":0.10, "machine_bonus":0, "acres_bonus":4.25, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00},
    {"name":"Meridian Node Group", "strengths":"CASH + FINANCING", "power_discount":0.0, "cash_bonus":30000.0, "mw_bonus":0.0, "machine_bonus":0, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.05},
    {"name":"BlueLoop Compute", "strengths":"ENERGY + PROFIT", "power_discount":0.006, "cash_bonus":10000.0, "mw_bonus":0.0, "machine_bonus":0, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Utility PPA", "loan_bonus":0.00},
    {"name":"SignalPeak Systems", "strengths":"MACHINES + ENERGY", "power_discount":0.004, "cash_bonus":0.0, "mw_bonus":0.0, "machine_bonus":6, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00},
    {"name":"Parallax Digital Works", "strengths":"MACHINES + MW", "power_discount":0.0, "cash_bonus":0.0, "mw_bonus":0.08, "machine_bonus":6, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00},
    {"name":"Lattice Energy Labs", "strengths":"POWER COST + MACHINES", "power_discount":0.010, "cash_bonus":0.0, "mw_bonus":0.0, "machine_bonus":5, "acres_bonus":0.0, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.00},
    {"name":"Epoch Harbor Holdings", "strengths":"CASH + ACRES", "power_discount":0.0, "cash_bonus":25000.0, "mw_bonus":0.0, "machine_bonus":0, "acres_bonus":4.25, "sats_bonus":0.0, "energy":"Grid", "loan_bonus":0.02}
]

const LOAN_TIERS := [
    {"name":"Community Bank", "kind":"Bank", "min_assets":50000.0, "ltv":0.22, "rate":0.120, "cap":100000.0, "min_stage":0},
    {"name":"Commercial Bank", "kind":"Bank", "min_assets":250000.0, "ltv":0.32, "rate":0.090, "cap":500000.0, "min_stage":0},
    {"name":"Infrastructure Bank", "kind":"Bank", "min_assets":1000000.0, "ltv":0.42, "rate":0.070, "cap":2500000.0, "min_stage":1},
    {"name":"State Development Fund", "kind":"Government", "min_assets":5000000.0, "ltv":0.52, "rate":0.055, "cap":10000000.0, "min_stage":2},
    {"name":"Strategic Infrastructure Program", "kind":"Government", "min_assets":20000000.0, "ltv":0.62, "rate":0.045, "cap":50000000.0, "min_stage":3}
]
