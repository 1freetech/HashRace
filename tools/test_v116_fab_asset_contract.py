from pathlib import Path
from world_script_contract import assert_world_inherits
ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v116.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
ASSET = ROOT / "Godot/assets/imported/v115/semiconductor_fab.jpg"

def main():
    assert ASSET.exists() and ASSET.stat().st_size > 1000
    assert 'V116_FAB_PATH := "res://assets/imported/v115/semiconductor_fab.jpg"' in WORLD
    assert "partner_idx != 3" in WORLD
    assert "draw_texture_rect_region" in WORLD
    assert "V116_FAB_DOWN_FRAME := Vector2i(1, 0)" in WORLD
    assert_world_inherits("world_v116.gd")
    print("v0.116 exact semiconductor-fab asset contract PASS")

if __name__ == "__main__":
    main()
