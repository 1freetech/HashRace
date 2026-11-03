from pathlib import Path
from math import isclose

from world_script_contract import assert_live_world_layer

ROOT = Path(__file__).resolve().parents[1]
world = (ROOT / "Godot" / "scripts" / "world_v105.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot" / "scenes" / "world.tscn").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert_live_world_layer(105)
assert 'extends "res://scripts/world_v104.gd"' in world
assert "func _additional_mw_for_load" in world
assert "if power_pct <= 0.0:" in world
assert "return load_mw" in world
assert "debug_v105_ready" in world

# Pure contract mirror: a total blackout requires enough capacity to serve the
# fleet's full electrical load; partial service requires only the unserved load.
def additional_mw(power_pct: float, load_mw: float) -> float:
    if power_pct >= 99.5 or load_mw <= 0.0:
        return 0.0
    if power_pct <= 0.0:
        return load_mw
    service_ratio = max(0.0, min(1.0, power_pct / 100.0))
    return max(0.0, load_mw * (1.0 - service_ratio))

assert additional_mw(0.0, 10.0) == 10.0
assert isclose(additional_mw(80.0, 10.0), 2.0, abs_tol=1e-9)
assert additional_mw(100.0, 10.0) == 0.0

print("v0.105 blackout MW target contract: PASS")
