from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def main():
    assert (ROOT / "VERSION").read_text().strip() >= "v0.128"

    asset = ROOT / "Godot/art/buildings/c01_mining_container.png"
    world = (ROOT / "Godot/scripts/world_v128.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()
    capture = (ROOT / "Godot/scripts/capture_screenshot.gd").read_text()

    assert asset.exists() and asset.stat().st_size > 5_000
    assert asset.read_bytes().startswith(b"\x89PNG\r\n\x1a\n")

    assert 'extends "res://scripts/world_v127.gd"' in world
    assert 'V128_CONTAINER_PATH := "res://art/buildings/c01_mining_container.png"' in world
    assert "CITY_ROAD_STYLES" in world
    assert "_v128_draw_city_road" in world
    assert "_v123_draw_ground" in world
    assert "_draw_mining_hq" in world
    assert "_v128_draw_container_sprite" in world
    assert "super._v115_draw_live_site" not in world

    for token in [
        "hashrace_v128_road_cleanup_revision",
        "hashrace_v128_container_asset_live",
        "hashrace_v128_single_road_stack",
    ]:
        assert token in world, token
        assert token in capture, token

    assert "world_v128.gd" in scene
    assert "world_v128.gd" in validator
    print("Hash Race v0.128 road/container cleanup contract: PASS")

if __name__ == "__main__":
    main()
