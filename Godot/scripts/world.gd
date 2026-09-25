extends Node2D

# Hash Race clean runtime. Release numbers belong in Git history, not gameplay.
const WORLD_SIZE := Vector2(1800, 1120)
const PLAYER_SPEED := 230.0
const GridNavigation = preload("res://scripts/grid_navigation.gd")
const Inventory = preload("res://scripts/infrastructure_inventory.gd")
const PlayerSheet = preload("res://scripts/default_player_sprite_sheet.gd")

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
var player_sprite: AnimatedSprite2D
var player_facing := "down"
var infrastructure_sprites: Dictionary = {}

const CAMPUS := {
    # Preserve the validated 128x102 container binary aspect ratio instead of\n    # stretching it across the old oversized house footprint.\n    "container": Rect2(320, 326, 256, 204),
    "solar": Rect2(1060, 210, 230, 230),
    "transformer": Rect2(950, 520, 180, 162),
    "asic": Rect2(560, 700, 190, 190),
    "wind": Rect2(1310, 260, 220, 220)
}

func _ready() -> void:
    grid_nav.configure(WORLD_SIZE, 48.0)
    for rect in CAMPUS.values():
        grid_nav.block_rect(_ground_foot(rect))
    _build_infrastructure_sprites()
    _build_player_sprite()
    camera = Camera2D.new()
    camera.position = rep_pos
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 7.0
    add_child(camera)
    camera.make_current()
    queue_redraw()

func _build_player_sprite() -> void:
    var frames := PlayerSheet.build_frames()
    if frames == null:
        return
    player_sprite = AnimatedSprite2D.new()
    player_sprite.name = "PlayerSprite"
    player_sprite.sprite_frames = frames
    player_sprite.animation = &"idle_down"
    player_sprite.position = rep_pos
    player_sprite.scale = Vector2(0.4, 0.4)
    player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    player_sprite.z_index = 0
    player_sprite.y_sort_enabled = false
    add_child(player_sprite)

func _process(delta: float) -> void:
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var moving := false
    if direction.length() > 0.0:
        walking = false
        moving = move_player(direction.normalized() * PLAYER_SPEED * delta)
        if moving:
            _set_player_facing(direction)
    elif walking:
        var offset := target - rep_pos
        if offset.length() < 5.0:
            walking = false
        else:
            var direction_to_target := offset.normalized()
            moving = move_player(direction_to_target * minf(PLAYER_SPEED * delta, offset.length()))
            if moving:
                _set_player_facing(direction_to_target)
    _update_player_animation(moving)
    camera.position = rep_pos
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        target = get_global_mouse_position()
        walking = true

func move_player(delta_pos: Vector2) -> bool:
    var candidate := rep_pos + delta_pos
    candidate.x = clampf(candidate.x, 40.0, WORLD_SIZE.x - 40.0)
    candidate.y = clampf(candidate.y, 40.0, WORLD_SIZE.y - 40.0)
    if not grid_nav.world_is_walkable(candidate):
        return false
    var moved := candidate.distance_to(rep_pos) > 0.01
    rep_pos = candidate
    if player_sprite != null:
        player_sprite.position = rep_pos
    return moved

func _set_player_facing(direction: Vector2) -> void:
    if absf(direction.x) > absf(direction.y):
        player_facing = "right" if direction.x > 0.0 else "left"
    else:
        player_facing = "down" if direction.y > 0.0 else "up"

func _update_player_animation(moving: bool) -> void:
    if player_sprite == null:
        return
    var wanted := StringName(("walk_" if moving else "idle_") + player_facing)
    if player_sprite.animation != wanted:
        player_sprite.play(wanted)
    elif moving and not player_sprite.is_playing():
        player_sprite.play(wanted)
    elif not moving and player_sprite.is_playing():
        player_sprite.stop()
        player_sprite.frame = 0

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("568c43"))
    _draw_service_road()
    _draw_hud()

func _draw_service_road() -> void:
    draw_rect(Rect2(170, 570, 1450, 88), Color("5b5b57"))
    draw_line(Vector2(170, 614), Vector2(1620, 614), Color("c7b46a"), 3.0)

