extends RefCounted
class_name InfrastructureInventory

# Hash Race infrastructure inventory and deployment core.
# v0.065 separates warehouse stock from active/deployed hardware so only
# installed equipment changes hashrate, site MW, reliability, cost, and cooling.

signal inventory_changed
signal deployment_changed
signal item_purchased(item_id: String, quantity: int)

const CATALOG: Array[Dictionary] = [
    {"id":"asic_gen1","name":"Generation 1 ASIC Rack","category":"MINERS","price":18000.0,"effect":"hashrate","amount":9.0,"unit":"PH/s","deployable":true,"load_mw":0.30,"heat_mw":0.28,"visual":"rack"},
    {"id":"asic_s19","name":"S19-Class ASIC Rack","category":"MINERS","price":42000.0,"effect":"hashrate","amount":20.8,"unit":"PH/s","deployable":true,"load_mw":0.614,"heat_mw":0.57,"visual":"rack"},
    {"id":"asic_s21","name":"S21-Class ASIC Rack","category":"MINERS","price":95000.0,"effect":"hashrate","amount":40.0,"unit":"PH/s","deployable":true,"load_mw":0.70,"heat_mw":0.65,"visual":"rack"},
    {"id":"asic_hydro","name":"Hydro ASIC Rack","category":"MINERS","price":180000.0,"effect":"hashrate","amount":67.0,"unit":"PH/s","deployable":true,"load_mw":1.072,"heat_mw":0.74,"visual":"hydro_rack"},

    {"id":"transformer_1mw","name":"1 MW Pad Transformer","category":"POWER","price":85000.0,"effect":"mw","amount":1.0,"unit":"MW","deployable":true,"visual":"transformer"},
    {"id":"transformer_5mw","name":"5 MW Substation Transformer","category":"POWER","price":390000.0,"effect":"mw","amount":5.0,"unit":"MW","deployable":true,"visual":"transformer"},
    {"id":"switchgear","name":"Medium-Voltage Switchgear","category":"POWER","price":125000.0,"effect":"uptime","amount":0.003,"unit":"uptime","deployable":true,"visual":"switchgear"},
    {"id":"pdu","name":"Mining PDU Bank","category":"POWER","price":24000.0,"effect":"uptime","amount":0.001,"unit":"uptime","deployable":true,"visual":"pdu"},

    {"id":"gas_turbine","name":"Natural-Gas Turbine","category":"ENERGY","price":1250000.0,"effect":"energy_source","amount":18.0,"unit":"MW","deployable":true,"energy_output_mw":18.0,"capacity_factor":0.94,"power_cost_delta":-0.006,"uptime_bonus":0.004,"maintenance":2000.0,"visual":"gas"},
    {"id":"microturbine","name":"Microturbine Generator","category":"ENERGY","price":310000.0,"effect":"energy_source","amount":4.0,"unit":"MW","deployable":true,"energy_output_mw":4.0,"capacity_factor":0.90,"power_cost_delta":-0.002,"uptime_bonus":0.002,"maintenance":650.0,"visual":"gas"},
    {"id":"hydro_turbine","name":"Hydro Turbine","category":"ENERGY","price":2200000.0,"effect":"energy_source","amount":30.0,"unit":"MW","deployable":true,"energy_output_mw":30.0,"capacity_factor":0.90,"power_cost_delta":-0.010,"uptime_bonus":0.012,"maintenance":1200.0,"visual":"hydro"},
    {"id":"solar_array","name":"Solar Farm Block","category":"ENERGY","price":480000.0,"effect":"energy_source","amount":5.0,"unit":"MW","deployable":true,"energy_output_mw":5.0,"capacity_factor":0.32,"power_cost_delta":-0.0015,"uptime_bonus":-0.002,"maintenance":200.0,"visual":"solar"},
    {"id":"wind_farm","name":"Wind Farm Block","category":"ENERGY","price":1400000.0,"effect":"energy_source","amount":12.0,"unit":"MW","deployable":true,"energy_output_mw":12.0,"capacity_factor":0.42,"power_cost_delta":-0.004,"uptime_bonus":-0.001,"maintenance":700.0,"visual":"wind"},
    {"id":"oil_field","name":"Oil Field + Generator","category":"ENERGY","price":3200000.0,"effect":"energy_source","amount":25.0,"unit":"MW","deployable":true,"energy_output_mw":25.0,"capacity_factor":0.80,"power_cost_delta":-0.0045,"uptime_bonus":0.002,"maintenance":2800.0,"visual":"oil"},
    {"id":"coal_plant","name":"Coal Power Block","category":"ENERGY","price":4000000.0,"effect":"energy_source","amount":40.0,"unit":"MW","deployable":true,"energy_output_mw":40.0,"capacity_factor":0.86,"power_cost_delta":-0.005,"uptime_bonus":0.004,"maintenance":3600.0,"visual":"coal"},
    {"id":"nuclear_smr","name":"Nuclear SMR Campus","category":"ENERGY","price":12000000.0,"effect":"energy_source","amount":65.0,"unit":"MW","deployable":true,"energy_output_mw":65.0,"capacity_factor":0.95,"power_cost_delta":-0.008,"uptime_bonus":0.018,"maintenance":6500.0,"visual":"smr"},
    {"id":"battery","name":"Grid Battery Container","category":"ENERGY","price":650000.0,"effect":"uptime","amount":0.006,"unit":"uptime","deployable":true,"visual":"battery"},

    {"id":"immersion_tank","name":"Immersion Cooling Tank","category":"COOLING","price":175000.0,"effect":"efficiency","amount":0.97,"unit":"multiplier","deployable":true,"cooling_mw":0.80,"visual":"cooling"},
    {"id":"dry_cooler","name":"Industrial Dry Cooler","category":"COOLING","price":72000.0,"effect":"uptime","amount":0.003,"unit":"uptime","deployable":true,"cooling_mw":0.45,"visual":"cooling"},
    {"id":"hydro_loop","name":"Hydro Cooling Loop","category":"COOLING","price":280000.0,"effect":"efficiency","amount":0.96,"unit":"multiplier","deployable":true,"cooling_mw":1.20,"visual":"cooling"},
    {"id":"pump_skid","name":"Cooling Pump Skid","category":"COOLING","price":38000.0,"effect":"uptime","amount":0.002,"unit":"uptime","deployable":true,"cooling_mw":0.25,"visual":"cooling"},

    {"id":"container","name":"40-Foot Mining Container","category":"FACILITY","price":110000.0,"effect":"machine_capacity","amount":200.0,"unit":"machines","deployable":true,"visual":"container"},
    {"id":"modular_dc","name":"Modular Mining Hall","category":"FACILITY","price":850000.0,"effect":"machine_capacity","amount":1200.0,"unit":"machines","deployable":true,"visual":"facility"},
    {"id":"warehouse","name":"Mining Warehouse","category":"FACILITY","price":1400000.0,"effect":"machine_capacity","amount":2000.0,"unit":"machines","deployable":true,"visual":"facility"},
    {"id":"fiber","name":"Dual Fiber Uplink","category":"NETWORK","price":22000.0,"effect":"uptime","amount":0.002,"unit":"uptime","deployable":true,"visual":"network"},
    {"id":"core_switch","name":"Core Network Switch","category":"NETWORK","price":12000.0,"effect":"uptime","amount":0.001,"unit":"uptime","deployable":true,"visual":"network"},
    {"id":"monitoring","name":"Fleet Monitoring Server","category":"NETWORK","price":18000.0,"effect":"uptime","amount":0.002,"unit":"uptime","deployable":true,"visual":"network"},
    {"id":"spares","name":"ASIC Spare-Parts Pallet","category":"MAINTENANCE","price":15000.0,"effect":"uptime","amount":0.002,"unit":"uptime","deployable":true,"visual":"maintenance"},
    {"id":"repair_lab","name":"Hashboard Repair Lab","category":"MAINTENANCE","price":90000.0,"effect":"ops_cost","amount":0.98,"unit":"multiplier","deployable":true,"visual":"maintenance"},
    {"id":"thermal_camera","name":"Thermal Inspection Kit","category":"MAINTENANCE","price":6500.0,"effect":"uptime","amount":0.001,"unit":"uptime","deployable":true,"visual":"maintenance"},
    {"id":"backup_gen","name":"Backup Generator","category":"RESILIENCE","price":210000.0,"effect":"uptime","amount":0.005,"unit":"uptime","deployable":true,"energy_output_mw":2.0,"capacity_factor":0.35,"visual":"generator"},
    {"id":"fire_system","name":"Fire Suppression System","category":"RESILIENCE","price":95000.0,"effect":"uptime","amount":0.002,"unit":"uptime","deployable":true,"visual":"safety"},
    {"id":"security","name":"Site Security System","category":"RESILIENCE","price":45000.0,"effect":"asset_protection","amount":0.02,"unit":"risk","deployable":true,"visual":"security"},
    {"id":"semi_deal","name":"Semiconductor Supply Stake","category":"STRATEGIC","price":1800000.0,"effect":"machine_discount","amount":0.05,"unit":"discount","deployable":false,"visual":"strategic"}
]

