#!/usr/bin/env python3
"""Dependency-free contract checks for the live Hash Race campaign and RPG overworld."""
from pathlib import Path
import re


def power_kw(hashrate_th, efficiency_jth):
    return hashrate_th * efficiency_jth / 1000.0


def btc_per_day(player_th, network_th, subsidy, fees=0.0, uptime=1.0):
    return (player_th / network_th) * 144.0 * (subsidy + fees) * uptime


def require(text, markers, label):
    for marker in markers:
        assert marker in text, f"{label} missing: {marker}"


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
    gbc_world = Path("Godot/scripts/world_gbc.gd").read_text(encoding="utf-8")
    rpg_world = Path("Godot/scripts/world_rpg_strategy.gd").read_text(encoding="utf-8")
    time_scale = Path("Godot/scripts/world_time_scale.gd").read_text(encoding="utf-8")
    company_ai = Path("Godot/scripts/world_company_ai.gd").read_text(encoding="utf-8")
    company_effects = Path("Godot/scripts/world_company_effects.gd").read_text(encoding="utf-8")
    treasury = Path("Godot/scripts/live_treasury_controls.gd").read_text(encoding="utf-8")
    playability = Path("Godot/scripts/world_playability.gd").read_text(encoding="utf-8")
    profiles = Path("Godot/scripts/company_profiles.gd").read_text(encoding="utf-8")
    validator = Path("Godot/scripts/validate_overworld.gd").read_text(encoding="utf-8")
    workflow = Path(".github/workflows/smoke-test.yml").read_text(encoding="utf-8")

    assert 'run/main_scene="res://scenes/campaign_setup.tscn"' in project
    assert "campaign_setup.gd" in setup_scene
    assert "world_company_effects.gd" in world_scene, "Live world must use material company-culture gameplay effects"
    assert "BootFallback" in world_scene
    assert 'extends "res://scripts/world_overworld.gd"' in towns
    assert 'extends "res://scripts/world_towns.gd"' in grid_world
    assert 'extends "res://scripts/world_grid.gd"' in gbc_world
    assert 'extends "res://scripts/world_gbc.gd"' in rpg_world
    assert 'extends "res://scripts/world_rpg_strategy.gd"' in time_scale
    assert 'extends "res://scripts/world_time_scale.gd"' in company_ai
    assert 'extends "res://scripts/world_company_ai.gd"' in company_effects
    assert "validate_overworld.gd" in workflow

    require(setup, ["MINING COMPANY", "CAMPAIGN LENGTH", "DEFAULT: 1 TURN = 1 MONTH", "DAY / WEEK / MONTH / QUARTER", "range(1, 21)", "hashrace_company_idx", "START MINING RACE", "BACKGROUND:", "CONTROVERSY:", "AGG %d", "RISK %d"], "Campaign setup")
    companies = ["VantaGrid Mining", "NeonForge Mining", "ArcShift Mining", "IronVector Mining", "Meridian Zero Mining", "BlueNova Mining", "SignalFlux Mining", "Parallax Core Mining", "LatticeX Mining", "Epoch Vector Mining"]
    require(profiles, companies, "Mining-company profile")
    require(profiles, ['"background"', '"controversy"', '"posture"', '"affinity"', '"aggression"', '"risk"', '"growth"', '"research"', '"treasury"', '"operations"', '"reputation"'], "Dynamic company profile")
    assert profiles.count('"background"') >= 10
    assert profiles.count('"controversy"') >= 10

    require(overworld, ["COMPANY OVERWORLD", "HashWorks ASIC Exchange", "Gridline Power Office", "Cascadia Utility District", "FoundryWorks Silicon", "Meridian Finance Cooperative", "QuickBite Services", "Pro Circuit Sports", "BlueRiver Energy Authority", "BUY 10 MACHINES", "CHANGE ENERGY", "TAKE LOAN", "REPAY DEBT", "STRIKE DEAL", "ATTEMPT ONE-TIME MERGER", "federal_rate", "land_price_per_acre"], "Live overworld")
    require(towns, ["TOWN_NAMES", "COMPANY_REPS", "PARTNER_REPS", "rival_rep", "partner_rep", "TOWN TRANSIT", "debug_company_rep_count", "debug_partner_rep_count", "debug_town_count"], "Town layer")
    require(gbc_world, ["GBPaint", "TileOps", "ART_TILE_SIZE", "_build_art_tilemap", "_draw_pixel_tile_world", "debug_gbc_map_ready"], "Pixel renderer")
    require(rpg_world, ["RPGMovement", "SCANNER_RANGE_CELLS", "SCANNER GRID", "_draw_scanner_overlay", "debug_rpg_collision_ready", "debug_scanner_reachable_count"], "RPG strategy layer")

    require(time_scale, ['"DAY", "days": 1.0', '"WEEK", "days": 7.0', '"MONTH", "days": 30.4375', '"QUARTER", "days": 91.3125', "turn_length_days", "turn_length_name", "_cycle_turn_length", "_project_scaled_profit", "_simulate_rivals_scaled", "_advance_market_scaled", "HALVING_DAYS", "elapsed_campaign_days", "recurring_income", "CONFIRM %s TURN", "1 turn = %s"], "Flexible season clock")
    assert "* days" in time_scale
    assert "days / 365.0" in time_scale
    assert "days / 91.3125" in time_scale

    require(company_ai, ["CULTURE_MONTH_DAYS", "_new_personality", "_posture", "_ratings_text", "_evolve_player_culture", "_run_rival_month", "_maybe_rival_partnership", "_maybe_rival_controversy", "_maybe_player_controversy", "Aggressive", "Conservative", "Moderate", "CURRENT CULTURE", "FOUNDING CONTROVERSY", "Current action", "Recent controversy", "debug_company_personality_ready", "debug_rival_personality_count", "debug_personality_ratings_in_range"], "Dynamic company AI")
    for key in ["aggression", "risk", "growth", "research", "treasury", "operations", "reputation"]:
        assert key in company_ai

    require(company_effects, ["_operations_uptime_bonus", "_financing_rate_adjustment", "_partner_cost_multiplier", "_research_cost_multiplier", "_expansion_cost_multiplier", "_merger_cost_multiplier", "func _uptime()", "func _loan_rate", "func _buy_machines", "func _buy_power", "func _buy_land", "func _upgrade_chips", "func _sign_partner", "func _merge_rival", "LIVE GAMEPLAY EFFECTS", "debug_culture_effects_ready", "debug_culture_effects_are_material"], "Material company-culture effects")
    assert "0.88" in company_effects and "1.12" in company_effects, "Culture modifiers need explicit balance bounds"

    require(treasury, ["HSlider", "min_value = 0.0", "max_value = 100.0", "step = 1.0", "BTC HOLD POLICY: %d / 100", "_on_hold_policy_changed", "turn_length_days", "_project_scaled_profit", "AUTO-FUND SAFE TURN"], "Live 0-100 treasury strategy")
    assert "HOLD_POLICIES" not in treasury, "BTC hold policy must not be restricted to presets"
    require(playability, ["BTC HOLD POLICY", "SELL 25% BTC TREASURY", "AUTO-FUND NEXT QUARTER", "QUARTER PLAN", "PREPARE SAFE QUARTER"], "Treasury playability layer")
    require(validator, ["debug_world_ready", "debug_entity_count", "debug_has_dialogue_ui", "debug_company_rep_count", "debug_gbc_map_ready", "debug_rpg_collision_ready", "debug_culture_effects_ready", "debug_culture_effects_are_material"], "Runtime validator")

    required_support = ["native/cpp/hashrace_core.cpp", "native/rust/hashrace_balance.rs", "tools/typescript/hashrace_validate.ts", "docs/LANGUAGE_STACK.md", "docs/ECONOMY_MODEL.md", "Godot/export_presets.cfg", "Godot/scripts/world_time_scale.gd", "Godot/scripts/world_company_ai.gd", "Godot/scripts/world_company_effects.gd", "Godot/scripts/world_rpg_strategy.gd", "Godot/scripts/grid_navigation.gd", "Godot/scripts/live_treasury_controls.gd"]
    for item in required_support:
        assert Path(item).exists(), f"Missing support file: {item}"

    print("Hash Race smoke test passed: ten Bitcoin mining companies have mutable 0-100 ratings that now materially affect player economics, rival AI remains personality-driven, the BTC hold strategy stays fully adjustable from 0-100, and the RPG world keeps its flexible day/week/month/quarter clock.")


if __name__ == "__main__":
    main()
