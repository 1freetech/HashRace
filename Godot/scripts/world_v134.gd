extends "res://scripts/world_v133.gd"

# Hash Race v0.134: make the safe ASIC batch recommendation budget-aware.
# Electrical headroom is only one half of a hardware purchase decision; the
# advisor now caps the suggested batch by available cash when price data exists.

const V134_BUDGET_ADVISOR_REVISION := 1
const V134_DEFAULT_ASIC_PRICE_USD := 3500.0
const V134_CASH_RESERVE_RATIO := 0.15

func _v134_budget_asic_limit(snapshot: Dictionary) -> int:
    var cash_usd := maxf(0.0, float(snapshot.get("cash_usd", -1.0)))
    if cash_usd < 0.0:
        return _v133_safe_asic_batch(snapshot)
    var asic_price_usd := maxf(1.0, float(snapshot.get("asic_price_usd", V134_DEFAULT_ASIC_PRICE_USD)))
    var spendable_cash := cash_usd * (1.0 - V134_CASH_RESERVE_RATIO)
    return maxi(0, int(floor(spendable_cash / asic_price_usd)))

func _v134_safe_affordable_batch(snapshot: Dictionary) -> int:
    return mini(_v133_safe_asic_batch(snapshot), _v134_budget_asic_limit(snapshot))

func _v132_capacity_advice(snapshot: Dictionary) -> String:
    var overload_mw := float(snapshot.get("overload_mw", 0.0))
    var headroom_mw := float(snapshot.get("headroom_mw", 0.0))
    if overload_mw > 0.001:
        return "ACTION: CURTAIL LOAD"
    if headroom_mw < V132_LOW_HEADROOM_MW:
        return "ACTION: EXPAND POWER"
    var electrical_batch := _v133_safe_asic_batch(snapshot)
    var affordable_batch := _v134_safe_affordable_batch(snapshot)
    if affordable_batch < 1:
        return "ACTION: BUILD CASH RESERVE"
    if affordable_batch < 8:
        return "ACTION: SAVE FOR ASIC BATCH"
    if affordable_batch < electrical_batch:
        return "ACTION: BUY %d ASICs (BUDGET CAP)" % affordable_batch
    return "ACTION: BUY UP TO %d ASICs" % electrical_batch

func debug_v134_ready() -> bool:
    var power_limited := {"overload_mw": 0.0, "headroom_mw": 1.0, "cash_usd": 2000000.0, "asic_price_usd": 3500.0}
    var budget_limited := {"overload_mw": 0.0, "headroom_mw": 1.0, "cash_usd": 100000.0, "asic_price_usd": 3500.0}
    var broke := {"overload_mw": 0.0, "headroom_mw": 1.0, "cash_usd": 1000.0, "asic_price_usd": 3500.0}
    return V134_BUDGET_ADVISOR_REVISION == 1 \
        and _v134_safe_affordable_batch(power_limited) == 257 \
        and _v134_safe_affordable_batch(budget_limited) == 24 \
        and _v132_capacity_advice(budget_limited) == "ACTION: BUY 24 ASICs (BUDGET CAP)" \
        and _v132_capacity_advice(broke) == "ACTION: BUILD CASH RESERVE" \
        and debug_v133_ready()
