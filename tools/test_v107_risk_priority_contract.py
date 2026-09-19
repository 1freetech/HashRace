from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
script = (ROOT / "Godot/scripts/world_v107.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert version == "v0.107"
assert 'res://scripts/world_v107.gd' in scene
assert 'extends "res://scripts/world_v106.gd"' in script
assert 'clampf(power_pct, 0.0, 100.0)' in script
assert '"CRITICAL"' in script and '"HIGH"' in script
assert '"WATCH"' in script and '"READY"' in script
assert 'OUTPUT AT RISK' in script
assert 'CURTAILED' in script
assert 'CASH RISK' in script
assert 'debug_v106_ready()' in script
assert '_safe_service_pct(-5.0) == 0.0' in script
assert '_safe_service_pct(105.0) == 100.0' in script
assert 'is_equal_approx(_curtailment_pct(80.0), 20.0)' in script

print("v0.107 risk-priority contract: PASS")
