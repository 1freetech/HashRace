from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v113.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")

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
    assert "world_v113.gd" in SCENE
    print("v0.113 industrial-site replacement contract PASS")

if __name__ == "__main__":
    main()
