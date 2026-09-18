#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
widget = (ROOT / "Godot/scripts/mining_ops_widget.gd").read_text()
compact = (ROOT / "Godot/scripts/world_ui_compact.gd").read_text()
target = (ROOT / "Godot/scripts/world_target_composition.gd").read_text()
texture = (ROOT / "Godot/scripts/world_texture_spacing.gd").read_text()

force_block = widget.split("func force_refresh() -> void:", 1)[1].split("func _accept_sample", 1)[0]
assert "_accept_sample" not in force_block, "UI refresh must not create fake history samples"
assert "if not simulation_snapshot.is_empty():" in widget
assert "_trend_direction" in widget
assert "return WARNING" in widget and "return BAD" in widget

assert "COMPACT_UI_REVISION: int = 2" in compact
assert "COMPACT_PROMPT_REFRESH_SECONDS" in compact
assert "COMPACT_STATUS_REFRESH_SECONDS" in compact
assert "debug_compact_ui_throttle_ready" in compact

assert "CAMPUS_ANIMATION_STEP_MS" in target
assert "next_phase != campus_animation_phase" in target
old_burst = 'if int(Time.get_ticks_msec() / 260) % 2 == 0:'
assert old_burst not in target
assert "debug_animation_scheduler_ready" in target

assert 'CHARACTER_LABEL_GREEN := Color("39ff75")' in texture
assert "BUILDING_LABEL_BG" in texture
assert "NAV_PATH_COLOR" in texture
assert "nav_path_index >= nav_path.size()" in texture
assert "One destination reticle" in texture

print("Hash Race v0.090 runtime polish/readability contract passed.")
