extends "res://scripts/world_company_ai.gd"

# v0.021: company ratings now change actual player economics instead of being
# mostly descriptive. Effects are deliberately modest so culture matters
# without replacing the player's strategic choices.

func _rating(key: String) -> float:
    if player_personality.is_empty():
        return 50.0
    return clampf(float(player_personality.get(key, 50)), 0.0, 100.0)

func _normalized_rating(key: String) -> float:
    return (_rating(key) - 50.0) / 50.0

func _operations_uptime_bonus() -> float:
    return _normalized_rating("operations") * 0.012

func _financing_rate_adjustment() -> float:
    var discipline: float = (_rating("treasury") * 0.70 + _rating("reputation") * 0.30 - 50.0) / 50.0
    return -discipline * 0.0125

func _partner_cost_multiplier() -> float:
    return clampf(1.0 - _normalized_rating("reputation") * 0.12, 0.88, 1.12)

func _research_cost_multiplier() -> float:
    var execution: float = (_rating("research") * 0.72 + _rating("operations") * 0.28 - 50.0) / 50.0
    return clampf(1.0 - execution * 0.12, 0.88, 1.12)

func _expansion_cost_multiplier() -> float:
    var execution: float = (_rating("growth") * 0.60 + _rating("operations") * 0.40 - 50.0) / 50.0
    var pressure: float = (_rating("aggression") + _rating("risk")) * 0.50
    var rush_premium: float = maxf(0.0, pressure - 70.0) / 30.0 * 0.04
    return clampf(1.0 - execution * 0.08 + rush_premium, 0.90, 1.12)

func _merger_cost_multiplier() -> float:
    var negotiation: float = (_rating("aggression") * 0.55 + _rating("reputation") * 0.45 - 50.0) / 50.0
    return clampf(1.0 - negotiation * 0.08, 0.92, 1.08)

func _signed_points(value: float) -> String:
    var prefix: String = "+" if value >= 0.0 else ""
    return prefix + ("%.2f" % value)

func _culture_effects_summary() -> String:
    return "OPS uptime %s pts • loan %s pts • partner x%.3f • R&D x%.3f • expansion x%.3f • merger x%.3f" % [
        _signed_points(_operations_uptime_bonus() * 100.0),
        _signed_points(_financing_rate_adjustment() * 100.0),
        _partner_cost_multiplier(),
        _research_cost_multiplier(),
        _expansion_cost_multiplier(),
        _merger_cost_multiplier()
    ]

func _uptime() -> float:
    var base: float = super._uptime()
    if player_personality.is_empty():
        return base
    return clampf(base + _operations_uptime_bonus(), 0.80, 0.997)

func _loan_rate(offer: Dictionary) -> float:
    var base: float = super._loan_rate(offer)
    if player_personality.is_empty():
        return base
    return clampf(base + _financing_rate_adjustment(), 0.02, 0.30)

func _buy_machines() -> void:
    if player_personality.is_empty():
        super._buy_machines()
        return
    var machine: Dictionary = MACHINES[int(player["machine_tier"])]
    var discount: float = clampf(float(player["machine_discount"]), 0.0, 0.25)
    var base_cost: float = float(machine["price"]) * 10.0 * (1.0 - discount)
    var effective_cost: float = base_cost * _expansion_cost_multiplier()
    var extra_kw: float = float(machine["kw"]) * 10.0 * 1.06
    if float(player["cash"]) < effective_cost:
        _feedback("Need $%d for 10 × %s after company-culture effects." % [int(effective_cost), String(machine["name"])])
        return
    if _machine_load_kw() + extra_kw > float(player["mw"]) * 1000.0:
        _feedback("Not enough energized MW. Visit Gridline Power Office first.")
        return
    player["cash"] = float(player["cash"]) + base_cost - effective_cost
    var before: int = int(player["machines"])
    super._buy_machines()
    if int(player["machines"]) > before:
        _feedback("Installed 10 × %s for $%d. Expansion culture multiplier: x%.3f." % [String(machine["name"]), int(effective_cost), _expansion_cost_multiplier()])

func _buy_power() -> void:
    if player_personality.is_empty():
        super._buy_power()
        return
    var base_cost: float = (26000.0 + float(player["mw"]) * 42000.0) * (1.0 - clampf(float(player["power_capex_discount"]), 0.0, 0.30))
    var effective_cost: float = base_cost * _expansion_cost_multiplier()
    if float(player["cash"]) < effective_cost:
        _feedback("Need $%d for +0.25 MW after company-culture effects." % int(effective_cost))
        return
    player["cash"] = float(player["cash"]) + base_cost - effective_cost
    var before: float = float(player["mw"])
    super._buy_power()
    if float(player["mw"]) > before:
        _feedback("Interconnect expanded to %.2f MW for $%d. Expansion culture multiplier: x%.3f." % [float(player["mw"]), int(effective_cost), _expansion_cost_multiplier()])

