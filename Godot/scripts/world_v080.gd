extends "res://scripts/world_v073.gd"

# Hash Race v0.080 pixel-integration layer.
# Aligns buildings, character feet and camera motion to the same hard pixel grid.
# The live overworld remains procedural, so this pass removes interpolated
# facility gradients rather than applying a full-screen pixelation effect.

const V080_PIXEL_INTEGRATION_REVISION: int = 1
const V080_BUILDING_PIXEL: float = 4.0
const V080_PLAYER_FOOT_OFFSET: float = 44.0
const V080_BUILDING_FOOT_OFFSET: float = 40.0
const V080_WALL_DARK := Color("101820")
const V080_WALL_MID := Color("1c2a31")
const V080_WALL_LIGHT := Color("33434a")
const V080_WINDOW_DARK := Color("071018")
const V080_METAL := Color("718087")
const V080_METAL_HI := Color("a8b5ba")

func _ready() -> void:
    super._ready()
    if is_instance_valid(camera):
        # Camera smoothing creates sub-pixel interpolation even when draw calls
        # are snapped. Pixel art gets a whole-pixel camera instead.
        camera.position_smoothing_enabled = false
        camera.position = VisualStack.snap_to_pixel(rep_pos)
    set_meta("hashrace_pixel_integration_revision", V080_PIXEL_INTEGRATION_REVISION)
    set_meta("hashrace_building_pixel_grid", V080_BUILDING_PIXEL)
    queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)
    if is_instance_valid(camera):
        camera.position_smoothing_enabled = false
        camera.position = VisualStack.snap_to_pixel(rep_pos)

# -----------------------------------------------------------------------------
# Base-Y painter order.
# The world is still one procedural Node2D, so CanvasItem YSort cannot sort the
# individual draw commands. Sorting render entries by their ground contact gives
# the same visual rule: lower feet/base points draw later and therefore appear
# in front.
# -----------------------------------------------------------------------------

func _draw() -> void:
    _draw_pixel_tile_world()
    _draw_pixel_town_labels()
    _draw_world_props_pixel()

    var depth_items: Array[Dictionary] = []
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        depth_items.append({
            "kind": "entity",
            "index": i,
            "depth": _v080_entity_depth(entity)
        })
    depth_items.append({
        "kind": "player",
        "index": -1,
        "depth": rep_pos.y + V080_PLAYER_FOOT_OFFSET
    })
    depth_items.sort_custom(Callable(self, "_v080_depth_less"))

    for item in depth_items:
        if String(item["kind"]) == "player":
            _draw_rep()
        else:
            var idx: int = int(item["index"])
            _draw_entity(entities[idx], idx)

    if scanner_overlay_enabled:
        _draw_scanner_overlay()
    _draw_clean_navigation_path()
    _draw_direction_state()

func _v080_entity_depth(entity: Dictionary) -> float:
    var pos: Vector2 = entity.get("pos", Vector2.ZERO)
    var kind: String = String(entity.get("kind", ""))
    if kind == "partner_rep" or kind == "rival_rep":
        return pos.y + V080_PLAYER_FOOT_OFFSET
    match kind:
        "hq", "rival":
            return pos.y + 45.0
        "machines":
            return pos.y + 41.0
        "partner", "power", "bank":
            return pos.y + 40.0
        "land":
            return pos.y + 39.0
        _:
            return pos.y + V080_BUILDING_FOOT_OFFSET

func _v080_depth_less(a: Dictionary, b: Dictionary) -> bool:
    var ad: float = float(a["depth"])
    var bd: float = float(b["depth"])
    if is_equal_approx(ad, bd):
        # Stable deterministic ordering at equal depth.
        return int(a["index"]) < int(b["index"])
    return ad < bd

# -----------------------------------------------------------------------------
# Hard-palette facility renderer.
# Replaces the prior interpolated roof gradient with snapped block shading,
# stepped roof edges, 4px details and a restrained shared metal/window palette.
# -----------------------------------------------------------------------------

