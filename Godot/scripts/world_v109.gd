extends "res://scripts/world_v108.gd"

# Hash Race v0.109 cash-rescue guidance fallback.
# If even a one-day turn would leave the mining company insolvent, tell the
# player the exact cash gap instead of returning no recovery action.

const V109_CASH_RESCUE_REVISION := 1

func _cash_rescue_turn_hint() -> String:
    var shorter_hint := super._cash_rescue_turn_hint()
    if not shorter_hint.is_empty():
        return shorter_hint

    var one_day_cash := float(player["cash"]) + float(_scaled_financial_preview(1.0)["profit"])
    if one_day_cash < 0.0:
        return "CASH GAP: raise or save at least $%d before ending even a 1-day turn" % int(ceil(abs(one_day_cash)))
    return ""

func debug_v109_ready() -> bool:
    return V109_CASH_RESCUE_REVISION == 1 and debug_v108_ready()
