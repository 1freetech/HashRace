from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
world = (ROOT / "Godot/scripts/world_v105.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert version == "v0.105", version
assert 'extends "res://scripts/world_v104.gd"' in world
assert 'world_v105.gd' in scene
assert "_v105_service_pct" in world
assert "is_nan(power_pct) or is_inf(power_pct)" in world
assert "_v105_curtailment_pct" in world
assert 'return "CRITICAL"' in world
assert 'return "HIGH"' in world
assert 'return "WATCH"' in world
assert 'return "READY"' in world
assert "grass_here and grass_there" in world
assert "OUTPUT AT RISK" in world
assert "debug_v105_ready" in world
print("v0.105 quality contract OK")
