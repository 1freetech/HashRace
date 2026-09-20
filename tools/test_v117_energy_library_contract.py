from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORLD = (ROOT / "Godot/scripts/world_v117.gd").read_text(encoding="utf-8")
ENERGY = (ROOT / "Godot/systems/energy_visual_catalog.gd").read_text(encoding="utf-8")
INFRA = (ROOT / "Godot/systems/infrastructure_visual_catalog.gd").read_text(encoding="utf-8")
CAPTURE = (ROOT / "Godot/scripts/capture_energy_site.gd").read_text(encoding="utf-8")

ENERGY_IDS = [
    "battery",
    "solar_array",
    "wind_farm",
    "gas_turbine",
    "hydro_turbine",
    "oil_field",
    "coal_plant",
    "nuclear_smr",
    "methane_generator",
    "diesel_generator",
    "geothermal_generator",
    "lpg_generator",
    "hydrogen_fuel_cell",
]

def main():
    # This is a historical module contract, not a live-version pin. Later worlds
    # must be allowed to inherit v0.117 without making this regression test fail.
    assert 'extends "res://scripts/world_v116.gd"' in WORLD

    for marker in [
        "_v117_draw_energy_module",
        "_v117_draw_energy_fleet",
        "_v117_draw_compute_scale",
        "_v117_draw_district_block",
        "InfrastructureVisualCatalog.electrical_orientation",
        "EnergyVisualCatalog.source_region(asset_id, orientation)",
        "draw_texture_rect_region",
        "V117_MAX_VISIBLE_DISTRICTS := 10",
        "V117_ENERGY_IDS.size() != 13",
    ]:
        assert marker in WORLD, marker

    for marker in [
        '"max_mw": 2.0',
        '"tiles": 2',
        '"max_mw": 10.0',
        '"tiles": 4',
        '"max_mw": 25.0',
        '"tiles": 6',
        '"max_mw": 100.0',
        '"tiles": 8',
        '"max_mw": 1000.0',
        '"max_mw": 10000.0',
        '"max_mw": 100000.0',
        '"max_mw": 1000000.0',
        "electrical_orientation",
        '"visible_block_count"',
    ]:
        assert marker in INFRA, marker

    assert "ENERGY_VISUALS.size() == 13" in ENERGY
    assert "ATLAS_PARTS.size() == 8" in ENERGY

    for asset_id in ENERGY_IDS:
        assert f'"{asset_id}"' in ENERGY, asset_id
        item = ROOT / f"Godot/data/items/{asset_id}.tres"
        assert item.exists(), f"missing gameplay ItemResource: {asset_id}"
        body = item.read_text(encoding="utf-8")
        assert f'id = "{asset_id}"' in body

    assert "V117_CAPTURE_ENERGY_IDS" in CAPTURE
    for asset_id in ENERGY_IDS:
        assert f'"{asset_id}"' in CAPTURE, asset_id
    assert "inventory.deploy(asset_id, company, 1)" in CAPTURE

    print("v0.117 complete 13-system energy library + district compression contract PASS")

if __name__ == "__main__":
    main()
