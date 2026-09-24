extends "res://scripts/world_v070.gd"

# Hash Race v0.072 negotiation-scene layer.
# Adds a battle-style negotiation overlay without replacing the existing
# mining simulation, town interactions, one-time merger logic, or live HUD.

const NegotiationManager = preload("res://systems/negotiation_manager.gd")
const V072_NEGOTIATION_REVISION: int = 1

var negotiation_manager: Node = null
var negotiation_last_result: Dictionary = {}

func _ready() -> void:
    super._ready()
    _install_negotiation_manager()
    set_meta("hashrace_negotiation_revision", V072_NEGOTIATION_REVISION)

func _install_negotiation_manager() -> void:
    if is_instance_valid(negotiation_manager):
        return
    negotiation_manager = NegotiationManager.new()
    negotiation_manager.name = "NegotiationManager"
    add_child(negotiation_manager)
    negotiation_manager.connect("negotiation_resolved", Callable(self, "_on_negotiation_resolved"))

func _open_rival(entity: Dictionary) -> void:
    super._open_rival(entity)
    var rival_idx: int = int(entity.get("rival_idx", -1))
    if rival_idx < 0 or rival_idx >= rivals.size():
        return
    var rival: Dictionary = rivals[rival_idx]
    if bool(rival.get("merged", false)):
        return

    var actions: Array = [
        {"label":"NEGOTIATE ACCESS DEAL", "call":Callable(self, "start_negotiation").bind(rival_idx)}
    ]
    if not merger_used:
        actions.append({"label":"ATTEMPT ONE-TIME MERGER", "call":Callable(self, "_merge_rival").bind(rival_idx)})
    _set_actions(actions)

func _open_rival_rep(entity: Dictionary) -> void:
    super._open_rival_rep(entity)
    var rival_idx: int = int(entity.get("rival_idx", -1))
    if rival_idx < 0 or rival_idx >= rivals.size():
        return
    var rival: Dictionary = rivals[rival_idx]
    if bool(rival.get("merged", false)):
        return

    var actions: Array = [
        {"label":"VIEW RIVAL COMPANY", "call":Callable(self, "_open_rival").bind(entity)},
        {"label":"NEGOTIATE ACCESS DEAL", "call":Callable(self, "start_negotiation").bind(rival_idx)}
    ]
    if not merger_used:
        actions.append({"label":"PROPOSE MERGER", "call":Callable(self, "_merge_rival").bind(rival_idx)})
    _set_actions(actions)

func start_negotiation(opponent: Variant) -> Node:
    if not is_instance_valid(negotiation_manager):
        _install_negotiation_manager()
    if not is_instance_valid(negotiation_manager):
        return null

    var rival_idx: int = _resolve_rival_index(opponent)
    if rival_idx < 0 or rival_idx >= rivals.size():
        _feedback("Negotiation target could not be resolved.")
        return null

    var rival: Dictionary = rivals[rival_idx]
    if bool(rival.get("merged", false)):
        _feedback("That company is already part of your organization.")
        return null

    var personality_variant: Variant = rival.get("personality", {})
    var personality: Dictionary = {}
    if personality_variant is Dictionary:
        personality = personality_variant

    var player_rep: int = 50
    var player_leverage: int = 50
    if not player_personality.is_empty():
        player_rep = clampi(int(player_personality.get("reputation", 50)), 0, 100)
        var ops: float = float(player_personality.get("operations", 50))
        var treasury: float = float(player_personality.get("treasury", 50))
        var growth: float = float(player_personality.get("growth", 50))
        player_leverage = clampi(int(roundf(ops * 0.40 + treasury * 0.35 + growth * 0.25)), 0, 100)

    var rival_power: int = clampi(int(roundf(
        float(personality.get("operations", 50)) * 0.42
        + float(personality.get("reputation", 50)) * 0.33
        + float(personality.get("treasury", 50)) * 0.25
    )), 0, 100)
    var rival_greed: int = clampi(int(roundf(
        float(personality.get("aggression", 50)) * 0.40
        + float(personality.get("growth", 50)) * 0.34
        + float(personality.get("risk", 50)) * 0.26
    )), 0, 100)

    var rival_cash: float = maxf(0.0, float(rival.get("cash", 0.0)))
    var deal_value: float = clampf(4500.0 + rival_cash * 0.0125, 4500.0, 18000.0)
    var reward_capacity_mw: float = clampf(0.05 + float(int(rival.get("tech_level", 0))) * 0.01, 0.05, 0.10)

    var context: Dictionary = {
        "rival_idx": rival_idx,
        "opponent_name": String(rival.get("name", "Rival Miner")),
        "opponent_company": String(rival.get("name", "Rival Mining Co.")),
        "player_company": String(player.get("name", "Player Mining Co.")),
        "opponent_power": rival_power,
        "opponent_greed": rival_greed,
        "player_reputation": player_rep,
        "player_leverage": player_leverage,
        "deal_value_usd": deal_value,
        "player_cash_usd": maxf(0.0, float(player.get("cash", 0.0))),
        "reward_mw": reward_capacity_mw,
        "deal_label": "SHARED POWER CAPACITY",
        "target_asset_label": "%.2f MW FLEX CAPACITY" % reward_capacity_mw
    }
    return negotiation_manager.call("launch", self, context) as Node

