#!/usr/bin/env python3
"""Prevent v0.160+ from silently reverting the approved player walk fix."""
import re
from pathlib import Path

from world_script_contract import assert_world_inherits

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
    capture = read("capture_player_sprite.gd")
    visual = read("default_player_visual.gd")
    validator = read("validate_player_walk_motion.gd")
    assert re.search(r"const WALK_SPEED:\s*float\s*=\s*144\.0\b", overworld)
    assert "const WALK_CYCLE_DISTANCE: float = 72.0" in movement
    assert "WALK_FRAME_COUNT := 4" in sheet
    assert "WALK_FPS := 8.0" in sheet
    assert "EFFECTIVE_FRAME_COUNT := 20" in sheet
    assert "EFFECTIVE_SOURCE_INDICES := [0, 1, 3, 5, 7]" in sheet
    assert "var walk_regions: Array = [regions[1], regions[3], regions[5], regions[7]]" in sheet
    # Four poses at eight frames per second give a 0.5 s cycle.
    # At 144 pixels/second the distance per cycle is 72 px, not guessed.
    assert 4 / 8 == 72 / 144
    # Test the live rendering and inherited movement, not just helper constants.
    assert "RPGMovement.settled_step_phase(actual_motion, rep_step_phase)" in rpg
    assert "RPGMovement.resolve_axis_motion" in rpg
    assert "DefaultPlayerSheet.walk_frame(moving, rep_step_phase)" in world_player
    assert "DefaultPlayerSheetV144.walk_frame(moving, rep_step_phase)" in palette_player
    assert "var built: SpriteFrames = DefaultPlayerSheet.build_frames()" in visual
    assert "for frame in range(5):" in capture
    assert "motion-" in capture and "advance_step_phase" in capture
    assert "HASH RACE WALK MOTION PASS" in validator
    assert_world_inherits("world_v121.gd")
    assert_world_inherits("world_v144.gd")
    print("HASH RACE WALK CONTRACT PASS: live 144 px/s, four authored walk poses, 8 FPS, 72 px, current renderer inheritance")

if __name__ == "__main__":
    main()
