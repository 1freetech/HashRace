#!/usr/bin/env python3
"""v0.070+ compact consolidated Mining Ops widget contract."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
version = (root / "VERSION").read_text(encoding="utf-8").strip()
scene = (root / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
current_world = (root / "Godot/scripts/world_v072.gd").read_text(encoding="utf-8")
live_world = (root / "Godot/scripts/world_v073.gd").read_text(encoding="utf-8")
release_world = (root / "Godot/scripts/world_v070.gd").read_text(encoding="utf-8")
world = (root / "Godot/scripts/world_v068.gd").read_text(encoding="utf-8")
parent_world = (root / "Godot/scripts/world_v067.gd").read_text(encoding="utf-8")
widget = (root / "Godot/scripts/mining_ops_widget.gd").read_text(encoding="utf-8")
capture = (root / "Godot/scripts/capture_mining_ops_widget.gd").read_text(encoding="utf-8")

assert re.fullmatch(r"v0\.\d{3}", version), version
assert int(version.split(".")[1]) >= 70, version
live_world_match = re.search(r'path="(res://scripts/world_v\d{3}\.gd)"', scene)
assert live_world_match, "Live scene does not reference a versioned world script"
live_world_path = live_world_match.group(1)
assert (root / "Godot" / live_world_path.removeprefix("res://")).is_file(), f"Live world is missing: {live_world_path}"
assert 'extends "res://scripts/world_v072.gd"' in live_world
assert 'extends "res://scripts/world_v070.gd"' in current_world
assert 'extends "res://scripts/world_v068.gd"' in release_world
assert 'extends "res://scripts/world_v067.gd"' in world
assert 'MODULAR_ARCHITECTURE_REVISION' in world
assert 'debug_mining_ops_widget_ready' in parent_world

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
assert 'MINING_OPS_WIDGET_REVISION: int = 2' in parent_world
assert 'top_stats.visible = false' in world
print(f"Hash Race {version} consolidated upper-right Mining Ops widget contract passed.")
