"""v0.145 Library-derived NPC miner binary/runtime integration contract."""
from hashlib import sha256
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]
sheet = ROOT / "Godot/art/characters/npc_miner_sheet.png"
data = sheet.read_bytes()
catalog = (ROOT / "Godot/scripts/npc_miner_sprite_sheet.gd").read_text(encoding="utf-8")
world = (ROOT / "Godot/scripts/world_v145.gd").read_text(encoding="utf-8")
capture = (ROOT / "Godot/scripts/capture_npc_miner_sprite.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")

assert (ROOT / "VERSION").read_text().strip() == "v0.145"
assert data[:8] == b"\x89PNG\r\n\x1a\n"
assert struct.unpack(">II", data[16:24]) == (512, 512)
assert sha256(data).hexdigest() == "519fa3a2b9b9d861da1acad119c7ebe991c182bc46e8e1dd95c0ec13deedb3f7"
assert '"down": 0' in catalog and '"left": 1' in catalog and '"right": 2' in catalog and '"up": 3' in catalog
assert "hashrace_npc_miner_asset_live" in world
assert "draw_texture_rect_region" in world
# Authored atlas cells may deliberately repeat. The actual-world proof compares
# source-pose equality with rendered-pose equality so direction/frame mapping
# is still strict without inventing uniqueness that is absent from the PNG.
assert "16 live poses preserve exact source direction/frame mapping" in capture
assert "source_same != live_same" in capture
assert 'path="res://scripts/world_v145.gd"' in scene
print("Hash Race v0.145 NPC miner valid-binary runtime contract: PASS")
