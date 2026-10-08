extends "res://scripts/world_v158.gd"

# Hash Race v0.159: promote the previously unused cable-tray cell from the
# electrical distribution source sheet into a real stationary live-world PNG.
# The live layer now also replaces v0.158's procedural facility bodies with an
# authored 3x3 pixel building sheet while preserving the numbered inheritance.
const V159_CABLE_TRAY_REVISION := 2
const V159_CABLE_TRAY_PATH := "res://art/electrical/cable_tray.png"
const V159_CABLE_TRAY_SHA256 := "e9cdcb9d3254793f8c299b75526441a90401eb30051ed67d8408048e1d8f9a96"
const FacilityBuildingSheet = preload("res://scripts/facility_building_sheet.gd")
const V166_FACILITY_SHEET: Texture2D = preload("res://art/buildings/facility_buildings_sheet.svg")
const V166_SPRITE_BUILDING_REVISION := 1
var v159_cable_tray_texture: Texture2D

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    v159_cable_tray_texture = _v128_load_texture(V159_CABLE_TRAY_PATH)
    super._ready()
    set_meta("hashrace_v159_cable_tray_live", v159_cable_tray_texture != null)
    set_meta("hashrace_v159_cable_tray_ground_footprint", Rect2(-47.0, -7.0, 94.0, 14.0))
    set_meta("hashrace_v166_sprite_buildings", debug_v166_sprite_buildings_ready())
    queue_redraw()

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)
    # Runtime proof from the first v0.159 head showed the tray directly beneath
    # an NPC. Keep the static sprite, but move it onto clear grass below the
    # distribution side so no character stands on the asset or its footprint.
    _v159_draw_cable_tray(origin + Vector2(20.0, 220.0))

func _v159_draw_cable_tray(center: Vector2) -> void:
    if v159_cable_tray_texture == null:
        return
    var size_value := Vector2(96.0, 96.0)
    var dest := Rect2(center - size_value * Vector2(0.5, 0.82), size_value)
    draw_ellipse_shadow(center + Vector2(0.0, 4.0), 45.0, 7.0)
    draw_texture_rect(v159_cable_tray_texture, dest, false)

# Replace the inherited rectangle/vent/door drawing with authored sprite frames.
# Entity positions, WorldScale collision sizes, selection radii, and interaction
# anchors remain inherited, so this is a visual replacement rather than a new
# placement system.
func _v158_draw_facility(entity: Dictionary, idx: int, accent: Color) -> void:
    var pos := Vector2(entity.get("pos", Vector2.ZERO))
    var kind := String(entity.get("kind", "partner"))
    var footprint := WorldScale.size_for_kind(kind)
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))

    var frame := FacilityBuildingSheet.frame_for(entity)
    var source := FacilityBuildingSheet.frame_rect(frame)
    var aspect := float(FacilityBuildingSheet.FRAME_SIZE.y) / float(FacilityBuildingSheet.FRAME_SIZE.x)
    var width := footprint.x * 0.92
    var height := width * aspect
    var max_height := footprint.y * 1.08
    if height > max_height:
        height = max_height
        width = height / aspect

    # Preserve v0.158's established building ground line so sprites sit exactly
    # where collision, doors, NPC representatives, and roads already expect them.
    var ground_y := pos.y + footprint.y * 0.38
    var dest := Rect2(
        VisualStack.snap_to_pixel(Vector2(pos.x - width * 0.5, ground_y - height)),
        Vector2(round(width), round(height))
    )

    # Ground the authored sprite with a compact service slab and soft foot shadow.
    # Do not reuse the inherited oversized polygon shadow/foundation: that visual
    # belonged to the old procedural rectangles and made the sprites look pasted
    # onto giant blocks.
    draw_ellipse_shadow(VisualStack.snap_to_pixel(Vector2(pos.x, ground_y + 2.0)), dest.size.x * 0.43, 7.0)
    var pad_width := dest.size.x * 0.88
    var pad := Rect2(
        VisualStack.snap_to_pixel(Vector2(pos.x - pad_width * 0.5, ground_y - 9.0)),
        Vector2(round(pad_width), 16.0)
    )
    draw_rect(pad, Color("465047b0"), true)
    draw_rect(Rect2(pad.position, Vector2(pad.size.x, 2.0)), Color("7a877b72"), true)
    for i in range(6):
        var px := pad.position.x + 8.0 + float(i) * maxf(10.0, (pad.size.x - 16.0) / 6.0)
        draw_rect(Rect2(Vector2(px, pad.end.y - 4.0), Vector2(3.0, 2.0)), Color("27342c88"), true)

    draw_texture_rect_region(V166_FACILITY_SHEET, dest, source)

    # Keep company identity without tinting or stretching the authored sprite.
    var marker_w := clampf(dest.size.x * 0.22, 34.0, 62.0)
    var marker := Rect2(Vector2(pos.x - marker_w * 0.5, ground_y - 7.0), Vector2(marker_w, 5.0))
    draw_rect(marker, accent.darkened(0.20), true)
    draw_rect(Rect2(marker.position, Vector2(marker.size.x, 2.0)), accent.lightened(0.18), true)

    _draw_building_name(entity, idx, accent, dest.size.y * 0.60 + 24.0, maxf(dest.size.x + 28.0, footprint.x + 28.0))

func debug_v166_sprite_buildings_ready() -> bool:
    return V166_SPRITE_BUILDING_REVISION == 1 \
        and FacilityBuildingSheet.valid_texture(V166_FACILITY_SHEET) \
        and FacilityBuildingSheet.frame_rect(FacilityBuildingSheet.FRAME_LAND_OFFICE).size == Vector2(160.0, 128.0)

func debug_v159_ready() -> bool:
    return V159_CABLE_TRAY_REVISION == 2 \
        and ResourceLoader.exists(V159_CABLE_TRAY_PATH) \
        and v159_cable_tray_texture != null \
        and v159_cable_tray_texture.get_width() == 128 \
        and v159_cable_tray_texture.get_height() == 128 \
        and debug_v158_ready()
