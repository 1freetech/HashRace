from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v118.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()


def main():
    assert VERSION == "v0.118", VERSION
    assert 'extends "res://scripts/world_v117.gd"' in WORLD
    assert "world_v118.gd" in SCENE

    for marker in [
        "_v118_site_utilization_state",
        'status = "OVER CAPACITY"',
        'status = "EXPAND NOW"',
        'status = "PLAN EXPANSION"',
        '"headroom_mw"',
        '"overload_mw"',
        "clampf(ratio, 0.0, 1.0)",
        "_machine_load_kw() / 1000.0",
        "_effective_available_mw()",
        "MINING LOAD %.1f / %.1f MW",
        "debug_v118_ready()",
        "debug_v117_ready()",
    ]:
        assert marker in WORLD, marker

    # Threshold order is gameplay-significant: overload first, then urgent/planning.
    overload = WORLD.index("if ratio >= 1.0")
    urgent = WORLD.index("elif ratio >= 0.90")
    planning = WORLD.index("elif ratio >= 0.75")
    assert overload < urgent < planning

    print("v0.118 live mining-site utilization contract PASS")


if __name__ == "__main__":
    main()
