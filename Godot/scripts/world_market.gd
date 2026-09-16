extends "res://scripts/world_playability.gd"

# Macro/finance layer: lender progression, Fed-sensitive asset markets,
# rare halving-era crashes, unique partner advantages, one merger, and
# energy-specific economic tradeoffs.

const ENERGY_ECONOMICS := {
    "Grid": {"credit":0.0, "penalty":0.0, "clean":false, "offgrid":false, "adv":"No project capex and easiest expansion.", "disadv":"Highest exposure to utility prices and market volatility."},
    "Utility PPA": {"credit":0.0005, "penalty":0.0, "clean":false, "offgrid":false, "adv":"Contracted pricing reduces market volatility.", "disadv":"Requires a utility partner and upfront contract capex."},
    "Natural Gas": {"credit":0.0, "penalty":0.0018, "clean":false, "offgrid":true, "adv":"Reliable off-grid generation with low energy cost.", "disadv":"Fuel and maintenance add operating cost and commodity risk."},
    "Hydro": {"credit":0.0030, "penalty":0.0, "clean":true, "offgrid":true, "adv":"Cheap, reliable, low-carbon off-grid power earns a clean-energy credit.", "disadv":"High capex and limited geographic access."},
    "Solar + Storage": {"credit":0.0045, "penalty":0.0, "clean":true, "offgrid":true, "adv":"Largest clean-energy credit and very low marginal power cost.", "disadv":"Needs substantial land and carries a reliability penalty."},
    "Nuclear PPA": {"credit":0.0018, "penalty":0.0, "clean":true, "offgrid":false, "adv":"Dense low-carbon baseload with the best reliability.", "disadv":"Very high capex and only large operators qualify."}
}

var federal_rate := 0.045
var land_price_per_acre := 8000.0
var energy_market_index := 1.0
var halvings_since_crash := 0
var merger_used := false
var last_market_event := "Normal market"
var merger_button: Button

func _ready() -> void:
    super._ready()
    initialize_market_fields()
    enrich_partner_descriptions()
    install_market_controls()
    rebind_quarter_button()
    update_hud("Macro market online. Rates, Bitcoin, land, lenders, energy and partner advantages now move with the quarterly simulation.")

func initialize_market_fields() -> void:
    for town in towns:
        town["merged_out"] = bool(town.get("merged_out", false))
        town["land_discount"] = float(town.get("land_discount", 0.0))
        town["power_capex_discount"] = float(town.get("power_capex_discount", 0.0))
        town["machine_efficiency_bonus"] = float(town.get("machine_efficiency_bonus", 0.0))
        town["partner_machine_discount"] = float(town.get("partner_machine_discount", 0.0))
        town["lender_spread_discount"] = float(town.get("lender_spread_discount", 0.0))
        town["clean_credit_bonus"] = float(town.get("clean_credit_bonus", 0.0))

func enrich_partner_descriptions() -> void:
    for partner in partner_nodes:
        match String(partner["name"]):
            "Cascadia Utility District":
                partner["note"] = "Cuts $/kWh and unlocks Utility PPA. Best direct power-cost partner."
            "Harbor Land Authority":
                partner["note"] = "Adds 10 acres and cuts future land purchases by 15%."
            "Ironline Infrastructure":
                partner["note"] = "Adds 0.25 MW and cuts future interconnect expansion capex by 12%."
            "FoundryWorks Silicon":
                partner["note"] = "Adds machines, 5% machine purchase discount and 6% fleet power-efficiency gain."
            "Meridian Finance Cooperative":
                partner["note"] = "Adds growth cash, raises loan capacity and trims lender spread by 1 point."
            "QuickBite Services":
                partner["note"] = "Adds steady non-mining commercial cash flow every quarter."
            "Pro Circuit Sports":
                partner["note"] = "Adds larger recurring sponsorship and venue income every quarter."
            "BlueRiver Energy Authority":
                partner["note"] = "Unlocks Hydro and improves clean-energy credits for off-grid generation."
            "Satoshi Treasury Network":
                partner["note"] = "Adds a large sats reserve, strengthening treasury value and asset-backed borrowing."

func install_market_controls() -> void:
    if not is_instance_valid(partner_label):
        return
    var side := partner_label.get_parent() as Control
    if side == null:
        return
    partner_label.position.y = 739
    partner_label.size.y = 24
    if is_instance_valid(event_label):
        event_label.position.y = 766
        event_label.size.y = 26
    merger_button = Button.new()
    merger_button.position = Vector2(16, 691)
    merger_button.size = Vector2(355, 40)
    merger_button.text = "MERGE SELECTED RIVAL // ONCE"
    merger_button.add_theme_font_size_override("font_size", 11)
    merger_button.pressed.connect(merge_selected_rival)
    side.add_child(merger_button)

