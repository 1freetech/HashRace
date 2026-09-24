extends "res://scripts/world_v115.gd"

# Hash Race v0.116 exact semiconductor-fab asset integration.
# The uploaded Hash Race semiconductor-fab sheet is materialized as a real JPEG
# in the Godot project and the live FoundryWorks Silicon partner building draws
# directly from that exact repository file. The sheet is a 2x2 orientation grid:
# UP, DOWN, LEFT, RIGHT. Stationary building frontage uses DOWN.

const V116_FAB_ASSET_REVISION := 1
const V116_FAB_PATH := "res://assets/imported/v115/semiconductor_fab.jpg"
const V116_FAB_GRID := Vector2i(2, 2)
const V116_FAB_DOWN_FRAME := Vector2i(1, 0)

var v116_fab_texture: Texture2D

func _ready() -> void:
    v116_fab_texture = load(V116_FAB_PATH) as Texture2D if ResourceLoader.exists(V116_FAB_PATH) else null
    super._ready()
    set_meta("hashrace_v116_fab_asset_revision", V116_FAB_ASSET_REVISION)
    set_meta("hashrace_v116_fab_loaded", v116_fab_texture != null)
    queue_redraw()

func _draw_partner_building(entity: Dictionary, idx: int) -> void:
    var partner_idx := int(entity.get("partner_idx", -1))
    if partner_idx != 3 or v116_fab_texture == null:
        super._draw_partner_building(entity, idx)
        return

    var pos: Vector2 = entity["pos"]
    var accent: Color = PARTNER_ACCENTS[partner_idx]
    var size_value := _v103_visual_size(pos, WorldScale.PARTNER_SIZE, "partner")
    _selection_ring(pos, idx, WorldScale.selection_radius("partner"))
    _v103_draw_building_shadow(pos, size_value)

    var cell := Vector2(
        float(v116_fab_texture.get_width()) / float(V116_FAB_GRID.x),
        float(v116_fab_texture.get_height()) / float(V116_FAB_GRID.y)
    )
    var src := Rect2(
        Vector2(float(V116_FAB_DOWN_FRAME.x) * cell.x, float(V116_FAB_DOWN_FRAME.y) * cell.y),
        cell
    )
    var dest := Rect2(
        VisualStack.snap_to_pixel(pos + Vector2(-size_value.x * 0.5, -size_value.y * 0.62)),
        size_value
    )
    draw_texture_rect_region(v116_fab_texture, dest, src)
    _draw_v088_entry_cue("partner", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.39 + 34.0, size_value.x + 34.0)

func debug_v116_ready() -> bool:
    return V116_FAB_ASSET_REVISION == 1         and V116_FAB_PATH.ends_with(".jpg")         and V116_FAB_GRID == Vector2i(2, 2)         and V116_FAB_DOWN_FRAME == Vector2i(1, 0)         and debug_v115_ready()