var owned: Dictionary = {}
var deployed: Dictionary = {}

func item(item_id: String) -> Dictionary:
    for prototype in CATALOG:
        if String(prototype["id"]) == item_id:
            return prototype
    return {}

func quantity(item_id: String) -> int:
    return int(owned.get(item_id, 0))

func deployed_quantity(item_id: String) -> int:
    return int(deployed.get(item_id, 0))

func stored_quantity(item_id: String) -> int:
    return maxi(0, quantity(item_id) - deployed_quantity(item_id))

func add(item_id: String, count: int = 1) -> bool:
    if item(item_id).is_empty() or count <= 0:
        return false
    owned[item_id] = quantity(item_id) + count
    inventory_changed.emit()
    return true

func remove(item_id: String, count: int = 1) -> bool:
    if count <= 0 or stored_quantity(item_id) < count:
        return false
    var left: int = quantity(item_id) - count
    if left == 0:
        owned.erase(item_id)
    else:
        owned[item_id] = left
    inventory_changed.emit()
    return true

func purchase(item_id: String, company: Dictionary, count: int = 1) -> bool:
    var prototype: Dictionary = item(item_id)
    if prototype.is_empty() or count <= 0:
        return false
    var cost: float = float(prototype["price"]) * count
    if float(company.get("cash", 0.0)) < cost:
        return false
    company["cash"] = float(company["cash"]) - cost
    add(item_id, count)
    if not bool(prototype.get("deployable", true)):
        _apply_effect(prototype, company, count)
        deployed[item_id] = deployed_quantity(item_id) + count
        deployment_changed.emit()
    item_purchased.emit(item_id, count)
    return true

