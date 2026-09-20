from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_v111_site_growth_contract():
    assert (ROOT / "VERSION").read_text().strip() == "v0.111"

    script = (ROOT / "Godot/scripts/world_v111.gd").read_text()
    assert 'extends "res://scripts/world_v110.gd"' in script
    assert "InfrastructureVisualCatalog" in script
    assert "_machine_load_kw() / 1000.0" in script
    assert '"STARTER SITE"' in script
    assert '"CONTAINER YARD"' in script
    assert '"MINING FACILITY"' in script
    assert '"POWER CAMPUS"' in script
    assert '"INDUSTRIAL CAMPUS"' in script
    assert '"MEGASITE"' in script
    assert '"GIGAWATT DISTRICT"' in script
    assert '"100-GW NETWORK"' in script
    assert '"TERAWATT NETWORK"' in script
    assert '"mw_to_next"' in script
    assert "infrastructure_visual_plan" in script
    assert "debug_v110_ready()" in script

    catalog = (ROOT / "Godot/systems/infrastructure_visual_catalog.gd").read_text()
    for asset_id in (
        "cooling_container",
        "fuel_tank",
        "pumpjack",
        "manufacturing_center",
        "solar_array",
        "diesel_generator",
        "wind_turbine",
        "geothermal_generator",
        "kva_transformer",
        "lpg_generator",
        "coal_generator",
        "methane_generator",
        "compute_rack",
    ):
        assert f'"{asset_id}"' in catalog
    assert '"up", "right", "down", "left"' in catalog
    assert '"max_mw": 1000000.0' in catalog
    assert '"block_capacity_mw": 100000.0' in catalog
    assert "AMD" not in catalog
    assert "NVIDIA" not in catalog

    placement = (ROOT / "Godot/systems/physical_placement_grid.gd").read_text()
    assert "place_footprint" in placement
    assert "footprint_cells" in placement
    assert "hashrace_orientation" in placement
    assert "hashrace_footprint" in placement
    assert "for key in occupied.keys()" in placement

    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    assert 'res://scripts/world_v111.gd' in scene


if __name__ == "__main__":
    test_v111_site_growth_contract()
    print("v0.111 site-growth and infrastructure contract: PASS")
