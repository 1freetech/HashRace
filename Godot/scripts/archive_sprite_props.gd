extends Node2D
class_name HashRaceArchiveSpriteProps

# Promoted reference sprites are support props, but they must still read at the
# live overworld camera scale.  Cells are cleaned/cropped at runtime, then fit
# into a practical map footprint instead of being blindly crushed to 32 px.
const LIVE_PROP_TARGET_HEIGHT_PX := 52.0
const LIVE_PROP_MAX_WIDTH_PX := 68.0
const LIVE_PROP_MIN_WIDTH_PX := 30.0
const LIVE_PROP_COLLISION_HEIGHT := 12.0
const LIVE_PROP_SPACING_PX := 80.0
const BACKGROUND_ALPHA_EPSILON := 0.04
const BACKGROUND_CHROMA_LIMIT := 0.12
const BACKGROUND_LOCAL_DELTA := 0.10
const BACKGROUND_REFERENCE_LUMA_DELTA := 0.34

const SHEETS = [
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_ats_handhole_bollards_96x32.png","cell":32,"names":["ats","handhole","bollards"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_cooling_electrical_energy_96x32.png","cell":32,"names":["cooling_unit","electrical_unit","energy_unit"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_harmonicfilter_bench_lightning_192x64.png","cell":64,"names":["harmonic_filter","bench","lightning_protection"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_loadbank_eyewash_cablereel_96x32.png","cell":32,"names":["load_bank","eyewash","cable_reel"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_mv_hydrant_truckscale_96x32.png","cell":32,"names":["mv_equipment","hydrant","truck_scale"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_mvtermination_diag_weather_96x32.png","cell":32,"names":["mv_termination","diagnostic_station","weather_station"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_power_cooling_washdown_96x32.png","cell":32,"names":["power_service","cooling_service","washdown_station"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_pump_salt_trench_96x32.png","cell":32,"names":["pump","salt_storage","trench"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_security_firewall_cctv_oilwater_96x32.png","cell":32,"names":["security_firewall","cctv","oil_water_separator"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_statcom_fiberped_gate_96x32.png","cell":32,"names":["statcom","fiber_pedestal","gate_control"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_telecom_air_drain_192x64.png","cell":64,"names":["telecom","compressed_air","drain"]},
]

const CLUSTER_ANCHORS = [
    Vector2i(400, 700), Vector2i(730, 700), Vector2i(1060, 700), Vector2i(1390, 700),
    Vector2i(400, 820), Vector2i(730, 820), Vector2i(1060, 820), Vector2i(1390, 820),
    Vector2i(400, 940), Vector2i(730, 940), Vector2i(1060, 940),
]

const NONBLOCKING = {
    "handhole": true,
    "bench": true,
    "eyewash": true,
    "hydrant": true,
    "weather_station": true,
    "cctv": true,
    "drain": true,
}

var live_sprites: Array[Sprite2D] = []
var collision_footprints: Array[Rect2] = []
var loaded_sheet_count: int = 0
var cleaned_cell_count: int = 0

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    y_sort_enabled = true
    _build_props()
    call_deferred("_connect_navigation_refresh")

func _build_props() -> void:
    for sheet_index in range(SHEETS.size()):
        var spec: Dictionary = SHEETS[sheet_index]
        var texture: Texture2D = load(String(spec["path"])) as Texture2D
        if texture == null:
            push_error("HashRaceArchiveSpriteProps: could not load %s" % String(spec["path"]))
            continue
        var atlas_image := texture.get_image()
        if atlas_image == null or atlas_image.is_empty():
            push_error("HashRaceArchiveSpriteProps: could not read %s" % String(spec["path"]))
            continue
        atlas_image.convert(Image.FORMAT_RGBA8)
        loaded_sheet_count += 1
        var cell: int = int(spec["cell"])
        var names: Array = Array(spec["names"])
        for cell_index in range(names.size()):
            var region_rect := Rect2i(cell_index * cell, 0, cell, cell)
            var cell_image := atlas_image.get_region(region_rect)
            var prepared := _prepare_cell_image(cell_image)
            var cell_texture := ImageTexture.create_from_image(prepared)

            var sprite := Sprite2D.new()
            sprite.name = "ArchiveProp_%s" % String(names[cell_index]).to_pascal_case()
            sprite.texture = cell_texture
            sprite.centered = true
            var scale_factor := _display_scale_for(prepared.get_size())
            sprite.scale = Vector2.ONE * scale_factor
            # Position is the ground contact.  Cropping transparent/background
            # pixels first keeps the visible bottom edge pinned to that point.
            sprite.offset = Vector2(0.0, -float(prepared.get_height()) * 0.5)
            sprite.position = _ground_position(sheet_index, cell_index)
            sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            sprite.set_meta("hashrace_archive_sheet", String(spec["path"]))
            sprite.set_meta("hashrace_archive_cell", cell_index)
            sprite.set_meta("hashrace_source_cell_px", cell)
            sprite.set_meta("hashrace_prepared_size", prepared.get_size())
            sprite.set_meta("hashrace_live_display_height_px", float(prepared.get_height()) * scale_factor)
            add_child(sprite)
            live_sprites.append(sprite)

            var prop_name: String = String(names[cell_index])
            if not NONBLOCKING.has(prop_name):
                var display_width := float(prepared.get_width()) * scale_factor
                var collision_width := clampf(display_width * 0.72, 28.0, 56.0)
                collision_footprints.append(Rect2(
                    sprite.position.x - collision_width * 0.5,
                    sprite.position.y - LIVE_PROP_COLLISION_HEIGHT,
                    collision_width,
                    LIVE_PROP_COLLISION_HEIGHT
                ))

func _prepare_cell_image(source: Image) -> Image:
    var image := source.duplicate()
    image.convert(Image.FORMAT_RGBA8)
    if _has_opaque_neutral_corner_background(image):
        _clear_connected_neutral_background(image)
        cleaned_cell_count += 1
    var bounds := _visible_bounds(image)
    if bounds.size.x <= 0 or bounds.size.y <= 0:
        return image
    # Keep one source pixel of breathing room when available so outlines are not
    # shaved by an exact alpha-bound crop.
    var left := maxi(0, bounds.position.x - 1)
    var top := maxi(0, bounds.position.y - 1)
    var right := mini(image.get_width(), bounds.end.x + 1)
    var bottom := mini(image.get_height(), bounds.end.y + 1)
    return image.get_region(Rect2i(left, top, right - left, bottom - top))

func _has_opaque_neutral_corner_background(image: Image) -> bool:
    if image.is_empty():
        return false
    var w := image.get_width()
    var h := image.get_height()
    var corners := [
        Vector2i(0, 0), Vector2i(w - 1, 0),
        Vector2i(0, h - 1), Vector2i(w - 1, h - 1),
    ]
    var opaque_neutral := 0
    for point in corners:
        var color := image.get_pixel(point.x, point.y)
        if color.a >= 0.90 and _chroma(color) <= BACKGROUND_CHROMA_LIMIT:
            opaque_neutral += 1
    return opaque_neutral >= 3

func _clear_connected_neutral_background(image: Image) -> void:
    var w := image.get_width()
    var h := image.get_height()
    if w <= 0 or h <= 0:
        return
    var reference := _corner_reference_color(image)
    var reference_luma := _luma(reference)
    var visited := PackedByteArray()
    visited.resize(w * h)
    var queue: Array[Vector2i] = []
    var seeds := [
        Vector2i(0, 0), Vector2i(w - 1, 0),
        Vector2i(0, h - 1), Vector2i(w - 1, h - 1),
    ]
    for seed in seeds:
        var index := seed.y * w + seed.x
        if visited[index] == 0:
            visited[index] = 1
            queue.append(seed)

    var cursor := 0
    while cursor < queue.size():
        var point := queue[cursor]
        cursor += 1
        var current := image.get_pixel(point.x, point.y)
        if not _is_background_pixel(current, reference_luma):
            continue
        image.set_pixel(point.x, point.y, Color(current.r, current.g, current.b, 0.0))
        for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var neighbor := point + direction
            if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= w or neighbor.y >= h:
                continue
            var neighbor_index := neighbor.y * w + neighbor.x
            if visited[neighbor_index] != 0:
                continue
            var candidate := image.get_pixel(neighbor.x, neighbor.y)
            visited[neighbor_index] = 1
            if candidate.a <= BACKGROUND_ALPHA_EPSILON:
                queue.append(neighbor)
                continue
            if _chroma(candidate) > BACKGROUND_CHROMA_LIMIT:
                continue
            if absf(_luma(candidate) - reference_luma) > BACKGROUND_REFERENCE_LUMA_DELTA:
                continue
            if _color_delta(current, candidate) <= BACKGROUND_LOCAL_DELTA:
                queue.append(neighbor)

func _corner_reference_color(image: Image) -> Color:
    var w := image.get_width()
    var h := image.get_height()
    var corners := [
        image.get_pixel(0, 0), image.get_pixel(w - 1, 0),
        image.get_pixel(0, h - 1), image.get_pixel(w - 1, h - 1),
    ]
    var total := Color(0.0, 0.0, 0.0, 0.0)
    var count := 0.0
    for color in corners:
        if color.a >= 0.90 and _chroma(color) <= BACKGROUND_CHROMA_LIMIT:
            total += color
            count += 1.0
    return total / count if count > 0.0 else Color(0.5, 0.5, 0.5, 1.0)

func _is_background_pixel(color: Color, reference_luma: float) -> bool:
    if color.a <= BACKGROUND_ALPHA_EPSILON:
        return true
    return color.a >= 0.90 \
        and _chroma(color) <= BACKGROUND_CHROMA_LIMIT \
        and absf(_luma(color) - reference_luma) <= BACKGROUND_REFERENCE_LUMA_DELTA

func _visible_bounds(image: Image) -> Rect2i:
    var min_x := image.get_width()
    var min_y := image.get_height()
    var max_x := -1
    var max_y := -1
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            if image.get_pixel(x, y).a <= BACKGROUND_ALPHA_EPSILON:
                continue
            min_x = mini(min_x, x)
            min_y = mini(min_y, y)
            max_x = maxi(max_x, x)
            max_y = maxi(max_y, y)
    if max_x < min_x or max_y < min_y:
        return Rect2i()
    return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _display_scale_for(size: Vector2i) -> float:
    if size.x <= 0 or size.y <= 0:
        return 1.0
    var height_scale := LIVE_PROP_TARGET_HEIGHT_PX / float(size.y)
    var width_scale := LIVE_PROP_MAX_WIDTH_PX / float(size.x)
    var scale_factor := minf(height_scale, width_scale)
    var projected_width := float(size.x) * scale_factor
    if projected_width < LIVE_PROP_MIN_WIDTH_PX:
        scale_factor = minf(LIVE_PROP_MAX_WIDTH_PX / float(size.x), LIVE_PROP_MIN_WIDTH_PX / float(size.x))
    return scale_factor

func _chroma(color: Color) -> float:
    return maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b))

func _luma(color: Color) -> float:
    return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722

func _color_delta(a: Color, b: Color) -> float:
    return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))

func _ground_position(sheet_index: int, cell_index: int) -> Vector2:
    var anchor: Vector2i = CLUSTER_ANCHORS[sheet_index]
    return Vector2(float(anchor.x) + float(cell_index - 1) * LIVE_PROP_SPACING_PX, float(anchor.y))

func _connect_navigation_refresh() -> void:
    var host: Node = get_parent()
    if host == null:
        return
    var inventory: Variant = host.get("infrastructure_inventory")
    var inventory_object: Object = inventory as Object
    if inventory_object != null and inventory_object.has_signal("deployment_changed"):
        var callback := Callable(self, "_register_navigation")
        if not inventory_object.is_connected("deployment_changed", callback):
            inventory_object.connect("deployment_changed", callback, CONNECT_DEFERRED)
    _register_navigation()

func _register_navigation() -> void:
    var host: Node = get_parent()
    if host == null:
        return
    var navigation: Variant = host.get("grid_nav")
    if navigation == null or not navigation.has_method("block_rect"):
        return
    for footprint in collision_footprints:
        navigation.call("block_rect", footprint)

func live_sprite_count() -> int:
    return live_sprites.size()

func live_sheet_count() -> int:
    return loaded_sheet_count

func debug_ready() -> bool:
    if loaded_sheet_count != SHEETS.size() or live_sprites.size() != 33:
        return false
    if collision_footprints.size() < 20:
        return false
    for sprite in live_sprites:
        if sprite == null or sprite.texture == null or sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
            return false
        var displayed_size := sprite.texture.get_size() * sprite.scale
        if displayed_size.x > LIVE_PROP_MAX_WIDTH_PX + 1.0:
            return false
        if displayed_size.y > LIVE_PROP_TARGET_HEIGHT_PX + 1.0:
            return false
        if displayed_size.x < 18.0 or displayed_size.y < 18.0:
            return false
    return true
