extends "res://scripts/world_v133.gd"

# Hash Race v0.134: keep expansion advice inside the mining company's budget.
# The electrical batch remains the hard ceiling, while a 15% treasury reserve
# protects payroll, power bills, repairs, and deal-making cash.

const V134_BUDGET_REVISION := 1
const V134_CASH_RESERVE_RATIO := 0.15

func _v134_affordable_asic_batch(snapshot: Dictionary, treasury_usd: float, asic_price_usd: float) -> int:
    var power_batch := _v133_safe_asic_batch(snapshot)
    if power_batch <= 0 or asic_price_usd <= 0.0:
        return 0
    var spendable_usd := maxf(0.0, treasury_usd * (1.0 - V134_CASH_RESERVE_RATIO))
    var budget_batch := maxi(0, int(floor(spendable_usd / asic_price_usd)))
    return mini(power_batch, budget_batch)

func capacity_purchase_advice(snapshot: Dictionary, treasury_usd: float, asic_price_usd: float) -> String:
    var overload_mw := float(snapshot.get("overload_mw", 0.0))
    var headroom_mw := float(snapshot.get("headroom_mw", 0.0))
    if overload_mw > 0.001:
        return "ACTION: CURTAIL LOAD"
    var power_batch := _v133_safe_asic_batch(snapshot)
    if headroom_mw < V132_LOW_HEADROOM_MW or power_batch < 8:
        return "ACTION: EXPAND POWER"
    var affordable_batch := _v134_affordable_asic_batch(snapshot, treasury_usd, asic_price_usd)
    if affordable_batch <= 0:
        return "ACTION: BUILD CASH RESERVE"
    if affordable_batch < power_batch:
        return "ACTION: BUY UP TO %d ASICs (BUDGET LIMIT)" % affordable_batch
    return "ACTION: BUY UP TO %d ASICs (POWER LIMIT)" % affordable_batch

func debug_v134_ready() -> bool:
    var safe := {"overload_mw": 0.0, "headroom_mw": 1.0, "reference_asic_count": 285}
    var tight := {"overload_mw": 0.0, "headroom_mw": 0.02, "reference_asic_count": 5}
    var overloaded := {"overload_mw": 0.5, "headroom_mw": 0.0, "reference_asic_count": 0}
    return V134_BUDGET_REVISION == 1 \
        and _v134_affordable_asic_batch(safe, 1000000.0, 3000.0) == 257 \
        and _v134_affordable_asic_batch(safe, 300000.0, 3000.0) == 85 \
        and capacity_purchase_advice(safe, 1000000.0, 3000.0) == "ACTION: BUY UP TO 257 ASICs (POWER LIMIT)" \
        and capacity_purchase_advice(safe, 300000.0, 3000.0) == "ACTION: BUY UP TO 85 ASICs (BUDGET LIMIT)" \
        and capacity_purchase_advice(safe, 1000.0, 3000.0) == "ACTION: BUILD CASH RESERVE" \
        and capacity_purchase_advice(tight, 1000000.0, 3000.0) == "ACTION: EXPAND POWER" \
        and capacity_purchase_advice(overloaded, 1000000.0, 3000.0) == "ACTION: CURTAIL LOAD" \
        and debug_v133_ready()