func _buy_land() -> void:
    if player_personality.is_empty():
        super._buy_land()
        return
    var discount: float = clampf(float(player["land_discount"]), 0.0, 0.35)
    var base_cost: float = land_price_per_acre * 5.0 * (1.0 - discount) + 5000.0
    var effective_cost: float = base_cost * _expansion_cost_multiplier()
    if float(player["cash"]) < effective_cost:
        _feedback("Need $%d for the next 5-acre parcel after company-culture effects." % int(effective_cost))
        return
    player["cash"] = float(player["cash"]) + base_cost - effective_cost
    var before: float = float(player["acres"])
    super._buy_land()
    if float(player["acres"]) > before:
        _feedback("Bought 5 acres for $%d. Company land is now %.1f acres. Expansion culture multiplier: x%.3f." % [int(effective_cost), float(player["acres"]), _expansion_cost_multiplier()])

func _upgrade_chips() -> void:
    if player_personality.is_empty():
        super._upgrade_chips()
        return
    var level: int = int(player["chip_level"])
    if level >= 3:
        _feedback("Captive chip manufacturing is already online.")
        return
    var base_costs: Array = [150000.0, 700000.0, 4000000.0]
    var names: Array = ["Strategic wafer deal", "Co-designed silicon", "Captive chip manufacturing"]
    var base_cost: float = float(base_costs[level])
    var effective_cost: float = base_cost * _research_cost_multiplier()
    if float(player["cash"]) < effective_cost:
        _feedback("Need $%d for %s after R&D-culture effects." % [int(effective_cost), String(names[level])])
        return
    player["cash"] = float(player["cash"]) + base_cost - effective_cost
    var before: int = level
    super._upgrade_chips()
    if int(player["chip_level"]) > before:
        _feedback("Chip strategy advanced to %s for $%d. R&D culture multiplier: x%.3f." % [String(names[level]), int(effective_cost), _research_cost_multiplier()])

func _sign_partner(partner_idx: int) -> void:
    if player_personality.is_empty():
        super._sign_partner(partner_idx)
        return
    var partner: Dictionary = PARTNERS[partner_idx]
    var partner_id: String = String(partner["id"])
    if signed_partners.has(partner_id):
        _feedback("That partnership is already active.")
        return
    var base_cost: float = float(partner["cost"])
    var effective_cost: float = base_cost * _partner_cost_multiplier()
    if float(player["cash"]) < effective_cost:
        _feedback("Need $%d to sign %s after reputation effects." % [int(effective_cost), String(partner["name"])])
        return
    player["cash"] = float(player["cash"]) + base_cost - effective_cost
    var before: int = signed_partners.size()
    super._sign_partner(partner_idx)
    if signed_partners.size() > before:
        _feedback("DEAL SIGNED with %s for $%d. Reputation multiplier: x%.3f. %s" % [String(partner["name"]), int(effective_cost), _partner_cost_multiplier(), String(partner["boost"])])

func _merge_rival(rival_idx: int) -> void:
    if player_personality.is_empty():
        super._merge_rival(rival_idx)
        return
    if merger_used:
        super._merge_rival(rival_idx)
        return
    var rival: Dictionary = rivals[rival_idx]
    if bool(rival["merged"]):
        super._merge_rival(rival_idx)
        return
    var rival_assets: float = float(rival["cash"]) + float(rival["sats"]) / SATS_PER_BTC * btc_price + float(rival["mw"]) * 90000.0 + float(rival["acres"]) * land_price_per_acre + float(rival["machines"]) * 700.0
    if rival_assets > _asset_value() * 1.25:
        super._merge_rival(rival_idx)
        return
    var base_price: float = maxf(100000.0, rival_assets * 0.70)
    var effective_price: float = base_price * _merger_cost_multiplier()
    if float(player["cash"]) < effective_price:
        _feedback("Need $%d cash to close this merger after negotiation effects." % int(effective_price))
        return
    player["cash"] = float(player["cash"]) + base_price - effective_price
    super._merge_rival(rival_idx)
    if bool(rivals[rival_idx]["merged"]):
        _feedback("ONE-TIME MERGER CLOSED: %s joined your company for $%d. Negotiation multiplier: x%.3f." % [String(rival["name"]), int(effective_price), _merger_cost_multiplier()])

