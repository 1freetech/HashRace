from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v114.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
ENERGY = (ROOT / "Godot/systems/energy_visual_catalog.gd").read_text(encoding="utf-8")
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

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
    # v0.114 remains a retained historical layer. The playable scene must boot
    # the current sequential release rather than stay pinned to world_v114.gd.
    current_world = f'world_v{int(VERSION.split(".")[1]):03d}.gd'
    assert current_world in SCENE, current_world
    assert (ROOT / "Godot/scripts/world_v114.gd").is_file()
    print(f"v0.114 live energy art + capacity scale contract PASS through {current_world}")

if __name__ == "__main__":
    main()
