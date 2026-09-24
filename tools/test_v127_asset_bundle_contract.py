from pathlib import Path
from world_script_contract import assert_world_inherits

ROOT = Path(__file__).resolve().parents[1]

def main():
    assert (ROOT / "VERSION").read_text().strip() >= "v0.127"
    assets = [
        ROOT / "Godot/art/terrain/industrial_road_tilesheet.png",
        ROOT / "Godot/art/props/utility_props_sheet.png",
        ROOT / "Godot/art/energy/wind_turbine_directional_sheet.png",
        ROOT / "Godot/art/machines/asic_air_s19j_directional.png",
        ROOT / "Godot/art/characters/default_player_sheet.png",
    ]
    for asset in assets:
        assert asset.exists(), asset
        assert asset.read_bytes().startswith(b"\x89PNG\r\n\x1a\n"), asset

    world = (ROOT / "Godot/scripts/world_v127.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()
    capture = (ROOT / "Godot/scripts/capture_screenshot.gd").read_text()
    player = (ROOT / "Godot/scripts/default_player_sprite_sheet.gd").read_text()

    for path in [
        "industrial_road_catalog.gd",
        "utility_props_catalog.gd",
        "wind_turbine_catalog.gd",
        "asic_air_s19j_catalog.gd",
        "world_v127.gd",
    ]:
        assert path in validator, path

    assert 'extends "res://scripts/world_v126.gd"' in world
    for token in [
        "hashrace_industrial_road_live",
        "hashrace_utility_props_live",
        "hashrace_wind_turbine_live",
        "hashrace_asic_air_live",
    ]:
        assert token in world, token
        assert token in capture, token

    assert "hashrace_player_32frame_asset_live" in world

    assert "_v127_draw_industrial_road" in world
    assert "_v127_draw_utility_cluster" in world
    assert_world_inherits("world_v127.gd")
    assert "FRAME_REGIONS" in player
    # Animation names are now assembled from the four facing keys so the
    # effective 16-pose runtime can reuse the exact approved 32-pose PNG.
    for facing in ["down", "up", "left", "right"]:
        assert f'"{facing}"' in player, facing
    assert 'StringName("walk_" + facing)' in player
    assert 'StringName("idle_" + facing)' in player
    print("Hash Race v0.127 live asset-bundle contract: PASS")

if __name__ == "__main__":
    main()
