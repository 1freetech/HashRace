#!/usr/bin/env python3
"""Energy/deployment contract retained by Hash Race v0.070."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
inventory = (ROOT / "Godot/scripts/infrastructure_inventory.gd").read_text(encoding="utf-8")
energy = (ROOT / "Godot/scripts/world_v065.gd").read_text(encoding="utf-8")
world_v067 = (ROOT / "Godot/scripts/world_v067.gd").read_text(encoding="utf-8")
world_v068 = (ROOT / "Godot/scripts/world_v068.gd").read_text(encoding="utf-8")
world_v070 = (ROOT / "Godot/scripts/world_v070.gd").read_text(encoding="utf-8")
world_v072 = (ROOT / "Godot/scripts/world_v072.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text().strip()

assert re.fullmatch(r"v0\.\d{3}", version), version
assert int(version.split(".")[1]) >= 70, version
assert 'res://scripts/world_v072.gd' in scene
assert 'extends "res://scripts/world_v070.gd"' in world_v072
assert 'extends "res://scripts/world_v068.gd"' in world_v070
assert 'extends "res://scripts/world_v067.gd"' in world_v068
assert 'extends "res://scripts/world_v065.gd"' in world_v067
assert 'extends "res://scripts/world_v059.gd"' in energy

for marker in [
    'var deployed: Dictionary = {}',
    'func stored_quantity',
    'func deploy(',
    'func undeploy(',
    'func purchase_and_deploy(',
    'total_deployed_hashrate_ph',
    'current_energy_output_mw',
    'total_cooling_capacity_mw',
    'debug_deployment_separation_ready',
    'ItemLibrary.load_catalog',
]:
    assert marker in inventory, f"Inventory missing deployment marker: {marker}"

for source in ["solar_array", "wind_farm", "gas_turbine", "hydro_turbine", "oil_field", "coal_plant", "nuclear_smr"]:
    path = ROOT / f"Godot/data/items/{source}.tres"
    assert path.exists(), f"Missing energy ItemResource {source}"
    text = path.read_text(encoding="utf-8")
    assert f'id = "{source}"' in text

for visual in [
    '_draw_energy_campus', '_draw_solar_unit', '_draw_wind_unit', '_draw_gas_unit',
    '_draw_hydro_unit', '_draw_oil_unit', '_draw_coal_unit', '_draw_smr_unit',
    '_draw_energy_power_flow', '_draw_heat_exhaust', '_facility_temperature_c',
    '_grid_stability_ratio', 'ENERGY MARKET', 'WAREHOUSE VS DEPLOYED',
    'debug_energy_visuals_ready'
]:
    assert visual in energy, f"Energy visual/gameplay layer missing: {visual}"

assert 'purchase_and_deploy(item_id, player, 1)' in energy
assert 'super._hashrate_th() + infrastructure_inventory.total_deployed_hashrate_ph() * 1000.0' in energy
assert 'super._machine_load_kw() + infrastructure_inventory.total_deployed_miner_load_mw() * 1000.0' in energy

print(f"Hash Race {version} retained energy/deployment contract passed.")
