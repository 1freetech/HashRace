extends "res://scripts/world_v120.gd"

# Default player rendering uses the approved 32-pose transparent character.
# NPCs retain their existing renderer. A missing player image is an error.

const DefaultPlayerSheet = preload("res://scripts/default_player_sprite_sheet.gd")
const V121_DEFAULT_PLAYER_REVISION := 1
const PLAYER_PIXEL_SCALE := 0.5

var v121_player_texture: Texture2D

func _ready() -> void:
    v121_player_texture = DefaultPlayerSheet.load_texture()
    if v121_player_texture == null:
        push_error("HASH RACE PLAYER ASSET FAIL: default_player_sheet.png did not load")
    super._ready()
    set_meta("hashrace_v121_default_player_revision", V121_DEFAULT_PLAYER_REVISION)
    set_meta("hashrace_character_render_mode", "approved_32frame_original_colors")
    set_meta("hashrace_player_32frame_asset_live", v121_player_texture != null)
    queue_redraw()

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if not is_player:
        super._draw_tech_rep(pos, accent, scanner, is_player)
        return
    if v121_player_texture == null:
        return

    var moving := not rep_animation_state.ends_with("_idle")
    var frame := _v121_walk_frame(moving)
    var region := DefaultPlayerSheet.frame_region(rep_facing, frame)
    var foot := VisualStack.snap_to_pixel(pos + Vector2(0.0, 43.0))
    var dest := Rect2(
        VisualStack.snap_to_pixel(foot + (DefaultPlayerSheet.frame_offset(region) - Vector2(DefaultPlayerSheet.FOOT_ANCHOR)) * PLAYER_PIXEL_SCALE),
        Vector2(region.size) * PLAYER_PIXEL_SCALE
    )

    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 42.0)), 28.0, 8.0)
    draw_texture_rect_region(v121_player_texture, dest, Rect2(region))

func _v121_walk_frame(moving: bool) -> int:
    return DefaultPlayerSheet.walk_frame(moving, rep_step_phase)

func debug_v121_ready() -> bool:
    return V121_DEFAULT_PLAYER_REVISION == 1 and DefaultPlayerSheet.debug_ready() and v121_player_texture != null and debug_v120_ready()
