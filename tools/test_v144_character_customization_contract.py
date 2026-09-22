"""v0.144 exact-sheet character customization regression contract."""
from hashlib import sha256
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
sheet = ROOT / "Godot/art/characters/default_player_sheet.png"
sheet_code = (ROOT / "Godot/scripts/default_player_sprite_sheet.gd").read_text(encoding="utf-8")
customization = (ROOT / "Godot/scripts/character_customization.gd").read_text(encoding="utf-8")
preview = (ROOT / "Godot/scripts/character_preview.gd").read_text(encoding="utf-8")
world = (ROOT / "Godot/scripts/world_v144.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")

assert sha256(sheet.read_bytes()).hexdigest() == "2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211"
assert "build_customized_texture" in sheet_code
assert "EFFECTIVE_SOURCE_INDICES" in sheet_code
assert "SUIT_COLORS" in customization and "DEFAULT_SUIT_COLOR" in customization
assert "DefaultPlayerSheet.build_customized_texture" in preview
assert "ACTUAL PLAYER PREVIEW" in preview
assert "approved_32frame_runtime_palette" in world
assert "debug_v144_palette_key" in world

# The v0.144 character contract must survive later live-world revisions. Resolve
# the scene's current world script, then walk its inheritance chain back to v144
# instead of pinning world.tscn forever to one historical version.
match = re.search(r'path="res://scripts/(world_v\d+\.gd)"', scene)
assert match, "world.tscn must reference a versioned live world script"
live_world_name = match.group(1)
visited = set()
while live_world_name != "world_v144.gd":
    assert live_world_name not in visited, "world inheritance chain contains a cycle"
    visited.add(live_world_name)
    live_world_path = ROOT / "Godot/scripts" / live_world_name
    assert live_world_path.exists(), f"missing live world script: {live_world_name}"
    live_world = live_world_path.read_text(encoding="utf-8")
    parent = re.search(r'extends\s+"res://scripts/(world_v\d+\.gd)"', live_world)
    assert parent, f"{live_world_name} must inherit a versioned world layer"
    live_world_name = parent.group(1)

print("Hash Race v0.144 exact approved-sheet skin/suit customization contract: PASS")
