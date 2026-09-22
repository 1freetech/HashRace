extends "res://scripts/world_v144.gd"

# v0.145 replaces block-drawn stationary representatives with a real,
# transparent four-direction miner atlas derived from the Library source.

const NpcMinerSheet = preload("res://scripts/npc_miner_sprite_sheet.gd")
const V145_NPC_MINER_REVISION := 1

var v145_npc_miner_texture: Texture2D
var v145_debug_npc_facing := ""
var v145_debug_npc_frame := -1

func _ready() -> void:
    v145_npc_miner_texture = NpcMinerSheet.load_texture()
    if v145_npc_miner_texture == null:
        push_error("HASH RACE NPC MINER ASSET FAIL: npc_miner_sheet.png did not load")
    super._ready()
    set_meta("hashrace_v145_npc_miner_revision", V145_NPC_MINER_REVISION)
    set_meta("hashrace_npc_miner_asset_live", v145_npc_miner_texture != null)
    queue_redraw()

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if is_player:
        super._draw_tech_rep(pos, accent, scanner, true)
        return
    if v145_npc_miner_texture == null:
        return
    var facing := v145_debug_npc_facing if NpcMinerSheet.ROWS.has(v145_debug_npc_facing) else _v073_npc_facing(pos, _v073_seed(pos, accent))
    var frame := clampi(v145_debug_npc_frame, 0, 3) if v145_debug_npc_frame >= 0 else 0
    var region := NpcMinerSheet.frame_region(facing, frame)
    var foot := VisualStack.snap_to_pixel(pos + Vector2(0.0, 39.0))
    var destination := Rect2(foot - Vector2(NpcMinerSheet.FOOT_ANCHOR), Vector2(NpcMinerSheet.FRAME_SIZE))
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 38.0)), 25.0, 7.0)
    draw_texture_rect_region(v145_npc_miner_texture, destination, Rect2(region))

func debug_v145_ready() -> bool:
    return V145_NPC_MINER_REVISION == 1 and NpcMinerSheet.debug_ready() \
        and v145_npc_miner_texture != null and debug_v144_ready()
