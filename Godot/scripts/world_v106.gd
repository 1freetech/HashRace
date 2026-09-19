extends "res://scripts/world_v105.gd"

# Hash Race v0.106 turn-preview priority fix.
# When a turn has both a power shortage and negative projected cash, preserve
# both recovery priorities instead of letting the inherited power-only hint hide
# the liquidity risk. This keeps the preview actionable before settlement.

const V106_COMBINED_RISK_REVISION := 1

func _turn_action_hint(power_pct: float, ending_cash: float, power_cost: float) -> String:
    if power_pct < 99.5 and ending_cash < 0.0:
        var load_mw := maxf(0.0, _machine_load_kw() / 1000.0)
        var additional_mw := _additional_mw_for_load(power_pct, load_mw)
        var mw_target := ""
        if additional_mw > 0.0:
            mw_target = " (~%.2f MW)" % additional_mw
        var curtailed_th := _curtailed_hashrate_th_for(power_pct, maxf(0.0, _hashrate_th()))
        var curtailed := ""
        if curtailed_th > 0.0:
            curtailed = " | CURTAILED: ~%s" % _format_hashrate_loss(curtailed_th)
        return "ACTION: add/deploy MW%s and protect cash before confirming%s" % [mw_target, curtailed]
    return super._turn_action_hint(power_pct, ending_cash, power_cost)

func debug_v106_ready() -> bool:
    var combined := _turn_action_hint(80.0, -1.0, 10000.0)
    return (
        V106_COMBINED_RISK_REVISION == 1
        and debug_v105_ready()
        and combined.contains("MW")
        and combined.contains("cash")
        and combined.contains("CURTAILED")
        and _turn_action_hint(100.0, -1.0, 10000.0).contains("raise cash")
    )
