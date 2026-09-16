extends "res://scripts/world_time_scale.gd"

# Dynamic mining-company identity layer.
# Each company starts from a fictional history plus 0-100 culture ratings.
# Those ratings are not fixed classes: time and decisions can move them, and
# rival AI uses the live ratings to choose expansion, R&D, infrastructure,
# treasury discipline, partnerships, and risk-taking.

const CULTURE_MONTH_DAYS: float = 30.4375

var player_personality: Dictionary = {}
var player_culture_days: float = 0.0
var company_news: String = "No new company controversy."

func _ready() -> void:
    super._ready()
    _initialize_personality_runtime()
    _refresh_ui()

func _initialize_personality_runtime() -> void:
    var player_profile: Dictionary = Profiles.PROFILES[company_idx]
    player_personality = _new_personality(player_profile)
    player_personality["last_cash"] = float(player["cash"])
    player_personality["last_machines"] = int(player["machines"])
    player_personality["last_mw"] = float(player["mw"])
    player_personality["last_acres"] = float(player["acres"])
    player_personality["last_debt"] = float(player["debt"])
    player_personality["last_chip_level"] = int(player["chip_level"])
    player_personality["last_partners"] = signed_partners.size()
    player_personality["last_treasury_hold"] = float(player["treasury_hold"])
    player_personality["last_action"] = "Starting from its original operating template."
    player_personality["recent_controversy"] = "Historical controversy only."

    for i in range(rivals.size()):
        var rival: Dictionary = rivals[i]
        var profile: Dictionary = Profiles.PROFILES[int(rival["profile_idx"])]
        var personality: Dictionary = _new_personality(profile)
        personality["last_cash"] = float(rival["cash"])
        personality["last_action"] = "Starting from its original operating template."
        personality["recent_controversy"] = "Historical controversy only."
        rival["personality"] = personality
        rival["behavior_days"] = 0.0
        rival["tech_level"] = 0
        rival["partner"] = "None"
        rivals[i] = rival

func _new_personality(profile: Dictionary) -> Dictionary:
    return {
        "background": String(profile["background"]),
        "founding_controversy": String(profile["controversy"]),
        "affinity": String(profile["affinity"]),
        "aggression": int(profile["aggression"]),
        "risk": int(profile["risk"]),
        "growth": int(profile["growth"]),
        "research": int(profile["research"]),
        "treasury": int(profile["treasury"]),
        "operations": int(profile["operations"]),
        "reputation": int(profile["reputation"])
    }

func _clamp_rating(value: int) -> int:
    return clampi(value, 0, 100)

func _posture(personality: Dictionary) -> String:
    var pressure: int = int(round((float(personality["aggression"]) + float(personality["risk"])) / 2.0))
    if pressure >= 70:
        return "Aggressive"
    if pressure <= 38:
        return "Conservative"
    return "Moderate"

func _ratings_text(personality: Dictionary) -> String:
    return "AGG %d • RISK %d • GROW %d • R&D %d • TREAS %d • OPS %d • REP %d" % [
        int(personality["aggression"]), int(personality["risk"]), int(personality["growth"]),
        int(personality["research"]), int(personality["treasury"]), int(personality["operations"]),
        int(personality["reputation"])
    ]

