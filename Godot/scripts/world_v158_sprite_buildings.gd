extends "res://scripts/world_v158.gd"

# Sprite-building bridge inserted between v0.158 and the later proven gameplay
# layers. Simulation placement, collision, door/interaction points, and entity
# kinds remain inherited; only the facility body renderer is replaced.
const FacilityBuildingSheet = preload("res://scripts/facility_building_sheet.gd")
const V166_FACILITY_SHEET: Texture2D = preload("res://art/buildings/facility_buildings_sheet.png")
const V166_SPRITE_BUILDING_REVISION := 1

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    super._ready()
    set_meta("hashrace_v166_sprite_buildings", debug_v166_sprite_buildings_ready())
    queue_redraw()

func _v158_draw_facility(entity: Dictionary, idx: int, accent: Color) -> void:
    var pos := Vector2(entity.get("pos", Vector2.ZERO))
    var kind := String(entity.get("kind", "partner"))
    var footprint := WorldScale.size_for_kind(kind)
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))

    var frame := FacilityBuildingSheet.frame_for(entity)
    var source := FacilityBuildingSheet.frame_rect(frame)
    var aspect := float(FacilityBuildingSheet.FRAME_SIZE.y) / float(FacilityBuildingSheet.FRAME_SIZE.x)

    # Use the logical collision footprint as the scale reference, but preserve
    # the authored 160:128 sprite aspect ratio instead of stretching the art.
    var width := footprint.x * 0.92
    var height := width * aspect
    var max_height := footprint.y * 1.08
    if height > max_height:
        height = max_height
        width = height / aspect

    # v0.158's collision/body contract places the front ground line at +38% of
    # the entity footprint. Anchor every authored sprite to that same baseline.
    var ground_y := pos.y + footprint.y * 0.38
    var dest := Rect2(
        VisualStack.snap_to_pixel(Vector2(pos.x - width * 0.5, ground_y - height)),
        Vector2(round(width), round(height))
    )

    # Compact service pad replaces the old full-height procedural rectangle.
    # It also makes each facility feel planted in the campus rather than pasted
    # on top of grass while leaving the existing road graph untouched.
    var pad := Rect2(
        Vector2(dest.position.x - 9.0, ground_y - height * 0.18),
        Vector2(dest.size.x + 18.0, height * 0.24 + 13.0)
    )
    draw_rect(pad, Color("424b43b8"), true)
    draw_rect(pad, Color("74807178"), false, 1.0)
    for i in range(7):
        var px := pad.position.x + 10.0 + float(i) * maxf(12.0, (pad.size.x - 20.0) / 7.0)
        var py := pad.end.y - 5.0 + float((i * 3) % 3)
        draw_rect(Rect2(Vector2(px, py), Vector2(3.0, 2.0)), Color("27342c99"), true)

    # Keep the proven cast-shadow language, now sized to the authored sprite.
    _v103_draw_building_shadow(pos, Vector2(dest.size.x, minf(dest.size.y, footprint.y)))
    draw_texture_rect_region(V166_FACILITY_SHEET, dest, source)

    # Company/role identity remains visible without recoloring the artwork.
    var marker_w := clampf(dest.size.x * 0.22, 34.0, 62.0)
    var marker := Rect2(Vector2(pos.x - marker_w * 0.5, ground_y - 7.0), Vector2(marker_w, 5.0))
    draw_rect(marker, accent.darkened(0.20), true)
    draw_rect(Rect2(marker.position, Vector2(marker.size.x, 2.0)), accent.lightened(0.18), true)

    _draw_building_name(entity, idx, accent, dest.size.y * 0.60 + 24.0, maxf(dest.size.x + 28.0, footprint.x + 28.0))

func debug_v166_sprite_buildings_ready() -> bool:
    return V166_SPRITE_BUILDING_REVISION == 1 \
        and FacilityBuildingSheet.valid_texture(V166_FACILITY_SHEET) \
        and FacilityBuildingSheet.frame_rect(FacilityBuildingSheet.FRAME_LAND_OFFICE).size == Vector2(160.0, 128.0)