func rebind_quarter_button() -> void:
    if not is_instance_valid(quarter_button):
        return
    disconnect_button(quarter_button)
    quarter_button.pressed.connect(request_end_quarter)

func request_end_quarter() -> void:
    if campaign_complete:
        update_hud("Campaign already complete. Start a new campaign from the results screen.")
        return
    if not quarter_confirmation_pending:
        quarter_confirmation_pending = true
        if is_instance_valid(quarter_button):
            quarter_button.text = "CONFIRM END QUARTER"
        var projection := projected_quarter_cash_result()
        var direction := "profit" if projection >= 0.0 else "loss"
        update_hud("Quarter preview: projected cash %s $%d. BTC $%d, land $%d/acre and Fed %.2f%% can move after settlement." % [
            direction, abs(int(projection)), int(btc_price), int(land_price_per_acre), federal_rate * 100.0
        ])
        return
    quarter_confirmation_pending = false
    if is_instance_valid(quarter_button):
        quarter_button.text = "END QUARTER"
    advance_turn()

func asset_value(town: Dictionary) -> float:
    var base_value := super.asset_value(town)
    var static_land_value := float(town["acres"]) * 8000.0
    var live_land_value := float(town["acres"]) * land_price_per_acre
    return max(0.0, base_value - static_land_value + live_land_value)

func raw_machine_kw(town: Dictionary) -> float:
    var base_kw := super.raw_machine_kw(town)
    var efficiency_bonus := clamp(float(town.get("machine_efficiency_bonus", 0.0)), 0.0, 0.20)
    return base_kw * (1.0 - efficiency_bonus)

func machine_purchase_price(town: Dictionary) -> float:
    var base_price := super.machine_purchase_price(town)
    var partner_discount := clamp(float(town.get("partner_machine_discount", 0.0)), 0.0, 0.20)
    return base_price * (1.0 - partner_discount)

func effective_power_cost(town: Dictionary) -> float:
    var base_cost := super.effective_power_cost(town)
    var energy_name := String(town["energy"])
    if energy_name == "Grid":
        return max(0.018, base_cost * (0.96 + 0.04 * energy_market_index))
    if energy_name == "Natural Gas":
        return max(0.018, base_cost * energy_market_index)
    return base_cost

func operating_cost_per_day(town: Dictionary) -> float:
    var base_cost := super.operating_cost_per_day(town)
    var energy_name := String(town["energy"])
    var profile: Dictionary = ENERGY_ECONOMICS.get(energy_name, {})
    if profile.is_empty():
        return base_cost
    var daily_kwh := site_load_kw(town) * 24.0 * effective_uptime(town)
    var credit_per_kwh := float(profile.get("credit", 0.0)) + float(town.get("clean_credit_bonus", 0.0))
    var penalty_per_kwh := float(profile.get("penalty", 0.0))
    var adjusted := base_cost + daily_kwh * penalty_per_kwh - daily_kwh * credit_per_kwh
    return max(0.0, adjusted)

func loan_rate_for_offer(town: Dictionary, offer: Dictionary) -> float:
    var spread := float(offer.get("spread", max(0.0, float(offer.get("rate", 0.12)) - 0.045)))
    spread = max(0.0025, spread - float(town.get("lender_spread_discount", 0.0)))
    return clamp(federal_rate + spread, 0.02, 0.28)

func take_loan() -> void:
    var town := towns[player_town_idx]
    var offer := eligible_loan_offer(town)
    if offer.is_empty():
        update_hud("No lender yet. Grow company assets before even Local Joker Bank will lend.")
        return
    var available := loan_limit(town)
    if available < 5000.0:
        update_hud("%s sees no additional secured borrowing room right now." % offer["name"])
        return
    var target_draw := max(10000.0, asset_value(town) * 0.15)
    var amount := min(available, min(float(offer["cap"]), target_draw))
    var live_rate := loan_rate_for_offer(town, offer)
    var old_debt := float(town["debt"])
    var old_rate := float(town.get("debt_rate", 0.0))
    var new_debt := old_debt + amount
    var blended_rate := live_rate
    if old_debt > 0.0 and old_rate > 0.0:
        blended_rate = ((old_debt * old_rate) + (amount * live_rate)) / new_debt
    town["debt"] = new_debt
    town["debt_rate"] = blended_rate
    town["debt_source"] = offer["name"]
    town["cash"] = float(town["cash"]) + amount
    update_hud("%s approved $%d at %.2f%% with Fed at %.2f%%. Bigger asset tiers unlock larger, cheaper lenders." % [
        offer["name"], int(amount), live_rate * 100.0, federal_rate * 100.0
    ])

