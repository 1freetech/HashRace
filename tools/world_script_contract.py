"""Follow the live scene's actual script inheritance, without historical comments."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def active_world_scripts():
    scene = (ROOT / "Godot/scenes/world.tscn").read_text()
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
