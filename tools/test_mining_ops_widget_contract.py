#!/usr/bin/env python3
"""Compact consolidated Mining Ops widget contract for the full live campaign."""
from pathlib import Path

from world_script_contract import active_world_scripts

root = Path(__file__).resolve().parents[1]
scene = (root / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
widget = (root / "Godot/scripts/mining_ops_widget.gd").read_text(encoding="utf-8")
capture = (root / "Godot/scripts/capture_mining_ops_widget.gd").read_text(encoding="utf-8")

live_scripts = active_world_scripts()
assert 'path="res://scripts/world_v165.gd"' in scene, "Live scene must use the restored v0.165 gameplay chain"
for required in [
    "res://scripts/world_v165.gd",
    "res://scripts/world_league_standings.gd",
    "res://scripts/world_overworld.gd",
]:
    assert required in live_scripts, f"Missing live gameplay layer: {required}"

for marker in [
    '"HASHRATE"', '"POWER"', '"EFFICIENCY"', '"UPTIME"', '"BTC TREASURY"', '"USD CASH"',
    '"MINING OPS"', '"// LIVE"', 'func _context_line()',
    'func _sample_metrics()', 'func apply_simulation_snapshot', 'world.call("_hashrate_th")', 'world.call("_effective_available_mw")',
    'world.call("_machine_load_kw")', 'world.call("_uptime")',
    'player.get("sats"', 'player.get("cash"',
    'func _draw_sparkline', 'func _draw_progress',
    'func _gui_input', 'dragging = true', 'func _cycle_mount', 'func mount_top_right',
    'func set_screen_scale', 'draw_string', 'MAX_HISTORY',
    'MIN_SIZE', 'EDGE_GRAB', 'RESIZE_LEFT', 'RESIZE_RIGHT', 'RESIZE_TOP', 'RESIZE_BOTTOM',
    'resizing = true', 'func _resize_mask_at', 'func _resize_from_global_pointer',
    'Control.CURSOR_HSIZE', 'Control.CURSOR_VSIZE', 'Control.CURSOR_FDIAGSIZE', 'Control.CURSOR_BDIAGSIZE',
    'expanded_size', 'func debug_resizable_ready', 'func debug_set_widget_size',
]:
    assert marker in widget, f"Missing live-widget marker: {marker}"

assert 'player["cash"] = before_cash + 12345.0' in capture
assert 'player["sats"]' in capture
assert 'USD cash card did not follow live company cash' in capture
assert 'BTC treasury card did not follow live company sats' in capture
assert 'debug_resize_edge_mask' in capture
assert 'debug_set_widget_size' in capture
assert 'responsive Mining Ops widget did not grow after resize' in capture

assert 'const BASE_SIZE := Vector2(528.0, 248.0)' in widget
assert 'const MIN_SIZE := Vector2(420.0, 208.0)' in widget
assert 'var mount_slot: int = 1' in widget
print("Hash Race full-gameplay consolidated upper-right Mining Ops widget contract passed.")
