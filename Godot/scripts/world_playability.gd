extends "res://scripts/world_campaign.gd"

# Playability layer for the quarterly campaign. Ending a quarter moves roughly
# three months of simulation at once, so require a second click and show the
# current cash projection before committing the turn.
var quarter_confirmation_pending := false
var quarter_button: Button
var treasury_button: Button
var treasury_policy_button: Button
const TREASURY_HOLD_LEVELS := [0.0, 0.25, 0.50, 0.75, 1.0]

func configure_campaign_buttons() -> void:
    super.configure_campaign_buttons()
    for node in find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == "END QUARTER":
            quarter_button = button
            disconnect_button(button)
            button.pressed.connect(request_end_quarter)
            break
    if is_instance_valid(quarter_button):
        treasury_policy_button = Button.new()
        treasury_policy_button.tooltip_text = "Choose how much newly mined Bitcoin to keep instead of selling for operating cash each quarter."
        quarter_button.get_parent().add_child(treasury_policy_button)
        treasury_policy_button.pressed.connect(cycle_treasury_hold)
        refresh_treasury_policy_button()

        treasury_button = Button.new()
        treasury_button.text = "SELL 25% BTC TREASURY"
        treasury_button.tooltip_text = "Convert 25% of your held sats to cash at the current simulated BTC price."
        quarter_button.get_parent().add_child(treasury_button)
        treasury_button.pressed.connect(sell_quarter_treasury)

func refresh_treasury_policy_button() -> void:
    if not is_instance_valid(treasury_policy_button) or towns.is_empty():
        return
    var hold_rate := float(towns[player_town_idx]["treasury_hold"])
    treasury_policy_button.text = "BTC HOLD POLICY: %d%%" % int(round(hold_rate * 100.0))

func cycle_treasury_hold() -> void:
    if towns.is_empty() or campaign_complete:
        return
    var player := towns[player_town_idx]
    var current := float(player["treasury_hold"])
    var next_index := 0
    var best_distance := 999.0
    for i in range(TREASURY_HOLD_LEVELS.size()):
        var distance := abs(current - float(TREASURY_HOLD_LEVELS[i]))
        if distance < best_distance:
            best_distance = distance
            next_index = (i + 1) % TREASURY_HOLD_LEVELS.size()
    player["treasury_hold"] = float(TREASURY_HOLD_LEVELS[next_index])
    quarter_confirmation_pending = false
    if is_instance_valid(quarter_button):
        quarter_button.text = "END QUARTER"
    refresh_treasury_policy_button()
    var projection := projected_quarter_cash_result()
    update_hud("Treasury policy changed: hold %d%% of newly mined BTC and sell %d%% for cash. Projected quarter cash result is now $%d." % [
        int(float(player["treasury_hold"]) * 100.0),
        int((1.0 - float(player["treasury_hold"])) * 100.0),
        int(projection)
    ])

func sell_quarter_treasury() -> void:
    if towns.is_empty() or campaign_complete:
        return
    var player := towns[player_town_idx]
    var held_sats := float(player["sats"])
    if held_sats < 1.0:
        update_hud("No Bitcoin treasury to sell yet. Mine and hold sats before using treasury liquidity.")
        return
    var sats_to_sell := max(1.0, floor(held_sats * 0.25))
    var btc_to_sell := sats_to_sell / SATS_PER_BTC
    var cash_raised := btc_to_sell * btc_price
    player["sats"] = held_sats - sats_to_sell
    player["cash"] = float(player["cash"]) + cash_raised
    quarter_confirmation_pending = false
    if is_instance_valid(quarter_button):
        quarter_button.text = "END QUARTER"
    update_hud("Treasury sale: sold %d sats (%.6f BTC) at BTC $%d and raised $%d cash. %d sats remain." % [sats_to_sell, btc_to_sell, int(btc_price), int(cash_raised), int(player["sats"])])

func projected_quarter_cash_result() -> float:
    if towns.is_empty():
        return 0.0
    var player := towns[player_town_idx]
    var mined_btc := btc_per_day(player) * QUARTER_DAYS
    var sold_btc := mined_btc * (1.0 - float(player["treasury_hold"]))
    var revenue := sold_btc * btc_price
    revenue += hosting_profit_per_day(player) * QUARTER_DAYS
    revenue += float(player["weekly_bonus"])
    return revenue - operating_cost_per_day(player) * QUARTER_DAYS

func projected_quarter_end_cash() -> float:
    if towns.is_empty():
        return 0.0
    return float(towns[player_town_idx]["cash"]) + projected_quarter_cash_result()

func quarter_risk_message() -> String:
    if towns.is_empty():
        return ""
    var player := towns[player_town_idx]
    var projection := projected_quarter_cash_result()
    var end_cash := projected_quarter_end_cash()
    var daily_cost := max(1.0, operating_cost_per_day(player))
    var runway_days := max(0, int(end_cash / daily_cost))
    if end_cash < 0.0:
        return " DANGER: this projection puts cash below $0. Lower BTC HOLD POLICY, use SELL 25% BTC TREASURY, financing, cost cuts, or delay expansion."
    if projection < 0.0 and runway_days < 120:
        return " WARNING: only about %d days of operating-cost runway remain after this quarter." % runway_days
    if projection < 0.0:
        return " Runway after the quarter is about %d days at today's operating cost." % runway_days
    return " Projected quarter-end cash: $%d." % int(end_cash)

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
        update_hud("Quarter preview: projected cash %s $%d at current BTC, fees, uptime, power and hosting.%s Click CONFIRM END QUARTER to advance about 91 days." % [direction, abs(int(projection)), quarter_risk_message()])
        return
    quarter_confirmation_pending = false
    if is_instance_valid(quarter_button):
        quarter_button.text = "END QUARTER"
    super.advance_turn()

func advance_turn() -> void:
    quarter_confirmation_pending = false
    if is_instance_valid(quarter_button) and not campaign_complete:
        quarter_button.text = "END QUARTER"
    super.advance_turn()

func rename_complete_button() -> void:
    quarter_confirmation_pending = false
    super.rename_complete_button()
