from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_v120_curtailment_contract():
    assert (ROOT / "VERSION").read_text().strip() == "v0.120"

    script = (ROOT / "Godot/scripts/world_v120.gd").read_text()
    assert 'extends "res://scripts/world_v119.gd"' in script
    assert "site_capacity_action" in script
    assert '"CURTAIL ALL MINERS"' in script
    assert '"CURTAIL %.1f MW"' in script
    assert '"KEEP MINING"' in script
    assert '"PLAN NEXT POWER BLOCK"' in script
    assert '"ADD POWER BEFORE NEXT EXPANSION"' in script
    assert '"online_mw"' in script
    assert '"curtail_mw"' in script
    assert '"curtail_percent"' in script
    assert "debug_v119_ready()" in script

    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    assert 'res://scripts/world_v120.gd' in scene
    assert '[node name="BootFallback" type="CanvasLayer" parent="."]' in scene

    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()
    assert 'res://scripts/world_v120.gd' in validator


if __name__ == "__main__":
    test_v120_curtailment_contract()
    print("v0.120 mining curtailment contract: PASS")
