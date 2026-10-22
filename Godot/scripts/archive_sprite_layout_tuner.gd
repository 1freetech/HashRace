extends Node2D
class_name HashRaceArchiveSpriteLayoutTuner

# Keep every promoted sprite-sheet object in the live world, but stop presenting
# them as a rigid proof grid. This helper runs after ArchiveSpriteProps builds its
# 33 Sprite2D children, applies authored relative scale, hand-places them into
# functional campus service zones, and rebuilds navigation from the final ground
# contacts. The source PNGs and archive-sprite renderer remain untouched.

# Two service verges flank the road. Each original three-cell sheet is now a
# compact functional equipment station, with clear grass gaps between stations
# instead of 33 evenly spaced props reading as an inventory strip.
const UPPER_CLUSTER_COUNT := 5
const LOWER_CLUSTER_COUNT := 6
const UPPER_GROUND_Y := 572.0
const LOWER_GROUND_Y := 1048.0
const CLUSTER_ITEM_GAP := 18.0
const CLUSTER_STATION_GAP := 36.0
const WORLD_LAYOUT_WIDTH := 1800.0

# The archive renderer deliberately gives every crop enough pixels to be legible.
# These multipliers then restore relative real-world hierarchy: access/safety
# details stay visible without reading as the same physical size as switchgear.
const SCALE_BY_NODE := {
    "ArchiveProp_Handhole": 0.72,
    "ArchiveProp_Bollards": 0.78,
    "ArchiveProp_Bench": 0.78,
    "ArchiveProp_Eyewash": 0.76,
    "ArchiveProp_CableReel": 0.82,
    "ArchiveProp_Hydrant": 0.82,
    "ArchiveProp_WeatherStation": 0.84,
    "ArchiveProp_Cctv": 0.76,
    "ArchiveProp_FiberPedestal": 0.80,
    "ArchiveProp_GateControl": 0.86,
    "ArchiveProp_Drain": 0.76,
    "ArchiveProp_Trench": 0.82,
    "ArchiveProp_DiagnosticStation": 0.90,
    "ArchiveProp_WashdownStation": 0.90,
    "ArchiveProp_CompressedAir": 0.94,
    "ArchiveProp_Telecom": 0.94,
}
const LAYOUT_PIXEL_GRID_REVISION := 3

const NONBLOCKING_NODES := {
    "ArchiveProp_Handhole": true,
    "ArchiveProp_Bench": true,
    "ArchiveProp_Eyewash": true,
    "ArchiveProp_Hydrant": true,
    "ArchiveProp_WeatherStation": true,
    "ArchiveProp_Cctv": true,
    "ArchiveProp_Drain": true,
}

var service_pad_rects: Array[Rect2] = []

# Small semi-transparent gravel/concrete islands keep equipment grounded without
# reading like giant proof rectangles or visually painting over nearby buildings.
# Gaps preserve the authored grass texture and make the infrastructure feel placed
# into the campus rather than laid on top of it.
func _ready() -> void:
    # Keep the pads at normal canvas depth. ArchiveSpriteProps is created after
    # the root world draw, and its y-sorted children then render equipment over
    # these pads. A negative z-index hid the pads behind the terrain.
    z_index = 0
    call_deferred("_apply_layout")
    queue_redraw()

func _draw() -> void:
    for rect in service_pad_rects:
        draw_rect(rect, Color("66746070"))
        draw_rect(rect, Color("8a968188"), false, 1.0)

func _apply_layout() -> void:
    var props := get_parent()
    if props == null:
        return
    var sprites_value: Variant = props.get("live_sprites")
    if not sprites_value is Array:
        return
    var sprites: Array = sprites_value
    if sprites.is_empty():
        return

    var groups: Array[Array] = []
    groups.resize(11)
    for index in range(groups.size()):
        groups[index] = []

    for item in sprites:
        var sprite := item as Sprite2D
        if sprite == null:
            continue
        var node_name := String(sprite.name)
        var scale_multiplier := float(SCALE_BY_NODE.get(node_name, 1.0))
        if not is_equal_approx(scale_multiplier, 1.0):
            _resize_sprite_nearest(sprite, scale_multiplier)
        sprite.scale = Vector2.ONE
        sprite.set_meta("hashrace_layout_scale_multiplier", scale_multiplier)
        sprite.set_meta("hashrace_layout_tuned", true)
        sprite.set_meta("hashrace_layout_pixel_grid_revision", LAYOUT_PIXEL_GRID_REVISION)
        var sheet_index := int(sprite.get_meta("hashrace_archive_sheet_index", -1))
        if sheet_index >= 0 and sheet_index < groups.size():
            groups[sheet_index].append(sprite)

    service_pad_rects.clear()
    _position_cluster_row(groups, 0, UPPER_CLUSTER_COUNT, UPPER_GROUND_Y)
    _position_cluster_row(groups, UPPER_CLUSTER_COUNT, LOWER_CLUSTER_COUNT, LOWER_GROUND_Y)
    queue_redraw()

    _rebuild_collision_footprints(props, sprites)

