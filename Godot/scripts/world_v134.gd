extends "res://scripts/world_v133.gd"

# Hash Race v0.134: semiconductor-fab readability pass.
# Keep the existing FoundryWorks Silicon position, but render the authored fab
# larger and unobstructed. No decorative doors, props, or overlays are added.

const V134_FAB_SCALE_REVISION := 1
const V134_FAB_SCALE := 1.22

func _draw_partner_building(entity: Dictionary, idx: int) -> void:
    var partner_idx := int(entity.get("partner_idx", -1))
    if partner_idx != 3 or v116_fab_texture == null:
        super._draw_partner_building(entity, idx)
        return

    var pos: Vector2 = entity["pos"]
    var accent: Color = PARTNER_ACCENTS[partner_idx]
    var base_size := _v103_visual_size(pos, WorldScale.PARTNER_SIZE, "partner")
    var size_value := base_size * V134_FAB_SCALE
    _selection_ring(pos, idx, WorldScale.selection_radius("partner") * V134_FAB_SCALE)
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
    _draw_building_name(entity, idx, accent, size_value.y * 0.39 + 34.0, size_value.x + 34.0)

func debug_v134_ready() -> bool:
    return V134_FAB_SCALE_REVISION == 1 \
        and V134_FAB_SCALE > 1.0 \
        and V134_FAB_SCALE <= 1.30 \
        and debug_v133_ready()
