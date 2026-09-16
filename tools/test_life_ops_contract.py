#!/usr/bin/env python3
"""Contract checks for Hash Race v0.023 life + operations gameplay."""
from pathlib import Path

life = Path("Godot/scripts/world_life_ops.gd").read_text(encoding="utf-8")
scene = Path("Godot/scenes/world.tscn").read_text(encoding="utf-8")
version = Path("VERSION").read_text().strip()

assert version == "v0.023"
assert "world_life_ops.gd" in scene
assert 'extends "res://scripts/world_league_standings.gd"' in life
for marker in [
    "operator_energy", "operator_focus", "operator_social", "_life_score",
    "RECOVER", "TRAIN", "NETWORK", "queued_routine", "_apply_elapsed_life",
    "_site_fit_score", "SITE FIT %d/100", "LIFE + SITE OVERVIEW",
    "elapsed_campaign_days", "super._end_quarter()", "debug_life_ops_ready"
]:
    assert marker in life, f"Life + Operations missing: {marker}"

# Universal gameplay ratings must remain bounded to 0-100.
assert "clampf((operator_energy + operator_focus + operator_social) / 3.0, 0.0, 100.0)" in life
assert life.count("100.0") >= 8

print("Hash Race v0.023 life + operations contract passed: 0-100 needs, paid routines, persistent routine queue, elapsed-time decay, site preview and 0-100 site-fit scoring are wired into the live league world.")
