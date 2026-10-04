"""v0.144 exact-sheet character customization regression contract."""
import re
from hashlib import sha256
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "Godot/scripts"
sheet = ROOT / "Godot/art/characters/default_player_sheet.png"
sheet_code = (SCRIPTS / "default_player_sprite_sheet.gd").read_text(encoding="utf-8")
customization = (SCRIPTS / "character_customization.gd").read_text(encoding="utf-8")
preview = (SCRIPTS / "character_preview.gd").read_text(encoding="utf-8")
world = (SCRIPTS / "world_v144.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")

assert sha256(sheet.read_bytes()).hexdigest() == "2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211"
assert "build_customized_texture" in sheet_code
assert "EFFECTIVE_SOURCE_INDICES" in sheet_code
assert "SUIT_COLORS" in customization and "DEFAULT_SUIT_COLOR" in customization
assert "DefaultPlayerSheet.build_customized_texture" in preview
assert "ACTUAL PLAYER PREVIEW" in preview
assert "approved_32frame_runtime_palette" in world
assert "debug_v144_palette_key" in world

# Customization must reach the current AnimatedSprite2D at campaign start.
live = (SCRIPTS / "world.gd").read_text(encoding="utf-8")
assert 'res://scripts/world.gd' in scene
for key in ["hashrace_character_skin_tone", "hashrace_character_suit_color", "hashrace_character_scouter_color"]:
    assert key in live
assert "PlayerSheet.build_customized_frames" in live
assert "player_sprite.sprite_frames = frames" in live
assert "CharacterCustomization.skin_tone(skin_idx)" in live
assert "CharacterCustomization.suit_color(suit_idx)" in live
assert "CharacterCustomization.scouter_lens_color(scouter_idx)" in live
print("Current approved-sheet skin/suit/scouter startup wiring contract: PASS")
