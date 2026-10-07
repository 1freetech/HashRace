#!/usr/bin/env python3
"""Regression contract for v0.165 live-head cleanup."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
world = (ROOT / "Godot/scripts/world_v165.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")

assert 'path="res://scripts/world_v165.gd" type="Script"' in scene

for marker in [
    'const V165_CLEANUP_REVISION := 1',
    'var v165_legacy_energy_owned_blocked_cells: Array[Vector2i] = []',
    'func _v165_legacy_energy_footprint(',
    'func _v165_clear_legacy_energy_collision() -> void:',
    'grid_nav.set_blocked(cell, false)',
    'asset_id == "solar_array"',
    'asset_id == "wind_farm"',
    'func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:',
    'super._draw_tech_rep(pos, accent, scanner, true)',
    'func _v165_draw_npc_rep(',
    'func _draw_neon_character_name(',
    'func debug_v165_npc_identity_ready() -> bool:',
    '"npc_identity": debug_v165_npc_identity_ready()',
]:
    assert marker in world, f"v0.165 cleanup marker missing: {marker}"

# The live head must not route stationary NPCs back through the inherited
# player-sheet renderer. Only the is_player path may call super.
npc_block = world.split('func _draw_tech_rep', 1)[1].split('func _v165_draw_npc_rep', 1)[0]
assert 'if is_player:' in npc_block
assert 'super._draw_tech_rep(pos, accent, scanner, true)' in npc_block
assert 'super._draw_tech_rep(pos, accent, scanner, false)' not in npc_block

print("v0.165 cleanup contract passed: owned solar/wind collision + distinct contextual NPC rendering.")
