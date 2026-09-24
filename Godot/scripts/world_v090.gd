extends "res://scripts/world_v089.gd"

const PowerDispatch = preload("res://systems/power_dispatch_model.gd")
const UtilityStrategyAI = preload("res://systems/utility_strategy_ai.gd")
const V090_STRATEGY_REVISION := 1
const BATTERY_DEFAULT_RESERVE_PCT := 35.0
const CRITICAL_LOAD_SHARE := 0.05
var battery_reserve_slider: HSlider

func _ready() -> void:
    super._ready()
    _ensure_battery_runtime_state()
    _install_battery_policy_slider()
    if not infrastructure_inventory.deployment_changed.is_connected(_on_v090_deployment_changed):
        infrastructure_inventory.deployment_changed.connect(_on_v090_deployment_changed)
    set_meta("hashrace_v090_strategy_revision",V090_STRATEGY_REVISION)

func _initialize_personality_runtime() -> void:
    super._initialize_personality_runtime()
    for i in range(rivals.size()):
        var rival: Dictionary = rivals[i]
        _stamp_next_rival_intent(rival)
        rivals[i] = rival

func _set_actions(actions: Array) -> void:
    super._set_actions(actions)
    if is_instance_valid(battery_reserve_slider):
        battery_reserve_slider.visible=false

func _open_energy_page(ids: Array[String],first_page: bool) -> void:
    super._open_energy_page(ids,first_page)
    if not first_page:
        return
    dialog_text.text += "\n\nBattery reserve: %d/100 • SOC %.1f / %.1f MWh" % [int(round(_battery_reserve_pct())),_battery_soc_mwh(),_battery_capacity_mwh()]
    _append_dialog_action("POWER STRATEGY",Callable(self,"_open_battery_policy"),150.0)

func _append_dialog_action(label_text: String,callback: Callable,width: float=190.0) -> void:
    if not is_instance_valid(action_row):
        return
    var button:=Button.new()
    button.custom_minimum_size=Vector2(width,42.0)
    button.text=label_text
    button.add_theme_font_size_override("font_size",11)
    button.pressed.connect(callback)
    action_row.add_child(button)

func _install_battery_policy_slider() -> void:
    if not is_instance_valid(dialog_panel):
        return
    battery_reserve_slider=HSlider.new()
    battery_reserve_slider.name="BatteryReservePolicy"
    battery_reserve_slider.position=Vector2(220.0,88.0)
    battery_reserve_slider.size=Vector2(560.0,28.0)
    battery_reserve_slider.min_value=0.0
    battery_reserve_slider.max_value=100.0
    battery_reserve_slider.step=1.0
    battery_reserve_slider.value=_battery_reserve_pct()
    battery_reserve_slider.tooltip_text="0 spends stored energy for hashrate now. 100 protects stored energy for critical operations."
    battery_reserve_slider.value_changed.connect(_on_battery_reserve_changed)
    battery_reserve_slider.visible=false
    dialog_panel.add_child(battery_reserve_slider)

func _open_battery_policy() -> void:
    _ensure_battery_runtime_state()
    dialog_title.text="POWER STRATEGY // FINITE STORAGE"
    _refresh_battery_policy_text()
    _set_actions([
        {"label":"BUY + DEPLOY BATTERY","call":Callable(self,"_buy_strategy_battery")},
        {"label":"BACK TO ENERGY","call":Callable(self,"_open_energy_market")}
    ])
    battery_reserve_slider.set_value_no_signal(_battery_reserve_pct())
    battery_reserve_slider.visible=true

func _refresh_battery_policy_text(note: String="") -> void:
    var prefix := "%s\n\n" % note if not note.is_empty() else ""
    dialog_text.text=prefix+"Reserve target %d/100 • Batteries %d • Stored %.1f / %.1f MWh.\nLower reserve favors current hashrate. Higher reserve protects energy for critical operations and future shortages." % [int(round(_battery_reserve_pct())),_battery_count(),_battery_soc_mwh(),_battery_capacity_mwh()]

func _on_battery_reserve_changed(value: float) -> void:
    if player.is_empty():
        return
    player["battery_reserve_pct"]=clampf(value,0.0,100.0)
    _refresh_battery_policy_text()
    _refresh_ui()

