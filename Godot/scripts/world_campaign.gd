extends "res://scripts/world_v2.gd"

const Profiles = preload("res://scripts/company_profiles.gd")
const QUARTER_DAYS := 91.25
const TURNS_PER_YEAR := 4
const HALVING_TURNS := 16
const DEFAULT_CAMPAIGN_YEARS := 4
const MAX_CAMPAIGN_YEARS := 100

var campaign_years := DEFAULT_CAMPAIGN_YEARS
var campaign_turns := DEFAULT_CAMPAIGN_YEARS * TURNS_PER_YEAR
var campaign_complete := false
var results_layer: CanvasLayer

func _ready() -> void:
    if get_tree().has_meta("hashrace_company_idx"):
        player_town_idx = clamp(int(get_tree().get_meta("hashrace_company_idx")), 0, COMPANY_NAMES.size() - 1)
    selected_town_idx = player_town_idx
    if get_tree().has_meta("hashrace_campaign_years"):
        campaign_years = clamp(int(get_tree().get_meta("hashrace_campaign_years")), 1, MAX_CAMPAIGN_YEARS)
    if get_tree().has_meta("hashrace_campaign_turns"):
        campaign_turns = clamp(int(get_tree().get_meta("hashrace_campaign_turns")), 4, MAX_CAMPAIGN_YEARS * TURNS_PER_YEAR)
    else:
        campaign_turns = campaign_years * TURNS_PER_YEAR
    super()
    configure_company_starts()
    selected_town_idx = player_town_idx
    player_pos = towns[player_town_idx]["center"] + Vector2(0, 220)
    camera.position = player_pos
    configure_campaign_buttons()
    var profile := Profiles.PROFILES[player_town_idx]
    update_hud("%s enters the race with %s strength. Campaign clock locked: %d year%s / %d quarterly turns." % [
        profile["name"], profile["strengths"], campaign_years, "" if campaign_years == 1 else "s", campaign_turns
    ])

func configure_company_starts() -> void:
    for i in range(towns.size()):
        var town := towns[i]
        var profile := Profiles.PROFILES[i]
        town["strengths"] = profile["strengths"]
        town["debt_rate"] = 0.0
        town["debt_source"] = "No lender"

        if i == player_town_idx:
            town["stage"] = 0
            town["sats"] = 0.0
            town["power_cost"] = 0.078
            town["mw"] = 0.06
            town["machine_counts"] = [12, 0, 0, 0, 0, 0]
            town["energy"] = "Grid"
            town["cash"] = 85000.0
            town["acres"] = 0.75
            town["cooling"] = 0
            town["chip_level"] = 0
            town["unlocked_tier"] = 0
            town["debt"] = 0.0
            town["hosting"] = false
            town["treasury_hold"] = 0.30
            town["partners"] = []
            town["weekly_bonus"] = 0.0
            town["utility_discount"] = 0.0
            town["finance_bonus"] = 0.0
            town["hydro_access"] = false
            town["uptime_base"] = 0.955
            town["last_profit"] = 0.0

        town["cash"] = float(town["cash"]) + float(profile["cash_bonus"])
        town["mw"] = float(town["mw"]) + float(profile["mw_bonus"])
        town["acres"] = float(town["acres"]) + float(profile["acres_bonus"])
        town["sats"] = float(town["sats"]) + float(profile["sats_bonus"])
        town["finance_bonus"] = float(town["finance_bonus"]) + float(profile["loan_bonus"])
        var tier := int(town["unlocked_tier"])
        town["machine_counts"][tier] += int(profile["machine_bonus"])
        if float(profile["power_discount"]) > 0.0:
            town["utility_discount"] = float(town["utility_discount"]) + float(profile["power_discount"])
        if String(profile["energy"]) != "Grid":
            town["energy"] = profile["energy"]

func campaign_year() -> int:
    return int((turn - 1) / TURNS_PER_YEAR) + 1

func campaign_quarter() -> int:
    return ((turn - 1) % TURNS_PER_YEAR) + 1

func turns_until_halving() -> int:
    return HALVING_TURNS - ((turn - 1) % HALVING_TURNS)

func halvings_completed() -> int:
    return int((turn - 1) / HALVING_TURNS)

func eligible_loan_offer(town: Dictionary) -> Dictionary:
    var assets := asset_value(town)
    var best: Dictionary = {}
    for tier in Profiles.LOAN_TIERS:
        if assets >= float(tier["min_assets"]) and int(town["stage"]) >= int(tier["min_stage"]):
            best = tier
    return best

