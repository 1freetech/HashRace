from pathlib import Path
from world_script_contract import assert_world_inherits

ROOT = Path(__file__).resolve().parents[1]

def main():
    assert (ROOT / "VERSION").read_text().strip() >= "v0.124"

    world = (ROOT / "Godot/scripts/world_v124.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()
    capture = (ROOT / "Godot/scripts/capture_screenshot.gd").read_text()
    spec = (ROOT / "docs/visual_target_v121.md").read_text()

    assert 'extends "res://scripts/world_v123.gd"' in world
    for token in [
        "_v124_draw_transmission_grid",
        "_v124_draw_sagging_cable",
        "_v124_draw_shoreline",
        "_v124_draw_sparse_landscape",
        "hashrace_runtime_visual_proof_required",
        "debug_v124_ready",
    ]:
        assert token in world, token

    assert_world_inherits("world_v124.gd")
    assert "world_v124.gd" in validator
    assert "hashrace_v124_visual_target_revision" in capture
    assert "Reference image = **target**." in spec
    assert (ROOT / "Godot/art/reference/hashrace_visual_target_v121.png").exists()

    print("Hash Race v0.124 visual-match contract: PASS")

if __name__ == "__main__":
    main()
