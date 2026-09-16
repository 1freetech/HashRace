#!/usr/bin/env python3
"""Dependency-free contract checks for the live Hash Race campaign and RPG overworld."""
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
    towns = Path("Godot/scripts/world_towns.gd").read_text(encoding="utf-8")
    grid_world = Path("Godot/scripts/world_grid.gd").read_text(encoding="utf-8")
    grid_nav = Path("Godot/scripts/grid_navigation.gd").read_text(encoding="utf-8")
    playability = Path("Godot/scripts/world_playability.gd").read_text(encoding="utf-8")
    validator = Path("Godot/scripts/validate_overworld.gd").read_text(encoding="utf-8")
    profiles = Path("Godot/scripts/company_profiles.gd").read_text(encoding="utf-8")
    smoke_workflow = Path(".github/workflows/smoke-test.yml").read_text(encoding="utf-8")

    assert 'run/main_scene="res://scenes/campaign_setup.tscn"' in project
    assert "campaign_setup.gd" in setup_scene
    assert "world_grid.gd" in world_scene, "Live world must use the grid-aware multi-town RPG layer"
    assert "BootFallback" in world_scene, "World scene must show a visible fallback instead of a blank gray screen"
    assert 'extends "res://scripts/world_overworld.gd"' in towns, "Town layer must retain the stable overworld core"
    assert 'extends "res://scripts/world_towns.gd"' in grid_world, "Grid layer must retain the town presentation layer"
    assert "validate_overworld.gd" in smoke_workflow

    setup_markers = ["MINING COMPANY", "CAMPAIGN LENGTH", "1 TURN = 1 QUARTER", "HALVING EVERY 16 TURNS", "range(1, 21)", "hashrace_company_idx", "hashrace_campaign_turns", "START MINING RACE"]
    for marker in setup_markers:
        assert marker in setup, f"Campaign setup missing: {marker}"

    companies = ["VantaGrid Mining", "NeonForge Mining", "ArcShift Mining", "IronVector Mining", "Meridian Zero Mining", "BlueNova Mining", "SignalFlux Mining", "Parallax Core Mining", "LatticeX Mining", "Epoch Vector Mining"]
    for company in companies:
        assert company in profiles, f"Missing mining-company profile: {company}"

    lenders = ["Local Joker Bank", "Main Street Business Bank", "Regional Commercial Bank", "Infrastructure Capital Bank", "State Development Fund", "Federal Strategic Infrastructure Program"]
    for lender in lenders:
        assert lender in profiles, f"Missing lender tier: {lender}"

    overworld_markers = ["COMPANY OVERWORLD", "COMPANY REP", "WALK • TALK • DEAL • BUILD • END QUARTER", "HashWorks ASIC Exchange", "Gridline Power Office", "Local Joker Bank", "Cascadia Utility District", "Harbor Land Authority", "Ironline Infrastructure", "FoundryWorks Silicon", "Meridian Finance Cooperative", "QuickBite Services", "Pro Circuit Sports", "BlueRiver Energy Authority", "Satoshi Treasury Network", "BUY 10 MACHINES", "BUY +0.25 MW", "CHANGE ENERGY", "TAKE LOAN", "REPAY DEBT", "STRIKE DEAL", "ATTEMPT ONE-TIME MERGER", "END QUARTER", "HALVING_TURNS", "federal_rate", "land_price_per_acre", "DOT-COM-STYLE TECH CRASH", "COVID-STYLE PROPERTY / LOGISTICS CRASH", "machine_efficiency_bonus", "land_discount", "power_capex_discount", "lender_spread_discount", "Grid", "Utility PPA", "Natural Gas", "Hydro", "Solar + Storage", "Nuclear PPA"]
    for marker in overworld_markers:
        assert marker in overworld, f"Live overworld missing gameplay feature: {marker}"

    town_markers = ["TOWN_NAMES", "COMPANY_REPS", "PARTNER_REPS", "VantaGrid City", "Neon Forge Row", "ArcShift Junction", "IronVector Works", "Meridian Zero Exchange", "BlueNova Harbor", "SignalFlux Heights", "Parallax Ward", "Lattice Reach", "Epoch Port", "rival_rep", "partner_rep", "scanner", "NEGOTIATE DEAL", "PROPOSE MERGER", "AcreX Land Market", "BUY 5 ACRES", "TOWN TRANSIT", "_travel_next_town", "debug_company_rep_count", "debug_partner_rep_count", "debug_town_count", "debug_has_land_market"]
    for marker in town_markers:
        assert marker in towns, f"Town/representative layer missing: {marker}"

    grid_markers = ["NAV_CELL_SIZE", "_rebuild_navigation_grid", "_route_to", "debug_grid_navigation_ready", "debug_grid_path_exists", "block_rect", "nearest_open", "find_path", "_manhattan"]
    for marker in grid_markers:
        assert marker in grid_world or marker in grid_nav, f"Grid/pathfinding layer missing: {marker}"

    playability_markers = ["BTC HOLD POLICY", "SELL 25% BTC TREASURY", "AUTO-FUND NEXT QUARTER", "QUARTER PLAN", "QUARTER_STRATEGY_PRESETS", '"CASH"', '"BALANCED"', '"HODL"', "cycle_quarter_strategy", "TREASURY_RESCUE_RESERVE", "auto_fund_next_quarter", "sell_sats_for_cash", "projected_quarter_end_cash", "CONFIRM END QUARTER"]
    for marker in playability_markers:
        assert marker in playability, f"Quarterly playability layer missing: {marker}"

    for marker in ["debug_world_ready", "debug_entity_count", "debug_has_dialogue_ui", "_end_quarter", "debug_company_rep_count", "debug_partner_rep_count", "debug_town_count", "debug_has_land_market"]:
        assert marker in validator or marker in overworld or marker in towns, f"Runtime validation missing: {marker}"

    required_support = ["native/cpp/hashrace_core.cpp", "native/rust/hashrace_balance.rs", "tools/typescript/hashrace_validate.ts", "docs/LANGUAGE_STACK.md", "docs/ECONOMY_MODEL.md", "Godot/export_presets.cfg", "Godot/scripts/grid_navigation.gd", "Godot/scripts/world_grid.gd"]
    for item in required_support:
        assert Path(item).exists(), f"Missing support file: {item}"

    print("Hash Race smoke test passed: campaign setup, ten Bitcoin mining companies, external partner economy, towns, grid navigation, treasury controls, smart quarter funding, CASH/BALANCED/HODL quarter plans, and runtime validation are present.")


if __name__ == "__main__":
    main()
