"""v0.144 exact-sheet character customization regression contract."""
from hashlib import sha256
from pathlib import Path

from world_script_contract import active_world_scripts

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

assert 'res://scripts/world_v165.gd' in scene
assert "res://scripts/world_v144.gd" in active_world_scripts(), "character customization must remain in live gameplay inheritance"
for marker in [
    "skin_tone_idx", "suit_color_idx", "scouter_color_idx",
    "CharacterCustomization.skin_tone(skin_idx)",
    "CharacterCustomization.suit_color(suit_idx)",
    "CharacterCustomization.scouter_lens_color(scouter_idx)",
    "DefaultPlayerSheetV144.build_customized_texture",
    "draw_texture_rect_region(v144_player_texture",
]:
    assert marker in world, f"Live v0.144 customization marker missing: {marker}"
print("Current approved-sheet skin/suit/scouter full-gameplay startup wiring contract: PASS")
