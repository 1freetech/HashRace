from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORLD = ROOT / "Godot" / "scripts" / "world_v122.gd"
SCENE = ROOT / "Godot" / "scenes" / "world.tscn"
VERSION = ROOT / "VERSION"


def test_v122_interaction_marker_contract() -> None:
    source = WORLD.read_text(encoding="utf-8")
    scene = SCENE.read_text(encoding="utf-8")

    assert 'extends "res://scripts/world_v121.gd"' in source
    assert "_nearest_entity()" in source
    assert "_entity_in_interact_range(idx)" in source
    assert "_v122_draw_interaction_target" in source
    assert "draw_arc(target" in source
    assert "debug_v121_ready()" in source
    assert 'res://scripts/world_v122.gd' in scene
    assert VERSION.read_text(encoding="utf-8").strip() == "v0.122"


if __name__ == "__main__":
    test_v122_interaction_marker_contract()
    print("Hash Race v0.122 interaction marker contract: PASS")
