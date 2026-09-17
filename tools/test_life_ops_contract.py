#!/usr/bin/env python3
"""Contract checks for the live Hash Race life + operations gameplay."""
from pathlib import Path
import re

life = Path("Godot/scripts/world_life_ops.gd").read_text(encoding="utf-8")
burnout = Path("Godot/scripts/world_burnout.gd").read_text(encoding="utf-8")
scene = Path("Godot/scenes/world.tscn").read_text(encoding="utf-8")
version = Path("VERSION").read_text().strip()

assert re.fullmatch(r"v0\.\d{3}", version), "Life + Operations requires a valid public version"
assert "world_burnout.gd" in scene
assert 'extends "res://scripts/world_life_ops.gd"' in burnout
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
    "if not _queued_routine_needed()", "_auto_routine_choice", '"AUTO"',
    "lowest >= AUTO_ROUTINE_NEED_THRESHOLD", 'queued_routine == "AUTO"',
    "AUTO chooses the weakest need"
]:
    assert marker in life, f"Life + Operations missing: {marker}"

for marker in [
    "BURNOUT_START_RATING: float = 35.0",
    "HIGH_BURNOUT_RISK: int = 50",
    "MAX_BURNOUT_UPTIME_PENALTY: float = 0.03",
    "func _burnout_risk() -> int",
    "clampf((energy_deficit + focus_deficit) * 0.5 * 100.0, 0.0, 100.0)",
    "func _burnout_uptime_penalty() -> float",
    "super._life_uptime_adjustment() - _burnout_uptime_penalty()",
    "func _auto_routine_choice() -> String",
    "if _burnout_risk() >= HIGH_BURNOUT_RISK",
    'return "RECOVER"',
    "return super._auto_routine_choice()",
    "func _train_operator(silent: bool = false) -> bool",
    "TRAIN BLOCKED: burnout is %d/100",
    "return super._train_operator(silent)",
    "TRAIN LOCKED — RECOVER FIRST",
    "manual TRAIN is locked until recovery",
    "TRAIN LOCKED",
    "AUTO prioritizes RECOVER",
    "AUTO→RECOVER",
    "BURNOUT RISK %d/100",
    "BURNOUT %d/100",
    "debug_burnout_ready"
]:
    assert marker in burnout, f"Burnout gameplay missing: {marker}"

assert "clampf((operator_energy + operator_focus + operator_social) / 3.0, 0.0, 100.0)" in life
assert life.count("100.0") >= 8
assert "match queued_routine:" not in life.split("func _apply_elapsed_life", 1)[1].split("func _end_quarter", 1)[0], "Elapsed-life settlement must not execute a queued routine directly once per turn"
assert life.index("if not _queued_routine_needed()") < life.index('var routine_to_run: String = _auto_routine_choice() if queued_routine == "AUTO" else queued_routine'), "Automatic routines must check need before choosing and spending"
assert 'var options := ["NONE", "AUTO", "RECOVER", "TRAIN", "NETWORK"]' in life, "AUTO must be a player-selectable queue option"
assert burnout.index("if _burnout_risk() >= HIGH_BURNOUT_RISK") < burnout.index("return super._auto_routine_choice()"), "High burnout must be checked before normal AUTO routine selection"
train_override = burnout.split("func _train_operator", 1)[1].split("func _open_life_overview", 1)[0]
assert train_override.index("if _burnout_risk() >= HIGH_BURNOUT_RISK") < train_override.index("return super._train_operator(silent)"), "Unsafe manual training must be blocked before cash is spent or Energy is drained"

print(f"Hash Race {version} life + operations contract passed: 0-100 needs remain material, queued routines are elapsed-time normalized, AUTO protects high-burnout operators, and unsafe manual training is blocked until recovery.")
