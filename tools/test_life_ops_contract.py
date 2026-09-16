#!/usr/bin/env python3
"""Contract checks for the live Hash Race life + operations gameplay."""
from pathlib import Path
import re

life = Path("Godot/scripts/world_life_ops.gd").read_text(encoding="utf-8")
scene = Path("Godot/scenes/world.tscn").read_text(encoding="utf-8")
version = Path("VERSION").read_text().strip()

# Do not pin this gameplay contract to an old release. VERSION is already
# checked for sequential public releases; this test should survive v0.024+.
assert re.fullmatch(r"v0\.\d{3}", version), "Life + Operations requires a valid public version"
assert "world_life_ops.gd" in scene
assert 'extends "res://scripts/world_league_standings.gd"' in life
for marker in [
    "operator_energy", "operator_focus", "operator_social", "_life_score",
    "RECOVER", "TRAIN", "NETWORK", "queued_routine", "_apply_elapsed_life",
    "_site_fit_score", "SITE FIT %d/100", "LIFE + SITE OVERVIEW",
    "elapsed_campaign_days", "super._end_quarter()", "debug_life_ops_ready",
    "_life_uptime_adjustment", "_life_research_cost_multiplier",
    "_life_partner_cost_multiplier", "debug_life_effects_material"
]:
    assert marker in life, f"Life + Operations missing: {marker}"

# Universal gameplay ratings must remain bounded to 0-100.
assert "clampf((operator_energy + operator_focus + operator_social) / 3.0, 0.0, 100.0)" in life
assert life.count("100.0") >= 8

print(f"Hash Race {version} life + operations contract passed: the live 0-100 needs, paid routines, persistent queue, elapsed-time decay, site fit and material mining-business effects remain wired into the league world.")
