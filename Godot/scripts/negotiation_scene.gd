extends CanvasLayer
class_name HashRaceNegotiationScene

signal negotiation_finished(result: Dictionary)
signal scene_closed(result: Dictionary)

@export var opponent_name: String = "Rival Miner"
@export var opponent_company: String = "Independent Miner"
@export var player_company: String = "Player Mining Co."
@export_range(0, 100, 1) var opponent_power: int = 60
@export_range(0, 100, 1) var opponent_greed: int = 40
@export_range(0, 100, 1) var player_reputation: int = 50
@export_range(0, 100, 1) var player_leverage: int = 50
@export var deal_value_usd: float = 12000.0
@export var player_cash_usd: float = 100000.0
@export var reward_mw: float = 0.05
@export var deal_label: String = "SHARED POWER CAPACITY"
@export var target_asset_label: String = "0.05 MW FLEX CAPACITY"
@export var rival_idx: int = -1

var negotiation_active: bool = false
var resolved: bool = false
var player_offer: float = 0.0
var opponent_offer: float = 0.0
var last_result: Dictionary = {}
var _context: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var background: ColorRect = $Background
@onready var intro_anim: AnimationPlayer = $IntroAnimation
@onready var intro_title: Label = $IntroTitle
@onready var player_card: PanelContainer = $PlayerCard
@onready var opponent_card: PanelContainer = $OpponentCard
@onready var player_name_label: Label = $PlayerCard/Margin/VBox/PlayerName
@onready var player_stat_label: Label = $PlayerCard/Margin/VBox/PlayerStat
@onready var opponent_name_label: Label = $OpponentCard/Margin/VBox/OpponentName
@onready var opponent_stat_label: Label = $OpponentCard/Margin/VBox/OpponentStat
@onready var negotiation_panel: PanelContainer = $NegotiationPanel
@onready var deal_label_node: Label = $NegotiationPanel/Margin/VBox/StatusRow/DealLabel
@onready var offer_state_label: Label = $NegotiationPanel/Margin/VBox/StatusRow/OfferState
@onready var pressure_label: Label = $NegotiationPanel/Margin/VBox/PressureLabel
@onready var dialogue: RichTextLabel = $NegotiationPanel/Margin/VBox/DialogueBox
@onready var success_meter: ProgressBar = $NegotiationPanel/Margin/VBox/SuccessMeter
@onready var result_label: RichTextLabel = $NegotiationPanel/Margin/VBox/ResultLabel
@onready var make_offer_button: Button = $NegotiationPanel/Margin/VBox/OfferBox/MakeOfferButton
@onready var counter_button: Button = $NegotiationPanel/Margin/VBox/OfferBox/CounterOfferButton
@onready var walk_away_button: Button = $NegotiationPanel/Margin/VBox/OfferBox/WalkAwayButton

func configure(context_data: Dictionary) -> void:
    _context = context_data.duplicate(true)
    opponent_name = String(context_data.get("opponent_name", opponent_name))
    opponent_company = String(context_data.get("opponent_company", opponent_company))
    player_company = String(context_data.get("player_company", player_company))
    opponent_power = clampi(int(context_data.get("opponent_power", opponent_power)), 0, 100)
    opponent_greed = clampi(int(context_data.get("opponent_greed", opponent_greed)), 0, 100)
    player_reputation = clampi(int(context_data.get("player_reputation", player_reputation)), 0, 100)
    player_leverage = clampi(int(context_data.get("player_leverage", player_leverage)), 0, 100)
    deal_value_usd = maxf(1.0, float(context_data.get("deal_value_usd", deal_value_usd)))
    player_cash_usd = maxf(0.0, float(context_data.get("player_cash_usd", player_cash_usd)))
    reward_mw = maxf(0.0, float(context_data.get("reward_mw", reward_mw)))
    deal_label = String(context_data.get("deal_label", deal_label))
    target_asset_label = String(context_data.get("target_asset_label", target_asset_label))
    rival_idx = int(context_data.get("rival_idx", rival_idx))

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _rng.randomize()
    _connect_buttons()
    _apply_context_to_ui()
    _build_intro_animation()
    call_deferred("_play_intro")

func _connect_buttons() -> void:
    make_offer_button.pressed.connect(Callable(self, "_make_offer"))
    counter_button.pressed.connect(Callable(self, "_counter_offer"))
    walk_away_button.pressed.connect(Callable(self, "_walk_away"))

func _apply_context_to_ui() -> void:
    player_name_label.text = player_company
    player_stat_label.text = "REP %d  //  LEVERAGE %d" % [player_reputation, player_leverage]
    opponent_name_label.text = opponent_name
    opponent_stat_label.text = "%s  //  POWER %d  //  GREED %d" % [opponent_company, opponent_power, opponent_greed]
    deal_label_node.text = deal_label
    pressure_label.text = "TARGET %s" % target_asset_label
    dialogue.text = ""
    result_label.text = ""
    success_meter.value = 0.0
    _refresh_offer_state()

