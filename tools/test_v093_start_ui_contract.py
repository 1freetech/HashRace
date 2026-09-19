"""v0.093 start-menu preview and UI cleanup regression contract."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
setup = (ROOT / "Godot/scripts/campaign_setup.gd").read_text(encoding="utf-8")
preview = (ROOT / "Godot/scripts/character_preview.gd").read_text(encoding="utf-8")
widget = (ROOT / "Godot/scripts/mining_ops_widget.gd").read_text(encoding="utf-8")
compact = (ROOT / "Godot/scripts/world_ui_compact.gd").read_text(encoding="utf-8")
overworld = (ROOT / "Godot/scripts/world_overworld.gd").read_text(encoding="utf-8")
campaign = (ROOT / "Godot/scripts/world_campaign.gd").read_text(encoding="utf-8")
release = (ROOT / "Godot/scripts/world_v093.gd").read_text(encoding="utf-8")

assert re.fullmatch(r"v0\.\d{3}", version), version
version_number = int(version.rsplit(".", 1)[1])
assert version_number >= 93, f"v0.093 feature contract requires v0.093 or newer, got {version}"
live_match = re.search(
    r'ext_resource path="res://scripts/world_v([0-9]+)[.]gd" type="Script" id="1_world"',
    scene,
)
assert live_match, "Live scene must declare a versioned world_v###.gd gameplay script"
assert int(live_match.group(1)) >= 93, "Live world must retain the v0.093 feature layer or a newer descendant"
assert (ROOT / "Godot/scripts/world_v093.gd").is_file(), "v0.093 feature layer must remain in the release chain"
assert 'preload("res://scripts/character_preview.gd")' in setup
assert 'character_preview.name = "CharacterPreview"' in setup
assert "character_preview.set_character(" in setup
assert "scouter_color_idx" in setup and "scouter_eye_idx" in setup, "Live preview must include current scouter customization"
assert "LIVE PLAYER PREVIEW" in preview
assert "func set_character(" in preview
assert "CharacterCustomization.skin_tone" in preview
assert "CharacterCustomization.outfit" in preview
assert "MAX_CAMPAIGN_YEARS: int = 100" in setup
assert "range(1, MAX_CAMPAIGN_YEARS + 1)" in setup

assert 'const BASE_SIZE := Vector2(528.0, 248.0)' in widget
assert 'const MIN_SIZE := Vector2(420.0, 208.0)' in widget
assert 'const HEADER_H: float = 44.0' in widget

assert "overworld_header_panel" in compact
assert "overworld_header_panel.visible = false" in compact
assert "debug_overworld_header_removed" in compact
assert "debug_v093_ready" in release
assert "MAX_CAMPAIGN_YEARS: int = 100" in overworld
assert "MAX_CAMPAIGN_YEARS := 100" in campaign

print("v0.093 start-menu preview / thin dashboard / overworld-header / 100-year campaign contract PASS")
