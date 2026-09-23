#!/usr/bin/env python3
"""Regression contract for exact v0.163 source files and authored PNG.
Usage: python tools/test_v163_industrial_visual_contract.py
"""
from pathlib import Path
import hashlib
import struct

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v163.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
VALIDATOR = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text(encoding="utf-8")
PNG = ROOT / "Godot/art/buildings/industrial_overhead_atlas.png"
EXPECTED_SHA256 = "9d5fdf09174676544fd68d929406b9b912331345244ced0b7c85660e007398c7"

def main():
    blob = PNG.read_bytes()
    assert blob.startswith(b"\x89PNG\r\n\x1a\n"), "Not PNG binary"
    assert struct.unpack(">II", blob[16:24]) == (192, 64), "Atlas must be 3 x 64-pixel cells"
    assert hashlib.sha256(blob).hexdigest() == EXPECTED_SHA256, "Unexpected binary drift"
    assert "res://scripts/world_v163.gd" in SCENE, "Scene is not running the refactor"
    assert '"res://scripts/world_v163.gd"' in VALIDATOR, "Missing modular parser gate"
    assert "extends \"res://scripts/world_v162.gd\"" in WORLD
    assert "func _v158_draw_facility(" in WORLD
    assert "draw_texture_rect_region(v163_industrial_texture" in WORLD
    assert "func _v128_draw_command_hut(" in WORLD
    assert "func _v159_draw_cable_tray(" in WORLD
    assert "GBPaint.paint_line(art_cells, Vector2i(2, 19), Vector2i(60, 19), 1" in WORLD
    assert "GBPaint.paint_line(art_cells, Vector2i(29, 9), Vector2i(29, 19), 1" in WORLD
    assert "debug_v162_ready()" in WORLD
    for tier in ("1.0) == 2", "10.0) == 4", "25.0) == 6", "100.0) == 8"):
        assert tier in WORLD, f"Capacity contract missing {tier}"
    print("PASS v0.163: binary PNG integrity, live scene, atlas rendering, road contract, capacity inheritance")

if __name__ == "__main__":
    main()