func _resolve_rival_index(opponent: Variant) -> int:
    if opponent is int:
        return int(opponent)
    var target_name: String = String(opponent)
    for i in range(rivals.size()):
        var rival: Dictionary = rivals[i]
        if String(rival.get("name", "")) == target_name:
            return i
    return -1

func _on_negotiation_resolved(result: Dictionary) -> void:
    negotiation_last_result = result.duplicate(true)
    var rival_idx: int = int(result.get("rival_idx", -1))
    if rival_idx < 0 or rival_idx >= rivals.size():
        return

    var rep_delta: int = int(result.get("reputation_delta", 0))
    if not player_personality.is_empty() and rep_delta != 0:
        player_personality["reputation"] = clampi(int(player_personality.get("reputation", 50)) + rep_delta, 0, 100)

    if not bool(result.get("success", false)):
        company_news = "Negotiation with %s ended without a deal." % String(result.get("opponent_company", "a rival"))
        _feedback(company_news)
        _refresh_ui()
        return

    var final_cost: float = maxf(0.0, float(result.get("final_cost_usd", 0.0)))
    var reward_capacity_mw: float = maxf(0.0, float(result.get("reward_mw", 0.0)))
    if float(player.get("cash", 0.0)) < final_cost:
        company_news = "Negotiation terms were agreed, but available cash was no longer sufficient to close."
        _feedback(company_news)
        _refresh_ui()
        return

    var rival: Dictionary = rivals[rival_idx]
    player["cash"] = float(player.get("cash", 0.0)) - final_cost
    player["mw"] = float(player.get("mw", 0.0)) + reward_capacity_mw
    rival["cash"] = float(rival.get("cash", 0.0)) + final_cost
    rivals[rival_idx] = rival

    company_news = "DEAL CLOSED with %s: %.2f MW flexible capacity for $%d." % [
        String(rival.get("name", "rival")),
        reward_capacity_mw,
        int(roundf(final_cost))
    ]
    _feedback(company_news)
    _refresh_ui()

func debug_negotiation_ready() -> bool:
    return (
        V072_NEGOTIATION_REVISION == 1
        and is_instance_valid(negotiation_manager)
        and bool(negotiation_manager.call("debug_ready"))
    )

func debug_negotiation_snapshot() -> Dictionary:
    if not is_instance_valid(negotiation_manager):
        return {}
    return negotiation_manager.call("debug_snapshot")

func debug_v072_ready() -> bool:
    return debug_v070_ready() and debug_negotiation_ready()
