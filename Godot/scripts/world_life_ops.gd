extends "res://scripts/world_league_standings.gd"

# v0.034: life/operations ratings have material gameplay consequences, queued
# routines use elapsed time, and manual routines refuse wasteful spending when
# their target needs are already at the 85/100 maintenance threshold.

const ROUTINE_INTERVAL_DAYS: float = 30.4375
const AUTO_ROUTINE_NEED_THRESHOLD: float = 85.0

var operator_energy: float = 72.0
var operator_focus: float = 68.0
var operator_social: float = 60.0
var queued_routine: String = "NONE"
var queued_routine_days: float = 0.0
var life_status_label: Label

func _ready() -> void:
    super._ready()
    _install_life_ops_ui()
    _refresh_life_ops_ui()

func _install_life_ops_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "LifeOpsLayer"
    layer.layer = 14
    add_child(layer)
    life_status_label = Label.new()
    life_status_label.position = Vector2(1080.0, 140.0)
    life_status_label.size = Vector2(330.0, 58.0)
    life_status_label.add_theme_font_size_override("font_size", 11)
    life_status_label.add_theme_color_override("font_color", Color("b8dce5"))
    layer.add_child(life_status_label)
    var overview := Button.new()
    overview.position = Vector2(1080.0, 202.0)
    overview.size = Vector2(330.0, 36.0)
    overview.text = "LIFE + SITE OVERVIEW"
    overview.tooltip_text = "Preview operator needs, live gameplay effects, facility context, queued routine and site fit."
    overview.pressed.connect(_open_life_overview)
    layer.add_child(overview)
    var recover := Button.new()
    recover.position = Vector2(1080.0, 242.0)
    recover.size = Vector2(105.0, 34.0)
    recover.text = "RECOVER"
    recover.tooltip_text = "$500: restore energy and focus when either needs maintenance."
    recover.pressed.connect(_recover_operator)
    layer.add_child(recover)
    var train := Button.new()
    train.position = Vector2(1190.0, 242.0)
    train.size = Vector2(105.0, 34.0)
    train.text = "TRAIN"
    train.tooltip_text = "$1,500: improve focus for technical work when Focus is below 85/100."
    train.pressed.connect(_train_operator)
    layer.add_child(train)
    var network := Button.new()
    network.position = Vector2(1300.0, 242.0)
    network.size = Vector2(110.0, 34.0)
    network.text = "NETWORK"
    network.tooltip_text = "$1,000: restore social capacity when Social is below 85/100."
    network.pressed.connect(_network_operator)
    layer.add_child(network)
    var queue := Button.new()
    queue.position = Vector2(1080.0, 281.0)
    queue.size = Vector2(330.0, 34.0)
    queue.text = "QUEUE ROUTINE: NONE  [CHANGE]"
    queue.tooltip_text = "Choose NONE, RECOVER, TRAIN, NETWORK or AUTO. AUTO services the weakest need about monthly when it is below 85/100."
    queue.pressed.connect(func() -> void:
        var options := ["NONE", "AUTO", "RECOVER", "TRAIN", "NETWORK"]
        queued_routine = String(options[(options.find(queued_routine) + 1) % options.size()])
        queued_routine_days = 0.0
        queue.text = "QUEUE ROUTINE: %s  [CHANGE]" % queued_routine
        _refresh_life_ops_ui()
    )
    layer.add_child(queue)

func _life_score() -> float:
    return clampf((operator_energy + operator_focus + operator_social) / 3.0, 0.0, 100.0)

func _rating_effect(value: float, maximum_swing: float) -> float:
    return clampf((value - 50.0) / 50.0, -1.0, 1.0) * maximum_swing

func _life_uptime_adjustment() -> float:
    return _rating_effect(operator_energy, 0.025)

func _life_research_cost_multiplier() -> float:
    return clampf(1.0 - _rating_effect(operator_focus, 0.08), 0.92, 1.08)

