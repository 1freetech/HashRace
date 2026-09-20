from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_v111_site_growth_contract():
    assert (ROOT / "VERSION").read_text().strip() == "v0.111"

    script = (ROOT / "Godot/scripts/world_v111.gd").read_text()
    assert 'extends "res://scripts/world_v110.gd"' in script
    assert "_machine_load_kw() / 1000.0" in script
    assert '"STARTER SITE"' in script
    assert '"CONTAINER YARD"' in script
    assert '"MINING FACILITY"' in script
    assert '"POWER CAMPUS"' in script
    assert '"INDUSTRIAL CAMPUS"' in script
    assert '"MEGASITE"' in script
    assert '"mw_to_next"' in script
    assert "debug_v110_ready()" in script

    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
    assert 'res://scripts/world_v111.gd' in scene


if __name__ == "__main__":
    test_v111_site_growth_contract()
    print("v0.111 site-growth contract: PASS")
