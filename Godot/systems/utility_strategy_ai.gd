class_name HashRaceUtilityStrategyAI
extends RefCounted

const INTENTS := ["FLEET EXPANSION","ASIC RESEARCH","POWER BUILDOUT","LAND BANK","CASH DEFENSE"]

static func plan(rival: Dictionary) -> Dictionary:
    var personality: Dictionary = rival.get("personality", {})
    var cash := maxf(0.0,float(rival.get("cash",0.0)))
    var machines := maxf(0.0,float(rival.get("machines",0)))
    var mw := maxf(0.0,float(rival.get("mw",0.0)))
    var acres := maxf(0.5,float(rival.get("acres",0.5)))
    var treasury := _rating(personality,"treasury")
    var risk := _rating(personality,"risk")
    var growth := _rating(personality,"growth")
    var aggression := _rating(personality,"aggression")
    var research := _rating(personality,"research")
    var operations := _rating(personality,"operations")
    var reputation := _rating(personality,"reputation")
    var reserve_ratio := minf(0.55,0.12+treasury/250.0)
    var reserve := maxf(12000.0,cash*reserve_ratio)
    var available := maxf(0.0,cash-reserve)
    var cash_headroom := clampf(50.0+(available/maxf(12000.0,reserve))*50.0,0.0,100.0)
    var required_mw := machines*0.006
    var power_pressure := clampf((required_mw-mw)/maxf(0.25,required_mw)*100.0+50.0,0.0,100.0)
    var power_headroom := 100.0-power_pressure
    var site_density := clampf((machines/acres)*4.0,0.0,100.0)
    var low_tech_pressure := clampf(72.0-float(rival.get("tech_level",0))*9.0,20.0,90.0)
    var liquidity_stress := 100.0-cash_headroom
    var scores := {
        "FLEET EXPANSION":growth*0.34+aggression*0.28+risk*0.12+power_headroom*0.16+cash_headroom*0.10,
        "ASIC RESEARCH":research*0.46+operations*0.22+reputation*0.12+low_tech_pressure*0.12+cash_headroom*0.08,
        "POWER BUILDOUT":operations*0.28+growth*0.22+treasury*0.12+power_pressure*0.30+cash_headroom*0.08,
        "LAND BANK":growth*0.30+treasury*0.22+site_density*0.24+risk*0.10+reputation*0.08+cash_headroom*0.06,
        "CASH DEFENSE":treasury*0.38+operations*0.22+(100.0-risk)*0.16+liquidity_stress*0.24,
    }
    if available <= 2500.0:
        scores["FLEET EXPANSION"] = -1.0
    if available <= 1500.0:
        scores["ASIC RESEARCH"] = -1.0
    if available <= 5000.0:
        scores["POWER BUILDOUT"] = -1.0
        scores["LAND BANK"] = -1.0
    var ordered := INTENTS.duplicate()
    ordered.sort_custom(func(a,b): return float(scores[a]) > float(scores[b]))
    var best: String = ordered[0]
    var second_score := float(scores[ordered[1]]) if ordered.size() > 1 else 0.0
    var best_score := float(scores[best])
    var margin := maxf(0.0,best_score-second_score)
    var confidence := clampi(int(round(55.0+margin*2.2)),55,95)
    return {"intent":best,"score":best_score,"confidence":confidence,"scores":scores,"reserve":reserve,"available":available}

static func _rating(personality: Dictionary,key: String) -> float:
    return clampf(float(personality.get(key,50)),0.0,100.0)

static func debug_contract_ready() -> bool:
    var expansion := {"cash":200000.0,"machines":20,"mw":2.0,"acres":30.0,"tech_level":1,"personality":{"treasury":45,"risk":72,"growth":92,"aggression":90,"research":35,"operations":55,"reputation":50}}
    var power := {"cash":200000.0,"machines":100,"mw":0.1,"acres":30.0,"tech_level":1,"personality":{"treasury":55,"risk":50,"growth":70,"aggression":55,"research":40,"operations":92,"reputation":55}}
    var defense := {"cash":9000.0,"machines":20,"mw":1.0,"acres":20.0,"tech_level":1,"personality":{"treasury":95,"risk":10,"growth":25,"aggression":20,"research":30,"operations":90,"reputation":60}}
    return String(plan(expansion)["intent"])=="FLEET EXPANSION" and String(plan(power)["intent"])=="POWER BUILDOUT" and String(plan(defense)["intent"])=="CASH DEFENSE"
