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
        length = struct.unpack(">I", data[pos:pos+4])[0]
        kind = data[pos+4:pos+8]
        payload = data[pos+8:pos+8+length]
        crc = struct.unpack(">I", data[pos+8+length:pos+12+length])[0]
        assert zlib.crc32(kind + payload) & 0xFFFFFFFF == crc
        if kind == b"IHDR":
            width, height, *_ = struct.unpack(">IIBBBBB", payload)
            assert (width, height) == (1536, 1024)
        elif kind == b"IDAT":
            idat.extend(payload)
        elif kind == b"IEND":
            seen_iend = True
            break
        pos += 12 + length
    assert seen_iend
    assert len(zlib.decompress(bytes(idat))) > 1024
    code = (ROOT / "Godot/scripts/default_player_sprite_sheet.gd").read_text()
    assert 'EFFECTIVE_FRAME_COUNT := 16' in code
    assert 'EFFECTIVE_SOURCE_INDICES := [0, 2, 4, 6]' in code
    assert 'WALK_FRAME_COUNT := 3' in code
    assert 'WALK_FPS := 6.0' in code
    print("Hash Race exact player PNG + effective 16-frame runtime contract: PASS")

if __name__ == "__main__":
    main()
