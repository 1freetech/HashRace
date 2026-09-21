"""Regression contract for Hash Race v0.102 visual cleanup."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
world = (ROOT / "Godot/scripts/world_v102.gd").read_text(encoding="utf-8")
rack = (ROOT / "Godot/data/items/ai_rack_system.tres").read_text(encoding="utf-8")

assert version.startswith("v0."), version
minor = int(version.split(".")[1])
assert minor >= 102, version
# The live scene must follow the current sequential release rather than remain
# pinned to v0.102 forever. The historical implementation below is still
# validated directly so later inheritance cannot silently remove its behavior.
assert f'world_v{minor:03d}.gd' in scene, (version, scene[:400])
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

print(f"Hash Race v0.102 visual cleanup contract passed through live {version} world.")
