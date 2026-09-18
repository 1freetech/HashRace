#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

scale = (ROOT / "Godot/scripts/world_scale_rules.gd").read_text()
camera = (ROOT / "Godot/scripts/camera_proportion_controller.gd").read_text()
manager = (ROOT / "Godot/autoloads/scene_manager.gd").read_text()
doorway = (ROOT / "Godot/components/world/doorway.gd").read_text()
roof = (ROOT / "Godot/components/world/roof_fade_area.gd").read_text()
world = (ROOT / "Godot/scripts/world_v089.gd").read_text()
grid = (ROOT / "Godot/scripts/world_grid.gd").read_text()
scene = (ROOT / "Godot/scenes/world.tscn").read_text()
project = (ROOT / "Godot/project.godot").read_text()
template = (ROOT / "Godot/templates/Doorway.tscn").read_text()
version = (ROOT / "VERSION").read_text().strip()

assert version == "v0.089", version
assert 'SceneManager="*res://autoloads/scene_manager.gd"' in project
assert "world_v089.gd" in scene

for marker in [
    "WORLD_TILE",
    "CHARACTER_VISUAL_HEIGHT",
    "DOOR_VISUAL_HEIGHT",
    "HQ_SIZE",
    "PARTNER_SIZE",
    "SERVICE_SIZE",
    "collision_rect",
    "front_door_world_pos",
    "depth_y",
]:
    assert marker in scale, marker

for marker in [
    "ZOOM_LEVELS",
    "0.75",
    "1.0",
    "1.5",
    "2.0",
    "KEY_MINUS",
    "KEY_EQUAL",
    "KEY_0",
    "MOUSE_BUTTON_WHEEL_UP",
    "MOUSE_BUTTON_WHEEL_DOWN",
    "_camera_shortcuts_allowed",
    "gui_get_focus_owner",
    "debug_focus_safe_shortcuts_ready",
]:
    assert marker in camera, marker

for marker in [
    "transition_to",
    "return_to_previous",
    "_scene_stack",
    "preserve_current_scene",
    "pending_spawn_name",
    "_find_player_actor",
    "_fade_to",
]:
    assert marker in manager, marker

for marker in [
    "target_scene",
    "target_spawn_point",
    "preserve_current_scene",
    "try_interact",
    '"/root/SceneManager"',
]:
    assert marker in doorway, marker

for marker in ["faded_alpha", "0.30", "target_path", "body_entered", "body_exited"]:
    assert marker in roof, marker

for marker in [
    "V089_CAMERA_INPUT_REVISION",
    "camera_proportion_controller",
    "debug_focus_safe_shortcuts_ready",
    "debug_v089_ready",
]:
    assert marker in world, marker

assert "WorldScale.collision_rect" in grid
assert "WorldScale.front_door_world_pos" in grid
assert "CollisionShape2D" in template

print("Hash Race v0.089 focus-safe camera, world scale, doorway, roof-fade and scene-transition contract passed.")
