extends "res://scripts/world_v146.gd"

# v0.147 ports the validated transparent four-direction NPC miner atlas onto
# the current v0.146 live world without replacing the field-control layers.

const NpcMinerSheetV147 = preload("res://scripts/npc_miner_sprite_sheet.gd")
const V147_NPC_MINER_REVISION := 1

var v147_npc_miner_texture: Texture2D
var v147_debug_npc_facing := ""
var v147_debug_npc_frame := -1

func _ready() -> void:
    v147_npc_miner_texture = NpcMinerSheetV147.load_texture()
    if v147_npc_miner_texture == null:
        push_error("HASH RACE NPC MINER ASSET FAIL: npc_miner_sheet.png did not load")
    super._ready()
    set_meta("hashrace_v147_npc_miner_revision", V147_NPC_MINER_REVISION)
    set_meta("hashrace_npc_miner_asset_live", v147_npc_miner_texture != null)
    queue_redraw()

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if is_player:
        super._draw_tech_rep(pos, accent, scanner, true)
        return
    if v147_npc_miner_texture == null:
        return
    var facing := v147_debug_npc_facing if NpcMinerSheetV147.ROWS.has(v147_debug_npc_facing) else _v073_npc_facing(pos, _v073_seed(pos, accent))
    var frame := clampi(v147_debug_npc_frame, 0, 3) if v147_debug_npc_frame >= 0 else 0
    var region := NpcMinerSheetV147.frame_region(facing, frame)
    var foot := VisualStack.snap_to_pixel(pos + Vector2(0.0, 39.0))
    var destination := Rect2(foot - Vector2(NpcMinerSheetV147.FOOT_ANCHOR), Vector2(NpcMinerSheetV147.FRAME_SIZE))
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 38.0)), 25.0, 7.0)
    draw_texture_rect_region(v147_npc_miner_texture, destination, Rect2(region))

func debug_v147_ready() -> bool:
    return V147_NPC_MINER_REVISION == 1 and NpcMinerSheetV147.debug_ready() \
        and v147_npc_miner_texture != null and debug_v146_ready()
