from pathlib import Path
import struct

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

assert ART.is_dir(), ART
assert sorted(p.name for p in ART.glob("*.png")) == sorted(EXPECTED), "live sprite-sheet directory must contain the exact 11 promoted PNGs"

for name, dims in EXPECTED.items():
    path = ART / name
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", name
    width, height = struct.unpack(">II", data[16:24])
    assert (width, height) == dims, (name, width, height, dims)
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
print("HASH RACE ARCHIVE SPRITE CONTRACT OK: 11 exact PNG sheets / 33 live atlas cells")
