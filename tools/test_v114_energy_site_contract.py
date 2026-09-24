from pathlib import Path
from world_script_contract import assert_world_inherits

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v114.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
ENERGY = (ROOT / "Godot/systems/energy_visual_catalog.gd").read_text(encoding="utf-8")

def main():
    assert 'extends "res://scripts/world_v113.gd"' in WORLD
    assert "_v114_draw_energy_source" in WORLD
    assert "_v114_draw_container" in WORLD
    assert "_v114_draw_transformer" in WORLD
    assert "_v114_footprint_tiles(1.0)" in WORLD
    assert "ten_mw == 4" in WORLD
    assert "hundred_mw == 8" in WORLD
    assert "master_texture()" in WORLD
    assert "ENERGY_VISUALS.size() == 13" in ENERGY
    assert_world_inherits("world_v114.gd")
    print("v0.114 live energy art + capacity scale contract PASS")

if __name__ == "__main__":
    main()