func _buy_strategy_battery() -> void:
    var prototype:=infrastructure_inventory.item("battery")
    if prototype.is_empty():
        _refresh_battery_policy_text("Battery catalog entry is unavailable.")
        return
    if float(player.get("cash",0.0)) < float(prototype.get("price",0.0)):
        _refresh_battery_policy_text("Need $%d for one Grid Battery Container." % int(prototype.get("price",0.0)))
        return
    if infrastructure_inventory.purchase_and_deploy("battery",player,1):
        _ensure_battery_runtime_state()
        _refresh_battery_policy_text("Battery deployed. New storage starts at 50% state of charge.")
        _refresh_ui()
        queue_redraw()
    else:
        _refresh_battery_policy_text("Battery deployment failed.")

func _on_v090_deployment_changed() -> void:
    _ensure_battery_runtime_state()

func _ensure_battery_runtime_state() -> void:
    if player.is_empty():
        return
    var count:=_battery_count()
    var previous_count:=int(player.get("battery_runtime_count",count))
    var capacity:=PowerDispatch.capacity_mwh(count)
    var soc:=float(player.get("battery_soc_mwh",PowerDispatch.capacity_mwh(previous_count)*0.5))
    if count>previous_count:
        soc += float(count-previous_count)*PowerDispatch.BATTERY_CAPACITY_MWH_PER_UNIT*0.5
    player["battery_soc_mwh"]=clampf(soc,0.0,capacity)
    player["battery_runtime_count"]=count
    if not player.has("battery_reserve_pct"):
        player["battery_reserve_pct"]=BATTERY_DEFAULT_RESERVE_PCT
    player["battery_reserve_pct"]=clampf(float(player["battery_reserve_pct"]),0.0,100.0)

func _battery_count() -> int:
    return infrastructure_inventory.deployed_quantity("battery") if infrastructure_inventory != null else 0

func _battery_capacity_mwh() -> float:
    return PowerDispatch.capacity_mwh(_battery_count())

func _battery_soc_mwh() -> float:
    return clampf(float(player.get("battery_soc_mwh",0.0)),0.0,_battery_capacity_mwh())

func _battery_reserve_pct() -> float:
    return clampf(float(player.get("battery_reserve_pct",BATTERY_DEFAULT_RESERVE_PCT)),0.0,100.0)

func _generation_without_storage_mw() -> float:
    var nominal_inventory_mw:=infrastructure_inventory.nominal_energy_capacity_mw()
    var base_grid_mw:=maxf(0.0,float(player.get("mw",0.0))-nominal_inventory_mw)
    return maxf(0.0,base_grid_mw+infrastructure_inventory.current_energy_output_mw())

func _effective_available_mw() -> float:
    var battery_now:=PowerDispatch.instantaneous_battery_output_mw(_battery_count(),_battery_soc_mwh(),_battery_reserve_pct(),1.0)
    return _generation_without_storage_mw()+battery_now

func _grid_stability_ratio() -> float:
    var load_mw:=_machine_load_kw()/1000.0
    if load_mw<=0.001:
        return 1.0
    return clampf(_effective_available_mw()/load_mw,0.0,1.0)

func _uptime_without_grid_penalty() -> float:
    var live:=super._uptime()
    var grid_penalty:=maxf(0.0,1.0-_grid_stability_ratio())*0.10
    return clampf(live+grid_penalty,0.72,0.999)

func _period_dispatch(days: float) -> Dictionary:
    _ensure_battery_runtime_state()
    var total_load_mw:=maxf(0.0,_machine_load_kw()/1000.0)
    var critical_load_mw:=total_load_mw*CRITICAL_LOAD_SHARE
    var mining_load_mw:=maxf(0.0,total_load_mw-critical_load_mw)
    return PowerDispatch.simulate_period(_generation_without_storage_mw(),mining_load_mw,critical_load_mw,_battery_count(),_battery_soc_mwh(),_battery_reserve_pct(),maxf(0.0,days)*24.0)

func _scaled_financial_preview(days: float) -> Dictionary:
    var dispatch:=_period_dispatch(days)
    var power_service:=minf(float(dispatch["critical_service_ratio"]),float(dispatch["mining_service_ratio"]))
    var effective_uptime:=_uptime_without_grid_penalty()*power_service
    var raw_btc_per_day:=0.0
    if network_hashrate_th>0.0:
        raw_btc_per_day=(_hashrate_th()/network_hashrate_th)*144.0*(block_subsidy_btc+average_fees_btc)
    var mined:=raw_btc_per_day*effective_uptime*days
    var held:=mined*float(player["treasury_hold"])
    var sold:=mined-held
    var revenue:=sold*btc_price
    var income:=float(player["recurring_income"])*(days/DAYS_PER_QUARTER)
    var power:=float(dispatch["source_energy_mwh"])*1000.0*_effective_power_cost()
    var ops:=float(player["machines"])*0.38*days
    var debt:=float(player["debt"])*float(player["debt_rate"])*(days/365.0)
    return {
        "mined_btc":mined,"held_btc":held,"sold_btc":sold,"mining_revenue":revenue,
        "partner_income":income,"power_cost":power,"ops_cost":ops,"debt_cost":debt,
        "profit":revenue+income-power-ops-debt,"power_service_ratio":power_service,
        "ending_battery_soc_mwh":float(dispatch["ending_soc_mwh"]),
        "battery_discharge_mwh":float(dispatch["battery_discharge_delivered_mwh"]),
        "battery_charge_input_mwh":float(dispatch["battery_charge_source_mwh"]),
        "curtailed_mining_mwh":float(dispatch["curtailed_mining_mwh"])
    }

