extends RefCounted
class_name InfrastructureInventory

# Hash Race v0.068 infrastructure inventory.
# The source of truth is now native HashRaceItemResource .tres files under
# res://data/items/. Legacy dictionaries are generated only at API boundaries
# so existing UI/gameplay code keeps working during the modular migration.

signal inventory_changed
signal deployment_changed
signal item_purchased(item_id: String, quantity: int)

const ItemLibrary = preload("res://data/item_library.gd")
const EXPECTED_CATALOG_SIZE: int = 34

var owned: Dictionary = {}
var deployed: Dictionary = {}

var _catalog_resources: Array = []
var _resources_by_id: Dictionary = {}
var _catalog_loaded: bool = false

func _init() -> void:
    _ensure_catalog()

func _ensure_catalog() -> void:
    if _catalog_loaded:
        return
    _catalog_resources = ItemLibrary.load_catalog()
    _resources_by_id = ItemLibrary.index_by_id(_catalog_resources)
    _catalog_loaded = true
    if _catalog_resources.size() < EXPECTED_CATALOG_SIZE:
        push_error("InfrastructureInventory: expected at least %d ItemResource files, loaded %d." % [EXPECTED_CATALOG_SIZE, _catalog_resources.size()])

func catalog_size() -> int:
    _ensure_catalog()
    return _catalog_resources.size()

func catalog_resources() -> Array:
    _ensure_catalog()
    return _catalog_resources.duplicate()

func catalog_item_at(index: int) -> Dictionary:
    _ensure_catalog()
    if _catalog_resources.is_empty():
        return {}
    var safe_index := clampi(index, 0, _catalog_resources.size() - 1)
    var resource = _catalog_resources[safe_index]
    return resource.call("to_legacy_dict")

func item_resource(item_id: String):
    _ensure_catalog()
    return _resources_by_id.get(item_id)

func item(item_id: String) -> Dictionary:
    var resource = item_resource(item_id)
    return resource.call("to_legacy_dict") if resource != null else {}

func quantity(item_id: String) -> int:
    return int(owned.get(item_id, 0))

func deployed_quantity(item_id: String) -> int:
    return int(deployed.get(item_id, 0))

func stored_quantity(item_id: String) -> int:
    return maxi(0, quantity(item_id) - deployed_quantity(item_id))

func add(item_id: String, count: int = 1) -> bool:
    if item_resource(item_id) == null or count <= 0:
        return false
    owned[item_id] = quantity(item_id) + count
    inventory_changed.emit()
    return true

func remove(item_id: String, count: int = 1) -> bool:
    if count <= 0 or stored_quantity(item_id) < count:
        return false
    var left := quantity(item_id) - count
    if left <= 0:
        owned.erase(item_id)
    else:
        owned[item_id] = left
    inventory_changed.emit()
    return true

func purchase(item_id: String, company: Dictionary, count: int = 1) -> bool:
    var resource = item_resource(item_id)
    if resource == null or count <= 0:
        return false
    var cost: float = float(resource.get("price")) * float(count)
    if float(company.get("cash", 0.0)) < cost:
        return false
    company["cash"] = float(company.get("cash", 0.0)) - cost
    add(item_id, count)
    if not bool(resource.get("deployable")):
        _apply_resource_effect(resource, company, count)
        deployed[item_id] = deployed_quantity(item_id) + count
        deployment_changed.emit()
    item_purchased.emit(item_id, count)
    return true

func deploy(item_id: String, company: Dictionary, count: int = 1) -> bool:
    var resource = item_resource(item_id)
    if resource == null or count <= 0 or stored_quantity(item_id) < count:
        return false
    deployed[item_id] = deployed_quantity(item_id) + count
    _apply_resource_effect(resource, company, count)
    deployment_changed.emit()
    inventory_changed.emit()
    return true

func undeploy(item_id: String, company: Dictionary, count: int = 1) -> bool:
    var resource = item_resource(item_id)
    if resource == null or count <= 0 or deployed_quantity(item_id) < count:
        return false
    var left := deployed_quantity(item_id) - count
    if left <= 0:
        deployed.erase(item_id)
    else:
        deployed[item_id] = left
    _remove_resource_effect(resource, company, count)
    deployment_changed.emit()
    inventory_changed.emit()
    return true