func deploy(item_id: String, company: Dictionary, count: int = 1) -> bool:
    var prototype: Dictionary = item(item_id)
    if prototype.is_empty() or count <= 0 or stored_quantity(item_id) < count:
        return false
    deployed[item_id] = deployed_quantity(item_id) + count
    _apply_effect(prototype, company, count)
    deployment_changed.emit()
    inventory_changed.emit()
    return true

func undeploy(item_id: String, company: Dictionary, count: int = 1) -> bool:
    var prototype: Dictionary = item(item_id)
    if prototype.is_empty() or count <= 0 or deployed_quantity(item_id) < count:
        return false
    var left: int = deployed_quantity(item_id) - count
    if left <= 0:
        deployed.erase(item_id)
    else:
        deployed[item_id] = left
    _remove_effect(prototype, company, count)
    deployment_changed.emit()
    inventory_changed.emit()
    return true

func purchase_and_deploy(item_id: String, company: Dictionary, count: int = 1) -> bool:
    var prototype: Dictionary = item(item_id)
    if prototype.is_empty():
        return false
    if not purchase(item_id, company, count):
        return false
    if bool(prototype.get("deployable", true)):
        return deploy(item_id, company, count)
    return true

func _apply_effect(prototype: Dictionary, company: Dictionary, count: int) -> void:
    var effect: String = String(prototype["effect"])
    var amount: float = float(prototype["amount"]) * count
    match effect:
        "mw":
            company["mw"] = float(company.get("mw", 0.0)) + amount
        "energy_source":
            company["mw"] = float(company.get("mw", 0.0)) + float(prototype.get("energy_output_mw", amount)) * count
        "hashrate":
            company["inventory_hashrate_ph"] = float(company.get("inventory_hashrate_ph", 0.0)) + amount
        "uptime":
            company["inventory_uptime_bonus"] = minf(0.08, float(company.get("inventory_uptime_bonus", 0.0)) + amount)
        "power_cost":
            company["inventory_power_discount"] = maxf(-0.03, float(company.get("inventory_power_discount", 0.0)) + amount)
        "efficiency":
            company["inventory_efficiency_multiplier"] = float(company.get("inventory_efficiency_multiplier", 1.0)) * pow(float(prototype["amount"]), count)
        "machine_capacity":
            company["machine_capacity"] = int(company.get("machine_capacity", 0)) + int(amount)
        "machine_discount":
            company["machine_discount"] = minf(0.25, float(company.get("machine_discount", 0.0)) + amount)
        "ops_cost":
            company["inventory_ops_multiplier"] = float(company.get("inventory_ops_multiplier", 1.0)) * pow(float(prototype["amount"]), count)
        "asset_protection":
            company["asset_protection"] = minf(0.20, float(company.get("asset_protection", 0.0)) + amount)

