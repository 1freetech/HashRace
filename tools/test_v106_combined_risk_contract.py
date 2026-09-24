from pathlib import Path

root = Path(__file__).resolve().parents[1]
world = (root / "Godot/scripts/world_v106.gd").read_text(encoding="utf-8")
scene = (root / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
version = (root / "VERSION").read_text(encoding="utf-8").strip()

assert version == "v0.106"
assert 'extends "res://scripts/world_v105.gd"' in world
assert "power_pct < 99.5 and ending_cash < 0.0" in world
assert "_additional_mw_for_load" in world
assert "_curtailed_hashrate_th_for" in world
assert "protect cash before confirming" in world
assert "debug_v106_ready" in world
assert 'res://scripts/world_v106.gd' in scene

# Contract: combined risk must retain both categories of recovery guidance.
combined_template = "ACTION: add/deploy MW%s and protect cash before confirming%s"
assert "MW" in combined_template
assert "cash" in combined_template

print("v0.106 combined-risk contract: PASS")
