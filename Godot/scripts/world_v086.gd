extends "res://scripts/world_v085.gd"

# Hash Race v0.086 computer-company offer layer.
# Computer hardware companies exist in the external NPC economy, not the mining
# league. They can proactively open supplier negotiations during normal play
# on a randomized real-time cadence, independent of turn settlement.

const V086_COMPUTER_OFFER_REVISION: int = 1
const COMPUTER_OFFER_INITIAL_MIN_SECONDS: float = 45.0
const COMPUTER_OFFER_INITIAL_MAX_SECONDS: float = 110.0
const COMPUTER_OFFER_REPEAT_MIN_SECONDS: float = 90.0
const COMPUTER_OFFER_REPEAT_MAX_SECONDS: float = 210.0

const COMPUTER_DEAL_COMPANIES: Array = [
    {
        "id":"cedarline",
        "name":"Cedarline Computer Systems",
        "rep":"Mara Vale",
        "sector":"COMPUTER HARDWARE",
        "base_cost":48000.0,
        "machines":8,
        "efficiency_bonus":0.005,
        "power":48,
        "greed":36
    },
    {
        "id":"voltamesh",
        "name":"VoltaMesh Computing",
        "rep":"Dorian Pike",
        "sector":"COMPUTE SYSTEMS",
        "base_cost":72000.0,
        "machines":12,
        "efficiency_bonus":0.010,
        "power":58,
        "greed":44
    },
    {
        "id":"northbridge",
        "name":"Northbridge Server Works",
        "rep":"Sera Quinn",
        "sector":"SERVER SYSTEMS",
        "base_cost":98000.0,
        "machines":16,
        "efficiency_bonus":0.015,
        "power":66,
        "greed":52
    }
]

var computer_offer_elapsed_seconds: float = 0.0
var computer_offer_next_seconds: float = COMPUTER_OFFER_INITIAL_MIN_SECONDS
var computer_offer_count: int = 0
var computer_offer_last_company: String = ""

func _ready() -> void:
    super._ready()
    _schedule_next_computer_offer(true)
    set_meta("hashrace_computer_offer_revision", V086_COMPUTER_OFFER_REVISION)

func _process(delta: float) -> void:
    super._process(delta)
    if campaign_complete or player.is_empty():
        return

    computer_offer_elapsed_seconds += maxf(0.0, delta)
    if computer_offer_elapsed_seconds < computer_offer_next_seconds:
        return

    if _negotiation_is_active():
        _schedule_next_computer_offer(false)
        return

    _launch_computer_company_offer()
    _schedule_next_computer_offer(false)

func _schedule_next_computer_offer(initial_offer: bool) -> void:
    computer_offer_elapsed_seconds = 0.0
    if initial_offer:
        computer_offer_next_seconds = randf_range(COMPUTER_OFFER_INITIAL_MIN_SECONDS, COMPUTER_OFFER_INITIAL_MAX_SECONDS)
    else:
        computer_offer_next_seconds = randf_range(COMPUTER_OFFER_REPEAT_MIN_SECONDS, COMPUTER_OFFER_REPEAT_MAX_SECONDS)

func _negotiation_is_active() -> bool:
    if not is_instance_valid(negotiation_manager):
        return false
    var active: Variant = negotiation_manager.get("active_scene")
    return active is Node and is_instance_valid(active)

func _player_offer_profile() -> Dictionary:
    var reputation: int = 50
    var leverage: int = 50
    if not player_personality.is_empty():
        reputation = clampi(int(player_personality.get("reputation", 50)), 0, 100)
        var ops: float = float(player_personality.get("operations", 50))
        var treasury: float = float(player_personality.get("treasury", 50))
        var growth: float = float(player_personality.get("growth", 50))
        leverage = clampi(int(roundf(ops * 0.40 + treasury * 0.35 + growth * 0.25)), 0, 100)
    return {"reputation":reputation, "leverage":leverage}

