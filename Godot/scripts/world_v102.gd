extends "res://scripts/world_v101.gd"

# Hash Race v0.102 curtailed-hashrate preview.
# A power shortage is easier to act on when the player can see both the missing
# infrastructure and the mining production being left offline. Keep v0.101's
# corrected MW target and add an estimated curtailed TH/s value to the action.

const V102_CURTAILMENT_PREVIEW_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v102_curtailment_preview_revision", V102_CURTAILMENT_PREVIEW_REVISION)

func _curtailed_hashrate_th(power_pct: float, fleet_hashrate_th: float) -> float:
    if power_pct >= 99.5 or fleet_hashrate_th <= 0.0:
        return 0.0
    var service_ratio := clampf(power_pct / 100.0, 0.0, 1.0)
    return maxf(0.0, fleet_hashrate_th * (1.0 - service_ratio))

func _format_hashrate_loss(hashrate_th: float) -> String:
    if hashrate_th >= 1000000.0:
        return "%.2f EH/s" % (hashrate_th / 1000000.0)
    if hashrate_th >= 1000.0:
        return "%.2f PH/s" % (hashrate_th / 1000.0)
    return "%.1f TH/s" % hashrate_th

func _turn_action_hint(power_pct: float, ending_cash: float, power_cost: float) -> String:
    if power_pct < 99.5:
        var extra_mw := _additional_mw_needed(power_pct)
        var curtailed_th := _curtailed_hashrate_th(power_pct, total_hashrate())
        var target := ""
        if extra_mw > 0.0:
            target = " (~%.1f MW more)" % extra_mw
        var loss := ""
        if curtailed_th > 0.0:
            loss = "; ~%s curtailed" % _format_hashrate_loss(curtailed_th)
        if ending_cash < 0.0:
            return "ACTION: add/deploy MW%s%s and protect cash before confirming" % [target, loss]
        return "ACTION: open ENERGY/INFRASTRUCTURE and add or deploy MW%s%s" % [target, loss]
    return super._turn_action_hint(power_pct, ending_cash, power_cost)

func debug_v102_ready() -> bool:
    return V102_CURTAILMENT_PREVIEW_REVISION == 1 and is_equal_approx(_curtailed_hashrate_th(80.0, 1000.0), 200.0) and _curtailed_hashrate_th(100.0, 1000.0) == 0.0 and _format_hashrate_loss(1500.0).contains("PH/s")