func _position_cluster_row(groups: Array, first_index: int, count: int, ground_y: float) -> void:
    var widths: Array[float] = []
    var widths_total := 0.0
    for offset in range(count):
        var width := _functional_cluster_width(groups[first_index + offset])
        widths.append(width)
        widths_total += width
    var station_gap := CLUSTER_STATION_GAP
    if count > 1 and widths_total + station_gap * float(count - 1) > WORLD_LAYOUT_WIDTH - 96.0:
        station_gap = maxf(10.0, (WORLD_LAYOUT_WIDTH - 96.0 - widths_total) / float(count - 1))
    var row_width := widths_total + station_gap * float(maxi(0, count - 1))
    var cursor_x := (WORLD_LAYOUT_WIDTH - row_width) * 0.5
    for offset in range(count):
        var group_width: float = widths[offset]
        var center_x := cursor_x + group_width * 0.5
        _position_functional_cluster(groups[first_index + offset], center_x, ground_y)
        cursor_x += group_width + station_gap

func _functional_cluster_width(group: Array) -> float:
    var width := 0.0
    for item in group:
        var sprite := item as Sprite2D
        if sprite != null and sprite.texture != null:
            width += float(sprite.texture.get_width())
    return width + CLUSTER_ITEM_GAP * float(maxi(0, group.size() - 1))

func _position_functional_cluster(group: Array, center_x: float, ground_y: float) -> void:
    var total_width := _functional_cluster_width(group)
    var cursor_x := center_x - total_width * 0.5
    for item in group:
        var sprite := item as Sprite2D
        if sprite == null or sprite.texture == null:
            continue
        var width := float(sprite.texture.get_width())
        sprite.position = Vector2(roundf(cursor_x + width * 0.5), ground_y)
        cursor_x += width + CLUSTER_ITEM_GAP

func _resize_sprite_nearest(sprite: Sprite2D, scale_multiplier: float) -> void:
    if sprite.texture == null or scale_multiplier <= 0.0:
        return
    var source: Image = sprite.texture.get_image()
    if source == null or source.is_empty():
        return
    var target := Vector2i(
        maxi(1, roundi(float(source.get_width()) * scale_multiplier)),
        maxi(1, roundi(float(source.get_height()) * scale_multiplier))
    )
    source.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
    sprite.texture = ImageTexture.create_from_image(source)
    # Every layout scale is applied around the existing foot anchor.
    sprite.offset = Vector2(0.0, -float(target.y) * 0.5)
    sprite.set_meta("hashrace_pixel_grid_size", target)
    sprite.set_meta("hashrace_live_display_height_px", float(target.y))

func debug_ready() -> bool:
    var props := get_parent()
    if props == null:
        return false
    var sprites_value: Variant = props.get("live_sprites")
    if not sprites_value is Array or sprites_value.size() != 33:
        return false
    var sprites: Array = sprites_value
    for index in range(sprites.size()):
        var a := sprites[index] as Sprite2D
        if a == null or a.texture == null or a.scale != Vector2.ONE:
            return false
        if a.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
            return false
        if int(a.get_meta("hashrace_layout_pixel_grid_revision", 0)) != LAYOUT_PIXEL_GRID_REVISION:
            return false
        var bounds_a := Rect2(
            a.position.x - float(a.texture.get_width()) * 0.5,
            a.position.y - float(a.texture.get_height()),
            float(a.texture.get_width()),
            float(a.texture.get_height())
        )
        for other_index in range(index + 1, sprites.size()):
            var b := sprites[other_index] as Sprite2D
            if b == null or b.texture == null:
                return false
            var bounds_b := Rect2(
                b.position.x - float(b.texture.get_width()) * 0.5,
                b.position.y - float(b.texture.get_height()),
                float(b.texture.get_width()),
                float(b.texture.get_height())
            )
            if bounds_a.intersects(bounds_b, true):
                return false
    return true

func _rebuild_collision_footprints(props: Node, sprites: Array) -> void:
    var footprints: Array[Rect2] = []
    for item in sprites:
        var sprite := item as Sprite2D
        if sprite == null or sprite.texture == null:
            continue
        var node_name := String(sprite.name)
        if NONBLOCKING_NODES.has(node_name):
            continue
        var displayed_size := sprite.texture.get_size() * sprite.scale
        var collision_width := clampf(displayed_size.x * 0.62, 24.0, 64.0)
        var collision_height := clampf(displayed_size.y * 0.16, 10.0, 16.0)
        footprints.append(Rect2(
            sprite.position.x - collision_width * 0.5,
            sprite.position.y - collision_height,
            collision_width,
            collision_height
        ))
    props.set("collision_footprints", footprints)