func _launch_computer_company_offer(company_index: int = -1) -> Node:
    if not is_instance_valid(negotiation_manager):
        _install_negotiation_manager()
    if not is_instance_valid(negotiation_manager) or _negotiation_is_active():
        return null
    if COMPUTER_DEAL_COMPANIES.is_empty():
        return null

    var idx: int = company_index
    if idx < 0 or idx >= COMPUTER_DEAL_COMPANIES.size():
        idx = randi_range(0, COMPUTER_DEAL_COMPANIES.size() - 1)

    var supplier: Dictionary = COMPUTER_DEAL_COMPANIES[idx]
    var profile: Dictionary = _player_offer_profile()
    var progression_scale: float = clampf(0.90 + float(maxi(0, turn - 1)) * 0.015, 0.90, 1.35)
    var deal_value: float = roundf(float(supplier["base_cost"]) * progression_scale / 100.0) * 100.0
    var reward_machines: int = int(supplier["machines"])
    var efficiency_bonus: float = float(supplier["efficiency_bonus"])

    var context: Dictionary = {
        "deal_type":"computer_supply",
        "source_kind":"computer_company",
        "computer_company_id":String(supplier["id"]),
        "rival_idx":-1,
        "opponent_name":String(supplier["rep"]),
        "opponent_company":String(supplier["name"]),
        "player_company":String(player.get("name", "Player Mining Co.")),
        "opponent_power":int(supplier["power"]),
        "opponent_greed":int(supplier["greed"]),
        "player_reputation":int(profile["reputation"]),
        "player_leverage":int(profile["leverage"]),
        "deal_value_usd":deal_value,
        "player_cash_usd":maxf(0.0, float(player.get("cash", 0.0))),
        "reward_mw":0.0,
        "reward_machines":reward_machines,
        "reward_efficiency_bonus":efficiency_bonus,
        "deal_label":"COMPUTER COMPANY SUPPLY OFFER",
        "target_asset_label":"%d CURRENT-GEN MACHINES + %.1f%% FLEET EFFICIENCY" % [reward_machines, efficiency_bonus * 100.0]
    }

    computer_offer_count += 1
    computer_offer_last_company = String(supplier["name"])
    company_news = "%s contacted your company with a live computer-hardware offer." % computer_offer_last_company
    _feedback(company_news)
    return negotiation_manager.call("launch", self, context) as Node

func _on_negotiation_resolved(result: Dictionary) -> void:
    if String(result.get("deal_type", "rival_capacity")) != "computer_supply":
        super._on_negotiation_resolved(result)
        return

    negotiation_last_result = result.duplicate(true)

    var rep_delta: int = int(result.get("reputation_delta", 0))
    if not player_personality.is_empty() and rep_delta != 0:
        player_personality["reputation"] = clampi(int(player_personality.get("reputation", 50)) + rep_delta, 0, 100)

    var supplier_name: String = String(result.get("opponent_company", "computer supplier"))
    if not bool(result.get("success", false)):
        company_news = "Computer-company negotiation with %s ended without a deal." % supplier_name
        _feedback(company_news)
        _refresh_ui()
        return

    var final_cost: float = maxf(0.0, float(result.get("final_cost_usd", 0.0)))
    if float(player.get("cash", 0.0)) < final_cost:
        company_news = "%s accepted the terms, but available cash was no longer sufficient to close." % supplier_name
        _feedback(company_news)
        _refresh_ui()
        return

    var reward_machines: int = maxi(0, int(result.get("reward_machines", 0)))
    var efficiency_bonus: float = maxf(0.0, float(result.get("reward_efficiency_bonus", 0.0)))

    player["cash"] = float(player.get("cash", 0.0)) - final_cost
    player["machines"] = int(player.get("machines", 0)) + reward_machines
    player["machine_efficiency_bonus"] = clampf(
        float(player.get("machine_efficiency_bonus", 0.0)) + efficiency_bonus,
        0.0,
        0.20
    )

    company_news = "COMPUTER DEAL CLOSED with %s: +%d current-gen machines and +%.1f%% fleet efficiency for $%d." % [
        supplier_name,
        reward_machines,
        efficiency_bonus * 100.0,
        int(roundf(final_cost))
    ]
    _feedback(company_news)
    _refresh_ui()

func debug_launch_computer_offer(company_index: int = 0) -> Node:
    return _launch_computer_company_offer(company_index)

func debug_computer_offer_ready() -> bool:
    return (
        V086_COMPUTER_OFFER_REVISION == 1
        and COMPUTER_DEAL_COMPANIES.size() >= 3
        and COMPUTER_OFFER_INITIAL_MIN_SECONDS > 0.0
        and COMPUTER_OFFER_REPEAT_MIN_SECONDS > COMPUTER_OFFER_INITIAL_MIN_SECONDS
        and has_method("_launch_computer_company_offer")
    )

func debug_computer_offer_snapshot() -> Dictionary:
    return {
        "count":computer_offer_count,
        "last_company":computer_offer_last_company,
        "elapsed_seconds":computer_offer_elapsed_seconds,
        "next_seconds":computer_offer_next_seconds,
        "companies":COMPUTER_DEAL_COMPANIES.size()
    }
