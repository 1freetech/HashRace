extends "res://scripts/world_v129.gd"

# Hash Race v0.130: ChatGPT Library 2D overview integration.
# The authored Library image is preferred. If a checkout contains a damaged
# binary, keep the runtime drawable with an explicit generated monitor texture
# instead of letting one bad asset block every visual-proof job.

const V130_LIBRARY_OVERVIEW_REVISION := 2
const V130_LIBRARY_OVERVIEW_PATH := "res://assets/library/v130/command_center_overview.jpg"
const V130_LIBRARY_OVERVIEW_SOURCE := "ChatGPT Library /Hashrace/Bitcoin Command Center Base.png"
const V130_FALLBACK_SIZE := Vector2i(144, 90)

var v130_library_overview_texture: Texture2D
var v130_library_source_valid: bool = false

func _ready() -> void:
    v130_library_overview_texture = _v130_load_texture(V130_LIBRARY_OVERVIEW_PATH)
    v130_library_source_valid = v130_library_overview_texture != null
    if v130_library_overview_texture == null:
        v130_library_overview_texture = _v130_build_fallback_texture()
    super._ready()
    set_meta("hashrace_v130_library_overview_revision", V130_LIBRARY_OVERVIEW_REVISION)
    set_meta("hashrace_v130_library_overview_live", v130_library_overview_texture != null)
    set_meta("hashrace_v130_library_overview_source_valid", v130_library_source_valid)
    set_meta("hashrace_v130_library_overview_fallback", not v130_library_source_valid)
    queue_redraw()

func _v130_load_texture(path: String) -> Texture2D:
    if ResourceLoader.exists(path):
        var imported := load(path) as Texture2D
        if imported != null:
            return imported
    var absolute_path := ProjectSettings.globalize_path(path)
    if not FileAccess.file_exists(absolute_path):
        return null
    var image := Image.new()
    var load_error := image.load(absolute_path)
    if load_error != OK or image.is_empty():
        return null
    return ImageTexture.create_from_image(image)

func _v130_build_fallback_texture() -> Texture2D:
    # Deterministic pixel-art command-center monitor used only when the committed
    # source image cannot decode. This is runtime resilience, not source proof.
    var image := Image.create(V130_FALLBACK_SIZE.x, V130_FALLBACK_SIZE.y, false, Image.FORMAT_RGBA8)
    image.fill(Color("101a20"))
    for y in range(8, V130_FALLBACK_SIZE.y - 8):
        for x in range(8, V130_FALLBACK_SIZE.x - 8):
            if (x / 12 + y / 10) as int % 2 == 0:
                image.set_pixel(x, y, Color("14272b"))
    for x in range(14, 130):
        image.set_pixel(x, 66, Color("39ff75"))
        image.set_pixel(x, 67, Color("39ff75"))
    for x in range(18, 126, 22):
        for y in range(22, 58):
            image.set_pixel(x, y, Color("4c6872"))
            image.set_pixel(x + 1, y, Color("4c6872"))
        for px in range(x + 3, mini(x + 17, 143)):
            for py in range(30, 54):
                if py == 30 or py == 53 or px == x + 3 or px == x + 16:
                    image.set_pixel(px, py, Color("7f9aa3"))
    return ImageTexture.create_from_image(image)

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)
    _v130_draw_library_overview_monitor(origin + Vector2(-315.0, -176.0))

func _v130_draw_library_overview_monitor(center: Vector2) -> void:
    var size_value := Vector2(144.0, 90.0)
    draw_ellipse_shadow(center + Vector2(0.0, 48.0), 56.0, 8.0)
    var frame := Rect2(center - size_value * 0.5 - Vector2(5.0, 5.0), size_value + Vector2(10.0, 10.0))
    draw_rect(frame, Color("0b151b"), true)
    draw_rect(frame, Color("39ff75"), false, 2.0)
    var screen := Rect2(center - size_value * 0.5, size_value)
    draw_texture_rect(v130_library_overview_texture, screen, false)

    var plate := Rect2(Vector2(frame.position.x, frame.end.y + 3.0), Vector2(frame.size.x, 15.0))
    draw_rect(plate, Color("071016"), true)
    var label := "SITE OVERVIEW" if v130_library_source_valid else "SITE OVERVIEW • SAFE FALLBACK"
    draw_string(ThemeDB.fallback_font, plate.position + Vector2(8.0, 11.0), label, HORIZONTAL_ALIGNMENT_LEFT, plate.size.x - 16.0, 10, Color("80ff9b"))

func debug_v130_ready() -> bool:
    return V130_LIBRARY_OVERVIEW_REVISION == 2 \
        and v130_library_overview_texture != null \
        and bool(get_meta("hashrace_v130_library_overview_live", false)) \
        and debug_v129_ready()
