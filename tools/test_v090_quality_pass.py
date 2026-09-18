"""Static regression contract for Hash Race v0.090 quality pass."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
quality = (ROOT / "Godot/scripts/world_v090.gd").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")

assert version == "v0.090", version
assert 'res://scripts/world_v090.gd' in scene

# Three bug fixes: turn/input conflict, building-door geometry, and remote clicks.
assert "key_event.keycode == KEY_SPACE" in quality
assert "_activate_nearest_interaction()" in quality
assert "WorldScale.front_door_world_pos" in quality
assert "func _entity_in_interact_range" in quality
assert "_queue_or_open_interaction" in quality
assert "Interaction opens on arrival." in quality

# Three gameplay/readability upgrades.
assert "pending_interaction_idx" in quality
assert "_nearest_building_idx" in quality
assert "func _draw_clean_navigation_path" in quality

# Visual clutter rules: scanner text off by default, phase text contextual,
# and labels limited to the nearest relevant building/town.
assert "scanner_overlay_enabled = false" in quality
assert "phase_label.visible = live_quarter_confirmation_pending" in quality
assert "V090_BUILDING_LABEL_DISTANCE" in quality
assert "V090_TOWN_LABEL_DISTANCE" in quality

assert "current **main** development build is **v0.090**" in readme
print("v0.090 quality pass contract PASS")
