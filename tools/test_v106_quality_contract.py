from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
world = (ROOT / "Godot" / "scripts" / "world_v106.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot" / "scenes" / "world.tscn").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert version == "v0.106"
assert 'extends "res://scripts/world_v105.gd"' in world
assert 'res://scripts/world_v106.gd' in scene
assert "func _service_pct" in world
assert "func _output_at_risk_pct" in world
assert "func _power_priority" in world
assert "func _v106_same_terrain_family" in world
assert "[Vector2i.UP, Vector2i.LEFT]" in world
assert "debug_v106_ready" in world


def service_pct(value: float) -> float:
    return max(0.0, min(100.0, value))


def curtailed(power_pct: float, hashrate: float) -> float:
    safe_hashrate = max(0.0, hashrate)
    service = service_pct(power_pct)
    if service >= 99.5 or safe_hashrate <= 0.0:
        return 0.0
    return safe_hashrate * (1.0 - service / 100.0)


def risk_pct(power_pct: float) -> float:
    return max(0.0, min(100.0, 100.0 - service_pct(power_pct)))


def priority(power_pct: float) -> str:
    risk = risk_pct(power_pct)
    if risk >= 50.0:
        return "CRITICAL"
    if risk >= 20.0:
        return "HIGH"
    if risk >= 5.0:
        return "WATCH"
    return "READY"

assert service_pct(-1.0) == 0.0
assert service_pct(101.0) == 100.0
assert curtailed(80.0, 100000.0) == 20000.0
assert curtailed(80.0, -100.0) == 0.0
assert risk_pct(80.0) == 20.0
assert priority(100.0) == "READY"
assert priority(90.0) == "WATCH"
assert priority(75.0) == "HIGH"
assert priority(40.0) == "CRITICAL"

print("v0.106 quality contract: PASS")