func _draw_pixel_facility(pos: Vector2, size_value: Vector2, accent: Color, floors: int, badge: String) -> void:
    var snapped_pos: Vector2 = _v080_snap(pos)
    var size_px: Vector2 = _v080_snap_size(size_value)
    var left: float = _v080_grid(snapped_pos.x - size_px.x * 0.5)
    var top: float = _v080_grid(snapped_pos.y - size_px.y * 0.62)
    var body := Rect2(Vector2(left, top), size_px)

    # Block shadow at the building's ground contact.
    var shadow_pos := _v080_snap(Vector2(
        snapped_pos.x - size_px.x * 0.46,
        snapped_pos.y + size_px.y * 0.43
    ))
    draw_rect(Rect2(shadow_pos, Vector2(_v080_grid(size_px.x * 0.92), 12.0)), Color("00000070"), true)

    # Main shell. Every edge lands on the same 4px source grid as the facade
    # details, so buildings read as authored pixel sprites rather than vectors.
    draw_rect(body, Color("020609"), true)
    var inner := Rect2(
        body.position + Vector2(V080_BUILDING_PIXEL, V080_BUILDING_PIXEL),
        body.size - Vector2(V080_BUILDING_PIXEL * 2.0, V080_BUILDING_PIXEL * 2.0)
    )
    draw_rect(inner, V080_WALL_MID, true)
    draw_rect(
        Rect2(inner.position, Vector2(12.0, inner.size.y)),
        V080_WALL_DARK,
        true
    )
    draw_rect(
        Rect2(Vector2(inner.position.x + inner.size.x - 12.0, inner.position.y), Vector2(12.0, inner.size.y)),
        V080_WALL_LIGHT,
        true
    )

    # Stepped roof cap: no interpolated vertex colors or antialiased diagonal.
    var roof_dark: Color = accent.darkened(0.55)
    var roof_mid: Color = accent.darkened(0.28)
    var roof_hi: Color = accent.lightened(0.08)
    draw_rect(Rect2(Vector2(left - 4.0, top - 8.0), Vector2(size_px.x + 8.0, 8.0)), Color("020609"), true)
    draw_rect(Rect2(Vector2(left, top - 4.0), Vector2(size_px.x, 12.0)), roof_dark, true)
    draw_rect(Rect2(Vector2(left + 8.0, top), Vector2(size_px.x - 16.0, 8.0)), roof_mid, true)
    draw_rect(Rect2(Vector2(left + 16.0, top), Vector2(maxf(8.0, size_px.x - 32.0), 4.0)), roof_hi, true)

    # Floor/window rhythm.
    var usable_h: float = maxf(32.0, size_px.y - 32.0)
    var floor_h: float = _v080_grid(usable_h / float(maxi(floors, 1)))
    floor_h = maxf(16.0, floor_h)
    var window_w: float = 16.0
    var window_h: float = 12.0
    var span: float = maxf(20.0, size_px.x - 32.0)
    var window_step: float = _v080_grid(span / 4.0)
    for floor_idx in range(maxi(floors, 1)):
        var fy: float = _v080_grid(top + 20.0 + float(floor_idx) * floor_h)
        for window_idx in range(4):
            var wx: float = _v080_grid(left + 16.0 + float(window_idx) * window_step)
            draw_rect(Rect2(Vector2(wx, fy), Vector2(window_w, window_h)), V080_WINDOW_DARK, true)
            draw_rect(Rect2(Vector2(wx + 4.0, fy + 4.0), Vector2(8.0, 4.0)), accent.darkened(0.16), true)

    # Door and service stripe.
    var door_h: float = _v080_grid(maxf(24.0, size_px.y * 0.28))
    var door_y: float = _v080_grid(top + size_px.y - door_h - 4.0)
    draw_rect(Rect2(Vector2(snapped_pos.x - 16.0, door_y), Vector2(32.0, door_h + 4.0)), Color("020609"), true)
    draw_rect(Rect2(Vector2(snapped_pos.x - 12.0, door_y + 4.0), Vector2(8.0, door_h - 4.0)), roof_dark, true)
    draw_rect(Rect2(Vector2(snapped_pos.x + 8.0, door_y + 8.0), Vector2(4.0, 4.0)), accent, true)
    draw_rect(Rect2(Vector2(left + 8.0, top + size_px.y - 16.0), Vector2(size_px.x - 16.0, 4.0)), roof_dark, true)

    # Rooftop mast uses square pixel blocks.
    var mast_x: float = _v080_grid(left + size_px.x * 0.76)
    draw_rect(Rect2(Vector2(mast_x, top - 32.0), Vector2(8.0, 28.0)), V080_METAL, true)
    draw_rect(Rect2(Vector2(mast_x - 8.0, top - 36.0), Vector2(24.0, 8.0)), Color("020609"), true)
    draw_rect(Rect2(Vector2(mast_x - 4.0, top - 32.0), Vector2(16.0, 4.0)), accent, true)

    if not badge.is_empty():
        var badge_rect := Rect2(Vector2(left + 8.0, top + 16.0), Vector2(44.0, 20.0))
        draw_rect(badge_rect, V080_WINDOW_DARK, true)
        draw_rect(Rect2(badge_rect.position + Vector2(4.0, 4.0), Vector2(36.0, 4.0)), roof_dark, true)
        draw_string(
            ThemeDB.fallback_font,
            Vector2(left + 12.0, top + 32.0),
            badge,
            HORIZONTAL_ALIGNMENT_LEFT,
            36.0,
            9,
            accent
        )