func loan_limit(town: Dictionary) -> float:
    var offer := eligible_loan_offer(town)
    if offer.is_empty():
        return 0.0
    var ltv := min(0.72, float(offer["ltv"]) + float(town["finance_bonus"]))
    var secured_capacity := min(float(offer["cap"]), asset_value(town) * ltv)
    return max(0.0, secured_capacity - float(town["debt"]))

func operating_cost_per_day(town: Dictionary) -> float:
    var machine_ops := float(total_machines(town)) * 0.38
    var fixed_site := float(town["stage"]) * 180.0
    var power := site_load_kw(town) * 24.0 * effective_power_cost(town) * effective_uptime(town)
    var rate := float(town.get("debt_rate", 0.10))
    if rate <= 0.0:
        rate = 0.10
    var debt_interest := float(town["debt"]) * rate / 365.0
    return machine_ops + fixed_site + power + debt_interest

func take_loan() -> void:
    var town := towns[player_town_idx]
    var offer := eligible_loan_offer(town)
    if offer.is_empty():
        update_hud("No lender yet. Build at least $50,000 in total assets to qualify for a Community Bank loan.")
        return
    var available := loan_limit(town)
    if available < 5000.0:
        update_hud("%s sees no additional secured borrowing room right now." % offer["name"])
        return
    var target_draw := max(25000.0, asset_value(town) * 0.15)
    var amount := min(available, min(float(offer["cap"]), target_draw))
    var old_debt := float(town["debt"])
    var old_rate := float(town.get("debt_rate", 0.0))
    var new_debt := old_debt + amount
    var blended_rate := float(offer["rate"])
    if old_debt > 0.0 and old_rate > 0.0:
        blended_rate = ((old_debt * old_rate) + (amount * float(offer["rate"]))) / new_debt
    town["debt"] = new_debt
    town["debt_rate"] = blended_rate
    town["debt_source"] = offer["name"]
    town["cash"] = float(town["cash"]) + amount
    update_hud("%s financing approved: borrowed $%d at %.1f%%. Total debt $%d." % [offer["name"], int(amount), float(offer["rate"]) * 100.0, int(new_debt)])

func repay_loan() -> void:
    var town := towns[player_town_idx]
    var debt := float(town["debt"])
    if debt <= 0.0:
        update_hud("No debt to repay. Your company is currently debt-free.")
        return
    var operating_reserve := 10000.0
    var available_cash := max(0.0, float(town["cash"]) - operating_reserve)
    if available_cash < 1000.0:
        update_hud("Keep at least $10,000 operating cash before making a debt payment.")
        return
    var target_payment := max(5000.0, debt * 0.25)
    var payment := min(debt, min(available_cash, target_payment))
    town["cash"] = float(town["cash"]) - payment
    town["debt"] = debt - payment
    if float(town["debt"]) <= 0.01:
        town["debt"] = 0.0
        town["debt_rate"] = 0.0
        town["debt_source"] = "No lender"
        update_hud("Debt fully repaid. The company is debt-free again.")
    else:
        update_hud("Repaid $%d of debt. Remaining balance: $%d at %.1f%% blended interest." % [
            int(payment), int(town["debt"]), float(town.get("debt_rate", 0.0)) * 100.0
        ])

func disconnect_button(button: Button) -> void:
    for connection in button.pressed.get_connections():
        var callable: Callable = connection["callable"]
        if button.pressed.is_connected(callable):
            button.pressed.disconnect(callable)

func configure_campaign_buttons() -> void:
    for node in find_children("*", "Button", true, false):
        var button := node as Button
        if button == null:
            continue
        if button.text == "END TURN +7D":
            button.text = "END QUARTER"
        elif button.text == "TAKE ASSET LOAN":
            button.text = "GET ASSET LOAN"
        elif button.text == "OLD MANAGEMENT":
            disconnect_button(button)
            button.text = "REPAY LOAN"
            button.pressed.connect(repay_loan)

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
    var offer := eligible_loan_offer(player)
    var lender_text := "NO LENDER"
    if not offer.is_empty():
        lender_text = "%s %.1f%%" % [offer["name"], float(offer["rate"]) * 100.0]
    market_label.text = "QUARTERLY MARKET  BTC $%d | Network %.0f EH/s | Subsidy %.4f BTC + %.2f fees | %s | %s | Loan room $%d | Hosting %s" % [
        int(btc_price), network_hashrate_th / 1000000.0, block_subsidy_btc, average_fees_btc, halving_text,
        lender_text, int(loan_limit(player)), "ON" if player["hosting"] else "OFF"
    ]
    var inspected := towns[selected_town_idx]
    selected_label.text += "\nStrength: %s" % String(inspected.get("strengths", "Balanced"))
    if selected_town_idx == player_town_idx:
        selected_label.text += "\nFinancing: %s | %.1f%% blended | Debt $%d" % [
            String(player.get("debt_source", "No lender")), float(player.get("debt_rate", 0.0)) * 100.0, int(player["debt"])
        ]

