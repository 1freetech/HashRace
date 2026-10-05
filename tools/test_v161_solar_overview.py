"""Check that the cropped transparent solar PNG is genuine and live in gameplay.

The live campaign now uses the full v0.165 inheritance chain; v0.161 solar must
remain inside that chain instead of forcing the stripped stable-world fixture.
"""
from pathlib import Path
import hashlib
import struct
import zlib

from world_script_contract import active_world_scripts

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
    assert 'path="res://scripts/world_v165.gd" type="Script"' in scene

    live_chain = active_world_scripts()
    assert "res://scripts/world_v165.gd" in live_chain
    assert "res://scripts/world_v161.gd" in live_chain

    solar_world = (ROOT / "Godot/scripts/world_v161.gd").read_text()
    solar_sprite = (ROOT / "Godot/scripts/v161_solar_overview_sprite.gd").read_text()
    assert 'const V161Solar = preload("res://scripts/v161_solar_overview_sprite.gd")' in solar_world
    assert 'asset_id != "solar_array"' in solar_world
    assert 'draw_texture_rect(v161_solar_texture, dest, false)' in solar_world
    assert 'grid_nav.block_rect(foot)' in solar_world
    assert 'func debug_v161_solar_ready() -> bool:' in solar_world
    assert 'TEXTURE_PATH := "res://art/energy/solar_array_overview.png"' in solar_sprite


if __name__ == "__main__":
    test_png()
    test_live()
    print("solar PNG CRC/alpha/hash and v0.165 gameplay-chain wiring passed")
