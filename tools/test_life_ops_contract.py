#!/usr/bin/env python3
"""Contract checks for the live Hash Race life + operations gameplay."""
from pathlib import Path
import re

life = Path("Godot/scripts/world_life_ops.gd").read_text(encoding="utf-8")
scene = Path("Godot/scenes/world.tscn").read_text(encoding="utf-8")
version = Path("VERSION").read_text().strip()

assert re.fullmatch(r"v0\.\d{3}", version), "Life + Operations requires a valid public version"
assert "world_life_ops.gd" in scene
assert 'extends "res://scripts/world_league_standings.gd"' in life
for marker in [
    "operator_energy", "operator_focus", "operator_social", "_life_score",
    "RECOVER", "TRAIN", "NETWORK", "queued_routine", "_apply_elapsed_life",
    "_site_fit_score", "SITE FIT %d/100", "LIFE + SITE OVERVIEW",
    "elapsed_campaign_days", "super._end_quarter()", "debug_life_ops_ready",
    "_life_uptime_adjustment", "_life_research_cost_multiplier",
    "_life_partner_cost_multiplier", "debug_life_effects_material",
    "ROUTINE_INTERVAL_DAYS: float = 30.4375", "queued_routine_days += days",
    "while queued_routine_days >= ROUTINE_INTERVAL_DAYS", "_run_queued_routine",
    "AUTO_ROUTINE_NEED_THRESHOLD: float = 85.0", "_queued_routine_needed",
    "if not _queued_routine_needed()", "Smart queue threshold"
]:
    assert marker in life, f"Life + Operations missing: {marker}"

assert "clampf((operator_energy + operator_focus + operator_social) / 3.0, 0.0, 100.0)" in life
assert life.count("100.0") >= 8
assert "match queued_routine:" not in life.split("func _apply_elapsed_life", 1)[1].split("func _end_quarter", 1)[0], "Elapsed-life settlement must not execute a queued routine directly once per turn"
assert life.index("if not _queued_routine_needed()") < life.index('"RECOVER": return _recover_operator(true)'), "Automatic routines must check need before spending cash"

print(f"Hash Race {version} life + operations contract passed: 0-100 needs remain material, queued routines are elapsed-time normalized, and automatic routines avoid wasting cash when needs are already high.")
