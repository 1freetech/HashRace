extends "res://scripts/world_v155.gd"

# Hash Race v0.156: use the authored C-01 container as a decoded PNG runtime object.
# v0.128 already replaced the old v0.114 procedural container at the live site;
# this layer removes the SVG-at-runtime dependency and requires the raster asset.
const V156_AUTHORED_CONTAINER_REVISION := 1
const V156_CONTAINER_PNG := "res://art/buildings/c01_mining_container.png"
const V156_CONTAINER_SHA256 := "5af801c621fb51739408866fad378ec06225fad6614190beacebbb29d7bf986a"

func _ready() -> void:
    super._ready()
    v128_container_texture = _v128_load_texture(V156_CONTAINER_PNG)
    set_meta("hashrace_v156_container_png_live", v128_container_texture != null)
    set_meta("hashrace_v156_container_ground_contact", Vector2(0.0, 0.42))
    queue_redraw()

func debug_v156_ready() -> bool:
    return V156_AUTHORED_CONTAINER_REVISION == 1 \
        and ResourceLoader.exists(V156_CONTAINER_PNG) \
        and v128_container_texture != null \
        and v128_container_texture.get_width() == 128 \
        and v128_container_texture.get_height() == 102 \
        and debug_v155_ready()
