from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
world = (ROOT / "Godot/scripts/world_v104.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert version == "v0.104", version
assert "world_v104.gd" in scene
assert 'extends "res://scripts/world_v103.gd"' in world
assert "func _curtailed_hashrate_th_for" in world
assert "func _format_hashrate_loss" in world
assert "CURTAILED: ~%s" in world
assert "_hashrate_th()" in world
assert "debug_v104_ready" in world

# Contract examples mirror the pure helper math used by GDScript.
def curtailed(power_pct: float, hashrate_th: float) -> float:
    if power_pct >= 99.5 or hashrate_th <= 0.0:
        return 0.0
    service = max(0.0, min(1.0, power_pct / 100.0))
    return max(0.0, hashrate_th * (1.0 - service))

assert abs(curtailed(80.0, 100_000.0) - 20_000.0) < 1e-6
assert curtailed(100.0, 100_000.0) == 0.0
assert curtailed(0.0, 100_000.0) == 100_000.0
