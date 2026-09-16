extends "res://scripts/world_v2.gd"

const QUARTER_DAYS := 91.25
const TURNS_PER_YEAR := 4
const HALVING_TURNS := 16
const DEFAULT_CAMPAIGN_YEARS := 4
const MAX_CAMPAIGN_YEARS := 20

var campaign_years := DEFAULT_CAMPAIGN_YEARS
var campaign_turns := DEFAULT_CAMPAIGN_YEARS * TURNS_PER_YEAR
var campaign_complete := false

func _ready() -> void:
    if get_tree().has_meta("hashrace_campaign_years"):
        campaign_years = clamp(int(get_tree().get_meta("hashrace_campaign_years")), 1, MAX_CAMPAIGN_YEARS)
    if get_tree().has_meta("hashrace_campaign_turns"):
        campaign_turns = clamp(int(get_tree().get_meta("hashrace_campaign_turns")), 4, MAX_CAMPAIGN_YEARS * TURNS_PER_YEAR)
    else:
        campaign_turns = campaign_years * TURNS_PER_YEAR
    super()
    rename_turn_button()
    update_hud("Campaign clock locked: %d year%s / %d quarterly turns. Build before the next halving." % [campaign_years, "" if campaign_years == 1 else "s", campaign_turns])

func campaign_year() -> int:
    return int((turn - 1) / TURNS_PER_YEAR) + 1

func campaign_quarter() -> int:
    return ((turn - 1) % TURNS_PER_YEAR) + 1

func turns_until_halving() -> int:
    return HALVING_TURNS - ((turn - 1) % HALVING_TURNS)

func halvings_completed() -> int:
    return int((turn - 1) / HALVING_TURNS)

func rename_turn_button() -> void:
    for node in find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == "END TURN +7D":
            button.text = "END QUARTER"

func update_hud(message: String = "") -> void:
    super(message)
    if not is_instance_valid(top_stats) or towns.is_empty():
        return
    var player := towns[player_town_idx]
    top_stats.text = "Y%d Q%d | TURN %d/%d | SATS %d | $%.3f/kWh | %.2f MW | %d units | Cash $%d" % [
        campaign_year(), campaign_quarter(), turn, campaign_turns, int(player["sats"]), effective_power_cost(player), float(player["mw"]), total_machines(player), int(player["cash"])
    ]
    var halving_text := "HALVING IN %d TURN%s" % [turns_until_halving(), "" if turns_until_halving() == 1 else "S"]
    if campaign_complete:
        halving_text = "CAMPAIGN COMPLETE"
    market_label.text = "QUARTERLY MARKET  BTC $%d | Network %.0f EH/s | Subsidy %.4f BTC + %.2f fees | %s | Campaign %dY/%dT | Loan $%d | Hosting %s" % [
        int(btc_price), network_hashrate_th / 1000000.0, block_subsidy_btc, average_fees_btc, halving_text,
        campaign_years, campaign_turns, int(loan_limit(player)), "ON" if player["hosting"] else "OFF"
    ]

func advance_turn() -> void:
    if campaign_complete:
        update_hud("Campaign already complete. Start a new campaign to choose another game clock.")
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

    btc_price = max(18000.0, btc_price * randf_range(0.84, 1.20))
    network_hashrate_th *= randf_range(0.985, 1.075)
    average_fees_btc = clamp(average_fees_btc * randf_range(0.72, 1.38), 0.04, 0.85)

    if settled_turn >= campaign_turns:
        campaign_complete = true
        var final_note := "Campaign complete after Year %d Q%d / Turn %d. Final quarter mined %d sats and produced $%d cash result." % [
            campaign_year(), campaign_quarter(), settled_turn, int(mined_sats), int(player["last_profit"])
        ]
        if halving_happened:
            final_note += " A Bitcoin halving also occurred at the finish line."
        update_hud(final_note)
        rename_complete_button()
        return

    turn += 1
    season = campaign_year()

    var note := "Quarter closed: mined %d sats, held %d, cash result $%d." % [int(mined_sats), int(hold_sats), int(player["last_profit"])]
    if settled_turn % TURNS_PER_YEAR == 0:
        note += " Year %d complete." % int(settled_turn / TURNS_PER_YEAR)
    if halving_happened:
        note += " HALVING: block subsidy is now %.4f BTC." % block_subsidy_btc
    update_hud(note)

func simulate_rivals() -> void:
    for i in range(towns.size()):
        if i == player_town_idx:
            continue
        var town := towns[i]
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

func rename_complete_button() -> void:
    for node in find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == "END QUARTER":
            button.text = "CAMPAIGN COMPLETE"
            button.disabled = true
