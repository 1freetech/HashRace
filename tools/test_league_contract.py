#!/usr/bin/env python3
"""Static regression checks for the live ten-miner league standings layer."""
from pathlib import Path
import re

scene = Path("Godot/scenes/world.tscn").read_text(encoding="utf-8")
league = Path("Godot/scripts/world_league_standings.gd").read_text(encoding="utf-8")
life_ops = Path("Godot/scripts/world_life_ops.gd").read_text(encoding="utf-8")
profiles = Path("Godot/scripts/company_profiles.gd").read_text(encoding="utf-8")
release_world = Path("Godot/scripts/world_v070.gd").read_text(encoding="utf-8")
modular_world = Path("Godot/scripts/world_v068.gd").read_text(encoding="utf-8")
version = Path("VERSION").read_text(encoding="utf-8").strip()

match = re.fullmatch(r"v0\.(\d{3})", version)
assert match, f"VERSION must use v0.### format, got {version!r}"
expected_world = f"world_v{match.group(1)}.gd"
assert expected_world in scene, f"Live Godot world must boot through {expected_world} for {version}"
assert 'extends "res://scripts/world_v068.gd"' in release_world
assert 'extends "res://scripts/world_v067.gd"' in modular_world
assert 'extends "res://scripts/world_league_standings.gd"' in life_ops, "Current gameplay chain must retain the league standings layer"
assert 'extends "res://scripts/world_company_effects.gd"' in league, "League must preserve company effects and the full gameplay inheritance chain"
for marker in ["LEAGUE #", "STANDINGS", "_league_rows", "_player_league_rank", "BITCOIN MINING LEAGUE // STANDINGS", "rows.size() == 10", "debug_league_standings_ready"]:
    assert marker in league, f"League standings missing: {marker}"

companies = ["VantaGrid Mining", "NeonForge Mining", "ArcShift Mining", "IronVector Mining", "Meridian Zero Mining", "BlueNova Mining", "SignalFlux Mining", "Parallax Core Mining", "LatticeX Mining", "Epoch Vector Mining"]
for company in companies:
    assert company in profiles, f"Missing Bitcoin mining league company: {company}"

assert profiles.count('"name"') >= 10, "League needs ten mining-company profiles"
print(f"Hash Race league contract passed: {version} boots through {expected_world}; ten Bitcoin mining companies feed the live standings layer and existing gameplay inheritance remains intact.")
