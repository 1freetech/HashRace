extends Node2D

# Hash Race clean runtime. Release numbers belong in Git history, not gameplay.
const WORLD_SIZE := Vector2(1800, 1120)
const PLAYER_SPEED := 230.0
const GridNavigation = preload("res://scripts/grid_navigation.gd")
const Inventory = preload("res://scripts/infrastructure_inventory.gd")

const PLAYER_ART := preload("res://art/characters/default_player_sheet.png")
const CONTAINER_ART := preload("res://art/buildings/c01_mining_container.png")
const TRANSFORMER_ART := preload("res://art/electrical/substation_transformer_rear.png")
const SOLAR_ART := preload("res://art/energy/solar_array_overview.png")
const WIND_ART := preload("res://art/energy/wind_turbine_directional_sheet.png")
const ASIC_ART := preload("res://art/machines/asic_air_s19j_directional.png")

var grid_nav = GridNavigation.new()
var infrastructure_inventory = Inventory.new()
var player := {"cash": 125000.0, "mw": 10.0}
var rep_pos := Vector2(900, 650)
var camera: Camera2D
var target := Vector2.ZERO
var walking := false

const CAMPUS := {
    "container": Rect2(280, 300, 330, 190),
    "solar": Rect2(1060, 210, 230, 230),
    "transformer": Rect2(950, 520, 180, 162),
    "asic": Rect2(560, 700, 190, 190),
    "wind": Rect2(1310, 260, 220, 220)
}

func _ready() -> void:
    grid_nav.configure(WORLD_SIZE, 48.0)
    for rect in CAMPUS.values():
        grid_nav.block_rect(_ground_foot(rect))
    camera = Camera2D.new()
    camera.position = rep_pos
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 7.0
    add_child(camera)
    camera.make_current()
    queue_redraw()

func _process(delta: float) -> void:
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if direction.length() > 0.0:
        walking = false
        _move_player(direction.normalized() * PLAYER_SPEED * delta)
    elif walking:
        var offset := target - rep_pos
        if offset.length() < 5.0:
            walking = false
        else:
            _move_player(offset.normalized() * minf(PLAYER_SPEED * delta, offset.length()))
    camera.position = rep_pos
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        target = get_global_mouse_position()
        walking = true

func _move_player(delta_pos: Vector2) -> void:
    var candidate := rep_pos + delta_pos
    candidate.x = clampf(candidate.x, 40.0, WORLD_SIZE.x - 40.0)
    candidate.y = clampf(candidate.y, 40.0, WORLD_SIZE.y - 40.0)
    if grid_nav.world_is_walkable(candidate):
        rep_pos = candidate

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("568c43"))
    _draw_service_road()
    _draw_asset(CONTAINER_ART, CAMPUS.container)
    _draw_asset(SOLAR_ART, CAMPUS.solar)
    _draw_asset(TRANSFORMER_ART, CAMPUS.transformer)
    _draw_asset(ASIC_ART, CAMPUS.asic)
    _draw_wind()
    _draw_player()
    _draw_hud()

func _draw_service_road() -> void:
    draw_rect(Rect2(170, 570, 1450, 88), Color("5b5b57"))
    draw_line(Vector2(170, 614), Vector2(1620, 614), Color("c7b46a"), 3.0)

func _draw_asset(texture: Texture2D, destination: Rect2) -> void:
    if texture == null:
        return
    draw_texture_rect(texture, destination, false)

func _draw_wind() -> void:
    if WIND_ART == null:
        return
    var source := Rect2(Vector2.ZERO, Vector2(WIND_ART.get_width() / 2.0, WIND_ART.get_height() / 2.0))
    draw_texture_rect_region(WIND_ART, CAMPUS.wind, source)

func _draw_player() -> void:
    if PLAYER_ART == null:
        draw_circle(rep_pos, 18.0, Color("64ff8c"))
        return
    var frame_size := Vector2(PLAYER_ART.get_width() / 8.0, PLAYER_ART.get_height() / 4.0)
    var source := Rect2(Vector2.ZERO, frame_size)
    draw_texture_rect_region(PLAYER_ART, Rect2(rep_pos - Vector2(24, 42), Vector2(48, 64)), source)

func _draw_hud() -> void:
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(1180, 30, 230, 88), Color(0.05, 0.08, 0.10, 0.88))
    draw_string(font, Vector2(1200, 60), "HASH RACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("64ff8c"))
    draw_string(font, Vector2(1200, 88), "Mining campus online", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

func _ground_foot(rect: Rect2) -> Rect2:
    return Rect2(rect.position + Vector2(rect.size.x * 0.16, rect.size.y * 0.74), Vector2(rect.size.x * 0.68, rect.size.y * 0.22))

func debug_wind_ready() -> bool:
    var foot := _ground_foot(CAMPUS.wind)
    return WIND_ART != null \
        and Vector2i(WIND_ART.get_size()) == Vector2i(128, 128) \
        and foot.size.x > 0.0 \
        and not grid_nav.world_is_walkable(foot.get_center())

func debug_runtime_ready() -> bool:
    return PLAYER_ART != null and CONTAINER_ART != null and TRANSFORMER_ART != null and SOLAR_ART != null and WIND_ART != null and ASIC_ART != null and grid_nav.blocked_count() > 0 and debug_wind_ready()