func _build_infrastructure_sprites() -> void:
    # Real Sprite2D nodes give infrastructure and the player a common Y-sort
    # contract. This prevents the representative from always rendering over a
    # building just because the old CanvasItem draw call happened first.
    y_sort_enabled = true
    var textures := {
        "container": CONTAINER_ART,
        "solar": SOLAR_ART,
        "transformer": TRANSFORMER_ART,
        "asic": ASIC_ART,
    }
    for asset_id in textures.keys():
        var texture: Texture2D = textures[asset_id]
        if texture == null:
            continue
        var bounds: Rect2 = CAMPUS[asset_id]
        var fitted := _aspect_fit_rect(texture, bounds)
        var sprite := Sprite2D.new()
        sprite.name = "Infrastructure_" + String(asset_id)
        sprite.texture = texture
        sprite.centered = false
        sprite.position = fitted.position
        sprite.scale = fitted.size / Vector2(texture.get_size())
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        # Sort at ground contact, not at the image's top edge.
        sprite.y_sort_origin = int(round(fitted.size.y))
        infrastructure_sprites[asset_id] = sprite
        add_child(sprite)

    if WIND_ART != null:
        var wind_source_size := Vector2(WIND_ART.get_width() / 2.0, WIND_ART.get_height() / 2.0)
        var wind_bounds: Rect2 = CAMPUS.wind
        var wind_scale := minf(wind_bounds.size.x / wind_source_size.x, wind_bounds.size.y / wind_source_size.y)
        var wind_region := AtlasTexture.new()
        wind_region.atlas = WIND_ART
        wind_region.region = Rect2(Vector2.ZERO, wind_source_size)
        var wind_sprite := Sprite2D.new()
        wind_sprite.name = "Infrastructure_wind"
        wind_sprite.texture = wind_region
        wind_sprite.centered = false
        wind_sprite.scale = Vector2.ONE * wind_scale
        var wind_size := wind_source_size * wind_scale
        wind_sprite.position = Vector2(
            wind_bounds.position.x + (wind_bounds.size.x - wind_size.x) * 0.5,
            wind_bounds.end.y - wind_size.y
        ).round()
        wind_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        wind_sprite.y_sort_origin = int(round(wind_size.y))
        infrastructure_sprites["wind"] = wind_sprite
        add_child(wind_sprite)

func _aspect_fit_rect(texture: Texture2D, bounds: Rect2) -> Rect2:
    if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0:
        return bounds
    var source_size := Vector2(texture.get_width(), texture.get_height())
    var fit_scale := minf(bounds.size.x / source_size.x, bounds.size.y / source_size.y)
    var fitted_size := source_size * fit_scale
    var fitted_position := Vector2(
        bounds.position.x + (bounds.size.x - fitted_size.x) * 0.5,
        bounds.end.y - fitted_size.y
    )
    return Rect2(fitted_position.round(), fitted_size.round())

func _draw_hud() -> void:
    var font := ThemeDB.fallback_font
    draw_rect(Rect2(1180, 30, 230, 88), Color(0.05, 0.08, 0.10, 0.88))
    draw_string(font, Vector2(1200, 60), "HASH RACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("64ff8c"))
    draw_string(font, Vector2(1200, 88), "Mining campus online", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

func _ground_foot(rect: Rect2) -> Rect2:
    return Rect2(rect.position + Vector2(rect.size.x * 0.16, rect.size.y * 0.74), Vector2(rect.size.x * 0.68, rect.size.y * 0.22))

func infrastructure_rect(asset_id: String) -> Rect2:
    return CAMPUS.get(asset_id, Rect2())

func infrastructure_footprint(asset_id: String) -> Rect2:
    var rect := infrastructure_rect(asset_id)
    if rect.size == Vector2.ZERO:
        return Rect2()
    return _ground_foot(rect)

func infrastructure_ready(asset_id: String) -> bool:
    var texture: Texture2D = null
    match asset_id:
        "container":
            texture = CONTAINER_ART
        "solar":
            texture = SOLAR_ART
        "transformer":
            texture = TRANSFORMER_ART
        "asic":
            texture = ASIC_ART
        "wind":
            texture = WIND_ART
        _:
            return false
    var foot := infrastructure_footprint(asset_id)
    if texture == null or foot.size == Vector2.ZERO:
        return false
    if not infrastructure_sprites.has(asset_id):
        return false
    var sprite := infrastructure_sprites[asset_id] as Sprite2D
    if sprite == null or not sprite.is_inside_tree():
        return false
    if asset_id == "container" and Vector2i(texture.get_size()) != Vector2i(128, 102):
        return false
    if asset_id == "wind" and Vector2i(texture.get_size()) != Vector2i(128, 128):
        return false
    return not grid_nav.world_is_walkable(foot.get_center())

func player_animation_ready() -> bool:
    if player_sprite == null or player_sprite.sprite_frames == null:
        return false
    for facing in ["down", "left", "right", "up"]:
        if player_sprite.sprite_frames.get_frame_count(StringName("walk_" + facing)) != PlayerSheet.WALK_FRAME_COUNT:
            return false
    return true

func runtime_ready() -> bool:
    if camera == null or not camera.is_inside_tree() or not player_animation_ready():
        return false
    if grid_nav.blocked_count() < CAMPUS.size():
        return false
    for asset_id in CAMPUS.keys():
        if not infrastructure_ready(String(asset_id)):
            return false
    return PLAYER_ART != null

# Compatibility names are semantic, never release-numbered.
func debug_wind_ready() -> bool:
    return infrastructure_ready("wind")

func debug_runtime_ready() -> bool:
    return runtime_ready()
