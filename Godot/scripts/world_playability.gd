extends "res://scripts/world_campaign.gd"

# Playability layer for the quarterly campaign. Ending a quarter moves roughly
# three months of simulation at once, so require a second click and show the
# current cash projection before committing the turn.
var quarter_confirmation_pending := false
var quarter_button: Button

func configure_campaign_buttons() -> void:
    super.configure_campaign_buttons()
    for node in find_children("*", "Button", true, false):
        var button := node as Button
        if button != null and button.text == "END QUARTER":
            quarter_button = button
            disconnect_button(button)
            button.pressed.connect(request_end_quarter)
            break

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
        update_hud("Quarter preview: projected cash %s $%d at current BTC, fees, uptime, power and hosting. Click CONFIRM END QUARTER to advance about 91 days." % [direction, abs(int(projection))])
        return
    quarter_confirmation_pending = false
    if is_instance_valid(quarter_button):
        quarter_button.text = "END QUARTER"
    super.advance_turn()

func advance_turn() -> void:
    # Keep keyboard/script calls safe too: the visible button is the intended
    # player path, while inherited systems may still call advance_turn directly.
    quarter_confirmation_pending = false
    if is_instance_valid(quarter_button) and not campaign_complete:
        quarter_button.text = "END QUARTER"
    super.advance_turn()

func rename_complete_button() -> void:
    quarter_confirmation_pending = false
    super.rename_complete_button()
