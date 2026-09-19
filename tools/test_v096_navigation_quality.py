from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v096.gd").read_text(encoding="utf-8")
SCENE = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
VERSION = (ROOT / "VERSION").read_text(encoding="utf-8").strip()


def require(*needles: str) -> None:
    for needle in needles:
        assert needle in WORLD, f"missing v0.096 navigation contract: {needle}"


def test_v096_quality_contract() -> None:
    require(
        'extends "res://scripts/world_v095.gd"',
        "NAV_EDGE_MARGIN",
        "NAV_MIN_WIDTH",
        "TOAST_DEDUPE_SECONDS",
        "navigation_panel.size.y = minf",
        "world_button.grab_focus()",
        "button.disabled = selected",
        "M MENU • 1-6 QUICK OPEN • ESC WORLD",
        "message == v096_last_toast",
        'return "ops"',
        'return "league"',
        'active_workspace != "world"',
        '_activate_workspace("world")',
        "get_viewport().gui_get_focus_owner() == null",
        "debug_v096_ready",
    )
    assert 'res://scripts/world_v096.gd' in SCENE
    assert VERSION == "v0.096"


if __name__ == "__main__":
    test_v096_quality_contract()
    print("v0.096 navigation quality contract: PASS")
