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
