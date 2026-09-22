extends "res://scripts/world_v145.gd"

# Hash Race v0.146: field HUD truth and interaction guidance.
# Keep the ten-company Bitcoin mining league unchanged while making the compact
# HUD agree with the actual controls and scanner state.
const V146_FIELD_UX_REVISION := 1

func _ready() -> void:
    super._ready()
    _v146_sync_scanner_state()
    _refresh_compact_prompt()
    set_meta("hashrace_v146_field_ux_revision", V146_FIELD_UX_REVISION)

func _toggle_scanner_overlay() -> void:
    super._toggle_scanner_overlay()
    _v146_sync_scanner_state()

func _v146_sync_scanner_state() -> void:
    if is_instance_valid(scanner_button):
        scanner_button.text = "SCANNER: %s  [R]" % ("ON" if scanner_overlay_enabled else "OFF")
    if is_instance_valid(scanner_menu_button):
        scanner_menu_button.text = "SCANNER: %s  [R]" % ("ON" if scanner_overlay_enabled else "OFF")
        scanner_menu_button.tooltip_text = "Toggle reachable-cell guidance. Shortcut: R."

func _refresh_compact_prompt() -> void:
    if not is_instance_valid(compact_prompt):
        return
    var idx: int = _nearest_entity()
    if idx >= 0:
        var entity: Dictionary = entities[idx]
        var target_name := String(entity.get("name", "TARGET")).to_upper()
        var distance := rep_pos.distance_to(_entity_interaction_point(idx))
        if _entity_in_interact_range(idx):
            compact_prompt.text = "[E/F] INTERACT  •  %s  •  %dm" % [target_name, int(round(distance))]
            compact_prompt.add_theme_color_override("font_color", Color("8affbd"))
            return
        if distance <= INTERACT_RANGE * 2.5:
            compact_prompt.text = "NEAREST  •  %s  •  %dm  •  MOVE CLOSER" % [target_name, int(round(distance))]
            compact_prompt.add_theme_color_override("font_color", Color("c4e4ea"))
            return
    compact_prompt.text = "WASD MOVE  •  M MENU  •  T TRANSIT  •  R SCANNER  •  F INTERACT"
    compact_prompt.add_theme_color_override("font_color", Color("c4e4ea"))

func debug_v146_ready() -> bool:
    return V146_FIELD_UX_REVISION == 1 \
        and V138_MINING_COMPANIES.size() == 10 \
        and debug_v145_ready()
