#!/usr/bin/env python3
"""Contract checks for the live Hash Race life + operations gameplay."""
from pathlib import Path
import re

life = Path("Godot/scripts/world_life_ops.gd").read_text(encoding="utf-8")
burnout = Path("Godot/scripts/world_burnout.gd").read_text(encoding="utf-8")
visual_detail = Path("Godot/scripts/world_visual_detail.gd").read_text(encoding="utf-8")
scene = Path("Godot/scenes/world.tscn").read_text(encoding="utf-8")
version = Path("VERSION").read_text().strip()
release_world = Path("Godot/scripts/world_v070.gd").read_text(encoding="utf-8")

assert re.fullmatch(r"v0\.\d{3}", version), "Life + Operations requires a valid public version"
assert "world_v080.gd" in scene, "Live scene must boot through the current release layer"
assert 'extends "res://scripts/world_v068.gd"' in release_world
assert 'extends "res://scripts/world_burnout.gd"' in visual_detail, "Current visual/gameplay chain must retain burnout and life operations"
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
    "AUTO chooses the weakest need", "RECOVER NOT NEEDED", "TRAIN NOT NEEDED",
    "NETWORK NOT NEEDED", "Manual and fixed routines only spend company cash"
]:
    assert marker in life, f"Life + Operations missing: {marker}"

for marker in [
    "BURNOUT_START_RATING: float = 35.0", "HIGH_BURNOUT_RISK: int = 50",
    "MAX_BURNOUT_UPTIME_PENALTY: float = 0.03", "func _burnout_risk() -> int",
    "func _burnout_uptime_penalty() -> float", "super._life_uptime_adjustment() - _burnout_uptime_penalty()",
    "func _auto_routine_choice() -> String", "if _burnout_risk() >= HIGH_BURNOUT_RISK",
    'return "RECOVER"', "return super._auto_routine_choice()", "func _train_operator(silent: bool = false) -> bool",
    "TRAIN BLOCKED: burnout is %d/100", "return super._train_operator(silent)",
    "TRAIN LOCKED — RECOVER FIRST", "manual TRAIN is locked until recovery", "TRAIN LOCKED",
    "AUTO prioritizes RECOVER", "AUTO→RECOVER", "BURNOUT RISK %d/100", "BURNOUT %d/100", "debug_burnout_ready"
]:
    assert marker in burnout, f"Burnout gameplay missing: {marker}"

assert "clampf((operator_energy + operator_focus + operator_social) / 3.0, 0.0, 100.0)" in life
assert life.count("100.0") >= 8
assert "match queued_routine:" not in life.split("func _apply_elapsed_life", 1)[1].split("func _end_quarter", 1)[0]
assert life.index("if not _queued_routine_needed()") < life.index('var routine_to_run: String = _auto_routine_choice() if queued_routine == "AUTO" else queued_routine')
assert 'var options := ["NONE", "AUTO", "RECOVER", "TRAIN", "NETWORK"]' in life
for func_name, guard in [("_recover_operator", "operator_energy >= AUTO_ROUTINE_NEED_THRESHOLD"), ("_train_operator", "operator_focus >= AUTO_ROUTINE_NEED_THRESHOLD"), ("_network_operator", "operator_social >= AUTO_ROUTINE_NEED_THRESHOLD")]:
    body = life.split("func %s" % func_name, 1)[1].split("func ", 1)[0]
    assert guard in body and body.index(guard) < body.index("_spend_for_routine"), f"{func_name} must reject needless spending before charging cash"
assert burnout.index("if _burnout_risk() >= HIGH_BURNOUT_RISK") < burnout.index("return super._auto_routine_choice()")
train_override = burnout.split("func _train_operator", 1)[1].split("func _open_life_overview", 1)[0]
assert train_override.index("if _burnout_risk() >= HIGH_BURNOUT_RISK") < train_override.index("return super._train_operator(silent)")

print(f"Hash Race {version} life + operations contract passed: manual and automatic routines protect company cash, elapsed-time normalization holds, and burnout safety remains active.")
