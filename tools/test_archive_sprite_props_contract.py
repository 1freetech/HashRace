from pathlib import Path
import binascii
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Godot" / "art" / "props" / "hr_sprite_sheets"
SCRIPT = (ROOT / "Godot" / "scripts" / "archive_sprite_props.gd").read_text()
INTERACTION = (ROOT / "Godot" / "scripts" / "archive_sprite_interaction.gd").read_text()
SCENE = (ROOT / "Godot" / "scenes" / "world.tscn").read_text()
WORLD_V165 = ROOT / "Godot" / "scripts" / "world_v165.gd"
WORLD_V165_TEXT = WORLD_V165.read_text()

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

# Live rendering contract: preserve nearest-neighbor pixel art, crop each atlas
# cell to its visible bounds, strip neutral edge-connected backgrounds, then
# render support equipment large enough to read beside the player/world art.
for marker in [
    "ImageTexture.create_from_image",
    "_prepare_cell_image",
    "_clear_connected_neutral_background",
    "_visible_bounds",
    "CanvasItem.TEXTURE_FILTER_NEAREST",
    "y_sort_enabled = true",
    "collision_footprints",
    "live_sprites.size() != 33",
    "loaded_sheet_count != SHEETS.size()",
    "const LIVE_PROP_TARGET_HEIGHT_PX := 72.0",
    "const LIVE_PROP_MAX_WIDTH_PX := 96.0",
    "const LIVE_PROP_MIN_WIDTH_PX := 42.0",
    "sprite.offset = Vector2(0.0, -float(prepared.get_height()) * 0.5)",
]:
    assert marker in SCRIPT, marker

# Promoted props are gameplay objects: survey progress, deterministic turn-scaled
# reliability events, on-site R repairs, real cash costs, and persistent fault state.
for marker in [
    "const INSPECT_RANGE := 82.0",
    "const HIGHLIGHT_RANGE := 126.0",
    "const REPAIR_RANGE := 92.0",
    "const SURVEY_MILESTONE_SIZE := 6",
    "const MAX_OPERATIONS_BONUS := 5",
    "const FAULT_CHECK_DAYS := 30.4375",
    "const FAULT_BASE_MONTHLY_CHANCE := 0.18",
    "FAULT_UPTIME_PENALTIES",
    "FAULT_BASE_REPAIR_COSTS",
    "equipment_surveys",
    "equipment_fault_key",
    "equipment_uptime_penalty",
    "equipment_faults_resolved",
    "_award_operations_point",
    "_update_reliability_clock",
    "_trigger_fault",
    "_repair_active_fault",
    "debug_force_fault",
    "[E/F] INSPECT",
    "[R] REPAIR",
    "EQUIPMENT_INFO.size() != 33",
]:
    assert marker in INTERACTION, marker

# The reliability penalty must enter the same uptime path used by the established
# v0.090 power-dispatch financial preview; source-only fault state is not enough.
for marker in [
    "func _equipment_uptime_penalty() -> float:",
    'player.get("equipment_uptime_penalty", 0.0)',
    "func _uptime_without_grid_penalty() -> float:",
    "super._uptime_without_grid_penalty()",
    "base - _equipment_uptime_penalty()",
]:
    assert marker in WORLD_V165_TEXT, marker

# Gameplay regression guard: sprite promotion/reliability must never replace the
# full live simulation/world inheritance chain.
assert WORLD_V165.is_file(), "world_v165.gd must remain present on the live branch"
assert 'res://scripts/world_v165.gd' in SCENE, "live world must use the v0.165 gameplay chain"
assert '[node name="ArchiveSpriteProps" type="Node2D" parent="."]' in SCENE
assert 'res://scripts/archive_sprite_props.gd' in SCENE
assert 'res://scripts/archive_sprite_interaction.gd' in SCENE
assert '[node name="EquipmentSurvey" type="Node2D" parent="ArchiveSpriteProps"]' in SCENE
print("HASH RACE ARCHIVE SPRITE CONTRACT OK: 11 PNG sheets / 33 readable live cells / inspect + fault + repair operations gameplay / uptime economics / v0.165 chain")
