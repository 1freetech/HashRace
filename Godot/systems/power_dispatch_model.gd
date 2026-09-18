class_name HashRacePowerDispatchModel
extends RefCounted

# Original Hash Race power-dispatch math, conceptually informed by the uploaded
# MIT-licensed Power System Sample by Luiz Fernando Silva. Hash Race keeps its
# own aggregate mining-site model while adopting the useful separation between
# generation, storage and consumption.

const BATTERY_CAPACITY_MWH_PER_UNIT := 4.0
const BATTERY_POWER_MW_PER_UNIT := 2.0
const ROUND_TRIP_EFFICIENCY := 0.90
const CHARGE_EFFICIENCY := 0.9486832980505138
const DISCHARGE_EFFICIENCY := 0.9486832980505138

static func capacity_mwh(battery_count: int) -> float:
    return maxf(0.0, float(battery_count) * BATTERY_CAPACITY_MWH_PER_UNIT)

static func power_limit_mw(battery_count: int) -> float:
    return maxf(0.0, float(battery_count) * BATTERY_POWER_MW_PER_UNIT)

static func reserve_mwh(battery_count: int, reserve_pct: float) -> float:
    return capacity_mwh(battery_count) * clampf(reserve_pct, 0.0, 100.0) / 100.0

static func instantaneous_battery_output_mw(battery_count: int, soc_mwh: float, reserve_pct: float, horizon_hours: float = 1.0) -> float:
    if battery_count <= 0 or horizon_hours <= 0.0:
        return 0.0
    var usable_stored_mwh := maxf(0.0, soc_mwh - reserve_mwh(battery_count, reserve_pct))
    return minf(power_limit_mw(battery_count), usable_stored_mwh * DISCHARGE_EFFICIENCY / horizon_hours)

static func simulate_period(generation_mw: float, mining_load_mw: float, critical_load_mw: float, battery_count: int, starting_soc_mwh: float, reserve_pct: float, duration_hours: float) -> Dictionary:
    var hours := maxf(0.0, duration_hours)
    var generation := maxf(0.0, generation_mw)
    var mining_load := maxf(0.0, mining_load_mw)
    var critical_load := maxf(0.0, critical_load_mw)
    var capacity := capacity_mwh(battery_count)
    var reserve := reserve_mwh(battery_count, reserve_pct)
    var soc := clampf(starting_soc_mwh, 0.0, capacity)
    if hours <= 0.0:
        return {"critical_service_ratio":1.0,"mining_service_ratio":1.0,"ending_soc_mwh":soc,"source_energy_mwh":0.0,"battery_charge_source_mwh":0.0,"battery_discharge_delivered_mwh":0.0,"curtailed_mining_mwh":0.0}

    var generated_mwh := generation * hours
    var critical_need_mwh := critical_load * hours
    var mining_need_mwh := mining_load * hours
    var direct_critical_mwh := minf(generated_mwh, critical_need_mwh)
    generated_mwh -= direct_critical_mwh
    var critical_shortfall_mwh := critical_need_mwh - direct_critical_mwh

    var usable_stored_mwh := maxf(0.0, soc - reserve)
    var discharge_deliverable_mwh := minf(usable_stored_mwh * DISCHARGE_EFFICIENCY, power_limit_mw(battery_count) * hours)
    var battery_to_critical_mwh := minf(critical_shortfall_mwh, discharge_deliverable_mwh)
    if battery_to_critical_mwh > 0.0:
        soc -= battery_to_critical_mwh / DISCHARGE_EFFICIENCY
        discharge_deliverable_mwh -= battery_to_critical_mwh
    var served_critical_mwh := direct_critical_mwh + battery_to_critical_mwh

    var direct_mining_mwh := minf(generated_mwh, mining_need_mwh)
    generated_mwh -= direct_mining_mwh
    var mining_shortfall_mwh := mining_need_mwh - direct_mining_mwh
    var battery_to_mining_mwh := minf(mining_shortfall_mwh, discharge_deliverable_mwh)
    if battery_to_mining_mwh > 0.0:
        soc -= battery_to_mining_mwh / DISCHARGE_EFFICIENCY
    var served_mining_mwh := direct_mining_mwh + battery_to_mining_mwh

    var room_mwh := maxf(0.0, capacity - soc)
    var charge_input_limit_mwh := minf(power_limit_mw(battery_count) * hours, room_mwh / CHARGE_EFFICIENCY if CHARGE_EFFICIENCY > 0.0 else 0.0)
    var battery_charge_source_mwh := minf(generated_mwh, charge_input_limit_mwh)
    soc += battery_charge_source_mwh * CHARGE_EFFICIENCY

    var direct_source_used_mwh := direct_critical_mwh + direct_mining_mwh + battery_charge_source_mwh
    var critical_ratio := 1.0 if critical_need_mwh <= 0.000001 else clampf(served_critical_mwh / critical_need_mwh, 0.0, 1.0)
    var mining_ratio := 1.0 if mining_need_mwh <= 0.000001 else clampf(served_mining_mwh / mining_need_mwh, 0.0, 1.0)
    return {
        "critical_service_ratio":critical_ratio,
        "mining_service_ratio":mining_ratio,
        "ending_soc_mwh":clampf(soc,0.0,capacity),
        "source_energy_mwh":direct_source_used_mwh,
        "battery_charge_source_mwh":battery_charge_source_mwh,
        "battery_discharge_delivered_mwh":battery_to_critical_mwh+battery_to_mining_mwh,
        "curtailed_mining_mwh":maxf(0.0,mining_need_mwh-served_mining_mwh),
        "generated_surplus_mwh":maxf(0.0,generated_mwh-battery_charge_source_mwh),
    }

static func debug_contract_ready() -> bool:
    var no_storage := simulate_period(1.0,2.0,0.0,0,0.0,0.0,1.0)
    var with_storage := simulate_period(1.0,2.0,0.0,1,4.0,0.0,1.0)
    var protected := simulate_period(0.0,2.0,0.0,1,4.0,100.0,1.0)
    var long_shortage := simulate_period(0.0,2.0,0.0,1,4.0,0.0,24.0*30.0)
    var charging := simulate_period(3.0,1.0,0.0,1,0.0,0.0,1.0)
    return float(no_storage["mining_service_ratio"]) < 0.51 and float(with_storage["mining_service_ratio"]) > 0.99 and float(protected["mining_service_ratio"]) <= 0.001 and float(long_shortage["mining_service_ratio"]) < 0.01 and float(charging["source_energy_mwh"]) > 1.0 and float(charging["ending_soc_mwh"]) > 0.0