func _evolve_player_culture(days: float) -> void:
    if player_personality.is_empty():
        return

    player_culture_days += days
    var months: int = int(floor(player_culture_days / CULTURE_MONTH_DAYS))
    if months <= 0:
        return
    player_culture_days -= float(months) * CULTURE_MONTH_DAYS
    var intensity: int = mini(months, 3)
    var action_parts: Array[String] = []

    var current_cash: float = float(player["cash"])
    var current_machines: int = int(player["machines"])
    var current_mw: float = float(player["mw"])
    var current_acres: float = float(player["acres"])
    var current_debt: float = float(player["debt"])
    var current_chip_level: int = int(player["chip_level"])
    var current_partners: int = signed_partners.size()
    var current_hold: float = float(player["treasury_hold"])

    if current_machines > int(player_personality["last_machines"]):
        player_personality["aggression"] = _clamp_rating(int(player_personality["aggression"]) + 2 * intensity)
        player_personality["growth"] = _clamp_rating(int(player_personality["growth"]) + 3 * intensity)
        action_parts.append("expanded the ASIC fleet")

    if current_mw > float(player_personality["last_mw"]) + 0.001 or current_acres > float(player_personality["last_acres"]) + 0.001:
        player_personality["growth"] = _clamp_rating(int(player_personality["growth"]) + 2 * intensity)
        player_personality["risk"] = _clamp_rating(int(player_personality["risk"]) + intensity)
        action_parts.append("committed capital to sites and power")

    if current_chip_level > int(player_personality["last_chip_level"]):
        player_personality["research"] = _clamp_rating(int(player_personality["research"]) + 4 * intensity)
        player_personality["operations"] = _clamp_rating(int(player_personality["operations"]) + intensity)
        action_parts.append("moved deeper into chip R&D")

    if current_debt > float(player_personality["last_debt"]) + 1000.0:
        player_personality["aggression"] = _clamp_rating(int(player_personality["aggression"]) + intensity)
        player_personality["risk"] = _clamp_rating(int(player_personality["risk"]) + 3 * intensity)
        player_personality["treasury"] = _clamp_rating(int(player_personality["treasury"]) - 2 * intensity)
        action_parts.append("used more leverage")
    elif current_debt + 1000.0 < float(player_personality["last_debt"]):
        player_personality["treasury"] = _clamp_rating(int(player_personality["treasury"]) + 3 * intensity)
        player_personality["risk"] = _clamp_rating(int(player_personality["risk"]) - intensity)
        action_parts.append("paid down debt")

    if current_partners > int(player_personality["last_partners"]):
        player_personality["reputation"] = _clamp_rating(int(player_personality["reputation"]) + 2 * intensity)
        player_personality["growth"] = _clamp_rating(int(player_personality["growth"]) + intensity)
        action_parts.append("expanded its partnership network")

    if current_hold > float(player_personality["last_treasury_hold"]) + 0.01:
        player_personality["treasury"] = _clamp_rating(int(player_personality["treasury"]) + 2 * intensity)
        player_personality["aggression"] = _clamp_rating(int(player_personality["aggression"]) - intensity)
        action_parts.append("raised its BTC hold policy")
    elif current_hold + 0.01 < float(player_personality["last_treasury_hold"]):
        player_personality["aggression"] = _clamp_rating(int(player_personality["aggression"]) + 2 * intensity)
        player_personality["risk"] = _clamp_rating(int(player_personality["risk"]) + intensity)
        action_parts.append("sold more production for immediate cash")

    if current_cash > float(player_personality["last_cash"]) * 1.08:
        player_personality["treasury"] = _clamp_rating(int(player_personality["treasury"]) + intensity)
    elif float(player["last_profit"]) < 0.0:
        player_personality["treasury"] = _clamp_rating(int(player_personality["treasury"]) + intensity)
        player_personality["operations"] = _clamp_rating(int(player_personality["operations"]) + intensity)
        player_personality["risk"] = _clamp_rating(int(player_personality["risk"]) - intensity)

    if action_parts.is_empty():
        player_personality["operations"] = _clamp_rating(int(player_personality["operations"]) + intensity)
        player_personality["treasury"] = _clamp_rating(int(player_personality["treasury"]) + intensity)
        player_personality["last_action"] = "Held the operating plan steady and emphasized execution."
    else:
        player_personality["last_action"] = ", ".join(action_parts).capitalize() + "."

    for _month in range(months):
        _maybe_player_controversy()

    player_personality["last_cash"] = current_cash
    player_personality["last_machines"] = current_machines
    player_personality["last_mw"] = current_mw
    player_personality["last_acres"] = current_acres
    player_personality["last_debt"] = current_debt
    player_personality["last_chip_level"] = current_chip_level
    player_personality["last_partners"] = current_partners
    player_personality["last_treasury_hold"] = current_hold

