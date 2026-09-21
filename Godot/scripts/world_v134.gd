extends "res://scripts/world_v133.gd"

# Hash Race v0.134: keep ASIC expansion recommendations affordable.
# Electrical headroom remains the hard ceiling, while 15% of current cash stays
# reserved for operating needs before the advisor recommends a purchase batch.

const V134_BUDGET_REVISION := 1
const V134_CASH_RESERVE_RATIO := 0.15
const V134_REFERENCE_ASIC_PRICE := 3500.0

func _v134_budget_asic_batch(snapshot: Dictionary, cash: float, asic_price: float = V134_REFERENCE_ASIC_PRICE) -> int:
    var power_batch := _v133_safe_asic_batch(snapshot)
    if power_batch <= 0 or cash <= 0.0 or asic_price <= 0.0:
        return 0
    var spendable_cash := maxf(0.0, cash * (1.0 - V134_CASH_RESERVE_RATIO))
    var cash_batch := maxi(0, int(floor(spendable_cash / asic_price)))
    return mini(power_batch, cash_batch)

func _v132_capacity_advice(snapshot: Dictionary) -> String:
    var overload_mw := float(snapshot.get("overload_mw", 0.0))
    var headroom_mw := float(snapshot.get("headroom_mw", 0.0))
    var power_batch := _v133_safe_asic_batch(snapshot)
    if overload_mw > 0.001:
        return "ACTION: CURTAIL LOAD"
    if headroom_mw < V132_LOW_HEADROOM_MW or power_batch < 8:
        return "ACTION: EXPAND POWER"

    var cash := float(player.get("cash", 0.0)) if not player.is_empty() else 0.0
    var affordable_batch := _v134_budget_asic_batch(snapshot, cash)
    if affordable_batch <= 0:
        return "ACTION: BUILD CASH RESERVE"
    if affordable_batch < power_batch:
        return "ACTION: BUY UP TO %d ASICs • BUDGET LIMIT" % affordable_batch
    return "ACTION: BUY UP TO %d ASICs • POWER LIMIT" % affordable_batch

func debug_v134_ready() -> bool:
    var safe := {"overload_mw": 0.0, "headroom_mw": 1.0, "reference_asic_count": 285}
    var tight := {"overload_mw": 0.0, "headroom_mw": 0.02, "reference_asic_count": 5}
    var overloaded := {"overload_mw": 0.5, "headroom_mw": 0.0, "reference_asic_count": 0}
    return V134_BUDGET_REVISION == 1 \
        and _v134_budget_asic_batch(safe, 100000.0) == 24 \
        and _v134_budget_asic_batch(safe, 2000000.0) == 257 \
        and _v134_budget_asic_batch(overloaded, 2000000.0) == 0 \
        and _v134_budget_asic_batch(tight, 2000000.0) == 5 \
        and debug_v133_ready()
