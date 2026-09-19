extends "res://scripts/world_v092.gd"

# Hash Race v0.093 start-menu preview and UI cleanup pass.
# Keeps v0.092 gameplay behavior while validating the thinner Mining Ops HUD
# and removal of the legacy full-width overworld header.

const V093_UI_REVISION: int = 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v093_ui_revision", V093_UI_REVISION)

func debug_v093_ready() -> bool:
    return (
        V093_UI_REVISION == 1
        and debug_v092_ready()
        and has_method("debug_overworld_header_removed")
        and bool(debug_overworld_header_removed())
    )