func _life_partner_cost_multiplier() -> float:
    return clampf(1.0 - _rating_effect(operator_social, 0.08), 0.92, 1.08)

func _uptime() -> float:
    return clampf(super._uptime() + _life_uptime_adjustment(), 0.82, 0.995)

func _research_cost_multiplier() -> float:
    return clampf(super._research_cost_multiplier() * _life_research_cost_multiplier(), 0.82, 1.20)

func _partner_cost_multiplier() -> float:
    return clampf(super._partner_cost_multiplier() * _life_partner_cost_multiplier(), 0.82, 1.20)

func _site_fit_score() -> int:
    if player.is_empty(): return 0
    var power_fit: float = clampf(float(player.get("mw", 0.0)) * 18.0, 0.0, 100.0)
    var land_fit: float = clampf(float(player.get("acres", 0.0)) * 4.0, 0.0, 100.0)
    var machine_fit: float = clampf(float(player.get("machines", 0)) / maxf(1.0, float(player.get("mw", 0.25)) * 35.0) * 100.0, 0.0, 100.0)
    return int(round((power_fit * 0.40) + (land_fit * 0.25) + (machine_fit * 0.35)))

func _open_life_overview() -> void:
    var routine_progress: int = int(round(clampf(queued_routine_days / ROUTINE_INTERVAL_DAYS * 100.0, 0.0, 100.0)))
    dialog_title.text = "OPERATOR LIFE + MINING SITE"
    dialog_text.text = "Operator ratings (0-100)\nEnergy %d  •  Focus %d  •  Social %d  •  Overall %d\n\nLIVE EFFECTS\nUptime %+0.1f%%  •  Research cost x%.3f  •  Partner cost x%.3f\n\nFacility preview\nMachines %d  •  Power %.2f MW  •  Land %.1f acres  •  Site fit %d/100\n\nQueued routine: %s  •  monthly progress %d/100\nAUTO chooses the weakest need below %d/100. Manual and fixed routines only spend company cash when their target needs maintenance." % [int(operator_energy), int(operator_focus), int(operator_social), int(_life_score()), _life_uptime_adjustment() * 100.0, _life_research_cost_multiplier(), _life_partner_cost_multiplier(), int(player.get("machines", 0)), float(player.get("mw", 0.0)), float(player.get("acres", 0.0)), _site_fit_score(), queued_routine, routine_progress, int(AUTO_ROUTINE_NEED_THRESHOLD)]
    _set_actions([])

func _spend_for_routine(cost: float) -> bool:
    if player.is_empty() or float(player.get("cash", 0.0)) < cost:
        _feedback("Not enough cash for that operator routine.")
        return false
    player["cash"] = float(player["cash"]) - cost
    return true

func _recover_operator(silent: bool = false) -> bool:
    if operator_energy >= AUTO_ROUTINE_NEED_THRESHOLD and operator_focus >= AUTO_ROUTINE_NEED_THRESHOLD:
        if not silent: _feedback("RECOVER NOT NEEDED: Energy and Focus are already at or above 85/100.")
        return false
    if not _spend_for_routine(500.0): return false
    operator_energy = minf(100.0, operator_energy + 24.0)
    operator_focus = minf(100.0, operator_focus + 8.0)
    if not silent: _feedback("RECOVER: -$500 • Energy and focus restored; mining uptime improves with Energy.")
    _refresh_ui()
    return true

func _train_operator(silent: bool = false) -> bool:
    if operator_focus >= AUTO_ROUTINE_NEED_THRESHOLD:
        if not silent: _feedback("TRAIN NOT NEEDED: Focus is already at or above 85/100.")
        return false
    if not _spend_for_routine(1500.0): return false
    operator_focus = minf(100.0, operator_focus + 18.0)
    operator_energy = maxf(0.0, operator_energy - 5.0)
    if not silent: _feedback("TRAIN: -$1,500 • Focus improved, lowering research cost; training used some energy.")
    _refresh_ui()
    return true

