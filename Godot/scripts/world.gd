extends Node2D

const WORLD_SIZE := Vector2(1800, 1120)
const SPEED := 230.0
const PLAYER := preload("res://art/characters/default_player_sheet.png")
const CONTAINER := preload("res://art/buildings/c01_mining_container.png")
const TRANSFORMER := preload("res://art/electrical/substation_transformer_rear.png")
const SOLAR := preload("res://art/energy/solar_array_overview.png")
const WIND := preload("res://art/energy/wind_turbine_directional_sheet.png")
const ASIC := preload("res://art/machines/asic_air_s19j_directional.png")
const FAB := preload("res://art/buildings/semiconductor_fab.jpg")

var player_position := Vector2(880, 760)
var camera: Camera2D
var blocked := [
    Rect2(250, 260, 350, 210),
    Rect2(980, 230, 250, 230),
    Rect2(930, 520, 190, 170),
    Rect2(540, 690, 210, 190),
    Rect2(1260, 650, 300, 230)
]

func _ready() -> void:
    camera = Camera2D.new()
    camera.position = player_position
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 7.0
    add_child(camera)
    camera.make_current()
    queue_redraw()

func _process(delta: float) -> void:
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    if direction.length() > 0.0:
        var candidate := player_position + direction.normalized() * SPEED * delta
        candidate.x = clampf(candidate.x, 36.0, WORLD_SIZE.x - 36.0)
        candidate.y = clampf(candidate.y, 36.0, WORLD_SIZE.y - 36.0)
        if not _blocked(candidate):
            player_position = candidate
    camera.position = player_position
    queue_redraw()

func _blocked(point: Vector2) -> bool:
    for rect in blocked:
        var foot := Rect2(rect.position + Vector2(rect.size.x * 0.15, rect.size.y * 0.72), Vector2(rect.size.x * 0.70, rect.size.y * 0.24))
        if foot.has_point(point):
            return true
    return false

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("568c43"))
    _draw_road()
    _asset(CONTAINER, blocked[0])
    _asset(SOLAR, blocked[1])
    _asset(TRANSFORMER, blocked[2])
    _asset(ASIC, blocked[3])
    _asset(FAB, blocked[4])
    _wind()
    _player()
    _hud()

func _draw_road() -> void:
    draw_rect(Rect2(130, 590, 1540, 86), Color("565956"))
    draw_line(Vector2(130, 633), Vector2(1670, 633), Color("c8b86b"), 3.0)

func _asset(texture: Texture2D, rect: Rect2) -> void:
    if texture != null:
        draw_texture_rect(texture, rect, false)

func _wind() -> void:
    if WIND == null:
        return
    var frame := Vector2(WIND.get_width() / 2.0, WIND.get_height() / 2.0)
    draw_texture_rect_region(WIND, Rect2(1320, 250, 220, 220), Rect2(Vector2.ZERO, frame))

func _player() -> void:
    if PLAYER == null:
        return
    var frame := Vector2(PLAYER.get_width() / 8.0, PLAYER.get_height() / 4.0)
    draw_texture_rect_region(PLAYER, Rect2(player_position - Vector2(24, 42), Vector2(48, 64)), Rect2(Vector2.ZERO, frame))

func _hud() -> void:
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(1175, 28, 235, 82), Color(0.04, 0.07, 0.09, 0.90))
    draw_string(font, Vector2(1195, 59), "HASH RACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("64ff8c"))
    draw_string(font, Vector2(1195, 86), "Mining campus", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

func debug_runtime_ready() -> bool:
    return PLAYER != null and CONTAINER != null and TRANSFORMER != null and SOLAR != null and WIND != null and ASIC != null and FAB != null
