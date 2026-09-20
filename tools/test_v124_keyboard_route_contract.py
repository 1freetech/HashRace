#!/usr/bin/env python3
"""Contract checks for v0.124 keyboard-to-interaction routing."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
world = (ROOT / "Godot/scripts/world_v124.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert 'extends "res://scripts/world_v123.gd"' in world
assert "V124_KEYBOARD_ROUTE_REVISION := 1" in world
assert "KEY_E" in world and "KEY_ENTER" in world and "KEY_SPACE" in world
assert "gui_get_focus_owner()" in world
assert "not _entity_in_interact_range(idx)" in world
assert "_queue_or_open_interaction(idx)" in world
assert "Esc cancels the route" in world
assert "_invalidate_quarter_preview" in world
assert 'res://scripts/world_v124.gd' in scene
assert 'res://scripts/world_v124.gd' in validator
assert version == "v0.124"

print("v0.124 keyboard interaction routing contract: PASS")