func purchase_and_deploy(item_id: String, company: Dictionary, count: int = 1) -> bool:
    var resource = item_resource(item_id)
    if resource == null:
        return false
    if not purchase(item_id, company, count):
        return false
    if bool(resource.get("deployable")):
        return deploy(item_id, company, count)
    return true

func _apply_resource_effect(resource, company: Dictionary, count: int) -> void:
    var amount: float = float(resource.get("effect_amount")) * float(count)
    match String(resource.get("effect")):
        "mw":
            company["mw"] = float(company.get("mw", 0.0)) + amount
        "energy_source":
            company["mw"] = float(company.get("mw", 0.0)) + float(resource.get("power_output_mw")) * float(count)
        "hashrate":
            company["inventory_hashrate_ph"] = float(company.get("inventory_hashrate_ph", 0.0)) + float(resource.get("base_hashrate_ph")) * float(count)
        "uptime":
            company["inventory_uptime_bonus"] = minf(0.08, float(company.get("inventory_uptime_bonus", 0.0)) + amount)
        "power_cost":
            company["inventory_power_discount"] = maxf(-0.03, float(company.get("inventory_power_discount", 0.0)) + amount)
        "efficiency":
            company["inventory_efficiency_multiplier"] = float(company.get("inventory_efficiency_multiplier", 1.0)) * pow(float(resource.get("effect_amount")), count)
        "machine_capacity":
            company["machine_capacity"] = int(company.get("machine_capacity", 0)) + int(amount)
        "machine_discount":
            company["machine_discount"] = minf(0.25, float(company.get("machine_discount", 0.0)) + amount)
        "ops_cost":
            company["inventory_ops_multiplier"] = float(company.get("inventory_ops_multiplier", 1.0)) * pow(float(resource.get("effect_amount")), count)
        "asset_protection":
            company["asset_protection"] = minf(0.20, float(company.get("asset_protection", 0.0)) + amount)

func _remove_resource_effect(resource, company: Dictionary, count: int) -> void:
    var amount: float = float(resource.get("effect_amount")) * float(count)
    match String(resource.get("effect")):
        "mw":
            company["mw"] = maxf(0.0, float(company.get("mw", 0.0)) - amount)
        "energy_source":
            company["mw"] = maxf(0.0, float(company.get("mw", 0.0)) - float(resource.get("power_output_mw")) * float(count))
        "hashrate":
            company["inventory_hashrate_ph"] = maxf(0.0, float(company.get("inventory_hashrate_ph", 0.0)) - float(resource.get("base_hashrate_ph")) * float(count))
        "uptime":
            company["inventory_uptime_bonus"] = maxf(0.0, float(company.get("inventory_uptime_bonus", 0.0)) - amount)
        "power_cost":
            company["inventory_power_discount"] = minf(0.0, float(company.get("inventory_power_discount", 0.0)) - amount)
        "efficiency":
            var factor: float = pow(float(resource.get("effect_amount")), count)
            if factor > 0.0:
                company["inventory_efficiency_multiplier"] = minf(1.0, float(company.get("inventory_efficiency_multiplier", 1.0)) / factor)
        "machine_capacity":
            company["machine_capacity"] = maxi(0, int(company.get("machine_capacity", 0)) - int(amount))
        "machine_discount":
            company["machine_discount"] = maxf(0.0, float(company.get("machine_discount", 0.0)) - amount)
        "ops_cost":
            var factor: float = pow(float(resource.get("effect_amount")), count)
            if factor > 0.0:
                company["inventory_ops_multiplier"] = minf(1.0, float(company.get("inventory_ops_multiplier", 1.0)) / factor)
        "asset_protection":
            company["asset_protection"] = maxf(0.0, float(company.get("asset_protection", 0.0)) - amount)

