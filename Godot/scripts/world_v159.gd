extends "res://scripts/world_v158.gd"

# Hash Race v0.159: promote the previously unused cable-tray cell from the
# electrical distribution source sheet into a real stationary live-world PNG.
const V159_CABLE_TRAY_REVISION := 1
const V159_CABLE_TRAY_PATH := "res://art/electrical/cable_tray.png"
const V159_CABLE_TRAY_SHA256 := "e9cdcb9d3254793f8c299b75526441a90401eb30051ed67d8408048e1d8f9a96"
var v159_cable_tray_texture: Texture2D

func _ready() -> void:
    v159_cable_tray_texture = _v128_load_texture(V159_CABLE_TRAY_PATH)
    super._ready()
    set_meta("hashrace_v159_cable_tray_live", v159_cable_tray_texture != null)
    set_meta("hashrace_v159_cable_tray_ground_footprint", Rect2(-47.0, -7.0, 94.0, 14.0))
    queue_redraw()

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)
    # One tray bridges the transformer/distribution side without entering the
    # player approach lane. Draw order stays inside the site's inherited pass.
    _v159_draw_cable_tray(origin + Vector2(124.0, 164.0))

func _v159_draw_cable_tray(center: Vector2) -> void:
    if v159_cable_tray_texture == null:
        return
    var size_value := Vector2(96.0, 96.0)
    var dest := Rect2(center - size_value * Vector2(0.5, 0.82), size_value)
    draw_ellipse_shadow(center + Vector2(0.0, 4.0), 45.0, 7.0)
    draw_texture_rect(v159_cable_tray_texture, dest, false)

func debug_v159_ready() -> bool:
    return V159_CABLE_TRAY_REVISION == 1 \
        and ResourceLoader.exists(V159_CABLE_TRAY_PATH) \
        and v159_cable_tray_texture != null \
        and v159_cable_tray_texture.get_width() == 128 \
        and v159_cable_tray_texture.get_height() == 128 \
        and debug_v158_ready()
