extends "res://scripts/world_v133.gd"

# Hash Race v0.134: capacity advice now respects both electrical and cash reserves.
# A mining company should never be told to buy an electrically safe batch that
# would consume the operating treasury needed to survive the next turn.

const V134_BUDGET_ADVISOR_REVISION := 1
const V134_CASH_RESERVE_RATIO := 0.15

func _v134_affordable_asic_batch(snapshot: Dictionary, cash: float, asic_price: float) -> int:
    var power_batch := _v133_safe_asic_batch(snapshot)
    if power_batch <= 0 or asic_price <= 0.0:
        return 0
    var spendable_cash := maxf(0.0, cash * (1.0 - V134_CASH_RESERVE_RATIO))
    var cash_batch := maxi(0, int(floor(spendable_cash / asic_price)))
    return mini(power_batch, cash_batch)

func _v134_expansion_advice(snapshot: Dictionary, cash: float, asic_price: float) -> String:
    var overload_mw := float(snapshot.get("overload_mw", 0.0))
    var headroom_mw := float(snapshot.get("headroom_mw", 0.0))
    if overload_mw > 0.001:
        return "ACTION: CURTAIL LOAD"
    var power_batch := _v133_safe_asic_batch(snapshot)
    if headroom_mw < V132_LOW_HEADROOM_MW or power_batch < 8:
        return "ACTION: EXPAND POWER"
    var affordable := _v134_affordable_asic_batch(snapshot, cash, asic_price)
    if affordable <= 0:
        return "ACTION: BUILD CASH RESERVE"
    if affordable < power_batch:
        return "ACTION: BUY %d ASICs // BUDGET LIMIT" % affordable
    return "ACTION: BUY UP TO %d ASICs // POWER LIMIT" % power_batch

func debug_v134_ready() -> bool:
    var safe := {"overload_mw": 0.0, "headroom_mw": 1.0, "reference_asic_count": 285}
    var tight := {"overload_mw": 0.0, "headroom_mw": 0.02, "reference_asic_count": 5}
    var overloaded := {"overload_mw": 0.5, "headroom_mw": 0.0, "reference_asic_count": 0}
    return V134_BUDGET_ADVISOR_REVISION == 1 \
        and _v134_affordable_asic_batch(safe, 1000000.0, 3000.0) == 257 \
        and _v134_affordable_asic_batch(safe, 30000.0, 3000.0) == 8 \
        and _v134_expansion_advice(safe, 1000000.0, 3000.0) == "ACTION: BUY UP TO 257 ASICs // POWER LIMIT" \
        and _v134_expansion_advice(safe, 30000.0, 3000.0) == "ACTION: BUY 8 ASICs // BUDGET LIMIT" \
        and _v134_expansion_advice(safe, 2000.0, 3000.0) == "ACTION: BUILD CASH RESERVE" \
        and _v134_expansion_advice(tight, 1000000.0, 3000.0) == "ACTION: EXPAND POWER" \
        and _v134_expansion_advice(overloaded, 1000000.0, 3000.0) == "ACTION: CURTAIL LOAD" \
        and debug_v133_ready()
