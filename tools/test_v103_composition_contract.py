"""Hash Race v0.103 intentional-world composition contract."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
world = (ROOT / "Godot/scripts/world_v103.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
renderer = (ROOT / "Godot/scripts/pixel_rpg_building_renderer.gd").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert version == "v0.103", version
assert "world_v103.gd" in scene
assert 'extends "res://scripts/world_v102.gd"' in world

for marker in [
    "_v103_expand_negative_space",
    "_v103_visual_size",
    "_v103_draw_building_shadow",
    "_v103_draw_terrain_transitions",
    "_v103_transition_strip",
    "_v103_transition_dither",
    "scale = 1.10",
    "scale = 0.94",
]:
    assert marker in world, marker

assert "V103_SHADOW_NEAR" in world
assert "V103_GRASS_FRINGE" in world
assert "V103_WATER_GLEAM" in world
assert "0.50" in renderer, "building renderer needs stronger source shadow"
assert 'style == "hq"' in renderer, "landscaping should be intentionally sparse"

print("Hash Race v0.103 composition contract passed.")