func _maybe_player_controversy() -> void:
    var chance: float = 0.004 + float(player_personality["risk"]) / 10000.0 + float(player_personality["aggression"]) / 20000.0
    if randf() >= chance:
        return

    var penalty: float = maxf(750.0, maxf(0.0, float(player["cash"])) * (0.01 + float(player_personality["risk"]) / 8000.0))
    var event_id: int = randi_range(0, 3)
    player["cash"] = float(player["cash"]) - penalty

    if event_id == 0:
        player_personality["recent_controversy"] = "A fast site expansion triggered a permitting and noise dispute."
        player_personality["reputation"] = _clamp_rating(int(player_personality["reputation"]) - 4)
        player_personality["operations"] = _clamp_rating(int(player_personality["operations"]) + 2)
    elif event_id == 1:
        player_personality["recent_controversy"] = "Investors challenged the company's financing and capital-allocation choices."
        player_personality["reputation"] = _clamp_rating(int(player_personality["reputation"]) - 3)
        player_personality["treasury"] = _clamp_rating(int(player_personality["treasury"]) + 2)
        player_personality["aggression"] = _clamp_rating(int(player_personality["aggression"]) - 1)
    elif event_id == 2:
        player_personality["recent_controversy"] = "A rushed firmware or equipment rollout caused downtime and a public rollback."
        player_personality["reputation"] = _clamp_rating(int(player_personality["reputation"]) - 2)
        player_personality["operations"] = _clamp_rating(int(player_personality["operations"]) + 3)
        player_personality["research"] = _clamp_rating(int(player_personality["research"]) + 1)
    else:
        player_personality["recent_controversy"] = "A local power-use dispute forced management to publish more operating data."
        player_personality["reputation"] = _clamp_rating(int(player_personality["reputation"]) - 2)
        player_personality["operations"] = _clamp_rating(int(player_personality["operations"]) + 2)

    company_news = "%s controversy: %s Cost about $%d." % [
        String(player["name"]), String(player_personality["recent_controversy"]), int(penalty)
    ]

func _simulate_rivals_scaled(days: float) -> void:
    _evolve_player_culture(days)
    var volatility_scale: float = sqrt(maxf(0.01, days / 91.3125))

    for i in range(rivals.size()):
        var rival: Dictionary = rivals[i]
        if bool(rival["merged"]):
            continue

        if not rival.has("personality"):
            var profile_fallback: Dictionary = Profiles.PROFILES[int(rival["profile_idx"])]
            rival["personality"] = _new_personality(profile_fallback)
            rival["personality"]["last_cash"] = float(rival["cash"])
            rival["personality"]["last_action"] = "Starting from its original operating template."
            rival["personality"]["recent_controversy"] = "Historical controversy only."
            rival["behavior_days"] = 0.0
            rival["tech_level"] = 0
            rival["partner"] = "None"

        var personality: Dictionary = rival["personality"]
        var risk: float = float(personality["risk"])
        var growth: float = float(personality["growth"])
        var operations: float = float(personality["operations"])
        var base_volatility: float = 0.025 + risk / 3000.0
        var operating_edge: float = (operations - 50.0) / 5000.0 + (growth - 50.0) / 8000.0
        var cash_return: float = randf_range(-base_volatility, base_volatility * 1.25) * volatility_scale + operating_edge * (days / 91.3125)
        rival["cash"] = float(rival["cash"]) * maxf(0.82, 1.0 + cash_return)

        rival["behavior_days"] = float(rival["behavior_days"]) + days
        while float(rival["behavior_days"]) >= CULTURE_MONTH_DAYS:
            _run_rival_month(rival)
            rival["behavior_days"] = float(rival["behavior_days"]) - CULTURE_MONTH_DAYS

        rivals[i] = rival

