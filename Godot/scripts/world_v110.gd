extends "res://scripts/world_v109.gd"

# Hash Race v0.110 cash-runway guidance.
# When even a one-day turn is insolvent, convert the cash gap into an actionable
# one-day break-even target so the player knows how much operating economics
# must improve before safely advancing time.

const V110_CASH_RUNWAY_REVISION := 1

func _cash_rescue_turn_hint() -> String:
    var base_hint := super._cash_rescue_turn_hint()
    if not base_hint.begins_with("CASH GAP:"):
        return base_hint

    var one_day_cash := float(player["cash"]) + float(_scaled_financial_preview(1.0)["profit"])
    if one_day_cash >= 0.0:
        return base_hint

    var break_even_delta := int(ceil(abs(one_day_cash)))
    return "%s | BREAK-EVEN: improve 1-day net cash by $%d through revenue, power savings, or cost cuts" % [base_hint, break_even_delta]

func debug_v110_ready() -> bool:
    return V110_CASH_RUNWAY_REVISION == 1 and debug_v109_ready()
