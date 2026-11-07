#!/usr/bin/env python3
"""Current Hash Race energy/deployment contract for the full campaign chain."""
from pathlib import Path

from world_script_contract import active_world_scripts

ROOT = Path(__file__).resolve().parents[1]
inventory = (ROOT / "Godot/scripts/infrastructure_inventory.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
world_v160 = (ROOT / "Godot/scripts/world_v160.gd").read_text(encoding="utf-8")
world_v161 = (ROOT / "Godot/scripts/world_v161.gd").read_text(encoding="utf-8")
world_v164 = (ROOT / "Godot/scripts/world_v164.gd").read_text(encoding="utf-8")
world_v165 = (ROOT / "Godot/scripts/world_v165.gd").read_text(encoding="utf-8")
physical_collision = (ROOT / "Godot/scripts/physical_campus_collision.gd").read_text(encoding="utf-8")
live_scripts = active_world_scripts()

assert 'res://scripts/world_v165.gd' in scene, "Live scene must use the restored full gameplay chain"
assert 'res://scripts/physical_campus_collision.gd' in scene, "Physical campus collision must be live"
for required in [
    "res://scripts/world_v127.gd",
    "res://scripts/world_v128.gd",
    "res://scripts/world_v160.gd",
    "res://scripts/world_v161.gd",
    "res://scripts/world_v164.gd",
    "res://scripts/world_v165.gd",
]:
    assert required in live_scripts, f"Energy/infrastructure gameplay layer is not live: {required}"

for marker in [
    'var deployed: Dictionary = {}',
    'func stored_quantity',
    'func deploy(',
    'func undeploy(',
    'func purchase_and_deploy(',
    'total_deployed_hashrate_ph',
    'current_energy_output_mw',
    'total_cooling_capacity_mw',
    'nominal_energy_capacity_mw',
    'debug_deployment_separation_ready',
    'ItemLibrary.load_catalog',
]:
    assert marker in inventory, f"Inventory missing deployment marker: {marker}"

for source in [
    "battery", "solar_array", "wind_farm", "gas_turbine", "hydro_turbine",
    "oil_field", "coal_plant", "nuclear_smr", "methane_generator",
    "diesel_generator", "geothermal_generator", "lpg_generator",
    "hydrogen_fuel_cell",
]:
    path = ROOT / f"Godot/data/items/{source}.tres"
    assert path.exists(), f"Missing energy ItemResource {source}"
    text = path.read_text(encoding="utf-8")
    assert f'id = "{source}"' in text

for texture_path in [
    "Godot/art/energy/solar_array_overview.png",
    "Godot/art/energy/wind_turbine_directional_sheet.png",
    "Godot/art/electrical/substation_transformer_rear.png",
    "Godot/art/buildings/c01_mining_container.png",
    "Godot/art/machines/asic_air_s19j_directional.png",
]:
    assert (ROOT / texture_path).is_file(), f"Live imported texture missing: {texture_path}"

assert 'V160SubstationSprite' in world_v160
for marker in [
    'func _v160_sync_transformer_footprint',
    'v160_transformer_owned_cells',
    'grid_nav.set_blocked(cell, true)',
    'grid_nav.set_blocked(cell, false)',
]:
    assert marker in world_v160, f"Transformer ownership contract missing: {marker}"

assert 'V161Solar' in world_v161 and 'asset_id != "solar_array"' in world_v161 and 'grid_nav.block_rect(foot)' in world_v161
assert 'V164Wind' in world_v164 and 'asset_id != "wind_farm"' in world_v164 and 'grid_nav.block_rect(foot)' in world_v164

for marker in [
    'const COLLISION_REVISION := 1',
    'CONTAINER_OFFSET := Vector2(-170.0, -165.0)',
    'COMMAND_OFFSET := Vector2(-205.0, 215.0)',
    'container_owned_cells',
    'command_owned_cells',
    'func _sync_owned_rect',
    'grid_nav.set_blocked(cell, true)',
    'grid_nav.set_blocked(cell, false)',
    'func debug_ready() -> bool:',
]:
    assert marker in physical_collision, f"Physical campus collision marker missing: {marker}"

# v0.165 dynamic energy sources own and release only navigation cells they
# introduced so source changes and undeploys never leave invisible obstacles.
for marker in [
    'V165_DIESEL_ASSET_ID := "diesel_generator"',
    'infrastructure_inventory.deployed_quantity(V165_DIESEL_ASSET_ID)',
    'infrastructure_inventory.deployment_changed.connect(_v165_on_deployment_changed)',
    'var v165_diesel_owned_blocked_cells: Array[Vector2i] = []',
    'func _v165_block_diesel_collision(foot: Rect2) -> void:',
    'func _v165_clear_diesel_collision() -> void:',
    'v165_legacy_energy_owned_blocked_cells',
    'func _v165_clear_legacy_energy_collision() -> void:',
    'func debug_v165_runtime_state() -> Dictionary:',
    'func debug_v165_diesel_ready() -> bool:',
]:
    assert marker in world_v165, f"v0.165 dynamic energy contract missing: {marker}"

print("Hash Race energy/deployment contract passed with physical campus and ownership-safe dynamic collision.")
