"""Regression contract for Hash Race v0.102 visual cleanup."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
world = (ROOT / "Godot/scripts/world_v102.gd").read_text(encoding="utf-8")
rack = (ROOT / "Godot/data/items/ai_rack_system.tres").read_text(encoding="utf-8")

assert version.startswith("v0."), version
assert int(version.split(".")[1]) >= 102, version
# The live scene advances through sequential world_vNNN scripts. Protect the
# historical v0.102 implementation itself without pinning world.tscn forever.
scene_script_line = next(
    line for line in scene.splitlines()
    if line.startswith("[ext_resource") and "scripts/world_v" in line
)
current_world_path = scene_script_line.split('path="', 1)[1].split('"', 1)[0]
assert current_world_path.endswith(f"world_v{int(version.split('.')[1]):03d}.gd"), current_world_path
assert 'extends "res://scripts/world_v101.gd"' in world

for required in [
    'func _draw_energy_campus(_origin: Vector2) -> void:',
    'func _draw_transformer_bank(_center: Vector2, _accent: Color) -> void:',
    'func _draw_campus_data_bus(_center: Vector2, _accent: Color, _seed: int) -> void:',
    'func _v102_rebuild_entry_walks() -> void:',
    'func _v102_tree_if_land(pos: Vector2) -> void:',
    'infrastructure_inventory.deployed_quantity("ai_rack_system")',
    '_draw_micro_server_rack(rack_center, accent, 0)',
]:
    assert required in world, required

assert 'id = "ai_rack_system"' in rack
assert 'visual = "ai_rack"' in rack
assert 'effect = "uptime"' in rack

print(f"Hash Race v0.102 visual cleanup contract passed through {current_world_path}.")
