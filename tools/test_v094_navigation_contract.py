"""v0.094 navigation / HUD declutter regression contract."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
scene = (ROOT / "Godot/scenes/world.tscn").read_text(encoding="utf-8")
release = (ROOT / "Godot/scripts/world_v094.gd").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")

assert version == "v0.094", version
assert "world_v094.gd" in scene
assert 'navigation_layer.name = "NavigationShell"' in release
assert 'navigation_button.text = "NAV • WORLD"' in release
assert '"MINING OPS", "ops"' in release
assert '"BTC TREASURY", "treasury"' in release
assert '"LIFE + SITE", "site"' in release
assert '"WARDROBE", "wardrobe"' in release
assert '"DIALOG", "dialog"' in release
assert '"TOOLS", "tools"' in release
assert "func _hide_workspace_panels()" in release
assert "dialog_panel.visible = false" in release
assert "mining_ops_widget.hide()" in release
assert "compact_prompt.visible = false" in release
assert "menu_button.visible = false" in release
assert "func _show_toast(" in release
assert "TOAST_SECONDS" in release
assert "func debug_v094_navigation_ready()" in release
assert "current development build is **v0.094**" in readme

print("v0.094 one-panel navigation / clean-world HUD contract PASS")
