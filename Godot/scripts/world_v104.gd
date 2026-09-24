extends "res://scripts/world_v103.gd"

# Hash Race v0.104 mining-output risk preview.
# Turn settlement already warns when the fleet is power constrained. Translate
# that same service deficit into curtailed Bitcoin-mining hashrate so the player
# can compare an infrastructure shortage in both MW and mining-production terms.

const V104_CURTAILMENT_PREVIEW_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v104_curtailment_preview_revision", V104_CURTAILMENT_PREVIEW_REVISION)

func _curtailed_hashrate_th_for(power_pct: float, fleet_hashrate_th: float) -> float:
    if power_pct >= 99.5 or fleet_hashrate_th <= 0.0:
        return 0.0
    var service_ratio := clampf(power_pct / 100.0, 0.0, 1.0)
    return maxf(0.0, fleet_hashrate_th * (1.0 - service_ratio))

func _format_hashrate_loss(hashrate_th: float) -> String:
    if hashrate_th >= 1000000.0:
        return "%.2f EH/s" % (hashrate_th / 1000000.0)
    if hashrate_th >= 1000.0:
        return "%.2f PH/s" % (hashrate_th / 1000.0)
    return "%.0f TH/s" % hashrate_th

func _turn_action_hint(power_pct: float, ending_cash: float, power_cost: float) -> String:
    var base_hint := super._turn_action_hint(power_pct, ending_cash, power_cost)
    if power_pct >= 99.5:
        return base_hint
    var curtailed_th := _curtailed_hashrate_th_for(power_pct, maxf(0.0, _hashrate_th()))
    if curtailed_th <= 0.0:
        return base_hint
    return "%s | CURTAILED: ~%s" % [base_hint, _format_hashrate_loss(curtailed_th)]

func debug_v104_ready() -> bool:
    return (
        V104_CURTAILMENT_PREVIEW_REVISION == 1
        and debug_v103_ready()
        and is_equal_approx(_curtailed_hashrate_th_for(80.0, 100000.0), 20000.0)
        and _curtailed_hashrate_th_for(100.0, 100000.0) == 0.0
        and _format_hashrate_loss(20000.0) == "20.00 PH/s"
    )
