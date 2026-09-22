"""v0.147 validated NPC miner binary/runtime integration contract."""
from hashlib import sha256
from pathlib import Path
import struct
ROOT=Path(__file__).resolve().parents[1]
data=(ROOT/"Godot/art/characters/npc_miner_sheet.png").read_bytes()
catalog=(ROOT/"Godot/scripts/npc_miner_sprite_sheet.gd").read_text()
world=(ROOT/"Godot/scripts/world_v147.gd").read_text()
capture=(ROOT/"Godot/scripts/capture_npc_miner_sprite.gd").read_text()
scene=(ROOT/"Godot/scenes/world.tscn").read_text()
assert (ROOT/"VERSION").read_text().strip()=="v0.147"
assert data[:8]==b"\x89PNG\r\n\x1a\n"
assert struct.unpack(">II",data[16:24])==(512,512)
assert sha256(data).hexdigest()=="519fa3a2b9b9d861da1acad119c7ebe991c182bc46e8e1dd95c0ec13deedb3f7"
assert all(token in catalog for token in ['"down": 0','"left": 1','"right": 2','"up": 3'])
assert 'extends "res://scripts/world_v146.gd"' in world
assert "hashrace_npc_miner_asset_live" in world and "draw_texture_rect_region" in world
assert "16 live poses preserve distinct source direction/frame mapping" in capture
assert "not source_same and live_same" in capture
assert 'path="res://scripts/world_v147.gd"' in scene
print("Hash Race v0.147 NPC miner valid-binary runtime contract: PASS")
