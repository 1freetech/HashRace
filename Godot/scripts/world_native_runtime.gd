extends "res://scripts/world_pixel_landscape.gd"

# Hash Race v0.046 native authority layer.
# C++ owns economic/gameplay state. GDScript above this layer renders, accepts
# input, runs presentation-oriented policy logic, and mirrors native snapshots.

const NATIVE_RUNTIME_CLASS: StringName = &"HashRaceRuntime"
const NATIVE_RUNTIME_REVISION := "v0.046-cpp-authoritative"

var native_runtime: Object
var native_runtime_ready: bool = false

func _ready() -> void:
    super._ready()
    assert(ClassDB.class_exists(NATIVE_RUNTIME_CLASS), "HashRaceRuntime GDExtension is required. Build the C++ extension before launching Hash Race.")
    native_runtime = ClassDB.instantiate(NATIVE_RUNTIME_CLASS)
    assert(native_runtime != null, "HashRaceRuntime could not be instantiated.")
    var market := _native_market_dictionary()
    var boot: Dictionary = native_runtime.call(
        "bootstrap",
        player,
        rivals,
        market,
        signed_partners,
        merger_used,
        elapsed_campaign_days,
        next_halving_day,
        campaign_years
    )
    assert(bool(boot.get("ok", false)), String(boot.get("message", "C++ runtime bootstrap failed.")))
    native_runtime_ready = true
    _native_push_culture_effects()
    _native_sync_from_cpp()
    set_meta("hashrace_native_runtime", true)
    set_meta("hashrace_native_runtime_revision", String(native_runtime.call("runtime_revision")))
    set_meta("hashrace_native_state_authority", "C++")
    _refresh_ui()

func _native_market_dictionary() -> Dictionary:
    return {
        "btc_price": btc_price,
        "network_hashrate_th": network_hashrate_th,
        "block_subsidy_btc": block_subsidy_btc,
        "average_fees_btc": average_fees_btc,
        "federal_rate": federal_rate,
        "land_price_per_acre": land_price_per_acre,
        "energy_market_index": energy_market_index,
        "halvings_since_crash": halvings_since_crash,
        "last_market_event": last_market_event
    }

func _native_push_culture_effects() -> void:
    if not native_runtime_ready:
        return
    var effects := {
        "uptime_bonus": 0.0,
        "financing_rate_adjustment": 0.0,
        "partner_cost_multiplier": 1.0,
        "research_cost_multiplier": 1.0,
        "expansion_cost_multiplier": 1.0,
        "merger_cost_multiplier": 1.0
    }
    if not player_personality.is_empty():
        effects["uptime_bonus"] = _operations_uptime_bonus()
        effects["financing_rate_adjustment"] = _financing_rate_adjustment()
        effects["partner_cost_multiplier"] = _partner_cost_multiplier()
        effects["research_cost_multiplier"] = _research_cost_multiplier()
        effects["expansion_cost_multiplier"] = _expansion_cost_multiplier()
        effects["merger_cost_multiplier"] = _merger_cost_multiplier()
    native_runtime.call("set_culture_effects", effects)

func _native_sync_from_cpp() -> void:
    if not native_runtime_ready:
        return
    player = native_runtime.call("player_snapshot") as Dictionary
    rivals = native_runtime.call("rivals_snapshot") as Array
    signed_partners = native_runtime.call("signed_partners_snapshot") as Dictionary
    merger_used = bool(native_runtime.call("merger_used"))
    var market: Dictionary = native_runtime.call("market_snapshot") as Dictionary
    btc_price = float(market.get("btc_price", btc_price))
    network_hashrate_th = float(market.get("network_hashrate_th", network_hashrate_th))
    block_subsidy_btc = float(market.get("block_subsidy_btc", block_subsidy_btc))
    average_fees_btc = float(market.get("average_fees_btc", average_fees_btc))
    federal_rate = float(market.get("federal_rate", federal_rate))
    land_price_per_acre = float(market.get("land_price_per_acre", land_price_per_acre))
    energy_market_index = float(market.get("energy_market_index", energy_market_index))
    halvings_since_crash = int(market.get("halvings_since_crash", halvings_since_crash))
    last_market_event = String(market.get("last_market_event", last_market_event))
    elapsed_campaign_days = float(native_runtime.call("elapsed_days"))
    next_halving_day = float(native_runtime.call("next_halving_day"))

func _native_commit_external_state() -> void:
    if not native_runtime_ready:
        return
    native_runtime.call("commit_external_state", player, rivals, signed_partners, merger_used)
    _native_push_culture_effects()
    _native_sync_from_cpp()

func _native_apply(action: Dictionary, show_feedback: bool = true) -> bool:
    if not bool(action.get("ok", false)):
        if show_feedback:
            _feedback(String(action.get("message", "Native action failed.")))
        return false
    _native_sync_from_cpp()
    if show_feedback:
        _feedback(String(action.get("message", "Native action complete.")))
    queue_redraw()
    return true

func _native_runtime_active() -> bool:
    return native_runtime_ready and native_runtime != null and bool(native_runtime.call("is_authoritative"))

func _hashrate_th() -> float:
    if not _native_runtime_active():
        return super._hashrate_th()
    return float(native_runtime.call("hashrate_th"))

func _machine_load_kw() -> float:
    if not _native_runtime_active():
        return super._machine_load_kw()
    return float(native_runtime.call("machine_load_kw"))

func _effective_power_cost() -> float:
    if not _native_runtime_active():
        return super._effective_power_cost()
    return float(native_runtime.call("effective_power_cost"))

func _uptime() -> float:
    if not _native_runtime_active():
        return super._uptime()
    _native_push_culture_effects()
    return float(native_runtime.call("uptime"))