func _run_rival_month(rival: Dictionary) -> void:
    var personality: Dictionary = rival["personality"]
    var profitable: bool = float(rival["cash"]) >= float(personality["last_cash"])

    if profitable:
        personality["growth"] = _clamp_rating(int(personality["growth"]) + randi_range(0, 2))
        if int(personality["risk"]) >= 60:
            personality["aggression"] = _clamp_rating(int(personality["aggression"]) + 1)
        if randf() < 0.30:
            personality["reputation"] = _clamp_rating(int(personality["reputation"]) + 1)
    else:
        personality["treasury"] = _clamp_rating(int(personality["treasury"]) + 2)
        personality["operations"] = _clamp_rating(int(personality["operations"]) + 1)
        personality["risk"] = _clamp_rating(int(personality["risk"]) - 1)
        personality["aggression"] = _clamp_rating(int(personality["aggression"]) - 1)

    var expansion_score: float = float(personality["growth"]) * 0.46 + float(personality["aggression"]) * 0.34 + float(personality["risk"]) * 0.20 + randf_range(0.0, 8.0)
    var research_score: float = float(personality["research"]) * 0.58 + float(personality["operations"]) * 0.22 + float(personality["reputation"]) * 0.20 + randf_range(0.0, 8.0)
    var infrastructure_score: float = float(personality["operations"]) * 0.42 + float(personality["growth"]) * 0.32 + float(personality["treasury"]) * 0.26 + randf_range(0.0, 8.0)
    var discipline_score: float = float(personality["treasury"]) * 0.58 + float(personality["operations"]) * 0.28 + float(100 - int(personality["risk"])) * 0.14 + randf_range(0.0, 8.0)

    var reserve_ratio: float = minf(0.55, 0.12 + float(personality["treasury"]) / 250.0)
    var reserve: float = maxf(12000.0, float(rival["cash"]) * reserve_ratio)
    var available: float = maxf(0.0, float(rival["cash"]) - reserve)

    if expansion_score >= research_score and expansion_score >= infrastructure_score and expansion_score >= discipline_score and available > 2500.0:
        var spend: float = minf(available, maxf(1500.0, float(rival["cash"]) * (0.025 + float(personality["growth"]) / 2200.0 + float(personality["aggression"]) / 3200.0)))
        var machines_bought: int = clampi(maxi(1, int(round(spend / 900.0))), 1, 24)
        rival["cash"] = float(rival["cash"]) - spend
        rival["machines"] = int(rival["machines"]) + machines_bought
        personality["aggression"] = _clamp_rating(int(personality["aggression"]) + 1)
        personality["growth"] = _clamp_rating(int(personality["growth"]) + 1)
        personality["treasury"] = _clamp_rating(int(personality["treasury"]) - 1)
        personality["last_action"] = "Bought %d miners and accepted a smaller cash cushion." % machines_bought
    elif research_score >= infrastructure_score and research_score >= discipline_score and available > 1500.0:
        var spend: float = minf(available, maxf(1000.0, float(rival["cash"]) * (0.012 + float(personality["research"]) / 4500.0)))
        rival["cash"] = float(rival["cash"]) - spend
        rival["tech_level"] = int(rival["tech_level"]) + 1
        personality["research"] = _clamp_rating(int(personality["research"]) + 1)
        personality["operations"] = _clamp_rating(int(personality["operations"]) + 1)
        personality["last_action"] = "Funded an efficiency and ASIC research cycle instead of maximizing fleet growth."
    elif infrastructure_score >= discipline_score and available > 5000.0:
        var add_power: bool = float(rival["mw"]) < float(rival["machines"]) * 0.006
        if add_power:
            rival["cash"] = float(rival["cash"]) - minf(available, 9000.0)
            rival["mw"] = float(rival["mw"]) + 0.25
            personality["last_action"] = "Added 0.25 MW so future fleet growth has energized capacity."
        else:
            rival["cash"] = float(rival["cash"]) - minf(available, 6500.0)
            rival["acres"] = float(rival["acres"]) + 5.0
            personality["last_action"] = "Bought 5 acres for a future mining-site expansion."
        personality["growth"] = _clamp_rating(int(personality["growth"]) + 1)
        personality["operations"] = _clamp_rating(int(personality["operations"]) + 1)
    else:
        var savings: float = maxf(100.0, float(rival["machines"]) * 8.0)
        rival["cash"] = float(rival["cash"]) + savings
        personality["treasury"] = _clamp_rating(int(personality["treasury"]) + 1)
        personality["operations"] = _clamp_rating(int(personality["operations"]) + 1)
        personality["last_action"] = "Protected cash and squeezed more savings from existing operations."

    _maybe_rival_partnership(rival)
    _maybe_rival_controversy(rival)
    personality["last_cash"] = float(rival["cash"])
    rival["personality"] = personality