func _build_intro_animation() -> void:
    if intro_anim.has_animation(&"intro"):
        return
    var animation: Animation = Animation.new()
    animation.length = 0.72

    var bg_track: int = animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(bg_track, NodePath("Background:modulate"))
    animation.track_insert_key(bg_track, 0.0, Color(1.0, 1.0, 1.0, 0.0))
    animation.track_insert_key(bg_track, 0.42, Color(1.0, 1.0, 1.0, 1.0))

    var title_track: int = animation.add_track(Animation.TYPE_VALUE)
    animation.track_set_path(title_track, NodePath("IntroTitle:modulate"))
    animation.track_insert_key(title_track, 0.0, Color(0.35, 1.0, 0.50, 0.0))
    animation.track_insert_key(title_track, 0.18, Color(0.35, 1.0, 0.50, 1.0))
    animation.track_insert_key(title_track, 0.46, Color(1.0, 1.0, 1.0, 1.0))
    animation.track_insert_key(title_track, 0.72, Color(0.35, 1.0, 0.50, 1.0))

    var library: AnimationLibrary = AnimationLibrary.new()
    library.add_animation(&"intro", animation)
    intro_anim.add_animation_library(&"", library)

func _play_intro() -> void:
    negotiation_active = false
    negotiation_panel.visible = false
    intro_title.visible = true
    background.modulate = Color(1.0, 1.0, 1.0, 0.0)
    intro_title.modulate = Color(0.35, 1.0, 0.50, 0.0)

    await get_tree().process_frame
    var player_target: Vector2 = player_card.position
    var opponent_target: Vector2 = opponent_card.position
    player_card.position = player_target + Vector2(-360.0, 0.0)
    opponent_card.position = opponent_target + Vector2(360.0, 0.0)

    var slide_tween: Tween = create_tween()
    slide_tween.set_parallel(true)
    slide_tween.tween_property(player_card, "position", player_target, 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    slide_tween.tween_property(opponent_card, "position", opponent_target, 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

    intro_anim.play(&"intro")
    await intro_anim.animation_finished
    _screen_shake()
    await get_tree().create_timer(0.10).timeout

    intro_title.visible = false
    negotiation_panel.visible = true
    negotiation_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
    var panel_tween: Tween = create_tween()
    panel_tween.tween_property(negotiation_panel, "modulate", Color.WHITE, 0.18)

    negotiation_active = true
    dialogue.text = "[b]NEGOTIATION OPEN[/b]\n%s from %s sits down across the table. The current package is %s." % [opponent_name, opponent_company, target_asset_label]
    _refresh_offer_state()

func _screen_shake() -> void:
    var shake: Tween = create_tween()
    shake.tween_property(self, "offset", Vector2(7.0, -5.0), 0.04).from(Vector2.ZERO)
    shake.tween_property(self, "offset", Vector2(-5.0, 4.0), 0.04)
    shake.tween_property(self, "offset", Vector2.ZERO, 0.05)

func _make_offer() -> void:
    if not negotiation_active or resolved:
        return
    if player_offer <= 0.0:
        player_offer = _round_money(deal_value_usd * 0.72)
    else:
        player_offer = _round_money(minf(deal_value_usd * 1.08, player_offer + deal_value_usd * 0.06))

    dialogue.text = "You put %s on the table for %s." % [_money(player_offer), target_asset_label]
    var success_score: float = _calculate_success(player_offer, true)
    if success_score >= 67.0:
        _resolve(true, "offer_accepted", player_offer, 1)
        return

    _issue_counter()
    _refresh_offer_state()

func _counter_offer() -> void:
    if not negotiation_active or resolved:
        return
    if player_offer <= 0.0:
        player_offer = _round_money(deal_value_usd * 0.72)
    if opponent_offer <= 0.0:
        _issue_counter()
        if resolved:
            return

    player_offer = _round_money((player_offer + opponent_offer) * 0.50)
    dialogue.text = "You counter at %s and ask %s to close the gap." % [_money(player_offer), opponent_name]
    var success_score: float = _calculate_success(player_offer, true)
    if success_score >= 62.0 or player_offer >= opponent_offer * 0.93:
        _resolve(true, "counter_accepted", player_offer, 1)
        return

    opponent_offer = _round_money(maxf(player_offer, opponent_offer - deal_value_usd * 0.04))
    dialogue.text += "\n\n%s moves only slightly: %s." % [opponent_name, _money(opponent_offer)]
    _refresh_offer_state()

func _issue_counter() -> void:
    opponent_offer = _round_money(deal_value_usd * (0.92 + float(opponent_greed) * 0.003))
    if player_offer >= opponent_offer * 0.94:
        _resolve(true, "offer_accepted", player_offer, 1)
        return
    dialogue.text += "\n\n%s counters at %s. Their posture is %s." % [opponent_name, _money(opponent_offer), _pressure_band()]
    _refresh_offer_state()

func _walk_away() -> void:
    if resolved:
        return
    dialogue.text = "You walk away with your cash and optionality intact."
    _resolve(false, "walked_away", 0.0, 0)

func _calculate_success(offer_value: float, include_random: bool) -> float:
    var fair_value: float = maxf(1.0, deal_value_usd)
    var offer_ratio: float = clampf(offer_value / fair_value, 0.0, 1.35)
    var noise: float = _rng.randf_range(-8.0, 8.0) if include_random else 0.0
    var score: float = offer_ratio * 50.0
    score += float(player_reputation) * 0.28
    score += float(player_leverage) * 0.22
    score -= float(opponent_greed) * 0.25
    score -= float(opponent_power) * 0.18
    score += noise
    return clampf(score, 0.0, 100.0)

func _pressure_band() -> String:
    var resistance: int = clampi(int(roundf(float(opponent_power + opponent_greed) * 0.50)), 0, 100)
    if resistance >= 75:
        return "HARD"
    if resistance >= 50:
        return "FIRM"
    return "OPEN"

func _resolve(success: bool, outcome: String, final_cost_usd: float, reputation_delta: int) -> void:
    if resolved:
        return

    var success_state: bool = success
    var outcome_state: String = outcome
    var cost_state: float = maxf(0.0, final_cost_usd)
    var rep_state: int = reputation_delta

    if success_state and cost_state > player_cash_usd:
        success_state = false
        outcome_state = "insufficient_cash"
        cost_state = 0.0
        rep_state = 0

    resolved = true
    negotiation_active = false
    _set_buttons_disabled(true)

    last_result = {
        "success": success_state,
        "outcome": outcome_state,
        "final_cost_usd": cost_state,
        "reputation_delta": rep_state,
        "reward_mw": reward_mw,
        "reward_machines": int(_context.get("reward_machines", 0)),
        "reward_efficiency_bonus": float(_context.get("reward_efficiency_bonus", 0.0)),
        "deal_type": String(_context.get("deal_type", "rival_capacity")),
        "source_kind": String(_context.get("source_kind", "mining_company")),
        "computer_company_id": String(_context.get("computer_company_id", "")),
        "deal_label": deal_label,
        "target_asset_label": target_asset_label,
        "rival_idx": rival_idx,
        "opponent_name": opponent_name,
        "opponent_company": opponent_company
    }

    if success_state:
        result_label.text = "[color=#62ff82][b]DEAL CLOSED[/b][/color]  %s for %s\nPress ESC to return to the district." % [target_asset_label, _money(cost_state)]
    elif outcome_state == "insufficient_cash":
        result_label.text = "[color=#ffb454][b]DEAL STALLED[/b][/color]  The terms exceed available cash.\nPress ESC to return."
    else:
        result_label.text = "[color=#ff6666][b]NO DEAL[/b][/color]  Outcome: %s\nPress ESC to return." % outcome_state.replace("_", " ").to_upper()

    _refresh_offer_state()
    negotiation_finished.emit(last_result.duplicate(true))

func _set_buttons_disabled(disabled_state: bool) -> void:
    make_offer_button.disabled = disabled_state
    counter_button.disabled = disabled_state
    walk_away_button.disabled = disabled_state

func _refresh_offer_state() -> void:
    var offer_text: String = "--" if player_offer <= 0.0 else _money(player_offer)
    var ask_text: String = "--" if opponent_offer <= 0.0 else _money(opponent_offer)
    offer_state_label.text = "YOUR OFFER %s   //   THEIR ASK %s" % [offer_text, ask_text]
    var probe_offer: float = player_offer if player_offer > 0.0 else deal_value_usd * 0.72
    var estimate: float = _calculate_success(probe_offer, false)
    success_meter.value = estimate
    pressure_label.text = "LEVERAGE %d/100  •  REP %d/100  •  DEAL READ %.0f/100  •  TARGET %s" % [player_leverage, player_reputation, estimate, target_asset_label]

func _round_money(value: float) -> float:
    return roundf(value / 100.0) * 100.0

func _money(value: float) -> String:
    return "$%d" % int(roundf(value))

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel"):
        if not resolved:
            _resolve(false, "walked_away", 0.0, 0)
        scene_closed.emit(last_result.duplicate(true))
        get_viewport().set_input_as_handled()
        queue_free()

func debug_force_open() -> void:
    intro_anim.stop()
    intro_title.visible = false
    background.modulate = Color.WHITE
    player_card.modulate = Color.WHITE
    opponent_card.modulate = Color.WHITE
    negotiation_panel.visible = true
    negotiation_panel.modulate = Color.WHITE
    negotiation_active = true
    offset = Vector2.ZERO
    dialogue.text = "[b]NEGOTIATION OPEN[/b] // DEBUG"
    _refresh_offer_state()

func debug_ready() -> bool:
    return (
        is_instance_valid(dialogue)
        and is_instance_valid(success_meter)
        and is_instance_valid(make_offer_button)
        and is_instance_valid(counter_button)
        and is_instance_valid(walk_away_button)
        and is_instance_valid(intro_anim)
    )

func debug_snapshot() -> Dictionary:
    return {
        "active": negotiation_active,
        "resolved": resolved,
        "player_offer": player_offer,
        "opponent_offer": opponent_offer,
        "meter": float(success_meter.value) if is_instance_valid(success_meter) else 0.0,
        "opponent": opponent_name,
        "company": opponent_company,
        "deal": deal_label,
        "target": target_asset_label,
        "result": last_result.duplicate(true)
    }
