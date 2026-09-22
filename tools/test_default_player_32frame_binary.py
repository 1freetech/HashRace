from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
PNG = ROOT / "Godot/art/characters/default_player_sheet.png"


def main():
    data = PNG.read_bytes()
    assert data.startswith(b"\x89PNG\r\n\x1a\n")

    pos = 8
    width = height = None
    idat = bytearray()
    seen_iend = False

    while pos + 12 <= len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + length]
        crc = struct.unpack(">I", data[pos + 8 + length:pos + 12 + length])[0]
        assert zlib.crc32(kind + payload) & 0xFFFFFFFF == crc

        if kind == b"IHDR":
            width, height, bit_depth, color_type, *_ = struct.unpack(
                ">IIBBBBB", payload
            )
            assert (width, height) == (256, 160)
            assert bit_depth == 8
            assert color_type in (3, 6)
        elif kind == b"IDAT":
            idat.extend(payload)
        elif kind == b"IEND":
            seen_iend = True
            break

        pos += 12 + length

    assert seen_iend and width == 256 and height == 160
    raw = zlib.decompress(bytes(idat))
    assert len(raw) > 160

    code = (ROOT / "Godot/scripts/default_player_sprite_sheet.gd").read_text()
    world = (ROOT / "Godot/scripts/world_v121.gd").read_text()

    # The committed PNG remains the validated 8x4 source binary.
    assert "Vector2i(32, 40)" in code
    assert "Vector2i(256, 160)" in code
    assert '"right": 1' in code and '"up": 2' in code and '"left": 3' in code

    # Runtime now deliberately samples four poses across each full row:
    # 4 directions x 4 frames = effective 16-frame character animation.
    assert "EFFECTIVE_FRAME_COUNT := 16" in code
    assert "WALK_FRAME_COUNT := 4" in code
    assert "EFFECTIVE_WALK_COLUMNS := [0, 2, 4, 6]" in code
    assert "WALK_FPS := 6.0" in code
    assert "source_column" in code

    # The live world already advances a four-step phase. frame_region() now
    # maps those 0..3 indices across the complete source stride instead of
    # reading source columns 0..3 and showing only half of the walk cycle.
    assert "phase * 4.0" in world
    assert "clampi(int(floor(phase * 4.0)), 0, 3)" in world

    print(
        "Hash Race player PNG + effective 16-frame integration contract: PASS"
    )


if __name__ == "__main__":
    main()
