#!/usr/bin/env python3
"""Current Hash Race energy/deployment contract.

Release numbers belong in Git history. This contract validates the stable
world.gd runtime, imported infrastructure resources, and inventory deployment
APIs used by the live mining campus.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
inventory = (ROOT / "Godot/scripts/infrastructure_inventory.gd").read_text(encoding="utf-8")
world = (ROOT / "Godot/scripts/world.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")

assert 'res://scripts/world.gd' in scene, "Live scene must use the stable world.gd entry point"

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

# The live campus uses Godot-imported Texture2D resources. Keep these exact
# res:// paths in source so exported builds retain their dependencies.
for texture_path in [
    "res://art/energy/solar_array_overview.png",
    "res://art/energy/wind_turbine_directional_sheet.png",
    "res://art/electrical/substation_transformer_rear.png",
    "res://art/buildings/c01_mining_container.png",
    "res://art/machines/asic_air_s19j_directional.png",
]:
    assert f'preload("{texture_path}")' in world, f"Live imported texture missing: {texture_path}"

for api in [
    "func runtime_ready()",
    "func infrastructure_ready(asset_id: String)",
    "func infrastructure_rect(asset_id: String)",
    "func infrastructure_footprint(asset_id: String)",
]:
    assert api in world, f"Stable energy/infrastructure API missing: {api}"

for asset_id in ["container", "solar", "transformer", "asic", "wind"]:
    assert f'"{asset_id}": Rect2' in world, f"Campus placement missing: {asset_id}"
    assert f'"{asset_id}":' in world or f'"{asset_id}"' in world

assert "grid_nav.block_rect(_ground_foot(rect))" in world
assert "return not grid_nav.world_is_walkable(foot.get_center())" in world
assert "_draw_asset(SOLAR_ART, CAMPUS.solar)" in world
assert "_draw_wind()" in world
assert "draw_texture_rect_region(WIND_ART, CAMPUS.wind, source)" in world

print("Hash Race stable energy/deployment contract passed.")
