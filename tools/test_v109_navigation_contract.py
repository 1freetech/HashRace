from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
nav = (ROOT / "Godot/scripts/grid_navigation.gd").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert version == "v0.109", version
assert "rect.intersection(world_bounds)" in nav
assert "not _world_point_in_bounds(world_pos)" in nav
assert "not _world_point_in_bounds(start_world)" in nav
assert "reachable_frontier" in nav
assert "route_distance" in nav
assert "_safe_goal_point" in nav
assert "allowed_lookup.has(start)" in nav
assert "allowed_lookup.has(goal)" in nav
assert "ring.sort_custom" in nav
assert "debug_v109_navigation_ready" in nav
print("v0.109 navigation contract PASS")