func advance_turn() -> void:
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
        show_campaign_results()
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

func final_standings() -> Array:
    var standings: Array = []
    for i in range(towns.size()):
        var town := towns[i]
        standings.append({
            "idx": i,
            "name": town["name"],
            "assets": asset_value(town),
            "cash": float(town["cash"]),
            "sats": float(town["sats"]),
            "mw": float(town["mw"]),
            "machines": total_machines(town)
        })
    standings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["assets"]) > float(b["assets"]))
    return standings

func show_campaign_results() -> void:
    if is_instance_valid(results_layer):
        return
    var standings := final_standings()
    var player_rank := 0
    for i in range(standings.size()):
        if int(standings[i]["idx"]) == player_town_idx:
            player_rank = i + 1
            break

    results_layer = CanvasLayer.new()
    results_layer.layer = 50
    add_child(results_layer)

    var shade := ColorRect.new()
    shade.position = Vector2.ZERO
    shade.size = Vector2(1440, 900)
    shade.color = Color("02070bd9")
    results_layer.add_child(shade)

    var panel := Panel.new()
    panel.position = Vector2(310, 70)
    panel.size = Vector2(820, 760)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("08131bf7")
    style.border_width_left = 3
    style.border_width_top = 3
    style.border_width_right = 3
    style.border_width_bottom = 3
    style.border_color = GREEN if player_rank == 1 else CYAN
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    panel.add_theme_stylebox_override("panel", style)
    results_layer.add_child(panel)

    var title := Label.new()
    title.position = Vector2(30, 24)
    title.size = Vector2(760, 52)
    title.text = "HASH RACE // FINAL STANDINGS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", GREEN if player_rank == 1 else CYAN)
    panel.add_child(title)

    var summary := Label.new()
    summary.position = Vector2(40, 84)
    summary.size = Vector2(740, 58)
    summary.text = "Winner: %s   •   Your finish: #%d of %d   •   %d years / %d turns" % [
        standings[0]["name"], player_rank, standings.size(), campaign_years, campaign_turns
    ]
    summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    summary.add_theme_font_size_override("font_size", 16)
    summary.add_theme_color_override("font_color", WHITE)
    panel.add_child(summary)

    var table := Label.new()
    table.position = Vector2(56, 154)
    table.size = Vector2(708, 470)
    var rows := "RANK   COMPANY                         TOTAL ASSETS       MW      MACHINES\n"
    rows += "────────────────────────────────────────────────────────────────────────\n"
    for i in range(standings.size()):
        var row := standings[i]
        var you := " ← YOU" if int(row["idx"]) == player_town_idx else ""
        rows += "#%-5d %-30s $%-15d %6.2f   %7d%s\n" % [
            i + 1, String(row["name"]), int(row["assets"]), float(row["mw"]), int(row["machines"]), you
        ]
    table.text = rows
    table.add_theme_font_size_override("font_size", 14)
    table.add_theme_color_override("font_color", Color("c9eaf1"))
    panel.add_child(table)

    var verdict := Label.new()
    verdict.position = Vector2(50, 628)
    verdict.size = Vector2(720, 42)
    verdict.text = "You won the Hash Race." if player_rank == 1 else "Build more total company assets to move up the next race."
    verdict.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    verdict.add_theme_font_size_override("font_size", 17)
    verdict.add_theme_color_override("font_color", GREEN if player_rank == 1 else ORANGE)
    panel.add_child(verdict)

    var restart := Button.new()
    restart.position = Vector2(240, 690)
    restart.size = Vector2(340, 48)
    restart.text = "START NEW CAMPAIGN"
    restart.add_theme_font_size_override("font_size", 16)
    restart.pressed.connect(start_new_campaign)
    panel.add_child(restart)

func start_new_campaign() -> void:
    get_tree().remove_meta("hashrace_campaign_years")
    get_tree().remove_meta("hashrace_campaign_turns")
    get_tree().remove_meta("hashrace_company_idx")
    get_tree().change_scene_to_file("res://scenes/campaign_setup.tscn")

func rename_complete_button() -> void:
    for node in find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == "END QUARTER":
            button.text = "CAMPAIGN COMPLETE"
            button.disabled = true