func buy_land() -> void:
    var town := towns[player_town_idx]
    var discount := clamp(float(town.get("land_discount", 0.0)), 0.0, 0.35)
    var cost := land_price_per_acre * 5.0 * (1.0 - discount) + 5000.0
    if float(town["cash"]) < cost:
        update_hud("Need $%d for the next 5-acre parcel at the current land market of $%d/acre." % [int(cost), int(land_price_per_acre)])
        return
    town["cash"] = float(town["cash"]) - cost
    town["acres"] = float(town["acres"]) + 5.0
    update_hud("Purchased 5 acres for $%d. Total %.2f acres. Live land price: $%d/acre." % [int(cost), float(town["acres"]), int(land_price_per_acre)])

func buy_power() -> void:
    var town := towns[player_town_idx]
    var increment := 0.25
    var base_cost := 26000.0 + float(town["mw"]) * 42000.0
    var discount := clamp(float(town.get("power_capex_discount", 0.0)), 0.0, 0.30)
    var cost := base_cost * (1.0 - discount)
    if float(town["cash"]) < cost:
        update_hud("Need $%d for another 0.25 MW of energized capacity." % int(cost))
        return
    town["cash"] = float(town["cash"]) - cost
    town["mw"] = float(town["mw"]) + increment
    update_hud("Interconnect expanded by 0.25 MW for $%d. Total %.2f MW." % [int(cost), float(town["mw"])])

func sign_selected_partner() -> void:
    if selected_partner_idx < 0:
        update_hud("Click an NPC company diamond first.")
        return
    var partner := partner_nodes[selected_partner_idx]
    var already_signed := bool(partner["signed"])
    var partner_name := String(partner["name"])
    super.sign_selected_partner()
    if already_signed or not bool(partner["signed"]):
        return
    var town := towns[player_town_idx]
    match partner_name:
        "Harbor Land Authority":
            town["land_discount"] = float(town.get("land_discount", 0.0)) + 0.15
        "Ironline Infrastructure":
            town["power_capex_discount"] = float(town.get("power_capex_discount", 0.0)) + 0.12
        "FoundryWorks Silicon":
            town["machine_efficiency_bonus"] = float(town.get("machine_efficiency_bonus", 0.0)) + 0.06
            town["partner_machine_discount"] = float(town.get("partner_machine_discount", 0.0)) + 0.05
        "Meridian Finance Cooperative":
            town["lender_spread_discount"] = float(town.get("lender_spread_discount", 0.0)) + 0.01
        "BlueRiver Energy Authority":
            town["clean_credit_bonus"] = float(town.get("clean_credit_bonus", 0.0)) + 0.001
    update_hud("%s partnership fully active: %s" % [partner_name, String(partner["note"])])

func merge_selected_rival() -> void:
    if merger_used:
        update_hud("Merger already used. Each mining company may complete only one merger per campaign.")
        return
    if selected_town_idx == player_town_idx:
        update_hud("Select a rival mining town first, then use MERGE SELECTED RIVAL.")
        return
    var player := towns[player_town_idx]
    var target := towns[selected_town_idx]
    if bool(target.get("merged_out", false)):
        update_hud("That rival has already been absorbed.")
        return
    var target_assets := max(0.0, asset_value(target) - float(target["debt"]))
    var player_assets := asset_value(player)
    if target_assets > player_assets * 1.25:
        update_hud("Merger rejected: %s is too large. Grow to at least 80%% of its net asset value first." % target["name"])
        return
    var purchase_price := max(100000.0, target_assets * 0.70)
    if float(player["cash"]) < purchase_price:
        update_hud("Need $%d cash to close the one-time merger with %s." % [int(purchase_price), target["name"]])
        return

    player["cash"] = float(player["cash"]) - purchase_price + max(0.0, float(target["cash"])) * 0.50
    player["sats"] = float(player["sats"]) + float(target["sats"])
    player["mw"] = float(player["mw"]) + float(target["mw"])
    player["acres"] = float(player["acres"]) + float(target["acres"])
    player["debt"] = float(player["debt"]) + float(target["debt"])
    for i in range(player["machine_counts"].size()):
        player["machine_counts"][i] += int(target["machine_counts"][i])
    player["stage"] = max(int(player["stage"]), int(target["stage"]))
    player["cooling"] = max(int(player["cooling"]), int(target["cooling"]))
    player["chip_level"] = max(int(player["chip_level"]), int(target["chip_level"]))
    player["unlocked_tier"] = max(int(player["unlocked_tier"]), int(target["unlocked_tier"]))

    var acquired_name := String(target["name"])
    target["merged_out"] = true
    target["name"] = acquired_name + " [MERGED]"
    target["cash"] = 0.0
    target["sats"] = 0.0
    target["mw"] = 0.0
    target["acres"] = 0.0
    target["debt"] = 0.0
    target["machine_counts"] = [0, 0, 0, 0, 0, 0]
    merger_used = true
    if is_instance_valid(merger_button):
        merger_button.text = "MERGER USED"
        merger_button.disabled = true
    selected_town_idx = player_town_idx
    queue_redraw()
    update_hud("ONE-TIME MERGER CLOSED: absorbed %s for $%d and combined machines, MW, land, sats and technology." % [acquired_name, int(purchase_price)])

