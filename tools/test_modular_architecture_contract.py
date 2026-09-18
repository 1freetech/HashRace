#!/usr/bin/env python3
"""Hash Race v0.070 modular Godot architecture contract."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
project = (ROOT / "Godot/project.godot").read_text(encoding="utf-8")
current_world = (ROOT / "Godot/scripts/world_v072.gd").read_text(encoding="utf-8")
live_world = (ROOT / "Godot/scripts/world_v073.gd").read_text(encoding="utf-8")
release_world = (ROOT / "Godot/scripts/world_v070.gd").read_text(encoding="utf-8")
world = (ROOT / "Godot/scripts/world_v068.gd").read_text(encoding="utf-8")
inventory = (ROOT / "Godot/scripts/infrastructure_inventory.gd").read_text(encoding="utf-8")
item_resource = (ROOT / "Godot/data/item_resource.gd").read_text(encoding="utf-8")
item_library = (ROOT / "Godot/data/item_library.gd").read_text(encoding="utf-8")
rack_slot = (ROOT / "Godot/components/building/rack_slot.gd").read_text(encoding="utf-8")
rack_container = (ROOT / "Godot/components/building/rack_container.gd").read_text(encoding="utf-8")
placement = (ROOT / "Godot/systems/physical_placement_grid.gd").read_text(encoding="utf-8")
simulation = (ROOT / "Godot/systems/simulation_manager.gd").read_text(encoding="utf-8")
widget = (ROOT / "Godot/scripts/mining_ops_widget.gd").read_text(encoding="utf-8")

assert re.fullmatch(r"v0\.\d{3}", version), version
assert int(version.split(".")[1]) >= 70, version
assert 'res://scripts/world_v073.gd' in scene
assert 'extends "res://scripts/world_v072.gd"' in live_world
assert 'extends "res://scripts/world_v070.gd"' in current_world
assert 'extends "res://scripts/world_v068.gd"' in release_world
assert 'debug_v070_ready' in release_world

# 1. Native Resource data model.
for marker in [
    "class_name HashRaceItemResource",
    "@export var id:",
    "@export var display_name:",
    "@export var slot_type:",
    "@export var base_hashrate_ph:",
    "@export var power_draw_mw:",
    "@export var heat_generated_mw:",
    "func to_legacy_dict()",
]:
    assert marker in item_resource, marker

item_files = sorted((ROOT / "Godot/data/items").glob("*.tres"))
assert len(item_files) >= 34, f"expected 34+ ItemResource files, found {len(item_files)}"
ids = []
for path in item_files:
    text = path.read_text(encoding="utf-8")
    assert 'script = ExtResource("1_item")' in text, path
    assert 'id = "' in text, path
    ids.append(path.stem)
assert len(ids) == len(set(ids)), "duplicate ItemResource filenames"

for required_id in [
    "asic_gen1", "asic_s19", "asic_s21", "asic_hydro",
    "transformer_1mw", "gas_turbine", "solar_array", "nuclear_smr",
    "immersion_tank", "hydro_loop", "container", "fiber",
    "repair_lab", "backup_gen", "semi_deal",
]:
    assert (ROOT / f"Godot/data/items/{required_id}.tres").exists(), required_id

assert "ITEM_DIRECTORY" in item_library
assert "load_catalog" in item_library
assert "const CATALOG" not in inventory, "old hardcoded infrastructure CATALOG must not remain source of truth"
for marker in [
    "ItemLibrary.load_catalog",
    "catalog_resources",
    "catalog_item_at",
    "item_resource",
    "debug_resource_catalog_ready",
]:
    assert marker in inventory, marker

# 2. Physical slot/grid deployment.
for marker in [
    "class_name HashRaceRackSlot",
    "installed_hardware",
    "can_install",
    "install_item",
    "remove_item",
]:
    assert marker in rack_slot, marker
for marker in [
    "class_name HashRaceRackContainer",
    "rebuild_slots",
    "first_free_slot",
    "aggregate_live_stats",
]:
    assert marker in rack_container, marker
for marker in [
    "class_name HashRacePhysicalPlacementGrid",
    "snap(",
    "can_place",
    "place(",
    "serialize_layout",
    "clear_all",
]:
    assert marker in placement, marker

# 3. Fixed-tick simulation loop.
for marker in [
    "class_name HashRaceSimulationManager",
    "signal tick_processed",
    "Timer.new()",
    "timer.wait_time = tick_rate",
    "func process_tick()",
    '"power_ratio"',
    '"thermal_factor"',
    '"effective_hashrate"',
]:
    assert marker in simulation, marker

for marker in [
    "SimulationManager",
    "PhysicalPlacementGrid",
    "RackContainer",
    "_sync_physical_racks",
    "_on_simulation_tick",
    "debug_modular_architecture_ready",
    "debug_simulation_snapshot",
]:
    assert marker in world, marker

# 4. Pixel settings and one nonduplicated upper-right metrics surface.
assert 'window/stretch/scale_mode="integer"' in project
assert '2d/snap/snap_2d_transforms_to_pixel=true' in project
assert '2d/snap/snap_2d_vertices_to_pixel=true' in project
assert 'const BASE_SIZE := Vector2(528.0, 326.0)' in widget
assert 'var mount_slot: int = 1' in widget
assert 'func mount_top_right()' in widget
assert 'func apply_simulation_snapshot' in widget
assert 'func _context_line()' in widget
assert 'top_stats.visible = false' in world
assert 'energy_status_label.visible = false' in world
assert 'debug_hud_consolidated' in world

print(f"Hash Race {version} modular architecture contract passed: Resources + slots/grid + fixed-tick sim + consolidated HUD.")
