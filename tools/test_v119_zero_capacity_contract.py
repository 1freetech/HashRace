from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_v119_zero_capacity_contract():
    assert (ROOT / "VERSION").read_text().strip() == "v0.119"

    script = (ROOT / "Godot/scripts/world_v119.gd").read_text()
    assert 'extends "res://scripts/world_v118.gd"' in script
    assert 'status = "NO POWER"' in script
    assert "safe_load > 0.0 and safe_capacity <= 0.0" in script
    assert "ratio = INF" in script
    assert "is_inf(float(powerless[\"ratio\"]))" in script
    assert "debug_v118_ready()" in script

    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    assert 'res://scripts/world_v119.gd' in scene

    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()
    assert 'res://scripts/world_v118.gd' in validator
    assert 'res://scripts/world_v119.gd' in validator


if __name__ == "__main__":
    test_v119_zero_capacity_contract()
    print("v0.119 zero-capacity safety contract: PASS")
