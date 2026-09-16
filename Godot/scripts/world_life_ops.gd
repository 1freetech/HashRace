extends "res://scripts/world_league_standings.gd"

# v0.024: life/operations ratings now have material gameplay consequences.
# Low energy/focus/social reduce uptime, research effectiveness and deal execution;
# healthy operator management earns small bounded bonuses. All ratings stay 0-100.

var operator_energy: float = 72.0
var operator_focus: float = 68.0
var operator_social: float = 60.0
var queued_routine: String = "NONE"
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
    recover.tooltip_text = "$500: restore energy and focus."
    recover.pressed.connect(_recover_operator)
    layer.add_child(recover)

    var train := Button.new()
    train.position = Vector2(1190.0, 242.0)
    train.size = Vector2(105.0, 34.0)
    train.text = "TRAIN"
    train.tooltip_text = "$1,500: improve focus for technical work."
    train.pressed.connect(_train_operator)
    layer.add_child(train)

    var network := Button.new()
    network.position = Vector2(1300.0, 242.0)
    network.size = Vector2(110.0, 34.0)
    network.text = "NETWORK"
    network.tooltip_text = "$1,000: restore social capacity for partner work."
    network.pressed.connect(_network_operator)
    layer.add_child(network)

    var queue := Button.new()
    queue.position = Vector2(1080.0, 281.0)
    queue.size = Vector2(330.0, 34.0)
    queue.text = "QUEUE ROUTINE: NONE  [CHANGE]"
    queue.tooltip_text = "Persist one routine and execute it automatically after each settled turn when cash allows."
    queue.pressed.connect(func() -> void:
        var options := ["NONE", "RECOVER", "TRAIN", "NETWORK"]
        queued_routine = String(options[(options.find(queued_routine) + 1) % options.size()])
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
    if player.is_empty():
        return 0
    var power_fit: float = clampf(float(player.get("mw", 0.0)) * 18.0, 0.0, 100.0)
    var land_fit: float = clampf(float(player.get("acres", 0.0)) * 4.0, 0.0, 100.0)
    var machine_fit: float = clampf(float(player.get("machines", 0)) / maxf(1.0, float(player.get("mw", 0.25)) * 35.0) * 100.0, 0.0, 100.0)
    return int(round((power_fit * 0.40) + (land_fit * 0.25) + (machine_fit * 0.35)))

func _open_life_overview() -> void:
    dialog_title.text = "OPERATOR LIFE + MINING SITE"
    dialog_text.text = "Operator ratings (0-100)\nEnergy %d  •  Focus %d  •  Social %d  •  Overall %d\n\nLIVE EFFECTS\nUptime %+0.1f%%  •  Research cost x%.3f  •  Partner cost x%.3f\n\nFacility preview\nMachines %d  •  Power %.2f MW  •  Land %.1f acres  •  Site fit %d/100\n\nQueued routine: %s\n\nEnergy now changes mining uptime, Focus changes research cost, and Social changes partner/deal cost. Manage the operator before advancing long turns or accept the operational penalty." % [int(operator_energy), int(operator_focus), int(operator_social), int(_life_score()), _life_uptime_adjustment() * 100.0, _life_research_cost_multiplier(), _life_partner_cost_multiplier(), int(player.get("machines", 0)), float(player.get("mw", 0.0)), float(player.get("acres", 0.0)), _site_fit_score(), queued_routine]
    _set_actions([])

func _spend_for_routine(cost: float) -> bool:
    if player.is_empty() or float(player.get("cash", 0.0)) < cost:
        _feedback("Not enough cash for that operator routine.")
        return false
    player["cash"] = float(player["cash"]) - cost
    return true

func _recover_operator(silent: bool = false) -> bool:
    if not _spend_for_routine(500.0):
        return false
    operator_energy = minf(100.0, operator_energy + 24.0)
    operator_focus = minf(100.0, operator_focus + 8.0)
    if not silent:
        _feedback("RECOVER: -$500 • Energy and focus restored; mining uptime improves with Energy.")
    _refresh_ui()
    return true

func _train_operator(silent: bool = false) -> bool:
    if not _spend_for_routine(1500.0):
        return false
    operator_focus = minf(100.0, operator_focus + 18.0)
    operator_energy = maxf(0.0, operator_energy - 5.0)
    if not silent:
        _feedback("TRAIN: -$1,500 • Focus improved, lowering research cost; training used some energy.")
    _refresh_ui()
    return true

func _network_operator(silent: bool = false) -> bool:
    if not _spend_for_routine(1000.0):
        return false
    operator_social = minf(100.0, operator_social + 22.0)
    operator_energy = maxf(0.0, operator_energy - 3.0)
    if not silent:
        _feedback("NETWORK: -$1,000 • Social improved, lowering partner/deal cost; networking used some energy.")
    _refresh_ui()
    return true

func _apply_elapsed_life(days: float) -> void:
    var pressure: float = days / 30.4375
    operator_energy = clampf(operator_energy - 8.0 * pressure, 0.0, 100.0)
    operator_focus = clampf(operator_focus - 5.0 * pressure, 0.0, 100.0)
    operator_social = clampf(operator_social - 4.0 * pressure, 0.0, 100.0)
    match queued_routine:
        "RECOVER": _recover_operator(true)
        "TRAIN": _train_operator(true)
        "NETWORK": _network_operator(true)
    _refresh_life_ops_ui()

func _end_quarter() -> void:
    var before_days: float = elapsed_campaign_days
    super._end_quarter()
    var advanced: float = elapsed_campaign_days - before_days
    if advanced > 0.0:
        _apply_elapsed_life(advanced)

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
