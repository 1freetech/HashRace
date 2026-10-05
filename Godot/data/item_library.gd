class_name HashRaceItemLibrary
extends RefCounted

const ITEM_DIRECTORY := "res://data/items/"
const ITEM_SCRIPT := preload("res://data/item_resource.gd")

# Export-safe source-of-truth manifest. Godot remaps .tres resources inside
# exported packages, so enumerating ITEM_DIRECTORY and filtering filenames by
# the literal .tres suffix returns an empty catalog at runtime. Loading the
# canonical res:// paths lets ResourceLoader follow the export remaps while
# preserving deterministic catalog order in editor and packaged builds.
const ITEM_FILES := [
    "ai_rack_system.tres",
    "asic_gen1.tres",
    "asic_hydro.tres",
    "asic_s19.tres",
    "asic_s21.tres",
    "backup_gen.tres",
    "battery.tres",
    "coal_plant.tres",
    "container.tres",
    "core_switch.tres",
    "diesel_generator.tres",
    "dry_cooler.tres",
    "fiber.tres",
    "fire_system.tres",
    "gas_turbine.tres",
    "geothermal_generator.tres",
    "hydrogen_fuel_cell.tres",
    "hydro_loop.tres",
    "hydro_turbine.tres",
    "immersion_tank.tres",
    "lpg_generator.tres",
    "methane_generator.tres",
    "microturbine.tres",
    "modular_dc.tres",
    "monitoring.tres",
    "nuclear_smr.tres",
    "oil_field.tres",
    "pdu.tres",
    "pump_skid.tres",
    "repair_lab.tres",
    "security.tres",
    "semi_deal.tres",
    "solar_array.tres",
    "spares.tres",
    "switchgear.tres",
    "thermal_camera.tres",
    "transformer_1mw.tres",
    "transformer_5mw.tres",
    "warehouse.tres",
    "wind_farm.tres",
]

static func load_catalog() -> Array:
    var result: Array = []
    for item_file in ITEM_FILES:
        var resource = load(ITEM_DIRECTORY + String(item_file))
        if resource == null:
            push_warning("HashRaceItemLibrary: failed to load %s" % item_file)
            continue
        if resource.get_script() != ITEM_SCRIPT:
            push_warning("HashRaceItemLibrary: unexpected resource script: %s" % item_file)
            continue
        var item_id := String(resource.get("id"))
        if item_id.is_empty():
            push_warning("HashRaceItemLibrary: item has no id: %s" % item_file)
            continue
        result.append(resource)
    return result

static func index_by_id(resources: Array) -> Dictionary:
    var result := {}
    for raw in resources:
        if raw == null:
            continue
        var item_id := String(raw.get("id"))
        if not item_id.is_empty():
            result[item_id] = raw
    return result
