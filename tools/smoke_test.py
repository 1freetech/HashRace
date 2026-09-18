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
    release_world = Path("Godot/scripts/world_v070.gd").read_text(encoding="utf-8")
    character_release = Path("Godot/scripts/world_v073.gd").read_text(encoding="utf-8")
    pixel_release = Path("Godot/scripts/world_v080.gd").read_text(encoding="utf-8")
    microtile_release = Path("Godot/scripts/world_v082.gd").read_text(encoding="utf-8")
    turn_shortcut_release = Path("Godot/scripts/world_v085.gd").read_text(encoding="utf-8")
    computer_offer_release = Path("Godot/scripts/world_v086.gd").read_text(encoding="utf-8")
    quality_release = Path("Godot/scripts/world_v090.gd").read_text(encoding="utf-8")
    microtile_rules = Path("Godot/scripts/gen2_microtile_rules.gd").read_text(encoding="utf-8")
    modular_world = Path("Godot/scripts/world_v068.gd").read_text(encoding="utf-8")
    item_resource = Path("Godot/data/item_resource.gd").read_text(encoding="utf-8")
    inventory_resource_core = Path("Godot/scripts/infrastructure_inventory.gd").read_text(encoding="utf-8")
    simulation_manager = Path("Godot/systems/simulation_manager.gd").read_text(encoding="utf-8")
    rack_slot = Path("Godot/components/building/rack_slot.gd").read_text(encoding="utf-8")
    placement_grid = Path("Godot/systems/physical_placement_grid.gd").read_text(encoding="utf-8")
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
    texture_spacing = Path("Godot/scripts/world_texture_spacing.gd").read_text(encoding="utf-8")
    customization = Path("Godot/scripts/world_customization.gd").read_text(encoding="utf-8")
    character_detail = Path("Godot/scripts/world_character_detail.gd").read_text(encoding="utf-8")
    character_catalog = Path("Godot/scripts/character_customization.gd").read_text(encoding="utf-8")
    building_placer = Path("Godot/scripts/building_placer.gd").read_text(encoding="utf-8")
    workflow = Path(".github/workflows/smoke-test.yml").read_text(encoding="utf-8")

    assert 'run/main_scene="res://scenes/campaign_setup.tscn"' in project
    assert "campaign_setup.gd" in setup_scene
    assert "world_v090.gd" in world_scene
    assert 'extends "res://scripts/world_v080.gd"' in microtile_release
    assert 'extends "res://scripts/world_v073.gd"' in pixel_release
    assert 'extends "res://scripts/world_v072.gd"' in character_release
    assert 'extends "res://scripts/world_v068.gd"' in release_world
    assert 'extends "res://scripts/world_v067.gd"' in modular_world
    assert "BootFallback" in world_scene
    assert 'extends "res://scripts/world_overworld.gd"' in towns
    assert 'extends "res://scripts/world_towns.gd"' in grid_world
    assert 'extends "res://scripts/world_grid.gd"' in gbc_world
    assert 'extends "res://scripts/world_gbc.gd"' in rpg_world
    assert 'extends "res://scripts/world_rpg_strategy.gd"' in time_scale
    assert 'extends "res://scripts/world_time_scale.gd"' in company_ai
    assert 'extends "res://scripts/world_company_ai.gd"' in company_effects
    assert 'extends "res://scripts/world_customization.gd"' in character_detail
    assert "validate_overworld.gd" in workflow

    require(setup, ["MINING COMPANY", "YOUR CHARACTER", "SKIN TONE", "GENDER / PRESENTATION", "CAMPAIGN LENGTH", "range(1, 21)", "hashrace_company_idx", "hashrace_character_skin_tone", "hashrace_character_gender", "hashrace_character_outfit", "START MINING RACE", "BACKGROUND:", "CONTROVERSY:", "AGG %d", "RISK %d", "Turn length can change"], "Campaign setup")

    companies = ["VantaGrid Mining", "NeonForge Mining", "ArcShift Mining", "IronVector Mining", "Meridian Zero Mining", "BlueNova Mining", "SignalFlux Mining", "Parallax Core Mining", "LatticeX Mining", "Epoch Vector Mining"]
    require(profiles, companies, "Mining-company profile")
    require(profiles, ['"background"', '"controversy"', '"posture"', '"affinity"', '"aggression"', '"risk"', '"growth"', '"research"', '"treasury"', '"operations"', '"reputation"'], "Dynamic company profile")
    assert profiles.count('"background"') >= 10
    assert profiles.count('"controversy"') >= 10

    require(overworld, ["COMPANY OVERWORLD", "HashWorks ASIC Exchange", "Gridline Power Office", "Cascadia Utility District", "FoundryWorks Silicon", "Meridian Finance Cooperative", "QuickBite Services", "Pro Circuit Sports", "BlueRiver Energy Authority", "BUY 10 MACHINES", "CHANGE ENERGY", "TAKE LOAN", "REPAY DEBT", "STRIKE DEAL", "ATTEMPT ONE-TIME MERGER", "federal_rate", "land_price_per_acre"], "Live overworld")
    require(towns, ["TOWN_NAMES", "COMPANY_REPS", "PARTNER_REPS", "rival_rep", "partner_rep", "TOWN TRANSIT", "debug_company_rep_count", "debug_partner_rep_count", "debug_town_count"], "Town layer")
    require(gbc_world, ["GBPaint", "TileOps", "ART_TILE_SIZE", "_build_art_tilemap", "_draw_pixel_tile_world", "debug_gbc_map_ready"], "Pixel renderer")
    require(rpg_world, ["RPGMovement", "SCANNER_RANGE_CELLS", "SCANNER GRID", "_draw_scanner_overlay", "debug_rpg_collision_ready", "debug_scanner_reachable_count"], "RPG strategy layer")

    require(time_scale, ['"DAY", "days": 1.0', '"MONTH", "days": 30.4375', '"QUARTER", "days": 91.3125', '"YEAR", "days": 365.25', '"CUSTOM", "days": 14.0', "turn_length_days", "turn_length_name", "_cycle_turn_length", "_project_scaled_profit", "_simulate_rivals_scaled", "_advance_market_scaled", "HALVING_DAYS", "elapsed_campaign_days", "recurring_income", "CONFIRM %s TURN", "days / turn", "set_custom_turn_days", "_elapsed_probability"], "Flexible season clock")
    require(time_scale, ["_btc_per_day()*days", "24*days*_effective_power_cost()", "0.38*days", "days/365.0", "days/DAYS_PER_QUARTER"], "Elapsed-time financial scaling")
    assert "days / 365.0" in time_scale or "days/365.0" in time_scale
    assert "days / DAYS_PER_QUARTER" in time_scale or "days/DAYS_PER_QUARTER" in time_scale

    require(company_ai, ["CULTURE_MONTH_DAYS", "_new_personality", "_posture", "_ratings_text", "_evolve_player_culture", "_run_rival_month", "_maybe_rival_partnership", "_maybe_rival_controversy", "_maybe_player_controversy", "Aggressive", "Conservative", "Moderate", "CURRENT CULTURE", "FOUNDING CONTROVERSY", "Current action", "Recent controversy", "debug_company_personality_ready", "debug_rival_personality_count", "debug_personality_ratings_in_range"], "Dynamic company AI")
    for key in ["aggression", "risk", "growth", "research", "treasury", "operations", "reputation"]:
        assert key in company_ai

    require(company_effects, ["_operations_uptime_bonus", "_financing_rate_adjustment", "_partner_cost_multiplier", "_research_cost_multiplier", "_expansion_cost_multiplier", "_merger_cost_multiplier", "func _uptime()", "func _loan_rate", "func _buy_machines", "func _buy_power", "func _buy_land", "func _upgrade_chips", "func _sign_partner", "func _merge_rival", "LIVE GAMEPLAY EFFECTS", "debug_culture_effects_ready", "debug_culture_effects_are_material"], "Material company-culture effects")
    assert "0.88" in company_effects and "1.12" in company_effects, "Culture modifiers need explicit balance bounds"

    require(treasury, ["HSlider", "min_value = 0.0", "max_value = 100.0", "step = 1.0", "BTC HOLD POLICY: %d / 100", "_on_hold_policy_changed", "turn_length_days", "_project_scaled_profit", "AUTO-FUND SAFE TURN"], "Live 0-100 treasury strategy")
    assert "HOLD_POLICIES" not in treasury, "BTC hold policy must not be restricted to presets"
    require(playability, ["BTC HOLD POLICY", "SELL 25% BTC TREASURY", "AUTO-FUND NEXT QUARTER", "QUARTER PLAN", "PREPARE SAFE QUARTER"], "Treasury playability layer")

    require(texture_spacing, ["MIN_TARGET_SPACING", "CHARACTER_LABEL_GREEN", "_paint_grass_pixels", "_paint_road_pixels", "_paint_lot_pixels", "_paint_water_pixels", "_draw_neon_character_name", "debug_texture_spacing_ready"], "v0.052 visual spacing layer")
    require(building_placer, ["MIN_TARGET_SPACING", "PARTNER_POSITIONS", "RIVAL_POSITIONS", "minimum_building_spacing"], "Building placer")
    require(release_world, ["V070_RELEASE_REVISION", "debug_v070_ready"], "v0.070 release world")
    require(character_release, ["V073_CHARACTER_REVISION", "V073_PX", "V073_BODY_VARIANTS", "V073_HAIR_VARIANTS", "idle_down", "walk_left", "run_right", "mining", "victory", "_draw_v073_front", "_draw_v073_back", "_draw_v073_side", "debug_v073_ready"], "v0.073 reusable high-density character world")
    require(pixel_release, ["V080_PIXEL_INTEGRATION_REVISION", "V080_BUILDING_PIXEL", "_v080_entity_depth", "_v080_depth_less", "_draw_pixel_facility", "_draw_facility_surface_detail", "position_smoothing_enabled = false", "debug_pixel_integration_ready", "debug_v080_ready"], "v0.080 pixel integration world")
    require(microtile_rules, ["MICRO_TILE_SIZE", "CELL_MICROTILES", "CELL_SIZE", "MOTIF_NAMES", "building_cladding", "neighbor_mask", "motif_slots", "source_contract_ready"], "Gen-2 microtile rules")
    require(microtile_release, ["V082_MICROTILE_REVISION", "V082_MICRO", "_draw_v082_microtile_overlay", "_draw_v082_edge_modules", "debug_v082_ready"], "v0.082 microtile release world")
    require(turn_shortcut_release, ["V085_TURN_SHORTCUT_REVISION", "KEY_SPACE", "debug_turn_shortcut_ready"], "v0.085 turn shortcut world")
    require(computer_offer_release, ["V086_COMPUTER_OFFER_REVISION", "COMPUTER_DEAL_COMPANIES", "_launch_computer_company_offer", "\"deal_type\":\"computer_supply\"", "debug_computer_offer_ready"], "v0.086 computer-company offers")
    require(quality_release, ["V090_QUALITY_REVISION", "_entity_interaction_point", "_queue_or_open_interaction", "debug_v090_ready"], "v0.090 quality world")
    assert 'window/stretch/mode="viewport"' in project
    require(modular_world, ["SimulationManager", "PhysicalPlacementGrid", "RackContainer", "debug_modular_architecture_ready", "debug_hud_consolidated"], "modular world")
    require(item_resource, ["class_name HashRaceItemResource", "base_hashrate_ph", "power_draw_mw", "heat_generated_mw", "slot_type"], "ItemResource")
    require(inventory_resource_core, ["ItemLibrary.load_catalog", "catalog_resources", "debug_resource_catalog_ready"], "Resource-backed inventory")
    assert "const CATALOG" not in inventory_resource_core, "Infrastructure source of truth must be .tres resources, not the old inline CATALOG"
    require(simulation_manager, ["class_name HashRaceSimulationManager", "Timer.new", "tick_processed", "process_tick"], "Fixed-tick simulation manager")
    require(rack_slot, ["class_name HashRaceRackSlot", "install_item", "installed_hardware"], "Physical rack slots")
    require(placement_grid, ["class_name HashRacePhysicalPlacementGrid", "snap", "can_place", "serialize_layout"], "Physical placement grid")
    item_files = list(Path("Godot/data/items").glob("*.tres"))
    assert len(item_files) >= 34, f"Expected 34+ ItemResource files, found {len(item_files)}"
    require(character_catalog, ["SKIN_TONES", "GENDERS", "OUTFITS", "Operator Suit", "Grid Runner", "Night Shift", '"cost"', 'Color("e9eeee")', 'Color("e07a2f")', 'Color("39ff75")'], "Character catalog")
    require(customization, ["CHARACTER WARDROBE", "OUTFIT SKINS // BUY WITH GAME CASH", "_cycle_skin_tone", "_cycle_gender", "_choose_outfit", "owned_outfits", "_draw_hashrace_player", "debug_character_customization_ready", "debug_paid_outfits_use_game_cash"], "Character customization")
    require(character_detail, ["CHARACTER_DETAIL_REVISION", "_draw_detailed_character", "_draw_hashrace_player", "_draw_tech_rep", "DETAIL_VISOR_GREEN", "Headphones/ear protection", "shoulder", "knee", "gloves", "boots", "debug_character_detail_ready"], "v0.053 shared detailed character renderer")
    require(validator, ["debug_world_ready", "debug_entity_count", "debug_has_dialogue_ui", "debug_company_rep_count", "debug_gbc_map_ready", "debug_rpg_collision_ready", "debug_culture_effects_ready", "debug_culture_effects_are_material", "debug_texture_spacing_ready", "debug_character_customization_ready", "debug_v080_ready", "debug_pixel_integration_ready"], "Runtime validator")

    required_support = ["native/cpp/hashrace_core.cpp", "native/rust/hashrace_balance.rs", "tools/typescript/hashrace_validate.ts", "docs/LANGUAGE_STACK.md", "docs/ECONOMY_MODEL.md", "Godot/export_presets.cfg", "Godot/scripts/world_time_scale.gd", "Godot/scripts/world_company_ai.gd", "Godot/scripts/world_company_effects.gd", "Godot/scripts/world_rpg_strategy.gd", "Godot/scripts/grid_navigation.gd", "Godot/scripts/live_treasury_controls.gd", "Godot/scripts/world_texture_spacing.gd", "Godot/scripts/world_customization.gd", "Godot/scripts/world_character_detail.gd", "Godot/scripts/character_customization.gd", "Godot/scripts/building_placer.gd", "Godot/scripts/world_v053.gd", "Godot/scripts/world_v068.gd", "Godot/scripts/world_v070.gd", "Godot/scripts/world_v072.gd", "Godot/scripts/world_v073.gd", "Godot/scripts/world_v080.gd", "Godot/scripts/world_v082.gd", "Godot/scripts/world_v085.gd", "Godot/scripts/world_v086.gd", "Godot/scripts/world_v090.gd", "Godot/scripts/gen2_microtile_rules.gd", "Godot/shaders/building_pixelate.gdshader", "docs/PIXEL_ART_BUILDING_PIPELINE.md", "Godot/data/item_resource.gd", "Godot/data/item_library.gd", "Godot/systems/simulation_manager.gd", "Godot/systems/physical_placement_grid.gd", "Godot/components/building/rack_slot.gd", "Godot/components/building/rack_container.gd"]
    for item in required_support:
        assert Path(item).exists(), f"Missing support file: {item}"

    print("Hash Race smoke test passed: v0.090 quality layer and prior modular strategy/visual systems are structurally intact.")


if __name__ == "__main__":
    main()
