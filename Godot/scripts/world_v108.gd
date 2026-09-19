extends "res://scripts/world_v107.gd"

# Hash Race v0.108 actionable cash-risk turn guidance.
# Negative-cash previews now identify the longest shorter preset that is
# projected to keep cash non-negative, so the player gets a concrete recovery
# move instead of only being told to choose a shorter turn.

const V108_CASH_TURN_GUIDANCE_REVISION := 1

func _cash_rescue_turn_hint() -> String:
    var current_days := turn_length_days()
    var candidates: Array = [
        {"name": "QUARTER", "days": 91.3125, "key": "3"},
        {"name": "MONTH", "days": 30.4375, "key": "2"},
        {"name": "DAY", "days": 1.0, "key": "1"},
    ]
    for candidate in candidates:
        var days := float(candidate["days"])
        if days >= current_days - 0.001:
            continue
        var projected_cash := float(player["cash"]) + float(_scaled_financial_preview(days)["profit"])
        if projected_cash >= 0.0:
            return "CASH OPTION: press %s for a %s turn (projected cash $%d)" % [String(candidate["key"]), String(candidate["name"]), int(projected_cash)]
    return ""

func _turn_action_hint(power_pct: float, ending_cash: float, power_cost: float) -> String:
    var base_hint := super._turn_action_hint(power_pct, ending_cash, power_cost)
    if ending_cash >= 0.0:
        return base_hint
    var rescue_hint := _cash_rescue_turn_hint()
    if rescue_hint.is_empty():
        return base_hint
    return "%s | %s" % [base_hint, rescue_hint]

func debug_v108_ready() -> bool:
    return V108_CASH_TURN_GUIDANCE_REVISION == 1 and debug_v107_ready() and has_method("_cash_rescue_turn_hint")
