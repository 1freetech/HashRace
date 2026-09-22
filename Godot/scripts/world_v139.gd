extends "res://scripts/world_v138.gd"

# v0.139 keeps the consolidated v0.138 recovery world and promotes the
# approved 32-pose player atlas to the numbered live release layer.
const V139_CHARACTER_ASSET_REVISION := 1
const V139_CHARACTER_SHEET_SHA256 := "2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211"

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v139_character_live", true)

func debug_v139_ready() -> bool:
    return V139_CHARACTER_ASSET_REVISION == 1 \
        and bool(get_meta("hashrace_player_32frame_asset_live", false)) \
        and debug_v138_ready()
