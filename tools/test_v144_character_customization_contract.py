"""v0.144 exact-sheet character customization regression contract."""
from hashlib import sha256
from pathlib import Path

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
# v0.144 is a retained regression layer; the playable scene may legitimately
# advance to a later world_v### layer as long as that layer inherits v0.144.
live_scene_match = __import__("re").search(r'path="res://scripts/(world_v\d+\.gd)" type="Script" id="1_world"', scene)
assert live_scene_match, "world.tscn must point at a versioned live world script"
live_world_path = ROOT / "Godot/scripts" / live_scene_match.group(1)
live_world = live_world_path.read_text(encoding="utf-8")
if live_world_path.name != "world_v144.gd":
    assert 'extends "res://scripts/world_v144.gd"' in live_world, (
        f"{live_world_path.name} must retain the v0.144 customization layer"
    )
print("Hash Race v0.144 exact approved-sheet skin/suit customization contract: PASS")