func _end_quarter() -> void:
    if campaign_complete:
        return
    var days:=minf(turn_length_days(),maxf(0.0,float(campaign_years)*DAYS_PER_YEAR-elapsed_campaign_days))
    if days<=0.0:
        return
    var preview:=_scaled_financial_preview(days)
    if not live_quarter_confirmation_pending:
        live_quarter_confirmation_pending=true
        quarter_button.text="CONFIRM %s TURN"%turn_length_name()
        _feedback("%s PREVIEW: %.2f days • BTC %.6f • POWER %.0f%% • BAT %.1f MWh • NET $%d • CASH AFTER $%d. Confirm or Esc."%[turn_length_name(),days,float(preview["mined_btc"]),float(preview["power_service_ratio"])*100.0,float(preview["ending_battery_soc_mwh"]),int(preview["profit"]),int(float(player["cash"])+float(preview["profit"]))])
        return
    live_quarter_confirmation_pending=false
    quarter_button.text="END %s TURN"%turn_length_name()
    player["sats"]=float(player["sats"])+float(preview["held_btc"])*SATS_PER_BTC
    player["cash"]=float(player["cash"])+float(preview["profit"])
    player["last_profit"]=float(preview["profit"])
    player["battery_soc_mwh"]=float(preview["ending_battery_soc_mwh"])
    _simulate_rivals_scaled(days)
    elapsed_campaign_days+=days
    var halving:=false
    while elapsed_campaign_days>=next_halving_day:
        block_subsidy_btc*=0.5
        next_halving_day+=HALVING_DAYS
        halving=true
    var note:=_advance_market_scaled(days,halving)
    var settled:=turn
    if elapsed_campaign_days>=float(campaign_years)*DAYS_PER_YEAR-0.01:
        campaign_complete=true
        quarter_button.disabled=true
        quarter_button.text="CAMPAIGN COMPLETE"
        _open_message("CAMPAIGN COMPLETE","Finished %d years in %d turns."%[campaign_years,settled])
        _refresh_ui()
        return
    turn+=1
    _recalculate_campaign_turns()
    _open_message("%s SETTLEMENT"%turn_length_name(),"%s TURN %d closed: %.2f days • mined %d sats • power %.0f%% • battery %.1f MWh • cash result $%d. %s"%[turn_length_name(),settled,days,int(float(preview["mined_btc"])*SATS_PER_BTC),float(preview["power_service_ratio"])*100.0,float(preview["ending_battery_soc_mwh"]),int(preview["profit"]),note])
    _refresh_ui()
    queue_redraw()