func _btc_per_day() -> float:
    if not _native_runtime_active():
        return super._btc_per_day()
    _native_push_culture_effects()
    return float(native_runtime.call("btc_per_day_live"))

func _asset_value() -> float:
    if not _native_runtime_active():
        return super._asset_value()
    return float(native_runtime.call("asset_value"))

func _eligible_lender() -> Dictionary:
    if not _native_runtime_active():
        return super._eligible_lender()
    return native_runtime.call("eligible_lender", Profiles.LOAN_TIERS) as Dictionary

func _loan_rate(offer: Dictionary) -> float:
    if not _native_runtime_active():
        return super._loan_rate(offer)
    _native_push_culture_effects()
    return float(native_runtime.call("loan_rate", offer))

func _loan_room() -> float:
    if not _native_runtime_active():
        return super._loan_room()
    return float(native_runtime.call("loan_room", Profiles.LOAN_TIERS))

func _project_scaled_profit(days: float) -> float:
    if not _native_runtime_active():
        return super._project_scaled_profit(days)
    _native_push_culture_effects()
    return float(native_runtime.call("project_profit", days))

func _buy_machines() -> void:
    if not _native_runtime_active():
        super._buy_machines()
        return
    _native_push_culture_effects()
    _native_apply(native_runtime.call("buy_machines", 10) as Dictionary)

func _buy_power() -> void:
    if not _native_runtime_active():
        super._buy_power()
        return
    _native_push_culture_effects()
    _native_apply(native_runtime.call("buy_power") as Dictionary)

func _buy_land() -> void:
    if not _native_runtime_active():
        super._buy_land()
        return
    _native_push_culture_effects()
    _native_apply(native_runtime.call("buy_land") as Dictionary)

func _upgrade_machine_tier() -> void:
    if not _native_runtime_active():
        super._upgrade_machine_tier()
        return
    _native_push_culture_effects()
    _native_apply(native_runtime.call("upgrade_machine_tier") as Dictionary)

func _upgrade_cooling() -> void:
    if not _native_runtime_active():
        super._upgrade_cooling()
        return
    _native_apply(native_runtime.call("upgrade_cooling") as Dictionary)

func _upgrade_chips() -> void:
    if not _native_runtime_active():
        super._upgrade_chips()
        return
    _native_push_culture_effects()
    _native_apply(native_runtime.call("upgrade_chips") as Dictionary)

func _change_energy() -> void:
    if not _native_runtime_active():
        super._change_energy()
        return
    _native_apply(native_runtime.call("change_energy") as Dictionary)

func _take_loan() -> void:
    if not _native_runtime_active():
        super._take_loan()
        return
    _native_push_culture_effects()
    _native_apply(native_runtime.call("take_loan", Profiles.LOAN_TIERS) as Dictionary)

func _repay_debt() -> void:
    if not _native_runtime_active():
        super._repay_debt()
        return
    _native_apply(native_runtime.call("repay_debt") as Dictionary)

func _sign_partner(partner_idx: int) -> void:
    if not _native_runtime_active():
        super._sign_partner(partner_idx)
        return
    _native_push_culture_effects()
    _native_apply(native_runtime.call("sign_partner", partner_idx, PARTNERS) as Dictionary)

func _merge_rival(rival_idx: int) -> void:
    if not _native_runtime_active():
        super._merge_rival(rival_idx)
        return
    _native_push_culture_effects()
    _native_apply(native_runtime.call("merge_rival", rival_idx) as Dictionary)

func _cycle_treasury() -> void:
    if not _native_runtime_active():
        super._cycle_treasury()
        return
    var current: int = clampi(int(round(float(player.get("treasury_hold", 0.30)) * 100.0)), 0, 100)
    var next_percent: int = (current + 10) % 110
    _native_apply(native_runtime.call("set_hold_percent", next_percent) as Dictionary)

func _spend_for_routine(cost: float) -> bool:
    if not _native_runtime_active():
        return super._spend_for_routine(cost)
    var action: Dictionary = native_runtime.call("spend_cash", cost, "operator routine") as Dictionary
    if not bool(action.get("ok", false)):
        _feedback(String(action.get("message", "Not enough cash for that operator routine.")))
        return false
    _native_sync_from_cpp()
    return true

func _native_set_hold_percent(percent: int) -> Dictionary:
    if not _native_runtime_active():
        return {"ok": false, "message": "C++ runtime is not active."}
    var action: Dictionary = native_runtime.call("set_hold_percent", clampi(percent, 0, 100)) as Dictionary
    if bool(action.get("ok", false)):
        _native_sync_from_cpp()
    return action

func _native_sell_sats(sats_to_sell: float) -> Dictionary:
    if not _native_runtime_active():
        return {"ok": false, "message": "C++ runtime is not active."}
    var action: Dictionary = native_runtime.call("sell_sats", sats_to_sell) as Dictionary
    if bool(action.get("ok", false)):
        _native_sync_from_cpp()
    return action

func _native_settle_turn(days: float) -> Dictionary:
    if not _native_runtime_active():
        return {"ok": false, "message": "C++ runtime is not active."}
    _native_push_culture_effects()
    var settlement: Dictionary = native_runtime.call("settle_turn", days) as Dictionary
    if bool(settlement.get("ok", false)):
        _native_sync_from_cpp()
    return settlement

func debug_native_runtime_ready() -> bool:
    return _native_runtime_active() and String(native_runtime.call("runtime_revision")) == NATIVE_RUNTIME_REVISION

func debug_native_inventory() -> Array:
    if not _native_runtime_active():
        return []
    return native_runtime.call("inventory_snapshot") as Array
