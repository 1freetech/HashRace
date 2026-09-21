extends "res://scripts/world_v129.gd"

# Hash Race v0.130: Command Center overview integration.
# The approved overview is used when it decodes correctly. A clean procedural
# Command Center monitor remains live when an imported image is missing/corrupt,
# so one bad binary asset can never make the playable world or release fail.

const V130_LIBRARY_OVERVIEW_REVISION := 1
const V130_LIBRARY_OVERVIEW_PATH := "res://assets/library/v130/command_center_overview.jpg"
const V130_LIBRARY_OVERVIEW_SOURCE := "ChatGPT Library /Hashrace/Bitcoin Command Center Base.png"

var v130_library_overview_texture: Texture2D

func _ready() -> void:
    v130_library_overview_texture = _v130_load_texture(V130_LIBRARY_OVERVIEW_PATH)
    super._ready()
    set_meta("hashrace_v130_library_overview_revision", V130_LIBRARY_OVERVIEW_REVISION)
    set_meta("hashrace_v130_library_overview_live", true)
    set_meta("hashrace_v130_library_overview_authored", v130_library_overview_texture != null)
    queue_redraw()

func _v130_load_texture(path: String) -> Texture2D:
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
    var size_value := Vector2(144.0, 90.0)
    draw_ellipse_shadow(center + Vector2(0.0, 48.0), 56.0, 8.0)
    var frame := Rect2(center - size_value * 0.5 - Vector2(5.0, 5.0), size_value + Vector2(10.0, 10.0))
    draw_rect(frame, Color("0b151b"), true)
    draw_rect(frame, Color("39ff75"), false, 2.0)
    var screen := Rect2(center - size_value * 0.5, size_value)
    if v130_library_overview_texture != null:
        draw_texture_rect(v130_library_overview_texture, screen, false)
    else:
        # Intentional fallback: a readable Command Center topology instead of
        # an error/X placeholder. Keeps the mining campus sparse and useful.
        draw_rect(screen, Color("102028"), true)
        var command_center := Rect2(screen.position + Vector2(8.0, 9.0), Vector2(42.0, 25.0))
        var mining_block := Rect2(screen.position + Vector2(84.0, 10.0), Vector2(49.0, 23.0))
        var power_block := Rect2(screen.position + Vector2(83.0, 57.0), Vector2(50.0, 22.0))
        draw_rect(command_center, Color("18343d"), true)
        draw_rect(command_center, Color("39ff75"), false, 1.5)
        draw_rect(mining_block, Color("18343d"), true)
        draw_rect(mining_block, Color("80ff9b"), false, 1.5)
        draw_rect(power_block, Color("18343d"), true)
        draw_rect(power_block, Color("80ff9b"), false, 1.5)
        draw_line(command_center.end - Vector2(0.0, 12.0), mining_block.position + Vector2(0.0, 12.0), Color("39ff75"), 2.0)
        draw_line(mining_block.position + Vector2(24.0, 23.0), power_block.position + Vector2(24.0, 0.0), Color("39ff75"), 2.0)
        draw_string(ThemeDB.fallback_font, command_center.position + Vector2(4.0, 16.0), "COMMAND", HORIZONTAL_ALIGNMENT_LEFT, 36.0, 6, Color("d8edf2"))
        draw_string(ThemeDB.fallback_font, mining_block.position + Vector2(5.0, 15.0), "MINING", HORIZONTAL_ALIGNMENT_LEFT, 39.0, 7, Color("d8edf2"))
        draw_string(ThemeDB.fallback_font, power_block.position + Vector2(5.0, 15.0), "POWER", HORIZONTAL_ALIGNMENT_LEFT, 39.0, 7, Color("d8edf2"))

    var plate := Rect2(Vector2(frame.position.x, frame.end.y + 3.0), Vector2(frame.size.x, 15.0))
    draw_rect(plate, Color("071016"), true)
    draw_string(ThemeDB.fallback_font, plate.position + Vector2(8.0, 11.0), "COMMAND CENTER OVERVIEW", HORIZONTAL_ALIGNMENT_LEFT, plate.size.x - 16.0, 9, Color("80ff9b"))

func debug_v130_ready() -> bool:
    return V130_LIBRARY_OVERVIEW_REVISION == 1 \
        and bool(get_meta("hashrace_v130_library_overview_live", false)) \
        and debug_v129_ready()
