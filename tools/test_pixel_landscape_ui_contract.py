from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

world_scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
landscape = (ROOT / "Godot/scripts/world_pixel_landscape.gd").read_text(encoding="utf-8")
compact = (ROOT / "Godot/scripts/world_ui_compact.gd").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert re.fullmatch(r"v0\.\d{3}", version), version
assert 'res://scripts/world_ui_compact.gd' in world_scene

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

print("pixel landscape + compact UI contract: PASS")
