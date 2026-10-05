"""Hash Race v0.103 intentional-world composition contract."""
from pathlib import Path
from world_script_contract import active_world_scripts

ROOT = Path(__file__).resolve().parents[1]
world = (ROOT / "Godot/scripts/world_v103.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
renderer = (ROOT / "Godot/scripts/pixel_rpg_building_renderer.gd").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert version.startswith("v0."), version
assert int(version.split(".")[1]) >= 103, version
live_scripts = active_world_scripts()
assert 'res://scripts/world_v165.gd' in scene
for required in ["res://scripts/world_v103.gd", "res://scripts/world_v102.gd", "res://scripts/world_v165.gd"]:
    assert required in live_scripts, f"intentional-world composition layer is not live: {required}"
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

# The promoted archive props are supplemental scenery only. Their live-map scale
# is independently guarded by test_archive_sprite_props_contract.py; v0.103's
# world-composition contract must not force the retired stripped five-prop scene.
print("Hash Race v0.103 composition remains in the restored full gameplay chain.")