func _maybe_rival_partnership(rival: Dictionary) -> void:
    if String(rival["partner"]) != "None":
        return
    var personality: Dictionary = rival["personality"]
    var chance: float = 0.008 + float(personality["reputation"] + personality["growth"]) / 12000.0
    if randf() >= chance:
        return

    var affinity: String = String(personality["affinity"])
    rival["partner"] = affinity
    if affinity == "Energy":
        rival["cash"] = float(rival["cash"]) + 3000.0
        personality["treasury"] = _clamp_rating(int(personality["treasury"]) + 2)
    elif affinity == "Semiconductor":
        rival["tech_level"] = int(rival["tech_level"]) + 1
        personality["research"] = _clamp_rating(int(personality["research"]) + 2)
    elif affinity == "Infrastructure":
        rival["mw"] = float(rival["mw"]) + 0.25
        personality["growth"] = _clamp_rating(int(personality["growth"]) + 2)
    elif affinity == "Finance":
        rival["cash"] = float(rival["cash"]) + 8000.0
        personality["growth"] = _clamp_rating(int(personality["growth"]) + 1)
    elif affinity == "Real Estate":
        rival["acres"] = float(rival["acres"]) + 5.0
        personality["treasury"] = _clamp_rating(int(personality["treasury"]) + 1)
    elif affinity == "Telecom":
        personality["operations"] = _clamp_rating(int(personality["operations"]) + 2)
        personality["reputation"] = _clamp_rating(int(personality["reputation"]) + 1)

    personality["reputation"] = _clamp_rating(int(personality["reputation"]) + 1)
    personality["last_action"] = "Signed a %s partnership that changed its operating plan." % affinity
    rival["personality"] = personality

func _maybe_rival_controversy(rival: Dictionary) -> void:
    var personality: Dictionary = rival["personality"]
    var chance: float = 0.004 + float(personality["risk"]) / 10000.0 + float(personality["aggression"]) / 20000.0
    if randf() >= chance:
        return

    var penalty: float = maxf(1200.0, maxf(0.0, float(rival["cash"])) * (0.01 + float(personality["risk"]) / 8000.0))
    rival["cash"] = float(rival["cash"]) - penalty
    var event_id: int = randi_range(0, 3)

    if event_id == 0:
        personality["recent_controversy"] = "A fast site expansion triggered a permitting and noise dispute."
        personality["reputation"] = _clamp_rating(int(personality["reputation"]) - 4)
        personality["operations"] = _clamp_rating(int(personality["operations"]) + 2)
    elif event_id == 1:
        personality["recent_controversy"] = "Investors challenged the company's financing and capital-allocation choices."
        personality["reputation"] = _clamp_rating(int(personality["reputation"]) - 3)
        personality["treasury"] = _clamp_rating(int(personality["treasury"]) + 3)
        personality["aggression"] = _clamp_rating(int(personality["aggression"]) - 2)
    elif event_id == 2:
        personality["recent_controversy"] = "A rushed deployment caused downtime and forced a public rollback."
        personality["reputation"] = _clamp_rating(int(personality["reputation"]) - 2)
        personality["operations"] = _clamp_rating(int(personality["operations"]) + 3)
        personality["research"] = _clamp_rating(int(personality["research"]) + 1)
    else:
        personality["recent_controversy"] = "A local power-use dispute forced management to publish more operating data."
        personality["reputation"] = _clamp_rating(int(personality["reputation"]) - 2)
        personality["operations"] = _clamp_rating(int(personality["operations"]) + 2)
        personality["treasury"] = _clamp_rating(int(personality["treasury"]) + 1)

    company_news = "%s controversy: %s Cost about $%d." % [
        String(rival["name"]), String(personality["recent_controversy"]), int(penalty)
    ]
    rival["personality"] = personality

