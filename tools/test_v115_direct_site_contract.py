from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v115.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
CAPTURE = (ROOT / "Godot/scripts/capture_energy_site.gd").read_text(encoding="utf-8")
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

def current_world_script() -> str:
    # VERSION is formatted like v0.134, while live scripts are world_v134.gd.
    # Derive the release layer from the numeric patch component instead of
    # deleting punctuation, which incorrectly produced world_v0134.gd.
    patch = int(VERSION.removeprefix("v").split(".")[-1])
    return f"world_v{patch:03d}.gd"

def main():
    assert 'extends "res://scripts/world_v114.gd"' in WORLD
    assert "func _draw_world_props_pixel" in WORLD
    assert "_v115_draw_live_site" in WORLD
    assert "_v114_draw_energy_source" in WORLD
    assert "_v114_draw_container" in WORLD
    assert "_v114_draw_transformer" in WORLD
    # v0.115 is a retained inherited gameplay layer; the live scene must boot
    # the world script matching the current release rather than point backward.
    live_world = current_world_script()
    assert live_world in SCENE, live_world
    assert "hashrace-energy-site.png" in CAPTURE
    print(f"v0.115 direct live mining-site contract PASS through {live_world}")

if __name__ == "__main__":
    main()
