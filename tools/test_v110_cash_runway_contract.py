from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_v110_cash_runway_contract():
    assert (ROOT / "VERSION").read_text().strip() == "v0.110"

    script = (ROOT / "Godot/scripts/world_v110.gd").read_text()
    assert 'extends "res://scripts/world_v109.gd"' in script
    assert 'base_hint.begins_with("CASH GAP:")' in script
    assert "BREAK-EVEN: improve 1-day net cash" in script
    assert "power savings" in script
    assert "debug_v109_ready()" in script

    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    assert 'res://scripts/world_v110.gd' in scene


if __name__ == "__main__":
    test_v110_cash_runway_contract()
    print("v0.110 cash-runway contract: PASS")
