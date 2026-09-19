from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
world = (ROOT / "Godot/scripts/world_v095.gd").read_text()
scene = (ROOT / "Godot/scenes/world.tscn").read_text()

required = [
    'extends "res://scripts/world_v094.gd"',
    'KEY_ESCAPE', 'KEY_O', 'KEY_C', 'KEY_B', 'KEY_I', 'KEY_T', 'KEY_L',
    'workspace_buttons', 'last_toast_message', 'Time.get_ticks_msec()',
    'navigation_panel.size.x = panel_width', 'first.grab_focus()',
    'debug_v095_quality_ready',
]
for token in required:
    assert token in world, f"missing v0.095 quality token: {token}"

assert 'res://scripts/world_v095.gd' in scene
assert 'res://scripts/world_v094.gd' not in scene
print('v0.095 quality contract: PASS')
