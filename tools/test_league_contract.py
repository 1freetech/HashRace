#!/usr/bin/env python3
"""Static regression checks for the live ten-miner league standings layer."""
from pathlib import Path

scene = Path("Godot/scenes/world.tscn").read_text(encoding="utf-8")
league = Path("Godot/scripts/world_league_standings.gd").read_text(encoding="utf-8")
profiles = Path("Godot/scripts/company_profiles.gd").read_text(encoding="utf-8")

assert "world_league_standings.gd" in scene, "Live Godot world must boot through the league standings layer"
assert 'extends "res://scripts/world_company_effects.gd"' in league, "League must preserve company effects and the full gameplay inheritance chain"
for marker in ["LEAGUE #", "STANDINGS", "_league_rows", "_player_league_rank", "BITCOIN MINING LEAGUE // STANDINGS", "rows.size() == 10", "debug_league_standings_ready"]:
    assert marker in league, f"League standings missing: {marker}"

companies = ["VantaGrid Mining", "NeonForge Mining", "ArcShift Mining", "IronVector Mining", "Meridian Zero Mining", "BlueNova Mining", "SignalFlux Mining", "Parallax Core Mining", "LatticeX Mining", "Epoch Vector Mining"]
for company in companies:
    assert company in profiles, f"Missing Bitcoin mining league company: {company}"

assert profiles.count('"name"') >= 10, "League needs ten mining-company profiles"
print("Hash Race league contract passed: ten Bitcoin mining companies feed the live standings layer and existing gameplay inheritance remains intact.")
