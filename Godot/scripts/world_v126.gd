extends "res://scripts/world_v125.gd"

# Hash Race v0.126 exact default-player integration.
# The live player uses the exact supplied 16-frame character art after removing
# the gray/grid background. Four frames per direction animate walking; frame 0
# is the idle pose. NPCs and special actions retain the procedural fallback.

const DefaultPlayerSheetV126 = preload("res://scripts/default_player_sprite_sheet.gd")
const V126_EXACT_PLAYER_REVISION := 1
const V126_PLAYER_HEIGHT := 124.0
const V126_PLAYER_ANCHOR_Y := 0.66

var v126_player_texture: Texture2D

func _ready() -> void:
    v126_player_texture = DefaultPlayerSheetV126.load_texture()
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    super._ready()
    set_meta("hashrace_v126_exact_player_revision", V126_EXACT_PLAYER_REVISION)
    set_meta("hashrace_v126_exact_player_asset_live", v126_player_texture != null)
    set_meta("hashrace_character_render_mode", "exact_uploaded_transparent_16_frame_sheet")
    queue_redraw()

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if not is_player or v126_player_texture == null or not v073_character_action.is_empty():
        super._draw_tech_rep(pos, accent, scanner, is_player)
        return
    var moving := not rep_animation_state.ends_with("_idle")
    var frame := _v121_walk_frame(moving)
    var region: Rect2i = DefaultPlayerSheetV126.frame_region(rep_facing, frame)
    var frame_aspect := float(region.size.x) / float(region.size.y)
    var size_value := Vector2(V126_PLAYER_HEIGHT * frame_aspect, V126_PLAYER_HEIGHT)
    var center := VisualStack.snap_to_pixel(pos + Vector2(0.0, -5.0))
    var dest := Rect2(center + Vector2(-size_value.x * 0.5, -size_value.y * V126_PLAYER_ANCHOR_Y), size_value)
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 43.0)), 27.0, 8.0)
    draw_texture_rect_region(v126_player_texture, dest, Rect2(region))

func debug_v126_ready() -> bool:
    return V126_EXACT_PLAYER_REVISION == 1 and v126_player_texture != null and DefaultPlayerSheetV126.FRAME_SIZE == Vector2i(40, 62) and DefaultPlayerSheetV126.SHEET_SIZE == Vector2i(160, 248) and DefaultPlayerSheetV126.debug_ready() and debug_v125_ready()
