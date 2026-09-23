extends "res://scripts/world_v155.gd"

# Hash Race v0.156: authored C-01 PNG is the only live container source.
# Override the inherited v0.128 asset path before the ready chain runs so
# v0.128 loads this PNG directly. The live world never loads the legacy SVG.
const V156_AUTHORED_CONTAINER_REVISION := 2
const V156_CONTAINER_PNG := "res://art/buildings/c01_mining_container.png"
const V156_CONTAINER_SHA256 := "5af801c621fb51739408866fad378ec06225fad6614190beacebbb29d7bf986a"

func _v128_load_texture(path: String) -> Texture2D:
    # v0.128 asks for its historical SVG path during super._ready(). Redirect
    # that one request to the authored PNG so there is a single obvious source.
    var live_path := V156_CONTAINER_PNG if path == V128_CONTAINER_PATH else path
    if ResourceLoader.exists(live_path):
        var imported := load(live_path) as Texture2D
        if imported != null:
            return imported
    var absolute_path := ProjectSettings.globalize_path(live_path)
    if not FileAccess.file_exists(absolute_path):
        return null
    var image := Image.new()
    var load_error := image.load(absolute_path)
    if load_error != OK or image.is_empty():
        return null
    return ImageTexture.create_from_image(image)

func _ready() -> void:
    super._ready()
    # super() now loaded the PNG directly through the override above.
    set_meta("hashrace_v156_container_png_live", v128_container_texture != null)
    set_meta("hashrace_v156_container_source", V156_CONTAINER_PNG)
    set_meta("hashrace_v156_container_ground_contact", Vector2(0.0, 0.42))

func debug_v156_ready() -> bool:
    return V156_AUTHORED_CONTAINER_REVISION == 2 \
        and ResourceLoader.exists(V156_CONTAINER_PNG) \
        and v128_container_texture != null \
        and v128_container_texture.get_width() == 128 \
        and v128_container_texture.get_height() == 102 \
        and String(get_meta("hashrace_v156_container_source", "")) == V156_CONTAINER_PNG \
        and debug_v155_ready()
