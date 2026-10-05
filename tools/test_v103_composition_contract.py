"""Hash Race v0.103 intentional-world composition contract."""
from pathlib import Path
from world_script_contract import active_world_scripts
import re

ROOT = Path(__file__).resolve().parents[1]
world = (ROOT / "Godot/scripts/world_v103.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
renderer = (ROOT / "Godot/scripts/pixel_rpg_building_renderer.gd").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert version.startswith("v0."), version
assert int(version.split(".")[1]) >= 103, version
# The retired source remains checked below; current composition follows the
# actual stable scene rather than requiring a numbered ancestor.
assert active_world_scripts() == {"res://scripts/world.gd"}
live = (ROOT / "Godot/scripts/world.gd").read_text(encoding="utf-8")
placements = {name: tuple(map(float, values)) for name, *values in re.findall(
    r'"(container|solar|transformer|asic|wind)": Rect2\((\d+), (\d+), (\d+), (\d+)\)', live
)}
assert len(placements) == 5, "all five permanent infrastructure placements required"
for name, (x, y, width, height) in placements.items():
    assert width > 0 and height > 0 and x >= 0 and y >= 0
    assert x + width <= 1800 and y + height <= 1120, name + " outside world"
    assert y + height < 570, name + " overlaps service road"
for name, (x, y, width, height) in placements.items():
    for other, (ox, oy, ow, oh) in placements.items():
        if name < other:
            assert x + width <= ox or ox + ow <= x or y + height <= oy or oy + oh <= y, (name, other)
assert placements["asic"][0] < placements["transformer"][0] < placements["solar"][0]
assert "y_sort_enabled = true" in live
assert "sprite.position = Vector2(fitted.position.x, fitted.end.y)" in live
assert "sprite.offset = Vector2(0.0, -float(texture.get_height()))" in live
assert "CHARACTER_FOOT_DRAW_OFFSET" in live
assert 'func _draw_service_road()' in live

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

print("Hash Race current campus composition and retained v0.103 source contract passed.")
