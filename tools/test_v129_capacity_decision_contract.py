from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    assert (ROOT / "VERSION").read_text().strip() == "v0.129"
    world = (ROOT / "Godot/scripts/world_v129.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()

    assert 'extends "res://scripts/world_v128.gd"' in world
    for token in [
        "capacity_decision_preview",
        "capacity_decision_summary",
        'decision := "DEPLOY"',
        'decision = "CURTAIL"',
        'decision := "HOLD"',
        "site_capacity_action(active_load, active_capacity)",
        "Up to %.1f MW of additional mining load fits current power.",
        "Remove %.1f MW of mining load before advancing.",
        "debug_v129_ready",
    ]:
        assert token in world, token

    assert "world_v129.gd" in scene
    assert "world_v129.gd" in validator
    print("Hash Race v0.129 capacity decision contract: PASS")


if __name__ == "__main__":
    main()
