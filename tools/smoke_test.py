#!/usr/bin/env python3
"""Dependency-free contract checks for the live Hash Race campaign and overworld."""
from pathlib import Path
import re


def power_kw(hashrate_th, efficiency_jth):
    return hashrate_th * efficiency_jth / 1000.0


def btc_per_day(player_th, network_th, subsidy, fees=0.0, uptime=1.0):
    return (player_th / network_th) * 144.0 * (subsidy + fees) * uptime


def main():
    assert power_kw(100.0, 20.0) == 2.0
    assert power_kw(100.0, 10.0) < power_kw(100.0, 20.0)
    assert abs(btc_per_day(1000.0, 100000.0, 25.0) - 36.0) < 1e-9

    version = Path("VERSION").read_text().strip()
    assert re.fullmatch(r"v0\.\d{3}", version), "Public version must use v0.001-style numbering"

    project = Path("Godot/project.godot").read_text(encoding="utf-8")
    setup_scene = Path("Godot/scenes/campaign_setup.tscn").read_text(encoding="utf-8")
    setup = Path("Godot/scripts/campaign_setup.gd").read_text(encoding="utf-8")
    world_scene = Path("Godot/scenes/world.tscn").read_text(encoding="utf-8")
    overworld = Path("Godot/scripts/world_overworld.gd").read_text(encoding="utf-8")
    validator = Path("Godot/scripts/validate_overworld.gd").read_text(encoding="utf-8")
    profiles = Path("Godot/scripts/company_profiles.gd").read_text(encoding="utf-8")

    assert 'run/main_scene="res://scenes/campaign_setup.tscn"' in project
    assert "campaign_setup.gd" in setup_scene
    assert "world_overworld.gd" in world_scene, "Live world must use the stable company overworld"
    assert "validate_overworld.gd" in Path(".github/workflows/smoke-test.yml").read_text(encoding="utf-8")

    setup_markers = [
        "MINING COMPANY", "CAMPAIGN LENGTH", "1 TURN = 1 QUARTER", "HALVING EVERY 16 TURNS",
        "range(1, 21)", "hashrace_company_idx", "hashrace_campaign_turns", "START MINING RACE"
    ]
    for marker in setup_markers:
        assert marker in setup, f"Campaign setup missing: {marker}"

    companies = [
        "Emberline Compute", "Helix Circuit Labs", "ArcCurrent Systems", "StoneGrid Infrastructure",
        "Meridian Node Group", "BlueLoop Compute", "SignalPeak Systems", "Parallax Digital Works",
        "Lattice Energy Labs", "Epoch Harbor Holdings"
    ]
    for company in companies:
        assert company in profiles, f"Missing mining-company profile: {company}"

    lenders = [
        "Local Joker Bank", "Main Street Business Bank", "Regional Commercial Bank",
        "Infrastructure Capital Bank", "State Development Fund", "Federal Strategic Infrastructure Program"
    ]
    for lender in lenders:
        assert lender in profiles, f"Missing lender tier: {lender}"

    overworld_markers = [
        "COMPANY OVERWORLD", "COMPANY REP", "WALK • TALK • DEAL • BUILD • END QUARTER",
        "HashWorks ASIC Exchange", "Gridline Power Office", "Local Joker Bank",
        "Cascadia Utility District", "Harbor Land Authority", "Ironline Infrastructure",
        "FoundryWorks Silicon", "Meridian Finance Cooperative", "QuickBite Services",
        "Pro Circuit Sports", "BlueRiver Energy Authority", "Satoshi Treasury Network",
        "BUY 10 MACHINES", "BUY +0.25 MW", "CHANGE ENERGY", "TAKE LOAN", "REPAY DEBT",
        "STRIKE DEAL", "ATTEMPT ONE-TIME MERGER", "END QUARTER", "HALVING_TURNS",
        "federal_rate", "land_price_per_acre", "DOT-COM-STYLE TECH CRASH",
        "COVID-STYLE PROPERTY / LOGISTICS CRASH", "machine_efficiency_bonus",
        "land_discount", "power_capex_discount", "lender_spread_discount",
        "Grid", "Utility PPA", "Natural Gas", "Hydro", "Solar + Storage", "Nuclear PPA"
    ]
    for marker in overworld_markers:
        assert marker in overworld, f"Live overworld missing gameplay feature: {marker}"

    for marker in ["debug_world_ready", "debug_entity_count", "debug_has_dialogue_ui", "_end_quarter"]:
        assert marker in validator or marker in overworld, f"Runtime validation missing: {marker}"

    required_support = [
        "native/cpp/hashrace_core.cpp", "native/rust/hashrace_balance.rs",
        "tools/typescript/hashrace_validate.ts", "docs/LANGUAGE_STACK.md",
        "docs/ECONOMY_MODEL.md", "Godot/export_presets.cfg"
    ]
    for item in required_support:
        assert Path(item).exists(), f"Missing support file: {item}"

    print(
        "Hash Race smoke test passed: campaign setup, company overworld, representative movement, "
        "interactive companies, partner deals, machines, land/power/energy, lender ladder, Fed/BTC/land markets, "
        "rare crashes, one-time merger, quarterly settlement, and runtime validator are present."
    )


if __name__ == "__main__":
    main()
