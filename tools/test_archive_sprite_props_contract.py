from pathlib import Path
import binascii
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Godot" / "art" / "props" / "hr_sprite_sheets"
SCRIPT = (ROOT / "Godot" / "scripts" / "archive_sprite_props.gd").read_text()
SCENE = (ROOT / "Godot" / "scenes" / "world.tscn").read_text()

EXPECTED = {
    "2026-10-04_ats_handhole_bollards_96x32.png": (96, 32),
    "2026-10-04_cooling_electrical_energy_96x32.png": (96, 32),
    "2026-10-04_harmonicfilter_bench_lightning_192x64.png": (192, 64),
    "2026-10-04_loadbank_eyewash_cablereel_96x32.png": (96, 32),
    "2026-10-04_mv_hydrant_truckscale_96x32.png": (96, 32),
    "2026-10-04_mvtermination_diag_weather_96x32.png": (96, 32),
    "2026-10-04_power_cooling_washdown_96x32.png": (96, 32),
    "2026-10-04_pump_salt_trench_96x32.png": (96, 32),
    "2026-10-04_security_firewall_cctv_oilwater_96x32.png": (96, 32),
    "2026-10-04_statcom_fiberped_gate_96x32.png": (96, 32),
    "2026-10-04_telecom_air_drain_192x64.png": (192, 64),
}


def validate_png(path: Path, dims: tuple[int, int]) -> None:
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path.name
    pos = 8
    idat = bytearray()
    ihdr = None
    saw_iend = False
    while pos + 12 <= len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        chunk_type = data[pos + 4:pos + 8]
        end = pos + 12 + length
        assert end <= len(data), f"{path.name}: truncated {chunk_type!r} chunk"
        payload = data[pos + 8:pos + 8 + length]
        stored_crc = struct.unpack(">I", data[pos + 8 + length:end])[0]
        calculated_crc = binascii.crc32(chunk_type + payload) & 0xFFFFFFFF
        assert stored_crc == calculated_crc, f"{path.name}: bad CRC in {chunk_type!r}"
        if chunk_type == b"IHDR":
            ihdr = struct.unpack(">IIBBBBB", payload)
        elif chunk_type == b"IDAT":
            idat.extend(payload)
        elif chunk_type == b"IEND":
            saw_iend = True
            assert length == 0, f"{path.name}: nonempty IEND"
            assert end == len(data), f"{path.name}: trailing bytes after IEND"
            break
        pos = end

    assert ihdr is not None, f"{path.name}: missing IHDR"
    width, height, bit_depth, color_type, compression, filtering, interlace = ihdr
    assert (width, height) == dims, (path.name, width, height, dims)
    assert (bit_depth, color_type, compression, filtering, interlace) == (8, 6, 0, 0, 0), f"{path.name}: unexpected PNG format {ihdr}"
    assert saw_iend, f"{path.name}: missing IEND"
    assert idat, f"{path.name}: missing IDAT"
    raw = zlib.decompress(bytes(idat))
    stride = 1 + width * 4
    assert len(raw) == height * stride, f"{path.name}: decoded byte count {len(raw)} != {height * stride}"
    filters = [raw[row * stride] for row in range(height)]
    assert all(value <= 4 for value in filters), f"{path.name}: invalid PNG filter byte"


assert ART.is_dir(), ART
assert sorted(p.name for p in ART.glob("*.png")) == sorted(EXPECTED), "live sprite-sheet directory must contain the exact 11 promoted PNGs"

for name, dims in EXPECTED.items():
    path = ART / name
    validate_png(path, dims)
    assert name in SCRIPT, f"{name} is not wired into archive_sprite_props.gd"

for marker in [
    "AtlasTexture.new()",
    "CanvasItem.TEXTURE_FILTER_NEAREST",
    "y_sort_enabled = true",
    "collision_footprints",
    "live_sprites.size() != 33",
    "loaded_sheet_count != SHEETS.size()",
]:
    assert marker in SCRIPT, marker

assert 'res://scripts/archive_sprite_props.gd' in SCENE
assert '[node name="ArchiveSpriteProps" type="Node2D" parent="."]' in SCENE
print("HASH RACE ARCHIVE SPRITE CONTRACT OK: 11 CRC-valid, fully decodable PNG sheets / 33 live atlas cells")
