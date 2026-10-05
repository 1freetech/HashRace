"""Binary and current full-gameplay wiring contract for the validated wind asset."""
from pathlib import Path
import hashlib
import struct
import zlib

from world_script_contract import active_world_scripts

ROOT = Path(__file__).resolve().parents[1]
PNG = ROOT / "Godot/art/energy/wind_turbine_directional_sheet.png"
EXPECTED = "5087f4b52e2fe324669efc6ffee0b4bbfd000b80d2280b7f73869ded94330c7d"


def test_png():
    data = PNG.read_bytes()
    assert len(data) == 2278
    assert data.startswith(b"\x89PNG\r\n\x1a\n")
    assert hashlib.sha256(data).hexdigest() == EXPECTED
    offset = 8
    dimensions = None
    saw_iend = False
    while offset + 12 <= len(data):
        length = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset + 4:offset + 8]
        end = offset + 12 + length
        assert end <= len(data), "truncated PNG"
        body = data[offset + 8:offset + 8 + length]
        crc = struct.unpack_from(">I", data, offset + 8 + length)[0]
        assert zlib.crc32(kind + body) & 0xffffffff == crc, f"CRC {kind}"
        if kind == b"IHDR": dimensions = struct.unpack(">IIBBBBB", body)
        if kind == b"IEND":
            saw_iend = True
            break
        offset = end
    assert dimensions[:2] == (128, 128), dimensions
    assert saw_iend


def test_live_wiring():
    world = (ROOT / "Godot/scripts/world_v164.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    assert 'res://scripts/world_v165.gd' in scene
    assert "res://scripts/world_v164.gd" in active_world_scripts()
    assert 'V164Wind = preload("res://scripts/wind_turbine_catalog.gd")' in world
    assert 'asset_id != "wind_farm"' in world
    assert 'V164Wind.region(orientation)' in world
    assert 'grid_nav.block_rect(foot)' in world
    assert 'v164_wind_footprint_registered = true' in world
    assert 'func debug_v164_wind_ready() -> bool:' in world
    assert 'not grid_nav.world_is_walkable(v164_wind_footprint.get_center())' in world


if __name__ == "__main__":
    test_png()
    test_live_wiring()
    print("wind PNG CRC/hash/dimensions + full gameplay runtime wiring passed")