func _draw_facility_surface_detail(pos: Vector2, size_value: Vector2, accent: Color, seed: int) -> void:
    var snapped_pos: Vector2 = _v080_snap(pos)
    var size_px: Vector2 = _v080_snap_size(size_value)
    var left: float = _v080_grid(snapped_pos.x - size_px.x * 0.5)
    var top: float = _v080_grid(snapped_pos.y - size_px.y * 0.62)

    # Roof vents: 4px cells, hard two-tone metal.
    var vent_span: float = maxf(24.0, size_px.x - 48.0)
    for i in range(4):
        var x: float = _v080_grid(left + 20.0 + float(i) * vent_span / 4.0)
        draw_rect(Rect2(Vector2(x, top + 8.0), Vector2(12.0, 8.0)), V080_WALL_DARK, true)
        draw_rect(Rect2(Vector2(x + 4.0, top + 8.0), Vector2(8.0, 4.0)), V080_METAL, true)

    # Facade seams become 4px shadow bands rather than 1px vector lines.
    for i in range(3):
        var y: float = _v080_grid(top + 40.0 + float(i) * 20.0)
        if y < top + size_px.y - 20.0:
            draw_rect(Rect2(Vector2(left + 8.0, y), Vector2(size_px.x - 16.0, 4.0)), V080_WALL_DARK, true)

    var box_range: int = maxi(8, int(size_px.x - 48.0))
    var box_x: float = _v080_grid(left + 12.0 + float((seed * 23) % box_range))
    var box_y: float = _v080_grid(top + size_px.y - 28.0)
    draw_rect(Rect2(Vector2(box_x, box_y), Vector2(20.0, 16.0)), V080_WINDOW_DARK, true)
    draw_rect(Rect2(Vector2(box_x + 4.0, box_y + 4.0), Vector2(12.0, 4.0)), accent.darkened(0.12), true)
    draw_rect(Rect2(Vector2(box_x + 12.0, box_y + 8.0), Vector2(4.0, 4.0)), accent.lightened(0.12), true)

func _v080_grid(value: float) -> float:
    return roundf(value / V080_BUILDING_PIXEL) * V080_BUILDING_PIXEL

func _v080_snap(value: Vector2) -> Vector2:
    return Vector2(_v080_grid(value.x), _v080_grid(value.y))

func _v080_snap_size(value: Vector2) -> Vector2:
    return Vector2(
        maxf(V080_BUILDING_PIXEL, _v080_grid(value.x)),
        maxf(V080_BUILDING_PIXEL, _v080_grid(value.y))
    )

func debug_pixel_integration_ready() -> bool:
    return (
        V080_PIXEL_INTEGRATION_REVISION >= 1
        and V080_BUILDING_PIXEL == 4.0
        and is_instance_valid(camera)
        and not camera.position_smoothing_enabled
    )

func debug_v080_ready() -> bool:
    return debug_v073_ready() and debug_pixel_integration_ready()
