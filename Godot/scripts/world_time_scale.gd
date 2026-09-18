extends "res://scripts/world_rpg_strategy.gd"

const TURN_LENGTHS: Array = [
    {"name": "DAY", "days": 1.0}, {"name": "MONTH", "days": 30.4375}, {"name": "QUARTER", "days": 91.3125}, {"name": "YEAR", "days": 365.25}, {"name": "CUSTOM", "days": 14.0}
]
const DAYS_PER_YEAR := 365.25
const DAYS_PER_QUARTER := 91.3125
const HALVING_DAYS := 1461.0
var turn_length_idx := 1
var elapsed_campaign_days := 0.0
var next_halving_day := HALVING_DAYS
var turn_scale_button: Button
var custom_days_spin: SpinBox
var custom_days := 14.0

func _ready() -> void:
    super._ready(); campaign_turns = int(ceil(float(campaign_years) * DAYS_PER_YEAR / turn_length_days())); _install_turn_scale_control(); _refresh_ui()
func turn_length_days() -> float: return custom_days if turn_length_name() == "CUSTOM" else float(TURN_LENGTHS[turn_length_idx]["days"])
func turn_length_name() -> String: return String(TURN_LENGTHS[turn_length_idx]["name"])
func _install_turn_scale_control() -> void:
    var layer := CanvasLayer.new(); layer.name = "TurnScaleLayer"; layer.layer = 12; add_child(layer)
    turn_scale_button = Button.new(); turn_scale_button.position = Vector2(1040,88); turn_scale_button.size = Vector2(370,42); turn_scale_button.add_theme_font_size_override("font_size",12); turn_scale_button.tooltip_text="Hotkeys: 1 Day, 2 Month, 3 Quarter, 4 Year, 5 Custom."; turn_scale_button.pressed.connect(_cycle_turn_length); layer.add_child(turn_scale_button)
    custom_days_spin=SpinBox.new(); custom_days_spin.position=Vector2(1210,134); custom_days_spin.size=Vector2(200,38); custom_days_spin.min_value=1; custom_days_spin.max_value=3650; custom_days_spin.step=1; custom_days_spin.value=custom_days; custom_days_spin.suffix=" days / turn"; custom_days_spin.value_changed.connect(_on_custom_days_changed); layer.add_child(custom_days_spin); _refresh_turn_scale_button()
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_C: _cycle_turn_length(); get_viewport().set_input_as_handled(); return
        var idx := -1
        match event.keycode: KEY_1: idx=0; KEY_2: idx=1; KEY_3: idx=2; KEY_4: idx=3; KEY_5: idx=4
        if idx >= 0: _set_turn_length(idx); get_viewport().set_input_as_handled(); return
    super._unhandled_input(event)
func _cycle_turn_length() -> void: _set_turn_length((turn_length_idx+1)%TURN_LENGTHS.size())
func _set_turn_length(idx:int)->void:
    idx=clampi(idx,0,TURN_LENGTHS.size()-1)
    if live_quarter_confirmation_pending: _invalidate_quarter_preview("Turn preview cancelled because the turn length changed.")
    turn_length_idx=idx; _recalculate_campaign_turns(); _refresh_turn_scale_button(); _refresh_ui()
func _on_custom_days_changed(days:float)->void:
    custom_days=clampf(days,1,3650)
    if turn_length_name()=="CUSTOM":
        if live_quarter_confirmation_pending: _invalidate_quarter_preview("Turn preview cancelled because the custom turn length changed.")
        _recalculate_campaign_turns(); _refresh_turn_scale_button(); _refresh_ui()
func _recalculate_campaign_turns()->void:
    campaign_turns=(turn-1)+int(ceil(maxf(0,float(campaign_years)*DAYS_PER_YEAR-elapsed_campaign_days)/turn_length_days()))
func set_custom_turn_days(days:float)->void:
    custom_days=clampf(days,1,3650)
    if is_instance_valid(custom_days_spin): custom_days_spin.set_value_no_signal(custom_days)
    _set_turn_length(4)
func custom_turn_days()->float:return custom_days
func _refresh_turn_scale_button()->void:
    if is_instance_valid(turn_scale_button): turn_scale_button.text="TURN: %s  [1 D • 2 M • 3 Q • 4 Y • 5 CUSTOM • C]" % (("CUSTOM %.0f DAYS"%custom_days) if turn_length_name()=="CUSTOM" else turn_length_name())
    if is_instance_valid(custom_days_spin): custom_days_spin.visible=turn_length_name()=="CUSTOM"
    if is_instance_valid(quarter_button) and not live_quarter_confirmation_pending and not campaign_complete: quarter_button.text="END %s TURN"%turn_length_name()
func _scaled_financial_preview(days:float)->Dictionary:
    var mined:=_btc_per_day()*days; var held:=mined*float(player["treasury_hold"]); var sold:=mined-held; var revenue:=sold*btc_price; var income:=float(player["recurring_income"])*(days/DAYS_PER_QUARTER); var power:=_machine_load_kw()*24*days*_effective_power_cost()*_uptime(); var ops:=float(player["machines"])*0.38*days; var debt:=float(player["debt"])*float(player["debt_rate"])*(days/365.0)
    return {"mined_btc":mined,"held_btc":held,"sold_btc":sold,"mining_revenue":revenue,"partner_income":income,"power_cost":power,"ops_cost":ops,"debt_cost":debt,"profit":revenue+income-power-ops-debt}
