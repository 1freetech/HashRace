"""Validate the actual extracted HashRace transformer binary and live wiring.

Runs without Pillow, ImageMagick or a cached Godot editor import. Godot's
independent fresh-checkout binary decode and rendered energy-site proof are
separate CI gates; this one catches damaged PNG and dead code early.
"""
from pathlib import Path
import hashlib
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
PNG = ROOT / "Godot/art/electrical/substation_transformer_rear.png"
WORLD = ROOT / "Godot/scripts/world_v160.gd"
CATALOG = ROOT / "Godot/scripts/substation_transformer_sprite.gd"
SCENE = ROOT / "Godot/scenes/world.tscn"
ENERGY_PROOF = ROOT / "Godot/scripts/capture_energy_site.gd"
EXPECTED_SHA = "4f1ece23333d48181085c3d0e22e7730181a45beaf7f6a80ed1fd254a1e16059"


def check_png() -> None:
    data = PNG.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    assert hashlib.sha256(data).hexdigest() == EXPECTED_SHA
    offset, image_data, alpha_chunk = 8, bytearray(), None
    dims = None
    while offset + 12 <= len(data):
        length = struct.unpack_from(">I", data, offset)[0]
        chunk_type = data[offset + 4:offset + 8]
        end = offset + 12 + length
        assert end <= len(data), f"truncated {chunk_type!r} chunk"
        body = data[offset + 8:offset + 8 + length]
        crc_stored = struct.unpack_from(">I", data, offset + 8 + length)[0]
        assert zlib.crc32(chunk_type + body) & 0xFFFFFFFF == crc_stored, f"bad CRC in {chunk_type!r}"
        if chunk_type == b"IHDR":
            dims = struct.unpack_from(">IIBBBBB", body)
        if chunk_type == b"IDAT":
            image_data.extend(body)
        if chunk_type == b"tRNS":
            alpha_chunk = body
        offset = end
        if chunk_type == b"IEND":
            break
    assert dims == (80, 72, 8, 3, 0, 0, 0), f"unexpected sprite size/encoding: {dims!r}"
    assert alpha_chunk is not None and alpha_chunk[0] == 0, "sprite must have a transparent background"
    assert len(zlib.decompress(image_data)) == 72 * (1 + 80), "PNG pixel stream failed full decode"


def check_runtime() -> None:
    world = WORLD.read_text(encoding="utf-8")
    catalog = CATALOG.read_text(encoding="utf-8")
    assert "func _v114_draw_transformer(" in world, "live v0.160 renderer must replace procedure"
    assert "V160SubstationSprite.texture()" in world
    assert "_v160_register_transformer_footprint" in world
    assert "grid_nav.block_rect(foot)" in world
    assert "func _draw_rep()" in world, "Y-aware player/transformer ordering missing"
    assert "draw_texture_rect(v160_transformer_texture" in world
    assert "substation_transformer_rear.png" in catalog
    assert "GROUND_CONTACT" in catalog and "sort_y" in catalog
    # The current scene advances by inheritance. Never pin regression coverage
    # to v0.160 forever: require its real implementation in the live chain.
    import re
    scene_source = SCENE.read_text(encoding="utf-8")
    match = re.search(r'res://scripts/(world_v\\d+\\.gd)', scene_source)
    assert match, "live scene has no versioned world"
    current = match.group(1)
    seen = set()
    while current != "world_v160.gd":
        assert current not in seen, "cycle in live world inheritance chain"
        seen.add(current)
        source_path = ROOT / "Godot/scripts" / current
        assert source_path.is_file(), f"missing live layer {current}"
        parent = re.search(r'^extends "res://scripts/(world_v\\d+\\.gd)"',
                           source_path.read_text(encoding="utf-8"), re.MULTILINE)
        assert parent, f"v0.160 no longer inherited from live {current}"
        current = parent.group(1)
    assert "debug_v160_transformer_ready" in ENERGY_PROOF.read_text(encoding="utf-8")


if __name__ == "__main__":
    check_png()
    check_runtime()
    print("v0.160 authentic Library transformer PNG integrity and runtime wiring passed")
