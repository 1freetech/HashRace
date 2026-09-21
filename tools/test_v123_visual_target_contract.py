from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def current_world_script(version: str) -> str:
    patch = int(version.removeprefix("v").split(".")[-1])
    return f"world_v{patch:03d}.gd"

def test_v123_visual_target_contract():
    version = (ROOT / "VERSION").read_text().strip()
    assert version >= "v0.123"

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

    # v0.123 remains in the inherited visual/gameplay chain; the live scene
    # must boot the current release layer rather than point backward at v0.123.
    live_world = current_world_script(version)
    assert live_world in scene, live_world
    assert "visual_target_hud.gd" in validator
    assert "world_v122.gd" in validator
    assert "world_v123.gd" in validator
    assert "Reference image = **target**." in spec
    assert "Godot 4.7.2" in spec

if __name__ == "__main__":
    test_v123_visual_target_contract()
    print(f"v0.123 visual target contract: PASS through {current_world_script((ROOT / 'VERSION').read_text().strip())}")
