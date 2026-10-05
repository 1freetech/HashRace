#!/usr/bin/env python3
"""Regression contract for Hash Race v0.091 interaction-quality pass."""
from pathlib import Path

from world_script_contract import active_world_scripts

ROOT = Path(__file__).resolve().parents[1]
version = (ROOT / "VERSION").read_text().strip()
scene = (ROOT / "Godot/scenes/world.tscn").read_text()
quality = (ROOT / "Godot/scripts/world_v091.gd").read_text()
strategy = (ROOT / "Godot/scripts/world_v090.gd").read_text()

assert version.startswith("v0."), version
live_scripts = active_world_scripts()
assert 'res://scripts/world_v165.gd' in scene
assert "res://scripts/world_v091.gd" in live_scripts, "v0.091 interaction gameplay must remain in the live inheritance chain"
assert 'extends "res://scripts/world_v090.gd"' in quality
assert "V090_STRATEGY_REVISION" in strategy

assert "key_event.keycode == KEY_SPACE" in quality
assert "_activate_nearest_interaction()" in quality
assert "WorldScale.front_door_world_pos" in quality
assert "func _entity_in_interact_range" in quality
assert "_queue_or_open_interaction" in quality
assert "Interaction opens on arrival." in quality

assert "pending_interaction_idx" in quality
assert "No walkable route to that target." in quality
assert "Q previews the current %s turn" in quality

assert "scanner_overlay_enabled = false" in quality
assert "scanner_button.visible = false" in quality
assert "phase_label.visible = live_quarter_confirmation_pending" in quality
assert "V091_BUILDING_LABEL_DISTANCE" in quality
assert "V091_TOWN_LABEL_DISTANCE" in quality
assert "_nearest_building_idx" in quality

print("v0.091 interaction-quality contract PASS through restored full live world")
