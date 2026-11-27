extends Node2D
## Isolated rendering experiment. It never changes campaign state or assets.
## Q/E rotate objects; arrows move the ground marker; Space toggles stacking.
## All sheet pixels are original procedural placeholders, not imported Forge art.

const CELL := Vector2i(48, 32)
const LAYERS := 12
const ZOOM := 3.0

class SliceStack:
    extends Node2D
    var atlas: Texture2D
    var cell := Vector2i(48, 32)
    var layer_count := 12
    var angle := 0.0
    var spacing := 3.0
    var zoom := 3.0
    var flat := false

    func _draw() -> void:
        if atlas == null or cell.x <= 0 or cell.y <= 0:
            return
        var count := mini(layer_count, int(atlas.get_width() / float(cell.x)))
        if count <= 0 or atlas.get_height() < cell.y:
            return
        # Rotate cross-sections on the ground plane, then compress screen Y.
        # Keep the node position at the ground anchor for parent Y sorting.
        var c := cos(angle)
        var s := sin(angle)
        var basis_x := Vector2(c, s * 0.65) * zoom
        var basis_y := Vector2(-s, c * 0.65) * zoom
        var first := count - 1 if flat else 0
        for layer in range(first, count):
            var height := 0.0 if flat else float(layer) * spacing
            draw_set_transform_matrix(Transform2D(basis_x, basis_y, Vector2(0, -height)))
            var source := Rect2(Vector2(layer * cell.x, 0), Vector2(cell))
            var target := Rect2(-Vector2(cell) * 0.5, Vector2(cell))
            draw_texture_rect_region(atlas, target, source)
        draw_set_transform_matrix(Transform2D.IDENTITY)

class GroundMarker:
    extends Node2D

    func _draw() -> void:
        draw_circle(Vector2(0, -12), 10.0, Color("78ff9b"))
        draw_circle(Vector2.ZERO, 3.0, Color("ffffff"))

var stacks: Array[SliceStack] = []
var marker: GroundMarker
var angle := 0.0
var flat := false
var previous_space := false

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    y_sort_enabled = true
    _add_stack(Vector2(240, 220), _make_sheet(true))
    _add_stack(Vector2(470, 300), _make_sheet(false))
    marker = GroundMarker.new()
    marker.position = Vector2(350, 265)
    add_child(marker)
    var ui := CanvasLayer.new()
    add_child(ui)
    var instructions := Label.new()
    instructions.text = "HASH RACE | Sprite-stack experiment\nQ/E rotate  |  Arrows move marker  |  Space: flat / stack"
    instructions.position = Vector2(16, 12)
    instructions.add_theme_color_override("font_color", Color("ffffff"))
    ui.add_child(instructions)
    queue_redraw()

func _add_stack(anchor: Vector2, sheet: Texture2D) -> void:
    var stack := SliceStack.new()
    stack.atlas = sheet
    stack.cell = CELL
    stack.layer_count = LAYERS
    stack.zoom = ZOOM
    stack.position = anchor
    stacks.append(stack)
    add_child(stack)

func _process(delta: float) -> void:
    var turn := float(Input.is_physical_key_pressed(KEY_E)) - float(Input.is_physical_key_pressed(KEY_Q))
    angle = fposmod(angle + turn * delta * 1.6, TAU)
    var pressed := Input.is_physical_key_pressed(KEY_SPACE)
    var changed := pressed and not previous_space
    if changed:
        flat = not flat
    previous_space = pressed
    if not is_zero_approx(turn) or changed:
        for stack in stacks:
            stack.angle = angle
            stack.flat = flat
            stack.queue_redraw()
    var motion := Vector2(
        float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT)),
        float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))
    )
    if motion.length_squared() > 0.0:
        marker.position += motion.normalized() * 150.0 * delta
        var bounds := get_viewport_rect().size
        marker.position = marker.position.clamp(Vector2(12, 65), Vector2(maxf(12.0, bounds.x - 12.0), maxf(65.0, bounds.y - 12.0)))

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("34483b"))
    for anchor in [Vector2(240, 220), Vector2(470, 300)]:
        draw_rect(Rect2(anchor - Vector2(88, 45), Vector2(176, 90)), Color("637267"))

func _make_sheet(container: bool) -> Texture2D:
    # A row of actual horizontal cross-sections, bottom to top.
    # The existing directional/animation sheets must not be reinterpreted this way.
    var image := Image.create(CELL.x * LAYERS, CELL.y, false, Image.FORMAT_RGBA8)
    image.fill(Color.TRANSPARENT)
    var footprint := Vector2i(40, 20) if container else Vector2i(26, 22)
    var origin := (CELL - footprint) / 2
    for z in range(LAYERS):
        var base := Vector2i(z * CELL.x, 0) + Vector2i(origin)
        var rim := Color("283c4b") if container else Color("30383e")
        var body := Color("648da3") if container else Color("a2a9ac")
        image.fill_rect(Rect2i(base, footprint), rim)
        image.fill_rect(Rect2i(base + Vector2i(1, 1), footprint - Vector2i(2, 2)), body.lightened(float(z) * 0.015))
        if container:
            for x in range(3, footprint.x - 2, 4):
                image.fill_rect(Rect2i(base + Vector2i(x, 0), Vector2i(1, footprint.y)), rim)
            if z == LAYERS - 1:
                image.fill_rect(Rect2i(base + Vector2i(5, 4), Vector2i(footprint.x - 10, footprint.y - 8)), Color("a0becd"))
        else:
            for x in [4, 15]:
                image.fill_rect(Rect2i(base + Vector2i(x, 4), Vector2i(7, 14)), Color("46535a"))
            if z == LAYERS - 1:
                image.fill_rect(Rect2i(base + Vector2i(3, 6), Vector2i(20, 10)), Color("d1d4d4"))
    return ImageTexture.create_from_image(image)