func _remove_effect(prototype: Dictionary, company: Dictionary, count: int) -> void:
    var effect: String = String(prototype["effect"])
    var amount: float = float(prototype["amount"]) * count
    match effect:
        "mw":
            company["mw"] = maxf(0.0, float(company.get("mw", 0.0)) - amount)
        "energy_source":
            company["mw"] = maxf(0.0, float(company.get("mw", 0.0)) - float(prototype.get("energy_output_mw", amount)) * count)
        "hashrate":
            company["inventory_hashrate_ph"] = maxf(0.0, float(company.get("inventory_hashrate_ph", 0.0)) - amount)
        "uptime":
            company["inventory_uptime_bonus"] = maxf(0.0, float(company.get("inventory_uptime_bonus", 0.0)) - amount)
        "efficiency":
            var factor: float = pow(float(prototype["amount"]), count)
            if factor > 0.0:
                company["inventory_efficiency_multiplier"] = minf(1.0, float(company.get("inventory_efficiency_multiplier", 1.0)) / factor)
        "machine_capacity":
            company["machine_capacity"] = maxi(0, int(company.get("machine_capacity", 0)) - int(amount))
        "machine_discount":
            company["machine_discount"] = maxf(0.0, float(company.get("machine_discount", 0.0)) - amount)
        "ops_cost":
            var factor: float = pow(float(prototype["amount"]), count)
            if factor > 0.0:
                company["inventory_ops_multiplier"] = minf(1.0, float(company.get("inventory_ops_multiplier", 1.0)) / factor)
        "asset_protection":
            company["asset_protection"] = maxf(0.0, float(company.get("asset_protection", 0.0)) - amount)

func total_deployed_hashrate_ph() -> float:
    var total := 0.0
    for prototype in CATALOG:
        if String(prototype["effect"]) == "hashrate":
            total += float(prototype["amount"]) * deployed_quantity(String(prototype["id"]))
    return total

func total_deployed_miner_load_mw() -> float:
    var total := 0.0
    for prototype in CATALOG:
        total += float(prototype.get("load_mw", 0.0)) * deployed_quantity(String(prototype["id"]))
    return total

func total_deployed_heat_mw() -> float:
    var total := 0.0
    for prototype in CATALOG:
        total += float(prototype.get("heat_mw", 0.0)) * deployed_quantity(String(prototype["id"]))
    return total

func total_cooling_capacity_mw() -> float:
    var total := 0.0
    for prototype in CATALOG:
        total += float(prototype.get("cooling_mw", 0.0)) * deployed_quantity(String(prototype["id"]))
    return total

func nominal_energy_capacity_mw() -> float:
    var total := 0.0
    for prototype in CATALOG:
        total += float(prototype.get("energy_output_mw", 0.0)) * deployed_quantity(String(prototype["id"]))
    return total

func current_energy_output_mw() -> float:
    var total := 0.0
    for prototype in CATALOG:
        var count: int = deployed_quantity(String(prototype["id"]))
        if count <= 0:
            continue
        total += float(prototype.get("energy_output_mw", 0.0)) * float(prototype.get("capacity_factor", 1.0)) * count
    return total

func deployed_power_cost_delta() -> float:
    var total := 0.0
    for prototype in CATALOG:
        total += float(prototype.get("power_cost_delta", 0.0)) * deployed_quantity(String(prototype["id"]))
    return clampf(total, -0.04, 0.0)

func deployed_uptime_bonus() -> float:
    var total := 0.0
    for prototype in CATALOG:
        var count: int = deployed_quantity(String(prototype["id"]))
        if count <= 0:
            continue
        if String(prototype["effect"]) == "uptime":
            total += float(prototype["amount"]) * count
        total += float(prototype.get("uptime_bonus", 0.0)) * count
    return clampf(total, -0.02, 0.08)

func maintenance_per_turn() -> float:
    var total := 0.0
    for prototype in CATALOG:
        total += float(prototype.get("maintenance", 0.0)) * deployed_quantity(String(prototype["id"]))
    return total

func deployed_visual_count(visual: String) -> int:
    var total := 0
    for prototype in CATALOG:
        if String(prototype.get("visual", "")) == visual:
            total += deployed_quantity(String(prototype["id"]))
    return total

func by_category(category: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for prototype in CATALOG:
        if String(prototype["category"]) == category:
            result.append(prototype)
    return result

func serialize() -> Dictionary:
    return {"owned": owned.duplicate(true), "deployed": deployed.duplicate(true)}

func deserialize(data: Dictionary) -> void:
    owned = Dictionary(data.get("owned", {})).duplicate(true)
    deployed = Dictionary(data.get("deployed", {})).duplicate(true)
    # Never allow deployment counts to exceed owned stock after loading old saves.
    for item_id in deployed.keys():
        deployed[item_id] = mini(int(deployed[item_id]), quantity(String(item_id)))
        if int(deployed[item_id]) <= 0:
            deployed.erase(item_id)
    inventory_changed.emit()
    deployment_changed.emit()

func debug_catalog_ready() -> bool:
    return CATALOG.size() >= 34 and CATALOG.all(func(p): return p.has("id") and p.has("price") and p.has("effect"))

func debug_deployment_separation_ready() -> bool:
    return stored_quantity("asic_s21") >= 0 and total_deployed_hashrate_ph() >= 0.0 and nominal_energy_capacity_mw() >= current_energy_output_mw()
