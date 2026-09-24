extends "res://scripts/world_v088.gd"

# Hash Race v0.089 camera input safety pass.
# The v0.088 proportional camera remains unchanged visually, but its keyboard
# and Ctrl+wheel zoom shortcuts now yield to focused HUD/menu controls so
# editing Custom turn days and other numeric fields cannot unexpectedly zoom.

const V089_CAMERA_INPUT_REVISION: int = 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v089_camera_input_revision", V089_CAMERA_INPUT_REVISION)

func debug_v089_ready() -> bool:
    return (
        V089_CAMERA_INPUT_REVISION == 1
        and is_instance_valid(camera_proportion_controller)
        and camera_proportion_controller.has_method("debug_focus_safe_shortcuts_ready")
        and camera_proportion_controller.debug_focus_safe_shortcuts_ready()
    )
