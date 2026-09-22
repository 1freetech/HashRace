"""v0.144 exact-sheet character customization regression contract."""
import re
from hashlib import sha256
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "Godot/scripts"
sheet = ROOT / "Godot/art/characters/default_player_sheet.png"
sheet_code = (SCRIPTS / "default_player_sprite_sheet.gd").read_text(encoding="utf-8")
customization = (SCRIPTS / "character_customization.gd").read_text(encoding="utf-8")
preview = (SCRIPTS / "character_preview.gd").read_text(encoding="utf-8")
world = (SCRIPTS / "world_v144.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")

assert sha256(sheet.read_bytes()).hexdigest() == "2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211"
assert "build_customized_texture" in sheet_code
assert "EFFECTIVE_SOURCE_INDICES" in sheet_code
assert "SUIT_COLORS" in customization and "DEFAULT_SUIT_COLOR" in customization
assert "DefaultPlayerSheet.build_customized_texture" in preview
assert "ACTUAL PLAYER PREVIEW" in preview
assert "approved_32frame_runtime_palette" in world
assert "debug_v144_palette_key" in world

# Historical regression layers are behavior contracts, not live-version locks.
# Follow the current world inheritance chain and require v0.144 to remain in it.
live_scene_match = re.search(
    r'path="res://scripts/(world_v\d+\.gd)" type="Script" id="1_world"', scene
)
assert live_scene_match, "world.tscn must point at a versioned live world script"
current_name = live_scene_match.group(1)
visited = []
while True:
    assert current_name not in visited, f"world inheritance cycle detected at {current_name}"
    visited.append(current_name)
    if current_name == "world_v144.gd":
        break
    current_path = SCRIPTS / current_name
    assert current_path.exists(), f"missing inherited world script: {current_name}"
    current_source = current_path.read_text(encoding="utf-8")
    parent_match = re.search(r'^extends\s+"res://scripts/(world_v\d+\.gd)"', current_source, re.MULTILINE)
    assert parent_match, (
        f"{current_name} must preserve the versioned inheritance chain back to v0.144; "
        f"visited: {' -> '.join(visited)}"
    )
    current_name = parent_match.group(1)

assert "world_v144.gd" in visited, (
    "current live world must preserve v0.144 customization behavior through inheritance; "
    f"visited: {' -> '.join(visited)}"
)
print(
    "Hash Race v0.144 exact approved-sheet skin/suit customization contract: PASS "
    f"through {' -> '.join(visited)}"
)
