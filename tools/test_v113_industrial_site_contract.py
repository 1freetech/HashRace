from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v113.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

def main():
    assert 'extends "res://scripts/world_v112.gd"' in WORLD
    for fn in [
        "_draw_mining_hq",
        "_draw_partner_building",
        "_draw_machine_market",
        "_draw_power_building",
        "_draw_bank_building",
        "_draw_land_building",
    ]:
        assert f"func {fn}" in WORLD
    assert "_v113_draw_industrial_base" in WORLD
    # v0.113 is a retained historical layer. The live scene must boot the
    # current sequential release rather than remain pinned to world_v113.gd.
    current_world = f'world_v{int(VERSION.split(".")[1]):03d}.gd'
    assert current_world in SCENE, current_world
    assert (ROOT / "Godot/scripts/world_v113.gd").is_file()
    print(f"v0.113 industrial-site replacement contract PASS through {current_world}")

if __name__ == "__main__":
    main()
