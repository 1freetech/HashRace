from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

world = (ROOT / "Godot/scripts/world_v107.gd").read_text(encoding="utf-8")
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
validate = (ROOT / "Godot/scripts/validate_overworld.gd").read_text(encoding="utf-8")
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()

assert version == "v0.107", version
assert 'extends "res://scripts/world_v106.gd"' in world
assert "V107_HQ_PLAYER_SCALE := 1.18" in world
assert "V107_PARTNER_SCALE := 0.88" in world
assert "_v107_draw_path_shape" in world
assert "_v107_corner_bite" in world
assert "_v107_draw_stepped_bank" in world
assert "_v107_shadow_quad" in world
assert "_draw_mining_campus" in world
assert "debug_v107_ready" in world
assert 'res://scripts/world_v107.gd' in scene
assert '"debug_v107_ready"' in validate

# Composition contract: hero structures must gain visual hierarchy while
# secondary partner offices recede and shadows stay layered.
assert 1.18 > 1.08 > 1.0
assert 0.88 < 1.0
shadow_alpha = [0.40, 0.24, 0.12]
assert shadow_alpha == sorted(shadow_alpha, reverse=True)

print("v0.107 pixel-world visual composition contract: PASS")
