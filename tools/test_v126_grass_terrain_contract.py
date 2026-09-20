from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def main():
    assert (ROOT / "VERSION").read_text().strip() >= "v0.126"
    asset = ROOT / "Godot/art/terrain/grass_terrain_tilesheet.png"
    catalog = (ROOT / "Godot/scripts/grass_terrain_catalog.gd").read_text()
    world125 = (ROOT / "Godot/scripts/world_v125.gd").read_text()
    world126 = (ROOT / "Godot/scripts/world_v126.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()
    capture = (ROOT / "Godot/scripts/capture_screenshot.gd").read_text()
    assert asset.exists() and asset.stat().st_size > 8_000
    assert asset.read_bytes().startswith(b"\x89PNG\r\n\x1a\n")
    for token in ["grass_plain","grass_light","grass_dark","grass_white_flowers","grass_yellow_flowers","grass_rocks","grass_bushes","edge_bottom","path_horizontal","path_vertical"]:
        assert token in catalog, token
    assert "_v125_draw_terrain_underlay(campus)" in world125
    assert 'extends "res://scripts/world_v125.gd"' in world126
    assert "_v126_draw_grass_tile" in world126
    assert "GrassTerrainCatalog.variant_for_cell" in world126
    assert "hashrace_grass_terrain_asset_live" in world126
    assert "world_v126.gd" in scene
    assert "grass_terrain_catalog.gd" in validator
    assert "world_v126.gd" in validator
    assert "hashrace_v126_grass_terrain_revision" in capture
    print("Hash Race v0.126 grass-terrain atlas contract: PASS")

if __name__ == "__main__":
    main()
