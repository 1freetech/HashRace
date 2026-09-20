from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v115.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
CAPTURE = (ROOT / "Godot/scripts/capture_energy_site.gd").read_text(encoding="utf-8")

def main():
    assert 'extends "res://scripts/world_v114.gd"' in WORLD
    assert "func _draw_world_props_pixel" in WORLD
    assert "_v115_draw_live_site" in WORLD
    assert "_v114_draw_energy_source" in WORLD
    assert "_v114_draw_container" in WORLD
    assert "_v114_draw_transformer" in WORLD
    assert "world_v115.gd" in SCENE
    assert "hashrace-energy-site.png" in CAPTURE
    print("v0.115 direct live mining-site contract PASS")

if __name__ == "__main__":
    main()
