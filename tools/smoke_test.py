#!/usr/bin/env python3
"""Dependency-free checks for Hash Race mining math, campaign setup, company identities, financing, Godot world, and polyglot support."""
from pathlib import Path


def power_kw(hashrate_th, efficiency_jth):
    return hashrate_th * efficiency_jth / 1000.0


def btc_per_day(player_th, network_th, subsidy, fees=0.0, uptime=1.0):
    return (player_th / network_th) * 144.0 * (subsidy + fees) * uptime


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
    setup_scene = Path("Godot/scenes/campaign_setup.tscn").read_text(encoding="utf-8")
    setup = Path("Godot/scripts/campaign_setup.gd").read_text(encoding="utf-8")
    world_scene = Path("Godot/scenes/world.tscn").read_text(encoding="utf-8")
    world = Path("Godot/scripts/world_v2.gd").read_text(encoding="utf-8")
    campaign = Path("Godot/scripts/world_campaign.gd").read_text(encoding="utf-8")
    profiles = Path("Godot/scripts/company_profiles.gd").read_text(encoding="utf-8")

    mining_companies = [
        "Emberline Compute", "Helix Circuit Labs", "ArcCurrent Systems", "StoneGrid Infrastructure",
        "Meridian Node Group", "BlueLoop Compute", "SignalPeak Systems",
        "Parallax Digital Works", "Lattice Energy Labs", "Epoch Harbor Holdings"
    ]
    for company in mining_companies:
        assert company in godot, f"Active Godot management build missing mining company: {company}"
        assert company in world, f"Tech-town world missing mining company: {company}"
        assert company in profiles, f"Starting company profile missing: {company}"

    assert "NeuralPeak Compute" not in godot, "AI company must not be a selectable mining company"
    partner_sectors = ["AI", "Robotics", "Semiconductor", "Energy", "Telecom", "Real Estate", "Finance", "Infrastructure", "Quick Service", "Sports"]
    for sector in partner_sectors:
        assert sector in godot, f"Godot management build missing partner sector: {sector}"
    assert "STARTING_MINERS" in godot and "PARTNERS" in godot

    required_support_files = [
        Path("native/cpp/hashrace_core.cpp"), Path("native/rust/hashrace_balance.rs"),
        Path("tools/typescript/hashrace_validate.ts"), Path("docs/LANGUAGE_STACK.md"),
        Path("docs/ECONOMY_MODEL.md"), Path("Godot/scripts/company_profiles.gd"),
        Path("Godot/scripts/world_campaign.gd"), Path("Godot/scripts/campaign_setup.gd"),
    ]
    for path in required_support_files:
        assert path.exists(), f"Missing support file: {path}"

    language_doc = Path("docs/LANGUAGE_STACK.md").read_text(encoding="utf-8")
    for language in ["C++", "Rust", "TypeScript"]:
        assert language in language_doc, f"Language stack document missing: {language}"

    assert "strategy_layer.gd" in scene, "Legacy Godot management scene must keep the strategy layer"
    for marker in ["Operations priority", "ASIC lab focus", "Season objective", "Company journal"]:
        assert marker in strategy_layer, f"Strategy layer missing gameplay system: {marker}"
    assert Path("docs/SHOWREEL_GAMEPLAY_REFERENCES.md").exists(), "Missing source-backed gameplay reference notes"

    assert 'run/main_scene="res://scenes/campaign_setup.tscn"' in project, "Godot must boot into the new-campaign setup menu"
    assert "campaign_setup.gd" in setup_scene, "Campaign setup scene must load its setup script"
    assert "world_campaign.gd" in world_scene, "Live world scene must load the fixed quarterly campaign controller"

    setup_markers = [
        "MINING COMPANY", "CAMPAIGN LENGTH", "1 TURN = 1 QUARTER", "HALVING EVERY 16 TURNS",
        "range(1, 21)", "hashrace_company_idx", "hashrace_campaign_turns", "START MINING RACE"
    ]
    for marker in setup_markers:
        assert marker in setup, f"Opening setup missing campaign/company option: {marker}"

    world_markers = [
        "COMPANY_NAMES", "MACHINE_CATALOG", "ENERGY_OPTIONS", "COOLING_LEVELS", "CHIP_LEVELS", "SITE_STAGES",
        "PARTNER_DEFS", "SATS", "Power:", "Capacity:", "Machines:", "Energy:", "Cash:", "Acres:",
        "100 machines", "0.35 MW", "5 acres", "Future 1 MW Rack", "Third-party chips", "Captive chip manufacturing",
        "Utility PPA", "Natural Gas", "Hydro", "Solar + Storage", "Nuclear PPA", "toggle_hosting",
        "btc_per_day", "network_hashrate_th", "draw_partner_district", "draw_town", "BUY MACHINES", "BUILD / UPGRADE SITE"
    ]
    for marker in world_markers:
        assert marker in world, f"Tech-town world missing material gameplay system: {marker}"

    campaign_markers = [
        "QUARTER_DAYS", "TURNS_PER_YEAR := 4", "HALVING_TURNS := 16", "MAX_CAMPAIGN_YEARS := 20",
        "END QUARTER", "block_subsidy_btc *= 0.5", "configure_company_starts", "eligible_loan_offer",
        "Community Bank", "Government", "debt_rate", "GET ASSET LOAN",
        "repay_loan", "REPAY LOAN", "operating_reserve", "final_standings", "show_campaign_results",
        "HASH RACE // FINAL STANDINGS", "Winner:", "START NEW CAMPAIGN"
    ]
    source = campaign + profiles
    for marker in campaign_markers:
        assert marker in source, f"Quarterly campaign/company financing or finish system missing: {marker}"

    for marker in ["POWER COST + PROFIT", "ACRES + MW", "CASH + FINANCING", "MACHINES + MW", "CASH + ACRES"]:
        assert marker in profiles, f"Company strength profile missing: {marker}"

    for lender in ["Community Bank", "Commercial Bank", "Infrastructure Bank", "State Development Fund", "Strategic Infrastructure Program"]:
        assert lender in profiles, f"Asset-tier lender missing: {lender}"

    print("Hash Race smoke test passed: the opening company/clock menu, quarterly campaign, halving clock, ten tech towns, company strengths, two-way asset financing, final standings/winner screen, seven-stat economy, sites, energy/cooling/chips, partners, hosting, mining math, and polyglot support are present.")


if __name__ == "__main__":
    main()
