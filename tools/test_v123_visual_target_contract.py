from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def test_v123_visual_target_contract():
    assert (ROOT / "VERSION").read_text().strip() == "v0.123"

    world = (ROOT / "Godot/scripts/world_v123.gd").read_text()
    hud = (ROOT / "Godot/scripts/visual_target_hud.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()
    spec = (ROOT / "docs/visual_target_v121.md").read_text()

    assert 'extends "res://scripts/world_v122.gd"' in world
    for token in [
        "_v123_draw_mining_rigs",
        "_v123_draw_transformer_target",
        "_v123_draw_power_module",
        "_v123_draw_storage_yard",
        "_v123_draw_site_sign",
        "_v123_draw_fence",
        "_v123_draw_capacity_meter",
        "VisualTargetHUD",
        "V123_GREEN",
    ]:
        assert token in world, token

    for token in [
        "HASH",
        "RACE",
        "BTC TREASURY",
        "CASH",
        "POWER",
        "HASHRATE",
        "EFFICIENCY",
        "Current Objective",
        "Interact",
    ]:
        assert token in hud, token

    assert "world_v123.gd" in scene
    assert "visual_target_hud.gd" in validator
    assert "world_v122.gd" in validator
    assert "world_v123.gd" in validator
    assert "Reference image = **target**." in spec
    assert "Godot 4.7.2" in spec

if __name__ == "__main__":
    test_v123_visual_target_contract()
    print("v0.123 visual target contract: PASS")
