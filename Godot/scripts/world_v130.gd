extends "res://scripts/world_v129.gd"

# Hash Race v0.130: ChatGPT Library 2D overview integration.
# One new Library image is promoted into a real Godot source asset each visual
# pass. This first pass uses the approved command-center overview as an in-world
# site monitor rather than leaving the reference idle outside the game.

const V130_LIBRARY_OVERVIEW_REVISION := 1
const V130_LIBRARY_OVERVIEW_PATH := "res://assets/library/v130/command_center_overview.jpg"
const V130_LIBRARY_OVERVIEW_SOURCE := "ChatGPT Library /Hashrace/Bitcoin Command Center Base.png"

var v130_library_overview_texture: Texture2D

func _ready() -> void:
    v130_library_overview_texture = _v130_load_texture(V130_LIBRARY_OVERVIEW_PATH)
    super._ready()
    set_meta("hashrace_v130_library_overview_revision", V130_LIBRARY_OVERVIEW_REVISION)
    set_meta("hashrace_v130_library_overview_live", v130_library_overview_texture != null)
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

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)
    _v130_draw_library_overview_monitor(origin + Vector2(-315.0, -176.0))

func _v130_draw_library_overview_monitor(center: Vector2) -> void:
    # The full overview stays readable as a single authored image and is kept
    # off the service road/player lane. A small frame makes it read as a live
    # command-center site monitor instead of another terrain tile.
    var size_value := Vector2(144.0, 90.0)
    draw_ellipse_shadow(center + Vector2(0.0, 48.0), 56.0, 8.0)
    var frame := Rect2(center - size_value * 0.5 - Vector2(5.0, 5.0), size_value + Vector2(10.0, 10.0))
    draw_rect(frame, Color("0b151b"), true)
    draw_rect(frame, Color("39ff75"), false, 2.0)
    var screen := Rect2(center - size_value * 0.5, size_value)
    if v130_library_overview_texture != null:
        draw_texture_rect(v130_library_overview_texture, screen, false)
    else:
        draw_rect(screen, Color("16242a"), true)
        draw_line(screen.position, screen.end, Color("39ff75"), 2.0)
        draw_line(Vector2(screen.position.x, screen.end.y), Vector2(screen.end.x, screen.position.y), Color("39ff75"), 2.0)

    var plate := Rect2(Vector2(frame.position.x, frame.end.y + 3.0), Vector2(frame.size.x, 15.0))
    draw_rect(plate, Color("071016"), true)
    draw_string(
        ThemeDB.fallback_font,
        plate.position + Vector2(8.0, 11.0),
        "SITE OVERVIEW",
        HORIZONTAL_ALIGNMENT_LEFT,
        plate.size.x - 16.0,
        10,
        Color("80ff9b")
    )

func debug_v130_ready() -> bool:
    return V130_LIBRARY_OVERVIEW_REVISION == 1 \
        and v130_library_overview_texture != null \
        and bool(get_meta("hashrace_v130_library_overview_live", false)) \
        and debug_v129_ready()
