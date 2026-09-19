"""v0.093 start-menu preview and UI cleanup regression contract."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
setup = (ROOT / "Godot/scripts/campaign_setup.gd").read_text(encoding="utf-8")
preview = (ROOT / "Godot/scripts/character_preview.gd").read_text(encoding="utf-8")
widget = (ROOT / "Godot/scripts/mining_ops_widget.gd").read_text(encoding="utf-8")
compact = (ROOT / "Godot/scripts/world_ui_compact.gd").read_text(encoding="utf-8")
release = (ROOT / "Godot/scripts/world_v093.gd").read_text(encoding="utf-8")

assert version == "v0.093", version
assert "world_v093.gd" in scene
assert 'preload("res://scripts/character_preview.gd")' in setup
assert 'character_preview.name = "CharacterPreview"' in setup
assert "character_preview.set_character(skin_idx, gender_idx)" in setup
assert "LIVE PLAYER PREVIEW" in preview
assert "func set_character(" in preview
assert "CharacterCustomization.skin_tone" in preview
assert "CharacterCustomization.outfit" in preview

assert 'const BASE_SIZE := Vector2(528.0, 248.0)' in widget
assert 'const MIN_SIZE := Vector2(420.0, 208.0)' in widget
assert 'const HEADER_H: float = 44.0' in widget

assert "overworld_header_panel" in compact
assert "overworld_header_panel.visible = false" in compact
assert "debug_overworld_header_removed" in compact
assert "debug_v093_ready" in release

print("v0.093 start-menu preview / thin dashboard / overworld-header cleanup contract PASS")
