#!/usr/bin/env python3
"""Prevent the full Hash Race gameplay chain from reverting the approved walk fix."""
import re
from pathlib import Path

from world_script_contract import active_world_scripts

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "Godot/scripts"

def read(path):
    return (SCRIPTS / path).read_text(encoding="utf-8")

def main():
    overworld = read("world_overworld.gd")
    movement = read("rpg_movement.gd")
    sheet = read("default_player_sprite_sheet.gd")
    rpg = read("world_rpg_strategy.gd")
    world_player = read("world_v121.gd")
    palette_player = read("world_v144.gd")
    visual = read("default_player_visual.gd")
    validator = read("validate_player_walk_motion.gd")
    assert re.search(r"const WALK_SPEED:\s*float\s*=\s*144\.0\b", overworld)
    assert "const WALK_CYCLE_DISTANCE: float = 72.0" in movement
    assert "WALK_FRAME_COUNT := 4" in sheet
    assert "WALK_FPS := 8.0" in sheet
    assert "EFFECTIVE_FRAME_COUNT := 20" in sheet
    assert "EFFECTIVE_SOURCE_INDICES := [0, 1, 3, 5, 7]" in sheet
    for facing in ["down", "left", "right", "up"]:
        assert f'"{facing}": [1, 3, 5, 7]' in sheet
    assert "for source_index in WALK_SOURCE_ORDER[facing]:" in sheet
    assert 4 / 8 == 72 / 144
    assert "RPGMovement.settled_step_phase(actual_motion, rep_step_phase)" in rpg
    assert "RPGMovement.resolve_axis_motion" in rpg
    assert "DefaultPlayerSheet.walk_frame(moving, rep_step_phase)" in world_player
    assert "DefaultPlayerSheetV144.walk_frame(moving, rep_step_phase)" in palette_player
    assert "var built: SpriteFrames = DefaultPlayerSheet.build_frames()" in visual
    assert "HASH RACE WALK MOTION PASS" in validator
    live_scripts = active_world_scripts()
    for required in ["res://scripts/world_v121.gd", "res://scripts/world_v144.gd", "res://scripts/world_v165.gd"]:
        assert required in live_scripts, f"walk/render gameplay layer is not live: {required}"
    assert 'res://scripts/world_v165.gd' in (ROOT / "Godot/scenes/world.tscn").read_text()
    print("HASH RACE WALK CONTRACT PASS: full gameplay chain retains 144 px/s, four authored poses, 8 FPS and 72 px cadence")

if __name__ == "__main__":
    main()