func _run_rival_month(rival: Dictionary) -> void:
    var personality: Dictionary=rival["personality"]
    var profitable:=float(rival["cash"])>=float(personality["last_cash"])
    if profitable:
        personality["growth"]=_clamp_rating(int(personality["growth"])+1)
        if int(personality["risk"])>=60:
            personality["aggression"]=_clamp_rating(int(personality["aggression"])+1)
    else:
        personality["treasury"]=_clamp_rating(int(personality["treasury"])+2)
        personality["operations"]=_clamp_rating(int(personality["operations"])+1)
        personality["risk"]=_clamp_rating(int(personality["risk"])-1)
        personality["aggression"]=_clamp_rating(int(personality["aggression"])-1)
    rival["personality"]=personality
    var current_plan:=UtilityStrategyAI.plan(rival)
    var intent:=String(personality.get("next_intent",current_plan["intent"]))
    var available:=float(current_plan["available"])
    var action_text:="Protected cash and optimized existing operations."
    match intent:
        "FLEET EXPANSION":
            if available>2500.0:
                var spend:=minf(available,maxf(1500.0,float(rival["cash"])*(0.025+float(personality["growth"])/2200.0+float(personality["aggression"])/3200.0)))
                var machines_bought:=clampi(maxi(1,int(round(spend/900.0))),1,24)
                rival["cash"]=float(rival["cash"])-spend
                rival["machines"]=int(rival["machines"])+machines_bought
                personality["aggression"]=_clamp_rating(int(personality["aggression"])+1)
                personality["growth"]=_clamp_rating(int(personality["growth"])+1)
                personality["treasury"]=_clamp_rating(int(personality["treasury"])-1)
                action_text="Executed the announced fleet expansion: bought %d miners."%machines_bought
        "ASIC RESEARCH":
            if available>1500.0:
                var spend:=minf(available,maxf(1000.0,float(rival["cash"])*(0.012+float(personality["research"])/4500.0)))
                rival["cash"]=float(rival["cash"])-spend
                rival["tech_level"]=int(rival["tech_level"])+1
                personality["research"]=_clamp_rating(int(personality["research"])+1)
                personality["operations"]=_clamp_rating(int(personality["operations"])+1)
                action_text="Executed the announced ASIC research cycle."
        "POWER BUILDOUT":
            if available>5000.0:
                var spend:=minf(available,9000.0)
                rival["cash"]=float(rival["cash"])-spend
                rival["mw"]=float(rival["mw"])+0.25
                personality["growth"]=_clamp_rating(int(personality["growth"])+1)
                personality["operations"]=_clamp_rating(int(personality["operations"])+1)
                action_text="Executed the announced power buildout: +0.25 MW."
        "LAND BANK":
            if available>5000.0:
                var spend:=minf(available,6500.0)
                rival["cash"]=float(rival["cash"])-spend
                rival["acres"]=float(rival["acres"])+5.0
                personality["growth"]=_clamp_rating(int(personality["growth"])+1)
                personality["treasury"]=_clamp_rating(int(personality["treasury"])+1)
                action_text="Executed the announced land bank: +5 acres."
        _:
            pass
    if action_text.begins_with("Protected cash"):
        var savings:=maxf(100.0,float(rival["machines"])*8.0)
        rival["cash"]=float(rival["cash"])+savings
        personality["treasury"]=_clamp_rating(int(personality["treasury"])+1)
        personality["operations"]=_clamp_rating(int(personality["operations"])+1)
    personality["last_strategy_action"]=action_text
    personality["last_action"]=action_text
    rival["personality"]=personality
    _maybe_rival_partnership(rival)
    _maybe_rival_controversy(rival)
    personality=rival["personality"]
    personality["last_cash"]=float(rival["cash"])
    rival["personality"]=personality
    _stamp_next_rival_intent(rival)

func _stamp_next_rival_intent(rival: Dictionary) -> void:
    if not rival.has("personality"):
        return
    var plan:=UtilityStrategyAI.plan(rival)
    var personality: Dictionary=rival["personality"]
    personality["next_intent"]=String(plan["intent"])
    personality["intent_confidence"]=int(plan["confidence"])
    personality["intent_score"]=float(plan["score"])
    personality["intent_scores"]=Dictionary(plan["scores"]).duplicate(true)
    rival["personality"]=personality

func _rival_intent_text(rival: Dictionary) -> String:
    var personality: Dictionary=rival.get("personality",{})
    return "NEXT INTENT: %s • confidence %d/100\nLast strategy: %s"%[String(personality.get("next_intent","CASH DEFENSE")),int(personality.get("intent_confidence",55)),String(personality.get("last_strategy_action",personality.get("last_action","No monthly action yet.")))]

func _open_rival(entity: Dictionary) -> void:
    super._open_rival(entity)
    var rival_idx:=int(entity.get("rival_idx",-1))
    if rival_idx<0 or rival_idx>=rivals.size() or bool(rivals[rival_idx].get("merged",false)):
        return
    dialog_text.text+="\n\n"+_rival_intent_text(rivals[rival_idx])

func _open_rival_rep(entity: Dictionary) -> void:
    super._open_rival_rep(entity)
    var rival_idx:=int(entity.get("rival_idx",-1))
    if rival_idx<0 or rival_idx>=rivals.size() or bool(rivals[rival_idx].get("merged",false)):
        return
    dialog_text.text+="\n\n"+_rival_intent_text(rivals[rival_idx])

func debug_v090_ready() -> bool:
    var native_nav_ready: bool = grid_nav != null and grid_nav.has_method("debug_native_astar_ready") and bool(grid_nav.debug_native_astar_ready())
    return V090_STRATEGY_REVISION==1 and PowerDispatch.debug_contract_ready() and UtilityStrategyAI.debug_contract_ready() and native_nav_ready and _battery_reserve_pct()>=0.0 and _battery_reserve_pct()<=100.0
