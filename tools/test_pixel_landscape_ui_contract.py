from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

world_scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
world_v059 = (ROOT / "Godot/scripts/world_v059.gd").read_text(encoding="utf-8")
world_v055 = (ROOT / "Godot/scripts/world_v055.gd").read_text(encoding="utf-8")
landscape = (ROOT / "Godot/scripts/world_pixel_landscape.gd").read_text(encoding="utf-8")
compact = (ROOT / "Godot/scripts/world_ui_compact.gd").read_text(encoding="utf-8")
texture_spacing = (ROOT / "Godot/scripts/world_texture_spacing.gd").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert re.fullmatch(r"v0\.\d{3}", version), version
assert 'res://scripts/world_v059.gd' in world_scene, "Live scene must boot through the current v0.059 infrastructure composition layer"
assert 'extends "res://scripts/world_v055.gd"' in world_v059, "v0.059 must retain the procedural-building composition chain"
assert 'extends "res://scripts/world_v053.gd"' in world_v055, "v0.055 must retain the v0.053 character/detail composition chain"
assert 'extends "res://scripts/world_ui_compact.gd"' in texture_spacing, "Current visual chain must retain the compact control center"

# Dense terrain must be generated from real low-resolution pixel textures and
# nearest-neighbor scaled, not painted only as giant screen rectangles.
for marker in [
    "MICRO_TILE_SIZE: int = 16",
    "Image.create(MICRO_TILE_SIZE, MICRO_TILE_SIZE",
    "img.set_pixel",
    "ImageTexture.create_from_image",
    "CanvasItem.TEXTURE_FILTER_NEAREST",
    "_stamp_campus_walkways",
    "_draw_walkway_edges",
    "_draw_road_curbs",
    "_draw_water_bank",
]:
    assert marker in landscape, marker

# The UI must hide the formerly overlapping modules and expose them through a
# single compact control center while keeping all gameplay systems available.
for marker in [
    '"MENU  [M]"',
    '"CONTROL CENTER"',
    '"COMPANY"',
    '"BTC TREASURY"',
    '"LIFE + SITE"',
    '"LEAGUE STANDINGS"',
    '"MARKET INFO"',
    '"NEXT MINING TOWN  [T]"',
    'scanner_overlay_enabled = false',
    'layer.visible = false',
    '_clear_detail_panels',
]:
    assert marker in compact, marker

for marker in [
    "_draw_site_container",
    "_draw_micro_server_rack",
    "_draw_transformer_bank",
    "_draw_campus_data_bus",
    "_draw_cable_bundle",
    "debug_infrastructure_detail_ready",
]:
    assert marker in world_v059, marker

print("pixel landscape + compact UI + data-center infrastructure contract: PASS")
