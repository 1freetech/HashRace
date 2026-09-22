extends "res://scripts/world_v120.gd"

# Hash Race v0.121 default-player sprite integration.
# The uploaded 4x4 sheet is now the primary live overworld player artwork.
# NPCs and special action poses keep the proven procedural renderer, which also
# remains the automatic fallback if the sprite asset cannot be loaded.

const DefaultPlayerSheet = preload("res://scripts/default_player_sprite_sheet.gd")
const V121_DEFAULT_PLAYER_REVISION := 1
const V121_CHARACTER_SIZE := Vector2(112.0, 112.0)
const V121_CHARACTER_ANCHOR_Y := 0.56

var v121_player_texture: Texture2D

func _ready() -> void:
    v121_player_texture = DefaultPlayerSheet.load_texture()
    super._ready()
    set_meta("hashrace_v121_default_player_revision", V121_DEFAULT_PLAYER_REVISION)
    set_meta("hashrace_character_render_mode", "uploaded_default_sheet_with_procedural_fallback")
    queue_redraw()

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if not is_player or v121_player_texture == null or not v073_character_action.is_empty():
        super._draw_tech_rep(pos, accent, scanner, is_player)
        return

    var moving := not rep_animation_state.ends_with("_idle")
    var frame := _v121_walk_frame(moving)
    var region := DefaultPlayerSheet.frame_region(rep_facing, frame)
    var center := VisualStack.snap_to_pixel(pos + Vector2(0.0, -7.0))
    var dest := Rect2(
        center + Vector2(-V121_CHARACTER_SIZE.x * 0.5, -V121_CHARACTER_SIZE.y * V121_CHARACTER_ANCHOR_Y),
        V121_CHARACTER_SIZE
    )

    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 42.0)), 28.0, 8.0)
    draw_texture_rect_region(v121_player_texture, dest, Rect2(region))

func _v121_walk_frame(moving: bool) -> int:
    if not moving:
        return 0
    var phase := fposmod(rep_step_phase, TAU) / TAU
    return clampi(int(floor(phase * 4.0)), 0, 3)

func debug_v121_ready() -> bool:
    return V121_DEFAULT_PLAYER_REVISION == 1 and DefaultPlayerSheet.ROW_BY_FACING.size() == 4 and DefaultPlayerSheet.FRAME_SIZE == Vector2i(32, 40) and debug_v120_ready()
