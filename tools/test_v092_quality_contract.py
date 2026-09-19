#!/usr/bin/env python3
"""Regression contract for Hash Race v0.092 route/input/readability pass."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
version = (ROOT / "VERSION").read_text().strip()
scene = (ROOT / "Godot/scenes/world.tscn").read_text()
quality = (ROOT / "Godot/scripts/world_v092.gd").read_text()
previous = (ROOT / "Godot/scripts/world_v091.gd").read_text()

assert version == "v0.092", version
assert "world_v092.gd" in scene
assert 'extends "res://scripts/world_v091.gd"' in quality
assert "V091_INTERACTION_REVISION" in previous

# Three gameplay/technical fixes: focused Space, stale ground-click target,
# and nearest-target geometry all use explicit contracts.
assert "gui_get_focus_owner() != null" in quality
assert "idx < 0 and pending_interaction_idx >= 0" in quality
assert "rep_pos.distance_to(_entity_interaction_point(i))" in quality

# Three usability upgrades: Esc cancel, stopped-route feedback, repeat-click status.
assert "key_event.keycode == KEY_ESCAPE" in quality
assert 'Route stopped before interaction range.' in quality
assert 'Still routing to %s. Esc cancels the route.' in quality

# Three visible readability fixes: actionable-only prompt, selected-dialog town
# suppression, and destination-only building label while routing.
assert "V092_INTERACT_PROMPT_DISTANCE" in quality
assert "if selected_entity_idx >= 0:" in quality
assert "return idx == pending_interaction_idx" in quality

# Additional high-impact polish: the turn tooltip documents the unified controls.
assert "Space interacts nearby. Esc cancels a queued route or turn preview." in quality
assert "debug_v092_ready" in quality

print("v0.092 quality contract PASS")
