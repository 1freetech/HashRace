from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_v121_operating_reserve_contract():
    assert (ROOT / "VERSION").read_text().strip() == "v0.121"

    script = (ROOT / "Godot/scripts/world_v121.gd").read_text()
    assert 'extends "res://scripts/world_v120.gd"' in script
    assert "V121_RESERVE_PERCENT := 10.0" in script
    assert "site_operating_reserve_plan" in script
    assert '"RESERVE AT RISK"' in script
    assert '"CURTAIL %.1f MW FOR RESERVE"' in script
    assert '"HOLD EXPANSION"' in script
    assert '"operating_limit_mw"' in script
    assert "debug_v120_ready()" in script

    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    assert 'res://scripts/world_v121.gd' in scene
    assert '[node name="BootFallback" type="CanvasLayer" parent="."]' in scene

    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()
    assert 'res://scripts/world_v121.gd' in validator


if __name__ == "__main__":
    test_v121_operating_reserve_contract()
    print("v0.121 operating reserve contract: PASS")