func _open_hq(entity: Dictionary) -> void:
    super._open_hq(entity)
    if not player_personality.is_empty():
        dialog_text.text += "\n\nLIVE GAMEPLAY EFFECTS\n" + _culture_effects_summary()

func _open_machine_shop(entity: Dictionary) -> void:
    super._open_machine_shop(entity)
    if not player_personality.is_empty():
        var machine: Dictionary = MACHINES[int(player["machine_tier"])]
        var discount: float = clampf(float(player["machine_discount"]), 0.0, 0.25)
        var base_cost: float = float(machine["price"]) * 10.0 * (1.0 - discount)
        dialog_text.text += "\nCulture-adjusted 10-machine cost: $%d (x%.3f)." % [int(base_cost * _expansion_cost_multiplier()), _expansion_cost_multiplier()]

func _open_power_office(entity: Dictionary) -> void:
    super._open_power_office(entity)
    if not player_personality.is_empty():
        var base_cost: float = (26000.0 + float(player["mw"]) * 42000.0) * (1.0 - clampf(float(player["power_capex_discount"]), 0.0, 0.30))
        dialog_text.text += "\nCulture-adjusted +0.25 MW cost: $%d (x%.3f)." % [int(base_cost * _expansion_cost_multiplier()), _expansion_cost_multiplier()]

func _open_land_market(entity: Dictionary) -> void:
    super._open_land_market(entity)
    if not player_personality.is_empty():
        var discount: float = clampf(float(player["land_discount"]), 0.0, 0.35)
        var base_cost: float = land_price_per_acre * 5.0 * (1.0 - discount) + 5000.0
        dialog_text.text += "\nCulture-adjusted parcel cost: $%d (x%.3f)." % [int(base_cost * _expansion_cost_multiplier()), _expansion_cost_multiplier()]

func _open_bank(entity: Dictionary) -> void:
    super._open_bank(entity)
    if not player_personality.is_empty():
        dialog_text.text += "\nTreasury + reputation loan-rate adjustment: %s percentage points." % _signed_points(_financing_rate_adjustment() * 100.0)

func _open_partner(entity: Dictionary) -> void:
    super._open_partner(entity)
    if player_personality.is_empty():
        return
    var partner_idx: int = int(entity["partner_idx"])
    var partner: Dictionary = PARTNERS[partner_idx]
    if not signed_partners.has(String(partner["id"])):
        dialog_text.text += "\nReputation-adjusted deal cost: $%d (x%.3f)." % [int(float(partner["cost"]) * _partner_cost_multiplier()), _partner_cost_multiplier()]

func _open_partner_rep(entity: Dictionary) -> void:
    super._open_partner_rep(entity)
    if player_personality.is_empty():
        return
    var partner_idx: int = int(entity["partner_idx"])
    var partner: Dictionary = PARTNERS[partner_idx]
    if not signed_partners.has(String(partner["id"])):
        dialog_text.text += "\nReputation-adjusted deal cost: $%d (x%.3f)." % [int(float(partner["cost"]) * _partner_cost_multiplier()), _partner_cost_multiplier()]

func debug_culture_effects_ready() -> bool:
    if player_personality.is_empty():
        return false
    return (
        _partner_cost_multiplier() >= 0.88 and _partner_cost_multiplier() <= 1.12
        and _research_cost_multiplier() >= 0.88 and _research_cost_multiplier() <= 1.12
        and _expansion_cost_multiplier() >= 0.90 and _expansion_cost_multiplier() <= 1.12
        and _merger_cost_multiplier() >= 0.92 and _merger_cost_multiplier() <= 1.08
        and absf(_operations_uptime_bonus()) <= 0.0121
        and absf(_financing_rate_adjustment()) <= 0.0126
    )

func debug_culture_effects_are_material() -> bool:
    if player_personality.is_empty():
        return false
    return (
        absf(_operations_uptime_bonus()) > 0.0001
        or absf(_financing_rate_adjustment()) > 0.0001
        or absf(_partner_cost_multiplier() - 1.0) > 0.0001
        or absf(_research_cost_multiplier() - 1.0) > 0.0001
        or absf(_expansion_cost_multiplier() - 1.0) > 0.0001
        or absf(_merger_cost_multiplier() - 1.0) > 0.0001
    )

func debug_culture_effects_summary() -> String:
    return _culture_effects_summary()
