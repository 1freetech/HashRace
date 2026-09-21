extends "res://scripts/world_v133.gd"

# Hash Race v0.134: make ASIC expansion respect both site power and operating cash.
# The advisor keeps the v0.133 10% electrical reserve and now also protects 15%
# of cash so a mining company does not spend its entire treasury on one hardware buy.

const V134_BUDGET_REVISION := 1
const V134_CASH_RESERVE_RATIO := 0.15

func _v134_affordable_asic_batch(snapshot: Dictionary, cash: float, asic_price: float) -> int:
    var power_batch := _v133_safe_asic_batch(snapshot)
    if power_batch <= 0 or asic_price <= 0.0:
        return 0
    var spendable_cash := maxf(0.0, cash * (1.0 - V134_CASH_RESERVE_RATIO))
    var cash_batch := maxi(0, int(floor(spendable_cash / asic_price)))
    return mini(power_batch, cash_batch)

func _v134_capacity_advice(snapshot: Dictionary, cash: float, asic_price: float) -> String:
    var overload_mw := float(snapshot.get("overload_mw", 0.0))
    var headroom_mw := float(snapshot.get("headroom_mw", 0.0))
    var power_batch := _v133_safe_asic_batch(snapshot)
    if overload_mw > 0.001:
        return "ACTION: CURTAIL LOAD"
    if headroom_mw < V132_LOW_HEADROOM_MW or power_batch < 8:
        return "ACTION: EXPAND POWER"
    var affordable := _v134_affordable_asic_batch(snapshot, cash, asic_price)
    if affordable < 1:
        return "ACTION: BUILD CASH RESERVE"
    if affordable < power_batch:
        return "ACTION: BUY UP TO %d ASICs • BUDGET LIMIT" % affordable
    return "ACTION: BUY UP TO %d ASICs • POWER LIMIT" % affordable

func debug_v134_ready() -> bool:
    var safe := {"overload_mw": 0.0, "headroom_mw": 1.0, "reference_asic_count": 285}
    var tight := {"overload_mw": 0.0, "headroom_mw": 0.02, "reference_asic_count": 5}
    var overloaded := {"overload_mw": 0.5, "headroom_mw": 0.0, "reference_asic_count": 0}
    return V134_BUDGET_REVISION == 1 \
        and _v134_affordable_asic_batch(safe, 1000000.0, 3500.0) == 242 \
        and _v134_affordable_asic_batch(safe, 10000.0, 3500.0) == 2 \
        and _v134_capacity_advice(safe, 1000000.0, 3500.0) == "ACTION: BUY UP TO 242 ASICs • BUDGET LIMIT" \
        and _v134_capacity_advice(safe, 2000000.0, 3500.0) == "ACTION: BUY UP TO 257 ASICs • POWER LIMIT" \
        and _v134_capacity_advice(safe, 1000.0, 3500.0) == "ACTION: BUILD CASH RESERVE" \
        and _v134_capacity_advice(tight, 1000000.0, 3500.0) == "ACTION: EXPAND POWER" \
        and _v134_capacity_advice(overloaded, 1000000.0, 3500.0) == "ACTION: CURTAIL LOAD" \
        and debug_v133_ready()
