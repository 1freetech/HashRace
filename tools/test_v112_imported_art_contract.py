from pathlib import Path
from world_script_contract import assert_world_inherits

ROOT = Path(__file__).resolve().parents[1]
WORLD = ROOT / "Godot" / "scripts" / "world_v112.gd"
REGISTRY = ROOT / "Godot" / "systems" / "imported_art_v112.gd"
SCENE = ROOT / "Godot" / "scenes" / "world.tscn"


def main() -> None:
    world = WORLD.read_text(encoding="utf-8")
    registry = REGISTRY.read_text(encoding="utf-8")
    scene = SCENE.read_text(encoding="utf-8")

    assert 'extends "res://scripts/world_v111.gd"' in world
    assert 'Vector2i(4, 4)' in world
    assert '_v112_character_row' in world
    assert '_v112_character_frame' in world
    assert '_draw_mining_campus' in world
    assert '"asic_air"' in world
    assert '"transformer"' in world
    assert '"command_center"' in world
    assert 'SITE_ENERGY_KEYS' in registry
    assert registry.count('ROOT + "') >= 20
    assert_world_inherits("world_v112.gd")
    print("v0.112 imported art integration contract PASS")


if __name__ == "__main__":
    main()