func simulate_rivals() -> void:
    for i in range(towns.size()):
        if i == player_town_idx:
            continue
        var town := towns[i]
        if bool(town.get("merged_out", false)):
            continue
        var profit := net_profit_per_day(town) * QUARTER_DAYS
        town["cash"] = float(town["cash"]) + profit
        town["sats"] = float(town["sats"]) + sats_per_day(town) * QUARTER_DAYS * 0.35
        if profit > 1000.0 and randf() < 0.55:
            var tier := int(town["unlocked_tier"])
            town["machine_counts"][tier] += 10 + randi_range(0, 35)
        if site_load_kw(town) > float(town["mw"]) * 900.0:
            town["mw"] = float(town["mw"]) + 0.25
        if randf() < 0.18:
            town["acres"] = float(town["acres"]) + 5.0

func advance_macro_market(halving_happened: bool) -> String:
    var rate_move := randf_range(-0.0035, 0.0035)
    if randf() < 0.12:
        rate_move += randf_range(-0.005, 0.005)
    federal_rate = clamp(federal_rate + rate_move, 0.005, 0.085)

    var rate_headwind := max(-0.02, federal_rate - 0.04)
    var btc_return := randf_range(-0.12, 0.18) - rate_headwind * 0.90
    var land_return := randf_range(-0.025, 0.040) - rate_headwind * 0.35
    btc_price = max(8000.0, btc_price * max(0.72, 1.0 + btc_return))
    land_price_per_acre = max(1800.0, land_price_per_acre * max(0.80, 1.0 + land_return))
    energy_market_index = clamp(energy_market_index * randf_range(0.94, 1.07), 0.72, 1.45)
    network_hashrate_th *= randf_range(0.985, 1.075)
    average_fees_btc = clamp(average_fees_btc * randf_range(0.72, 1.38), 0.04, 0.85)

    var note := "Market moved: Fed %.2f%%, BTC $%d, land $%d/acre." % [federal_rate * 100.0, int(btc_price), int(land_price_per_acre)]
    last_market_event = "Normal market"
    if halving_happened:
        halvings_since_crash += 1
        var crash_due := halvings_since_crash >= 3 or (halvings_since_crash >= 2 and randf() < 0.55)
        if crash_due:
            note += " " + trigger_rare_crash()
            halvings_since_crash = 0
    return note

func trigger_rare_crash() -> String:
    if randf() < 0.5:
        var btc_hit := randf_range(0.45, 0.62)
        var land_hit := randf_range(0.92, 0.98)
        btc_price = max(6000.0, btc_price * btc_hit)
        land_price_per_acre = max(1500.0, land_price_per_acre * land_hit)
        federal_rate = max(0.005, federal_rate - 0.010)
        last_market_event = "DOT-COM-STYLE TECH CRASH"
        return "%s: Bitcoin took the main hit; land only softened. BTC now $%d." % [last_market_event, int(btc_price)]
    var land_hit := randf_range(0.60, 0.76)
    var btc_hit := randf_range(0.84, 0.95)
    land_price_per_acre = max(1500.0, land_price_per_acre * land_hit)
    btc_price = max(6000.0, btc_price * btc_hit)
    energy_market_index = min(1.55, energy_market_index * 1.12)
    federal_rate = max(0.005, federal_rate - 0.0075)
    last_market_event = "COVID-STYLE PROPERTY / LOGISTICS CRASH"
    return "%s: land took the main hit while Bitcoin fell less. Land now $%d/acre." % [last_market_event, int(land_price_per_acre)]

