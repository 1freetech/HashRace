from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    assert (ROOT / "VERSION").read_text().strip() == "v0.127"
    world = (ROOT / "Godot/scripts/world_v127.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()

    assert 'extends "res://scripts/world_v126.gd"' in world
    for token in [
        "_machine_load_kw()",
        "_effective_available_mw()",
        "site_capacity_action(load_mw, capacity_mw)",
        '"MINING CAPACITY"',
        '"CURTAIL 2.0 MW"',
        "hashrace_v127_capacity_feedback_revision",
    ]:
        assert token in world, token

    assert "world_v127.gd" in scene
    assert "world_v127.gd" in validator
    print("Hash Race v0.127 live mining-capacity feedback contract: PASS")


if __name__ == "__main__":
    main()
