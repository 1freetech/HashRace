from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def main():
    version = (ROOT / "VERSION").read_text().strip()
    assert version.startswith("v0.") and int(version.split(".")[-1]) >= 125

    asset = ROOT / "Godot/art/terrain/dirt_road_tilesheet.png"
    catalog = (ROOT / "Godot/scripts/dirt_road_catalog.gd").read_text()
    world = (ROOT / "Godot/scripts/world_v125.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()
    capture = (ROOT / "Godot/scripts/capture_screenshot.gd").read_text()

    assert asset.exists() and asset.stat().st_size > 20_000
    assert asset.read_bytes().startswith(b"\x89PNG\r\n\x1a\n")
    assert "res://art/terrain/dirt_road_tilesheet.png" in catalog
    for token in ["straight_v", "straight_h", "cross", "t_down", "t_up", "end_left", "filler_tracks"]:
        assert token in catalog, token

    assert 'extends "res://scripts/world_v124.gd"' in world
    for token in [
        "_v125_draw_dirt_network",
        "_v125_draw_dirt_tile",
        "DirtRoadCatalog.choose_tile",
        "TEXTURE_FILTER_NEAREST",
        "hashrace_dirt_road_asset_live",
    ]:
        assert token in world, token

    assert "world_v125.gd" in scene or "world_v126.gd" in scene
    assert "dirt_road_catalog.gd" in validator
    assert "world_v125.gd" in validator
    assert "hashrace_v125_dirt_road_revision" in capture

    print("Hash Race v0.125 dirt-road atlas contract: PASS")

if __name__ == "__main__":
    main()