func advance_turn() -> void:
    quarter_confirmation_pending = false
    if is_instance_valid(quarter_button) and not campaign_complete:
        quarter_button.text = "END QUARTER"
    if campaign_complete:
        update_hud("Campaign already complete. Start a new campaign from the results screen.")
        return

    var player := towns[player_town_idx]
    var settled_turn := turn
    var mined_btc := btc_per_day(player) * QUARTER_DAYS
    var mined_sats := mined_btc * SATS_PER_BTC
    var hold_sats := mined_sats * float(player["treasury_hold"])
    var sold_btc := mined_btc * (1.0 - float(player["treasury_hold"]))
    var cash_revenue := sold_btc * btc_price + (hosting_profit_per_day(player) * QUARTER_DAYS) + float(player["weekly_bonus"])
    var costs := operating_cost_per_day(player) * QUARTER_DAYS
    player["sats"] = float(player["sats"]) + hold_sats
    player["cash"] = float(player["cash"]) + cash_revenue - costs
    player["last_profit"] = cash_revenue - costs

    simulate_rivals()

    var halving_happened := settled_turn % HALVING_TURNS == 0
    if halving_happened:
        block_subsidy_btc *= 0.5
    var market_note := advance_macro_market(halving_happened)

    if settled_turn >= campaign_turns:
        campaign_complete = true
        var final_note := "Campaign complete after Year %d Q%d / Turn %d. Final quarter mined %d sats and produced $%d cash result. %s" % [
            campaign_year(), campaign_quarter(), settled_turn, int(mined_sats), int(player["last_profit"]), market_note
        ]
        if halving_happened:
            final_note += " A Bitcoin halving also occurred at the finish line."
        update_hud(final_note)
        rename_complete_button()
        show_campaign_results()
        return

    turn += 1
    season = campaign_year()
    var note := "Quarter closed: mined %d sats, held %d, cash result $%d. %s" % [int(mined_sats), int(hold_sats), int(player["last_profit"]), market_note]
    if settled_turn % TURNS_PER_YEAR == 0:
        note += " Year %d complete." % int(settled_turn / TURNS_PER_YEAR)
    if halving_happened:
        note += " HALVING: block subsidy is now %.4f BTC." % block_subsidy_btc
    update_hud(note)

func update_hud(message: String = "") -> void:
    super.update_hud(message)
    if not is_instance_valid(market_label) or towns.is_empty():
        return
    var player := towns[player_town_idx]
    var offer := eligible_loan_offer(player)
    var lender_text := "NO LENDER"
    if not offer.is_empty():
        lender_text = "%s %.2f%%" % [offer["name"], loan_rate_for_offer(player, offer) * 100.0]
    var energy_name := String(player["energy"])
    var energy_profile: Dictionary = ENERGY_ECONOMICS.get(energy_name, {})
    var clean_text := "STANDARD"
    if bool(energy_profile.get("clean", false)) and bool(energy_profile.get("offgrid", false)):
        clean_text = "CLEAN OFF-GRID REWARDED"
    elif bool(energy_profile.get("clean", false)):
        clean_text = "LOW-CARBON CREDIT"
    market_label.text = "MARKET  BTC $%d | Land $%d/ac | Fed %.2f%% | Network %.0f EH/s | Subsidy %.4f | %s | Loan room $%d | %s" % [
        int(btc_price), int(land_price_per_acre), federal_rate * 100.0, network_hashrate_th / 1000000.0,
        block_subsidy_btc, lender_text, int(loan_limit(player)), clean_text
    ]
    if is_instance_valid(selected_label):
        var inspected := towns[selected_town_idx]
        var inspected_energy := String(inspected["energy"])
        var profile: Dictionary = ENERGY_ECONOMICS.get(inspected_energy, {})
        if not profile.is_empty():
            selected_label.text += "\nEnergy +: %s\nEnergy -: %s" % [profile["adv"], profile["disadv"]]
        selected_label.text += "\nMerger: %s" % ("USED" if merger_used else "AVAILABLE ONCE")

func debug_federal_rate() -> float:
    return federal_rate

func debug_land_price() -> float:
    return land_price_per_acre

func debug_merger_available() -> bool:
    return not merger_used

func debug_energy_profile_count() -> int:
    return ENERGY_ECONOMICS.size()