func _project_scaled_profit(days:float)->float:return float(_scaled_financial_preview(days)["profit"])
func _end_quarter()->void:
    if campaign_complete:return
    var days:=minf(turn_length_days(),maxf(0,float(campaign_years)*DAYS_PER_YEAR-elapsed_campaign_days)); if days<=0:return
    if not live_quarter_confirmation_pending:
        live_quarter_confirmation_pending=true; var p:=_scaled_financial_preview(days); quarter_button.text="CONFIRM %s TURN"%turn_length_name(); _feedback("%s PREVIEW: %.2f days • BTC %.6f • NET $%d • CASH AFTER $%d. Confirm or Esc."%[turn_length_name(),days,float(p["mined_btc"]),int(p["profit"]),int(float(player["cash"])+float(p["profit"]))]); return
    live_quarter_confirmation_pending=false; quarter_button.text="END %s TURN"%turn_length_name(); var mined:=_btc_per_day()*days; var sats:=mined*SATS_PER_BTC; var held:=sats*float(player["treasury_hold"]); var p:=_scaled_financial_preview(days); player["sats"]=float(player["sats"])+held; player["cash"]=float(player["cash"])+float(p["profit"]); player["last_profit"]=float(p["profit"]); _simulate_rivals_scaled(days); elapsed_campaign_days+=days
    var halving:=false
    while elapsed_campaign_days>=next_halving_day:block_subsidy_btc*=0.5;next_halving_day+=HALVING_DAYS;halving=true
    var note:=_advance_market_scaled(days,halving); var settled:=turn
    if elapsed_campaign_days>=float(campaign_years)*DAYS_PER_YEAR-0.01: campaign_complete=true;quarter_button.disabled=true;quarter_button.text="CAMPAIGN COMPLETE";_open_message("CAMPAIGN COMPLETE","Finished %d years in %d turns."%[campaign_years,settled]);_refresh_ui();return
    turn+=1;_recalculate_campaign_turns();_open_message("%s SETTLEMENT"%turn_length_name(),"%s TURN %d closed: %.2f days • mined %d sats • cash result $%d. %s"%[turn_length_name(),settled,days,int(sats),int(p["profit"]),note]);_refresh_ui();queue_redraw()
func _cancel_live_quarter_confirmation()->void:
    if live_quarter_confirmation_pending: live_quarter_confirmation_pending=false;quarter_button.text="END %s TURN"%turn_length_name();_feedback("Turn settlement cancelled.")
func _elapsed_probability(quarter_probability:float,days:float)->float:
    var p:=clampf(quarter_probability,0,1); return 1.0-pow(1.0-p,maxf(0,days)/DAYS_PER_QUARTER)
func _simulate_rivals_scaled(days:float)->void:
    var scale:=maxf(0,days/DAYS_PER_QUARTER)
    for i in range(rivals.size()):
        var rival:Dictionary=rivals[i]
        if bool(rival["merged"]):continue
        rival["cash"]=float(rival["cash"])*maxf(0.85,1.0+randf_range(-0.04,0.08)*sqrt(scale))
        if randf()<_elapsed_probability(0.55,days):rival["machines"]=int(rival["machines"])+max(1,int(round(float(randi_range(5,25))*maxf(0.1,scale))))
        if randf()<_elapsed_probability(0.25,days):rival["mw"]=float(rival["mw"])+0.25*maxf(1,scale)
        if randf()<_elapsed_probability(0.16,days):rival["acres"]=float(rival["acres"])+5.0*maxf(1,scale)
        rivals[i]=rival
func _advance_market_scaled(days:float,halving_happened:bool)->String:
    var scale:=sqrt(days/DAYS_PER_QUARTER); federal_rate=clampf(federal_rate+randf_range(-0.0035,0.0035)*scale,0.005,0.085); btc_price=maxf(8000,btc_price*maxf(0.72,1+randf_range(-0.12,0.18)*scale)); land_price_per_acre=maxf(1800,land_price_per_acre*maxf(0.80,1+randf_range(-0.025,0.040)*scale)); energy_market_index=clampf(energy_market_index*(1+randf_range(-0.06,0.07)*scale),0.72,1.45);network_hashrate_th*=maxf(0.90,1+randf_range(-0.015,0.075)*scale);average_fees_btc=clampf(average_fees_btc*maxf(0.50,1+randf_range(-0.28,0.38)*scale),0.04,0.85);return "Fed %.2f%% • BTC $%d • land $%d/acre."%[federal_rate*100,int(btc_price),int(land_price_per_acre)]
func _refresh_ui()->void:
    super._refresh_ui()
    if not is_instance_valid(top_stats) or player.is_empty():return
    var year:=mini(campaign_years,int(elapsed_campaign_days/DAYS_PER_YEAR)+1);var day:=int(fmod(elapsed_campaign_days,DAYS_PER_YEAR))+1;var q:=clampi(int((day-1)/(DAYS_PER_YEAR/4))+1,1,4);top_stats.text="%s | Y%d Q%d DAY %d | TURN %d | %s | Cash $%d | SATS %d"%[String(player["name"]),year,q,day,turn,turn_length_name(),int(player["cash"]),int(player["sats"])]
