from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v116.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
ASSET = ROOT / "Godot/assets/imported/v115/semiconductor_fab.jpg"
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

def current_world_script() -> str:
    patch = int(VERSION.removeprefix("v").split(".")[-1])
    return f"world_v{patch:03d}.gd"

def main():
    assert ASSET.exists() and ASSET.stat().st_size > 1000
    assert 'V116_FAB_PATH := "res://assets/imported/v115/semiconductor_fab.jpg"' in WORLD
    assert "partner_idx != 3" in WORLD
    assert "draw_texture_rect_region" in WORLD
    assert "V116_FAB_DOWN_FRAME := Vector2i(1, 0)" in WORLD
    # v0.116 remains in the inherited gameplay chain; the live scene should
    # boot the current release layer instead of pointing backward at v0.116.
    live_world = current_world_script()
    assert live_world in SCENE, live_world
    print(f"v0.116 exact semiconductor-fab asset contract PASS through {live_world}")

if __name__ == "__main__":
    main()
