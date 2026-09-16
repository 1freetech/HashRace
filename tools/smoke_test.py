#!/usr/bin/env python3
"""Dependency-free checks for Hash Race mining math, corrected company model, and Godot migration."""
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

    desktop = Path("desktop/HashRace.Desktop/ProgramV002.cs").read_text(encoding="utf-8")
    godot = Path("Godot/scripts/main.gd").read_text(encoding="utf-8")
    assert Path("Godot/project.godot").exists()
    assert Path("Godot/scenes/main.tscn").exists()

    mining_companies = [
        "BlockForge Mining", "Northstar Hash", "VoltHash Mining", "TerraHash Industries",
        "Frontier Mining Co.", "HydroBlock Mining", "IronPeak Digital Mining",
        "Atlas Hashworks", "Cascade Mining Systems", "DeepCore Bitcoin Mining"
    ]
    for company in mining_companies:
        assert company in desktop, f"Desktop build missing mining company: {company}"
        assert company in godot, f"Godot build missing mining company: {company}"

    assert "NeuralPeak Compute" not in desktop, "AI company must not be a selectable mining company"
    assert "Atlas Robotics\", \"Robotics\"" not in desktop.split("private static readonly List<Company>")[1].split("private static readonly List<Partner>")[0]

    partner_sectors = ["AI", "Robotics", "Semiconductor", "Energy", "Telecom", "Real Estate", "Finance", "Infrastructure", "Quick Service", "Sports"]
    for sector in partner_sectors:
        assert sector in desktop, f"Desktop build missing partner sector: {sector}"
        assert sector in godot, f"Godot build missing partner sector: {sector}"

    assert "STARTING_MINERS" in godot and "PARTNERS" in godot
    print("Hash Race smoke test passed: mining math is sane, all ten competitors are Bitcoin miners, all ten outside partner sectors exist, and the Godot migration files are present.")


if __name__ == "__main__":
    main()
