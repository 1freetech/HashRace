"""Follow the live scene's actual script inheritance, without historical comments."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def active_world_scripts(scene_path="Godot/scenes/world.tscn"):
    scene = (ROOT / scene_path).read_text()
    root_script = re.search(r'^script = ExtResource\("([^"]+)"\)', scene, re.M)
    assert root_script, "Live world root has no script"
    resources = {}
    for block in re.findall(r'\[ext_resource ([^\]]+)\]', scene):
        attributes = dict(re.findall(r'(\w+)="([^"]+)"', block))
        if attributes.get("type") == "Script":
            resources[attributes["id"]] = attributes["path"]
    path = resources[root_script[1]]
    scripts = set()
    while path.startswith("res://"):
        assert path not in scripts, "Cyclic world inheritance"
        scripts.add(path)
        source = (ROOT / "Godot" / path.removeprefix("res://")).read_text()
        parent = re.search(r'^extends\s+"([^"]+)"', source, re.M)
        if not parent:
            break
        path = parent[1]
    return scripts


def assert_world_inherits(filename):
    assert "res://scripts/" + filename in active_world_scripts(), filename + " is not in the live world inheritance chain"


def assert_live_world_layer(minor_version):
    """Check a retained source layer and a current release at least that new.

    Inheritance preserves access to the layer; later overrides can replace a
    behavior, so runtime tests are still needed to prove live behavior.
    """
    version = (ROOT / "VERSION").read_text().strip()
    match = re.fullmatch(r"v(\d+)\.(\d+)", version)
    assert match, f"invalid VERSION: {version}"
    assert (int(match[1]), int(match[2])) >= (0, minor_version), version
    assert_world_inherits(f"world_v{minor_version:03}.gd")


def assert_historical_world_inherits(filename):
    """Require preserved behavior in the explicit historical integration fixture.

    This is source regression coverage, never evidence of live integration.
    assert_world_inherits remains strict for the actual campaign scene.
    """
    scripts = active_world_scripts("Godot/scenes/historical_world.tscn")
    assert "res://scripts/" + filename in scripts, filename + " missing from historical fixture"
