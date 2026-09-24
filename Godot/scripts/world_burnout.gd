extends "res://scripts/world_life_ops.gd"

# v0.033: sustained low Energy and Focus create a visible 0-100 burnout risk.
# Burnout can reduce mining uptime by up to 3 percentage points. AUTO prioritizes
# recovery at high burnout, and manual TRAIN is blocked until burnout is safer.

const BURNOUT_START_RATING: float = 35.0
const HIGH_BURNOUT_RISK: int = 50
const MAX_BURNOUT_UPTIME_PENALTY: float = 0.03

func _burnout_risk() -> int:
    var energy_deficit: float = maxf(0.0, BURNOUT_START_RATING - operator_energy) / BURNOUT_START_RATING
    var focus_deficit: float = maxf(0.0, BURNOUT_START_RATING - operator_focus) / BURNOUT_START_RATING
    return int(round(clampf((energy_deficit + focus_deficit) * 0.5 * 100.0, 0.0, 100.0)))

func _burnout_uptime_penalty() -> float:
    return (float(_burnout_risk()) / 100.0) * MAX_BURNOUT_UPTIME_PENALTY

func _life_uptime_adjustment() -> float:
    return super._life_uptime_adjustment() - _burnout_uptime_penalty()

func _auto_routine_choice() -> String:
    if _burnout_risk() >= HIGH_BURNOUT_RISK:
        return "RECOVER"
    return super._auto_routine_choice()

func _train_operator(silent: bool = false) -> bool:
    if _burnout_risk() >= HIGH_BURNOUT_RISK:
        if not silent:
            _feedback("TRAIN BLOCKED: burnout is %d/100. RECOVER first to protect mining uptime." % _burnout_risk())
        return false
    return super._train_operator(silent)

func _open_life_overview() -> void:
    super._open_life_overview()
    var training_note: String = "TRAIN LOCKED — RECOVER FIRST" if _burnout_risk() >= HIGH_BURNOUT_RISK else "TRAIN READY"
    dialog_text.text += "\n\nBURNOUT RISK %d/100  •  uptime penalty -%.1f%%\nRisk starts when Energy or Focus falls below %d/100. At %d/100 burnout, AUTO prioritizes RECOVER and manual TRAIN is locked until recovery.\n%s" % [_burnout_risk(), _burnout_uptime_penalty() * 100.0, int(BURNOUT_START_RATING), HIGH_BURNOUT_RISK, training_note]

func _refresh_life_ops_ui() -> void:
    super._refresh_life_ops_ui()
    if is_instance_valid(life_status_label):
        var high_burnout: bool = _burnout_risk() >= HIGH_BURNOUT_RISK
        var auto_note: String = "  •  AUTO→RECOVER" if queued_routine == "AUTO" and high_burnout else ""
        var train_note: String = "  •  TRAIN LOCKED" if high_burnout else ""
        life_status_label.text += "\nBURNOUT %d/100  •  UPTIME -%.1f%%%s%s" % [_burnout_risk(), _burnout_uptime_penalty() * 100.0, auto_note, train_note]

func debug_burnout_ready() -> bool:
    var risk: int = _burnout_risk()
    return risk >= 0 and risk <= 100 and _burnout_uptime_penalty() >= 0.0 and _burnout_uptime_penalty() <= MAX_BURNOUT_UPTIME_PENALTY
