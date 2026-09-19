extends "res://scripts/world_v106.gd"

# Hash Race v0.107 decision-priority pass.
# Keep the END TURN preview short enough to scan while making simultaneous
# infrastructure/liquidity risk explicit and deterministic.

const V107_RISK_PRIORITY_REVISION := 1

func _safe_service_pct(power_pct: float) -> float:
    return clampf(power_pct, 0.0, 100.0)

func _power_risk_label(power_pct: float) -> String:
    var pct := _safe_service_pct(power_pct)
    if pct < 50.0:
        return "CRITICAL"
    if pct < 80.0:
        return "HIGH"
    if pct < 99.5:
        return "WATCH"
    return "READY"

func _curtailment_pct(power_pct: float) -> float:
    return 100.0 - _safe_service_pct(power_pct)

func _turn_action_hint(power_pct: float, ending_cash: float, power_cost: float) -> String:
    var pct := _safe_service_pct(power_pct)
    if pct >= 99.5:
        return super._turn_action_hint(pct, ending_cash, power_cost)

    var load_mw := maxf(0.0, _machine_load_kw() / 1000.0)
    var additional_mw := _additional_mw_for_load(pct, load_mw)
    var curtailed_th := _curtailed_hashrate_th_for(pct, maxf(0.0, _hashrate_th()))
    var cash_flag := ""
    if ending_cash < 0.0:
        cash_flag = " | CASH RISK"

    return "%s POWER | +%.2f MW | %.1f%% OUTPUT AT RISK | ~%s CURTAILED%s" % [
        _power_risk_label(pct),
        additional_mw,
        _curtailment_pct(pct),
        _format_hashrate_loss(curtailed_th),
        cash_flag,
    ]

func debug_v107_ready() -> bool:
    var combined := _turn_action_hint(80.0, -1.0, 10000.0)
    return (
        V107_RISK_PRIORITY_REVISION == 1
        and debug_v106_ready()
        and _safe_service_pct(-5.0) == 0.0
        and _safe_service_pct(105.0) == 100.0
        and _power_risk_label(0.0) == "CRITICAL"
        and _power_risk_label(60.0) == "HIGH"
        and _power_risk_label(90.0) == "WATCH"
        and _power_risk_label(100.0) == "READY"
        and is_equal_approx(_curtailment_pct(80.0), 20.0)
        and combined.contains("+" )
        and combined.contains("OUTPUT AT RISK")
        and combined.contains("CURTAILED")
        and combined.contains("CASH RISK")
    )
