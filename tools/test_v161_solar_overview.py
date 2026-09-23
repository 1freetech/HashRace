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
    script = (ROOT / "Godot/scripts/world_v161.gd").read_text()
    v162 = (ROOT / "Godot/scripts/world_v162.gd").read_text()
    v163_path = ROOT / "Godot/scripts/world_v163.gd"
    catalog = (ROOT / "Godot/scripts/v161_solar_overview_sprite.gd").read_text()
    capture = (ROOT / "Godot/scripts/capture_v161_solar.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    # Preservation assertion follows the current live inheritance chain instead
    # of pinning the scene forever to an older live-world layer.
    if v163_path.exists():
        current = v163_path.read_text()
        assert "world_v163.gd" in scene
        assert 'extends "res://scripts/world_v162.gd"' in current
        assert "V161Solar.texture()" in current
        assert "func _draw_power_building(" in current
    else:
        assert "world_v162.gd" in scene
    assert 'extends "res://scripts/world_v161.gd"' in v162
    assert "solar_array_overview.png" in catalog
    assert "V161Solar.texture()" in script
    assert "func _v114_draw_energy_source(" in script
    assert "super._v114_draw_energy_source(" in script
    assert "grid_nav.block_rect(foot)" in script
    assert "func _draw_rep()" in script and "draw_texture_rect(v161_solar_texture" in script
    assert 'inventory.deploy("solar_array"' in capture
    assert "debug_v161_solar_ready" in capture

if __name__ == "__main__":
    test_png()
    test_live()
    print("v0.161 real solar PNG CRC/alpha/hash/live inheritance passed")