func _open_hq(entity: Dictionary) -> void:
    dialog_title.text = String(entity["name"]) + " // YOUR HQ"
    if player_personality.is_empty():
        super._open_hq(entity)
        return
    dialog_text.text = "BACKGROUND: %s\n\nFOUNDING CONTROVERSY: %s\n\nCURRENT CULTURE: %s\n%s\nCurrent action: %s\nRecent controversy: %s\n\nStarting strength: %s" % [
        String(player_personality["background"]), String(player_personality["founding_controversy"]),
        _posture(player_personality), _ratings_text(player_personality),
        String(player_personality["last_action"]), String(player_personality["recent_controversy"]),
        String(player["strengths"])
    ]
    _set_actions([
        {"label":"TREASURY HOLD", "call":Callable(self, "_cycle_treasury")},
        {"label":"UPGRADE COOLING", "call":Callable(self, "_upgrade_cooling")},
        {"label":"UPGRADE CHIPS", "call":Callable(self, "_upgrade_chips")}
    ])

func _open_rival(entity: Dictionary) -> void:
    var rival_idx: int = int(entity["rival_idx"])
    var rival: Dictionary = rivals[rival_idx]
    dialog_title.text = String(rival["name"]) + " // MINING RIVAL"
    if bool(rival["merged"]):
        dialog_text.text = "This mining company has already been absorbed into your company."
        _set_actions([])
        return

    var personality: Dictionary = rival["personality"]
    dialog_text.text = "BACKGROUND: %s\n\nFOUNDING CONTROVERSY: %s\n\nCURRENT CULTURE: %s\n%s\nCurrent action: %s\nRecent controversy: %s\nPartner: %s • Tech cycles: %d\n\nMachines %d • %.2f MW • %.1f acres • Cash $%d." % [
        String(personality["background"]), String(personality["founding_controversy"]),
        _posture(personality), _ratings_text(personality),
        String(personality["last_action"]), String(personality["recent_controversy"]),
        String(rival["partner"]), int(rival["tech_level"]),
        int(rival["machines"]), float(rival["mw"]), float(rival["acres"]), int(rival["cash"])
    ]
    if merger_used:
        _set_actions([])
    else:
        _set_actions([{"label":"ATTEMPT ONE-TIME MERGER", "call":Callable(self, "_merge_rival").bind(rival_idx)}])

func _refresh_ui() -> void:
    super._refresh_ui()
    if player_personality.is_empty() or not is_instance_valid(company_stats):
        return

    company_stats.text += "\n\nCulture: %s\nAGG %d  RISK %d  GROW %d  R&D %d\nTREAS %d  OPS %d  REP %d" % [
        _posture(player_personality),
        int(player_personality["aggression"]), int(player_personality["risk"]),
        int(player_personality["growth"]), int(player_personality["research"]),
        int(player_personality["treasury"]), int(player_personality["operations"]),
        int(player_personality["reputation"])
    ]
    if is_instance_valid(market_label) and company_news != "No new company controversy.":
        market_label.text += "  •  COMPANY NEWS: " + company_news

func debug_company_personality_ready() -> bool:
    return not player_personality.is_empty() and player_personality.has("aggression") and player_personality.has("reputation")

func debug_rival_personality_count() -> int:
    var count: int = 0
    for rival in rivals:
        if rival.has("personality"):
            count += 1
    return count

func debug_personality_ratings_in_range() -> bool:
    if player_personality.is_empty():
        return false
    for key in ["aggression", "risk", "growth", "research", "treasury", "operations", "reputation"]:
        var value: int = int(player_personality[key])
        if value < 0 or value > 100:
            return false
    for rival in rivals:
        if not rival.has("personality"):
            return false
        var personality: Dictionary = rival["personality"]
        for key in ["aggression", "risk", "growth", "research", "treasury", "operations", "reputation"]:
            var value: int = int(personality[key])
            if value < 0 or value > 100:
                return false
    return true
