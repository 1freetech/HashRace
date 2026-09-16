#!/usr/bin/env python3
"""Dependency-free checks for Hash Race mining math, company rules, Godot world, and polyglot support."""
from pathlib import Path


def power_kw(hashrate_th, efficiency_jth):
    return hashrate_th * efficiency_jth / 1000.0


def btc_per_day(player_th, network_th, subsidy, uptime=1.0):
    return (player_th / network_th) * 144.0 * subsidy * uptime


def main():
    assert power_kw(100.0, 20.0) == 2.0
    assert power_kw(100.0, 10.0) < power_kw(100.0, 20.0)
    assert abs(btc_per_day(1000.0, 100000.0, 25.0) - 36.0) < 1e-9

    assert Path("VERSION").read_text().strip() == "v0.002"

    assert Path("desktop/HashRace.Desktop/ProgramV002.cs").exists(), "Transitional desktop build must remain available"
    godot = Path("Godot/scripts/main.gd").read_text(encoding="utf-8")
    scene = Path("Godot/scenes/main.tscn").read_text(encoding="utf-8")
    strategy_layer = Path("Godot/scripts/strategy_layer.gd").read_text(encoding="utf-8")
    project = Path("Godot/project.godot").read_text(encoding="utf-8")
    world_scene = Path("Godot/scenes/world.tscn").read_text(encoding="utf-8")
    world = Path("Godot/scripts/world.gd").read_text(encoding="utf-8")

    mining_companies = [
        "Emberline Compute", "Helix Circuit Labs", "ArcCurrent Systems", "StoneGrid Infrastructure",
        "Meridian Node Group", "BlueLoop Compute", "SignalPeak Systems",
        "Parallax Digital Works", "Lattice Energy Labs", "Epoch Harbor Holdings"
    ]
    for company in mining_companies:
        assert company in godot, f"Active Godot build missing mining company: {company}"

    assert "NeuralPeak Compute" not in godot, "AI company must not be a selectable mining company"

    partner_sectors = ["AI", "Robotics", "Semiconductor", "Energy", "Telecom", "Real Estate", "Finance", "Infrastructure", "Quick Service", "Sports"]
    for sector in partner_sectors:
        assert sector in godot, f"Godot build missing partner sector: {sector}"

    assert "STARTING_MINERS" in godot and "PARTNERS" in godot

    required_polyglot_files = [
        Path("native/cpp/hashrace_core.cpp"),
        Path("native/rust/hashrace_balance.rs"),
        Path("tools/typescript/hashrace_validate.ts"),
        Path("docs/LANGUAGE_STACK.md"),
    ]
    for path in required_polyglot_files:
        assert path.exists(), f"Missing polyglot support file: {path}"

    language_doc = Path("docs/LANGUAGE_STACK.md").read_text(encoding="utf-8")
    for language in ["C++", "Rust", "TypeScript"]:
        assert language in language_doc, f"Language stack document missing: {language}"

    assert "strategy_layer.gd" in scene, "Legacy Godot management scene must keep the strategy layer"
    for marker in ["Operations priority", "ASIC lab focus", "Season objective", "Company journal"]:
        assert marker in strategy_layer, f"Strategy layer missing gameplay system: {marker}"
    assert Path("docs/SHOWREEL_GAMEPLAY_REFERENCES.md").exists(), "Missing source-backed gameplay reference notes"

    assert 'run/main_scene="res://scenes/world.tscn"' in project, "Godot must boot into the 2D world instead of the old menu"
    assert "world.gd" in world_scene, "World scene must load its world script"
    world_markers = [
        "Hash Hall A", "Hash Hall B", "Hydro Cooling", "Substation", "ASIC Lab", "NOC + HQ",
        "WASD / arrows", "click_target", "update_workers", "draw_hash_racks", "draw_cooling_system",
        "draw_substation_detail", "draw_player", "SITE CONTROL", "ADVANCE DAY", "BUY ASIC"
    ]
    for marker in world_markers:
        assert marker in world, f"2D world missing visible/interactive system: {marker}"

    print("Hash Race smoke test passed: mining math and current company rules are intact, Godot boots into the interactive 2D mining campus, the legacy strategy screen remains available, and the C++/Rust/TypeScript support files are installed.")


if __name__ == "__main__":
    main()