func total_deployed_hashrate_ph() -> float:
    var total := 0.0
    for raw in catalog_resources():
        var resource = raw
        total += float(resource.get("base_hashrate_ph")) * float(deployed_quantity(String(resource.get("id"))))
    return total

func total_deployed_miner_load_mw() -> float:
    var total := 0.0
    for raw in catalog_resources():
        var resource = raw
        total += float(resource.get("power_draw_mw")) * float(deployed_quantity(String(resource.get("id"))))
    return total

func total_deployed_heat_mw() -> float:
    var total := 0.0
    for raw in catalog_resources():
        var resource = raw
        total += float(resource.get("heat_generated_mw")) * float(deployed_quantity(String(resource.get("id"))))
    return total

func total_cooling_capacity_mw() -> float:
    var total := 0.0
    for raw in catalog_resources():
        var resource = raw
        total += float(resource.get("cooling_capacity_mw")) * float(deployed_quantity(String(resource.get("id"))))
    return total

func nominal_energy_capacity_mw() -> float:
    var total := 0.0
    for raw in catalog_resources():
        var resource = raw
        total += float(resource.get("power_output_mw")) * float(deployed_quantity(String(resource.get("id"))))
    return total

func current_energy_output_mw() -> float:
    var total := 0.0
    for raw in catalog_resources():
        var resource = raw
        total += float(resource.call("effective_power_output_mw")) * float(deployed_quantity(String(resource.get("id"))))
    return total

func deployed_power_cost_delta() -> float:
    var total := 0.0
    for raw in catalog_resources():
        var resource = raw
        total += float(resource.get("power_cost_delta")) * float(deployed_quantity(String(resource.get("id"))))
    return clampf(total, -0.04, 0.0)

func deployed_uptime_bonus() -> float:
    var total := 0.0
    for raw in catalog_resources():
        var resource = raw
        var count := deployed_quantity(String(resource.get("id")))
        if count <= 0:
            continue
        if String(resource.get("effect")) == "uptime":
            total += float(resource.get("effect_amount")) * float(count)
        total += float(resource.get("uptime_bonus")) * float(count)
    return clampf(total, -0.02, 0.08)

func maintenance_per_turn() -> float:
    var total := 0.0
    for raw in catalog_resources():
        var resource = raw
        total += float(resource.get("maintenance")) * float(deployed_quantity(String(resource.get("id"))))
    return total

func deployed_visual_count(visual: String) -> int:
    var total := 0
    for raw in catalog_resources():
        var resource = raw
        if String(resource.get("visual")) == visual:
            total += deployed_quantity(String(resource.get("id")))
    return total

func by_category(category: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for raw in catalog_resources():
        var resource = raw
        if String(resource.get("category")) == category:
            result.append(resource.call("to_legacy_dict"))
    return result

func serialize() -> Dictionary:
    return {
        "owned": owned.duplicate(true),
        "deployed": deployed.duplicate(true)
    }

func deserialize(data: Dictionary) -> void:
    owned = Dictionary(data.get("owned", {})).duplicate(true)
    deployed = Dictionary(data.get("deployed", {})).duplicate(true)
    for item_id in deployed.keys():
        deployed[item_id] = mini(int(deployed[item_id]), quantity(String(item_id)))
        if int(deployed[item_id]) <= 0:
            deployed.erase(item_id)
    inventory_changed.emit()
    deployment_changed.emit()

func debug_catalog_ready() -> bool:
    _ensure_catalog()
    if _catalog_resources.size() < EXPECTED_CATALOG_SIZE:
        return false
    for raw in _catalog_resources:
        var resource = raw
        if resource == null or String(resource.get("id")).is_empty() or String(resource.get("display_name")).is_empty() or float(resource.get("price")) < 0.0 or String(resource.get("effect")).is_empty():
            return false
    return true

func debug_resource_catalog_ready() -> bool:
    return debug_catalog_ready() and item_resource("asic_s21") != null and item_resource("nuclear_smr") != null

func debug_deployment_separation_ready() -> bool:
    return stored_quantity("asic_s21") >= 0 and total_deployed_hashrate_ph() >= 0.0 and nominal_energy_capacity_mw() >= current_energy_output_mw()
