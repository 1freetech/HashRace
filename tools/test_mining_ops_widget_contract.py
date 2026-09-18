#!/usr/bin/env python3
"""v0.067 draggable live Mining Ops widget contract."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = (root / "VERSION").read_text(encoding="utf-8").strip()
scene = (root / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
world = (root / "Godot/scripts/world_v067.gd").read_text(encoding="utf-8")
widget = (root / "Godot/scripts/mining_ops_widget.gd").read_text(encoding="utf-8")
capture = (root / "Godot/scripts/capture_mining_ops_widget.gd").read_text(encoding="utf-8")

assert version == "v0.067"
assert 'res://scripts/world_v067.gd' in scene
assert 'extends "res://scripts/world_v065.gd"' in world
assert 'MINING_OPS_WIDGET_REVISION' in world
assert 'debug_mining_ops_widget_ready' in world

for marker in [
    '"HASHRATE"', '"POWER"', '"EFFICIENCY"', '"UPTIME"', '"BTC TREASURY"', '"USD CASH"',
    '"MINING OPS"', '"// LIVE"', '"DRAG TO MOVE"',
    'func _sample_metrics()', 'world.call("_hashrate_th")', 'world.call("_effective_available_mw")',
    'world.call("_machine_load_kw")', 'world.call("_uptime")',
    'player.get("sats"', 'player.get("cash"',
    'func _draw_sparkline', 'func _draw_progress',
    'func _gui_input', 'dragging = true', 'func _cycle_mount',
    'func set_screen_scale', 'draw_string', 'MAX_HISTORY',
]:
    assert marker in widget, f"Missing live-widget marker: {marker}"

assert 'player["cash"] = before_cash + 12345.0' in capture
assert 'player["sats"]' in capture
assert 'USD cash card did not follow live company cash' in capture
assert 'BTC treasury card did not follow live company sats' in capture

print("Hash Race v0.067 live Mining Ops widget contract passed.")
