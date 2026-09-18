class_name HashRaceItemResource
extends Resource

## Native content definition for Hash Race infrastructure.
## These values are editable in the Godot inspector and serializable as .tres.

@export var id: String = ""
@export var display_name: String = ""
@export var category: String = "MISC"
@export var slot_type: String = "ANY"
@export var price: float = 0.0
@export var deployable: bool = true

@export_group("Mining")
@export var base_hashrate_ph: float = 0.0
@export var power_draw_mw: float = 0.0
@export var heat_generated_mw: float = 0.0

@export_group("Power and cooling")
@export var power_output_mw: float = 0.0
@export_range(0.0, 1.0, 0.01) var capacity_factor: float = 1.0
@export var cooling_capacity_mw: float = 0.0
@export var uptime_bonus: float = 0.0
@export var power_cost_delta: float = 0.0
@export var maintenance: float = 0.0

@export_group("Gameplay")
@export var effect: String = ""
@export var effect_amount: float = 0.0
@export var effect_unit: String = ""
@export var visual: String = ""
@export var tier: int = 0
@export_multiline var description: String = ""

func effective_power_output_mw() -> float:
    return maxf(0.0, power_output_mw) * clampf(capacity_factor, 0.0, 1.0)

func is_compatible_with(slot: String) -> bool:
    var normalized := slot.strip_edges().to_upper()
    return normalized == "ANY" or slot_type.to_upper() == "ANY" or slot_type.to_upper() == normalized

func to_legacy_dict() -> Dictionary:
    var amount := effect_amount
    if effect == "hashrate":
        amount = base_hashrate_ph
    elif effect == "energy_source":
        amount = power_output_mw
    return {
        "id": id,
        "name": display_name,
        "category": category,
        "slot_type": slot_type,
        "price": price,
        "effect": effect,
        "amount": amount,
        "unit": effect_unit,
        "deployable": deployable,
        "load_mw": power_draw_mw,
        "heat_mw": heat_generated_mw,
        "energy_output_mw": power_output_mw,
        "capacity_factor": capacity_factor,
        "cooling_mw": cooling_capacity_mw,
        "uptime_bonus": uptime_bonus,
        "power_cost_delta": power_cost_delta,
        "maintenance": maintenance,
        "visual": visual,
        "tier": tier,
        "description": description
    }
