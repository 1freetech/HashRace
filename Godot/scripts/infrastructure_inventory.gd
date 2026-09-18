extends RefCounted
class_name InfrastructureInventory

# Hash Race inventory core. Architecture is clean-room GDScript inspired by
# MIT-licensed Godot inventory projects such as GLoot: data-driven item
# prototypes, separate owned-item state, add/remove operations, categories,
# quantities, and serialization. Hash Race's implementation and mining effects
# are original and purpose-built for infrastructure rather than RPG loot.

signal inventory_changed
signal item_purchased(item_id: String, quantity: int)

const CATALOG: Array[Dictionary] = [
    {"id":"asic_gen1","name":"Generation 1 ASIC Rack","category":"MINERS","price":18000.0,"effect":"hashrate","amount":9.0,"unit":"PH/s"},
    {"id":"asic_s19","name":"S19-Class ASIC Rack","category":"MINERS","price":42000.0,"effect":"hashrate","amount":20.8,"unit":"PH/s"},
    {"id":"asic_s21","name":"S21-Class ASIC Rack","category":"MINERS","price":95000.0,"effect":"hashrate","amount":40.0,"unit":"PH/s"},
    {"id":"asic_hydro","name":"Hydro ASIC Rack","category":"MINERS","price":180000.0,"effect":"hashrate","amount":67.0,"unit":"PH/s"},
    {"id":"transformer_1mw","name":"1 MW Pad Transformer","category":"POWER","price":85000.0,"effect":"mw","amount":1.0,"unit":"MW"},
    {"id":"transformer_5mw","name":"5 MW Substation Transformer","category":"POWER","price":390000.0,"effect":"mw","amount":5.0,"unit":"MW"},
    {"id":"switchgear","name":"Medium-Voltage Switchgear","category":"POWER","price":125000.0,"effect":"uptime","amount":0.003,"unit":"uptime"},
    {"id":"pdu","name":"Mining PDU Bank","category":"POWER","price":24000.0,"effect":"uptime","amount":0.001,"unit":"uptime"},
    {"id":"gas_turbine","name":"Natural-Gas Turbine","category":"ENERGY","price":1250000.0,"effect":"power_cost","amount":-0.006,"unit":"$/kWh"},
    {"id":"microturbine","name":"Microturbine Generator","category":"ENERGY","price":310000.0,"effect":"power_cost","amount":-0.002,"unit":"$/kWh"},
    {"id":"hydro_turbine","name":"Hydro Turbine","category":"ENERGY","price":2200000.0,"effect":"power_cost","amount":-0.010,"unit":"$/kWh"},
    {"id":"solar_array","name":"Solar Array Block","category":"ENERGY","price":480000.0,"effect":"power_cost","amount":-0.0015,"unit":"$/kWh"},
    {"id":"battery","name":"Grid Battery Container","category":"ENERGY","price":650000.0,"effect":"uptime","amount":0.006,"unit":"uptime"},
    {"id":"immersion_tank","name":"Immersion Cooling Tank","category":"COOLING","price":175000.0,"effect":"efficiency","amount":0.97,"unit":"multiplier"},
    {"id":"dry_cooler","name":"Industrial Dry Cooler","category":"COOLING","price":72000.0,"effect":"uptime","amount":0.003,"unit":"uptime"},
    {"id":"hydro_loop","name":"Hydro Cooling Loop","category":"COOLING","price":280000.0,"effect":"efficiency","amount":0.96,"unit":"multiplier"},
    {"id":"pump_skid","name":"Cooling Pump Skid","category":"COOLING","price":38000.0,"effect":"uptime","amount":0.002,"unit":"uptime"},
    {"id":"container","name":"40-Foot Mining Container","category":"FACILITY","price":110000.0,"effect":"machine_capacity","amount":200.0,"unit":"machines"},
    {"id":"modular_dc","name":"Modular Mining Hall","category":"FACILITY","price":850000.0,"effect":"machine_capacity","amount":1200.0,"unit":"machines"},
    {"id":"warehouse","name":"Mining Warehouse","category":"FACILITY","price":1400000.0,"effect":"machine_capacity","amount":2000.0,"unit":"machines"},
    {"id":"fiber","name":"Dual Fiber Uplink","category":"NETWORK","price":22000.0,"effect":"uptime","amount":0.002,"unit":"uptime"},
    {"id":"core_switch","name":"Core Network Switch","category":"NETWORK","price":12000.0,"effect":"uptime","amount":0.001,"unit":"uptime"},
    {"id":"monitoring","name":"Fleet Monitoring Server","category":"NETWORK","price":18000.0,"effect":"uptime","amount":0.002,"unit":"uptime"},
    {"id":"spares","name":"ASIC Spare-Parts Pallet","category":"MAINTENANCE","price":15000.0,"effect":"uptime","amount":0.002,"unit":"uptime"},
    {"id":"repair_lab","name":"Hashboard Repair Lab","category":"MAINTENANCE","price":90000.0,"effect":"ops_cost","amount":0.98,"unit":"multiplier"},
    {"id":"thermal_camera","name":"Thermal Inspection Kit","category":"MAINTENANCE","price":6500.0,"effect":"uptime","amount":0.001,"unit":"uptime"},
    {"id":"backup_gen","name":"Backup Generator","category":"RESILIENCE","price":210000.0,"effect":"uptime","amount":0.005,"unit":"uptime"},
    {"id":"fire_system","name":"Fire Suppression System","category":"RESILIENCE","price":95000.0,"effect":"uptime","amount":0.002,"unit":"uptime"},
    {"id":"security","name":"Site Security System","category":"RESILIENCE","price":45000.0,"effect":"asset_protection","amount":0.02,"unit":"risk"},
    {"id":"semi_deal","name":"Semiconductor Supply Stake","category":"STRATEGIC","price":1800000.0,"effect":"machine_discount","amount":0.05,"unit":"discount"}
]

var owned: Dictionary = {}

func item(item_id: String) -> Dictionary:
    for prototype in CATALOG:
        if String(prototype["id"]) == item_id:
            return prototype
    return {}

func quantity(item_id: String) -> int:
    return int(owned.get(item_id, 0))

func add(item_id: String, count: int = 1) -> bool:
    if item(item_id).is_empty() or count <= 0:
        return false
    owned[item_id] = quantity(item_id) + count
    inventory_changed.emit()
    return true

func remove(item_id: String, count: int = 1) -> bool:
    if count <= 0 or quantity(item_id) < count:
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
    _apply_effect(prototype, company, count)
    item_purchased.emit(item_id, count)
    return true

func _apply_effect(prototype: Dictionary, company: Dictionary, count: int) -> void:
    var effect: String = String(prototype["effect"])
    var amount: float = float(prototype["amount"]) * count
    match effect:
        "mw":
            company["mw"] = float(company.get("mw", 0.0)) + amount
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

func by_category(category: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for prototype in CATALOG:
        if String(prototype["category"]) == category:
            result.append(prototype)
    return result

func serialize() -> Dictionary:
    return {"owned": owned.duplicate(true)}

func deserialize(data: Dictionary) -> void:
    owned = Dictionary(data.get("owned", {})).duplicate(true)
    inventory_changed.emit()

func debug_catalog_ready() -> bool:
    return CATALOG.size() >= 30 and CATALOG.all(func(p): return p.has("id") and p.has("price") and p.has("effect"))
