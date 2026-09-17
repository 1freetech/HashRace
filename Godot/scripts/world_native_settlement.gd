extends "res://scripts/world_native_runtime.gd"

# The active turn path is native-only for mining/economic settlement. The older
# GDScript settlement methods remain lower in the inheritance tree for source
# history, but this top-level override prevents them from owning live state.

func _end_quarter() -> void:
    if campaign_complete:
        _feedback("Campaign complete. Start a new campaign from the setup menu.")
        return
    assert(_native_runtime_active(), "C++ runtime must be authoritative before a turn can settle.")

    var days: float = minf(turn_length_days(), maxf(0.0, float(campaign_years) * DAYS_PER_YEAR - elapsed_campaign_days))
    if days <= 0.0:
        campaign_complete = true
        return

    if not live_quarter_confirmation_pending:
        live_quarter_confirmation_pending = true
        var projected_profit: float = _project_scaled_profit(days)
        var projected_cash: float = float(player["cash"]) + projected_profit
        quarter_button.text = "CONFIRM %s TURN" % turn_length_name()
        var risk := ""
        if projected_cash < 0.0:
            risk = " DANGER: projected cash falls below $0."
        elif projected_profit < 0.0:
            risk = " Warning: this turn is projected to lose cash."
        _feedback("%s PREVIEW [C++]: %.2f days • projected cash result $%d • projected ending cash $%d.%s Confirm to settle, or press Esc to cancel." % [turn_length_name(), days, int(projected_profit), int(projected_cash), risk])
        return

    live_quarter_confirmation_pending = false
    quarter_button.text = "END %s TURN" % turn_length_name()
    var settled_turn := turn
    var before_days := elapsed_campaign_days
    var settlement := _native_settle_turn(days)
    assert(bool(settlement.get("ok", false)), String(settlement.get("message", "Native settlement failed.")))

    # Existing AI/personality/life policy code can still make decisions in
    # GDScript, but it mutates only the mirror. Commit the resulting choices
    # straight back into C++ before any subsequent economic query.
    _simulate_rivals_scaled(days)
    _apply_elapsed_life(days)
    _native_commit_external_state()

    var advanced := elapsed_campaign_days - before_days
    assert(advanced > 0.0, "C++ settlement did not advance campaign time.")
    var halving_happened := bool(settlement.get("halving_happened", false))
    var market_note := String(settlement.get("market_note", "C++ market settled."))
    var mined_sats := float(settlement.get("mined_sats", 0.0))
    var held_sats := float(settlement.get("held_sats", 0.0))
    var profit := float(settlement.get("profit", 0.0))

    if elapsed_campaign_days >= float(campaign_years) * DAYS_PER_YEAR - 0.01:
        campaign_complete = true
        quarter_button.disabled = true
        quarter_button.text = "CAMPAIGN COMPLETE"
        _open_message(
            "CAMPAIGN COMPLETE",
            "Finished %d years in %d turns on the C++ runtime. Final assets $%d • cash $%d • machines %d • %.2f MW • %.1f acres. %s" % [
                campaign_years, settled_turn, int(_asset_value()), int(player["cash"]), int(player["machines"]), float(player["mw"]), float(player["acres"]), market_note
            ]
        )
        _refresh_ui()
        return

    turn += 1
    var remaining_days: float = maxf(0.0, float(campaign_years) * DAYS_PER_YEAR - elapsed_campaign_days)
    campaign_turns = (turn - 1) + int(ceil(remaining_days / turn_length_days()))
    var note := "%s TURN %d [C++] closed: %.2f days • mined %d sats • held %d • cash result $%d. %s" % [
        turn_length_name(), settled_turn, days, int(mined_sats), int(held_sats), int(profit), market_note
    ]
    if halving_happened:
        note += " HALVING: subsidy is now %.4f BTC." % block_subsidy_btc
    _open_message("%s C++ SETTLEMENT" % turn_length_name(), note)
    _refresh_ui()
    queue_redraw()

func debug_native_settlement_ready() -> bool:
    return _native_runtime_active() and has_meta("hashrace_native_state_authority") and String(get_meta("hashrace_native_state_authority")) == "C++"
