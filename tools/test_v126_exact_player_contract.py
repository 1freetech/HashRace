from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]

def main():
    version = (ROOT / "VERSION").read_text().strip()
    assert version.startswith("v0.")
    assert int(version.split(".")[1]) >= 126

    asset = ROOT / "Godot/art/characters/default_player_sheet.png"
    sheet = (ROOT / "Godot/scripts/default_player_sprite_sheet.gd").read_text()
    world = (ROOT / "Godot/scripts/world_v126.gd").read_text()
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    validator = (ROOT / "Godot/scripts/validate_modular_scripts.gd").read_text()

    png = asset.read_bytes()
    assert png.startswith(b"\x89PNG\r\n\x1a\n")
    width, height = struct.unpack(">II", png[16:24])
    assert (width, height) == (160, 248)
    assert b"tRNS" in png or png[25] in (4, 6)
    assert asset.stat().st_size > 10_000

    assert 'FRAME_SIZE := Vector2i(40, 62)' in sheet
    assert 'SHEET_SIZE := Vector2i(160, 248)' in sheet
    for direction in ("down", "up", "left", "right"):
        assert f'"{direction}"' in sheet
        assert f'&"walk_{direction}"' in sheet
        assert f'&"idle_{direction}"' in sheet

    assert 'extends "res://scripts/world_v125.gd"' in world
    assert "V126_EXACT_PLAYER_REVISION := 1" in world
    assert "exact_uploaded_transparent_16_frame_sheet" in world
    assert "DefaultPlayerSheetV126.frame_region(rep_facing, frame)" in world
    assert "TEXTURE_FILTER_NEAREST" in world
    assert "v123_green_player_texture" not in world
    assert "hashrace_v126_exact_player_asset_live" in world

    assert "world_v126.gd" in scene
    assert "world_v126.gd" in validator

    print("Hash Race v0.126 exact default-player contract: PASS")

if __name__ == "__main__":
    main()
