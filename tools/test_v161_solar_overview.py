"""Check that the cropped, transparent solar image is a genuine repo PNG.

Godot import and the live screenshot are separate mandatory gates.
"""
from pathlib import Path
import hashlib
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
PNG = ROOT / "Godot/art/energy/solar_array_overview.png"
EXPECTED = "06b542233279854dea18a10cf10e16b32772057add0bec8f896fc2a282ab407f"


def test_png():
    data = PNG.read_bytes()
    assert data.startswith(b"\x89PNG\r\n\x1a\n")
    assert hashlib.sha256(data).hexdigest() == EXPECTED
    offset = 8
    image_stream = bytearray()
    dimensions = None
    has_alpha = False
    while offset + 12 <= len(data):
        length = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset + 4:offset + 8]
        end = offset + 12 + length
        assert end <= len(data), "truncated PNG"
        body = data[offset + 8:offset + 8 + length]
        check = struct.unpack_from(">I", data, offset + 8 + length)[0]
        assert zlib.crc32(kind + body) & 0xffffffff == check, f"CRC {kind}"
        if kind == b"IHDR":
            dimensions = struct.unpack(">IIBBBBB", body)
        elif kind == b"tRNS":
            has_alpha = 0 in body
        elif kind == b"IDAT":
            image_stream.extend(body)
        offset = end
        if kind == b"IEND":
            break
    assert dimensions == (128, 136, 8, 3, 0, 0, 0), dimensions
    assert has_alpha, "transparent palette/background required"
    assert len(zlib.decompress(image_stream)) == 136 * (1 + 128)


def test_live():
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    stable_world = ROOT / "Godot/scripts/world.gd"

    # The current scene has one stable entry point and one semantic infrastructure
    # API. Release-numbered catalogs/capture scripts are historical evidence only.
    assert 'path="res://scripts/world.gd" type="Script"' in scene
    assert stable_world.exists()
    live = stable_world.read_text()
    assert 'const SOLAR_ART := preload("res://art/energy/solar_array_overview.png")' in live
    assert '"solar": Rect2(' in live
    assert '_draw_asset(SOLAR_ART, CAMPUS.solar)' in live
    assert 'grid_nav.block_rect(_ground_foot(rect))' in live
    assert 'func infrastructure_ready(asset_id: String) -> bool:' in live
    assert '"solar":\n            texture = SOLAR_ART' in live
    assert 'return not grid_nav.world_is_walkable(foot.get_center())' in live


if __name__ == "__main__":
    test_png()
    test_live()
    print("solar PNG CRC/alpha/hash and semantic stable-runtime wiring passed")