func _network_operator(silent: bool = false) -> bool:
    if operator_social >= AUTO_ROUTINE_NEED_THRESHOLD:
        if not silent: _feedback("NETWORK NOT NEEDED: Social is already at or above 85/100.")
        return false
    if not _spend_for_routine(1000.0): return false
    operator_social = minf(100.0, operator_social + 22.0)
    operator_energy = maxf(0.0, operator_energy - 3.0)
    if not silent: _feedback("NETWORK: -$1,000 • Social improved, lowering partner/deal cost; networking used some energy.")
    _refresh_ui()
    return true

func _auto_routine_choice() -> String:
    var lowest: float = minf(operator_energy, minf(operator_focus, operator_social))
    if lowest >= AUTO_ROUTINE_NEED_THRESHOLD:
        return "NONE"
    if operator_energy <= operator_focus and operator_energy <= operator_social:
        return "RECOVER"
    if operator_focus <= operator_social:
        return "TRAIN"
    return "NETWORK"

func _queued_routine_needed() -> bool:
    match queued_routine:
        "AUTO": return _auto_routine_choice() != "NONE"
        "RECOVER": return operator_energy < AUTO_ROUTINE_NEED_THRESHOLD or operator_focus < AUTO_ROUTINE_NEED_THRESHOLD
        "TRAIN": return operator_focus < AUTO_ROUTINE_NEED_THRESHOLD
        "NETWORK": return operator_social < AUTO_ROUTINE_NEED_THRESHOLD
    return false

func _run_queued_routine() -> bool:
    if not _queued_routine_needed():
        return true
    var routine_to_run: String = _auto_routine_choice() if queued_routine == "AUTO" else queued_routine
    match routine_to_run:
        "RECOVER": return _recover_operator(true)
        "TRAIN": return _train_operator(true)
        "NETWORK": return _network_operator(true)
    return true

func _apply_elapsed_life(days: float) -> void:
    var pressure: float = days / ROUTINE_INTERVAL_DAYS
    operator_energy = clampf(operator_energy - 8.0 * pressure, 0.0, 100.0)
    operator_focus = clampf(operator_focus - 5.0 * pressure, 0.0, 100.0)
    operator_social = clampf(operator_social - 4.0 * pressure, 0.0, 100.0)
    if queued_routine != "NONE":
        queued_routine_days += days
        while queued_routine_days >= ROUTINE_INTERVAL_DAYS:
            if not _run_queued_routine(): break
            queued_routine_days -= ROUTINE_INTERVAL_DAYS
    else:
        queued_routine_days = 0.0
    _refresh_life_ops_ui()

func _end_quarter() -> void:
    var before_days: float = elapsed_campaign_days
    super._end_quarter()
    var advanced: float = elapsed_campaign_days - before_days
    if advanced > 0.0: _apply_elapsed_life(advanced)

func _refresh_life_ops_ui() -> void:
    if is_instance_valid(life_status_label):
        life_status_label.text = "LIFE %d/100  •  SITE FIT %d/100\nENERGY %d  FOCUS %d  SOCIAL %d" % [int(_life_score()), _site_fit_score(), int(operator_energy), int(operator_focus), int(operator_social)]

func _refresh_ui() -> void:
    super._refresh_ui()
    _refresh_life_ops_ui()

func debug_life_ops_ready() -> bool:
    return operator_energy >= 0.0 and operator_energy <= 100.0 and operator_focus >= 0.0 and operator_focus <= 100.0 and operator_social >= 0.0 and operator_social <= 100.0 and _site_fit_score() >= 0 and _site_fit_score() <= 100

func debug_life_effects_material() -> bool:
    return _life_uptime_adjustment() != 0.0 and _life_research_cost_multiplier() != 1.0 and _life_partner_cost_multiplier() != 1.0
