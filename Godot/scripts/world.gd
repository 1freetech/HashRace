extends Node2D

# Hash Race clean runtime. Release numbers belong in Git history, not gameplay.
const WORLD_SIZE := Vector2(1800, 1120)
const PLAYER_SPEED := 144.0
const GridNavigation = preload("res://scripts/grid_navigation.gd")
const Inventory = preload("res://scripts/infrastructure_inventory.gd")
const PlayerSheet = preload("res://scripts/default_player_sprite_sheet.gd")
# Restore the last runtime-proven walk cadence from commit 9f3e8c2: four
# visually inspected alternating-leg poses at 8 FPS move 18 px per pose,
# yielding a 72 px cycle at 144 px/s instead of the refactor's 230 px/s glide.
const WALK_CYCLE_DISTANCE := 72.0
# SpriteFrames are padded to 160x240 with the authored foot at y=232. AnimatedSprite2D
# centers that texture by default, so without an offset the Node2D/Y-sort position sits
# 112 source pixels above the feet. Move the drawing upward while keeping rep_pos/NPC
# positions at the actual ground contact used by navigation and Y-sort.
const CHARACTER_FOOT_DRAW_OFFSET := Vector2(0.0, -(PlayerSheet.FOOT_ANCHOR.y - PlayerSheet.FRAME_SIZE.y * 0.5))

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
var npc_sprites: Array[AnimatedSprite2D] = []
var npc_origins: Array[Vector2] = []
var npc_time := 0.0

const NPCS := [
    {"pos": Vector2(430, 545), "scale": 0.26, "skin": Color("6b3f2a"), "suit": Color("1e5aa8"), "scouter": Color("62e88d"), "facing": "right", "patrol": Vector2(54, 0), "phase": 0.0},
    {"pos": Vector2(760, 545), "scale": 0.24, "skin": Color("c98b62"), "suit": Color("7b2d8e"), "scouter": Color("4fd7ff"), "facing": "left", "patrol": Vector2(-48, 0), "phase": 1.4},
    {"pos": Vector2(1030, 500), "scale": 0.27, "skin": Color("8b5a3c"), "suit": Color("16705a"), "scouter": Color("ffd35a"), "facing": "down", "patrol": Vector2(0, 44), "phase": 2.8},
    {"pos": Vector2(1370, 520), "scale": 0.23, "skin": Color("e0ad83"), "suit": Color("9b3b31"), "scouter": Color("b783ff"), "facing": "up", "patrol": Vector2(0, -40), "phase": 4.2},
]

const CAMPUS := {
    # Preserve the validated 128x102 container binary aspect ratio instead of
    # stretching it across the old oversized house footprint.
    "container": Rect2(410, 390, 192, 153),
    "solar": Rect2(1060, 300, 176, 176),
    # Screenshot-backed scale repair: keep the validated transformer binary and
    # aspect-fit/Y-sort/collision path, but reduce its live footprint so it no
    # longer dominates the nearby player and ASIC equipment.
    "transformer": Rect2(890, 450, 120, 108),
    "asic": Rect2(650, 650, 80, 80),
    "wind": Rect2(1280, 300, 176, 176)
}

func _ready() -> void:
    grid_nav.configure(WORLD_SIZE, 48.0)
    for rect in CAMPUS.values():
        grid_nav.block_rect(_ground_foot(rect))
    _build_infrastructure_sprites()
    _build_player_sprite()
    _build_npc_population()
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
    player_sprite.offset = CHARACTER_FOOT_DRAW_OFFSET
    player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    player_sprite.z_index = 0
    player_sprite.y_sort_enabled = false
    add_child(player_sprite)

func _build_npc_population() -> void:
    # Every NPC uses the exact validated player-sheet regions, but gets a
    # deterministic palette and patrol so the campus is visibly populated by
    # distinct people rather than uniform-grid crops of the same character.
    for index in range(NPCS.size()):
        var spec: Dictionary = NPCS[index]
        var frames := PlayerSheet.build_customized_frames(spec.skin, spec.suit, spec.scouter)
        if frames == null:
            continue
        var sprite := AnimatedSprite2D.new()
        sprite.name = "CampusNPC_%02d" % index
        sprite.sprite_frames = frames
        sprite.animation = StringName("idle_" + str(spec.facing))
        sprite.position = spec.pos
        sprite.scale = Vector2.ONE * float(spec.scale)
        sprite.offset = CHARACTER_FOOT_DRAW_OFFSET
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        npc_origins.append(spec.pos)
        npc_sprites.append(sprite)
        add_child(sprite)

func _update_npc_population(delta: float) -> void:
    npc_time += delta
    for index in range(npc_sprites.size()):
        var sprite := npc_sprites[index]
        var spec: Dictionary = NPCS[index]
        var phase := npc_time * 0.7 + float(spec.phase)
        var amount := sin(phase)
        var patrol: Vector2 = spec.patrol
        var next_position := npc_origins[index] + patrol * amount
        var velocity := next_position - sprite.position
        sprite.position = next_position
        var moving := absf(cos(phase)) > 0.18 and velocity.length_squared() > 0.01
        var facing := str(spec.facing)
        if absf(patrol.x) > absf(patrol.y):
            facing = "right" if velocity.x >= 0.0 else "left"
        elif absf(patrol.y) > 0.0:
            facing = "down" if velocity.y >= 0.0 else "up"
        var wanted := StringName(("walk_" if moving else "idle_") + facing)
        # Match foot cadence to actual patrol ground speed. The sinusoidal patrol
        # decelerates near each turnaround; fixed 8 FPS made NPC feet visibly slide.
        # PlayerSheet's validated four-frame walk advances 18 source pixels per frame.
        var ground_speed := velocity.length() / maxf(delta, 0.000001)
        var authored_stride_speed := PlayerSheet.WALK_FPS * (WALK_CYCLE_DISTANCE / float(PlayerSheet.WALK_FRAME_COUNT))
        sprite.speed_scale = clampf(ground_speed / authored_stride_speed, 0.2, 1.0) if moving else 1.0
        if sprite.animation != wanted:
            sprite.play(wanted)
        elif moving and not sprite.is_playing():
            sprite.play(wanted)
        elif not moving and sprite.is_playing():
            sprite.stop()
            sprite.frame = 0

func _process(delta: float) -> void:
    _update_npc_population(delta)
    var frame_start_position := rep_pos
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
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
            else:
                # A blocked click target used to leave walking=true forever,
                # retrying the same collision every frame. Stop cleanly so the
                # player returns to idle and the next click responds immediately.
                walking = false
    var player_ground_speed := rep_pos.distance_to(frame_start_position) / maxf(delta, 0.000001)
    _update_player_animation(moving, player_ground_speed)
    camera.position = rep_pos
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var clicked := get_global_mouse_position()
        # Keep click-to-move destinations inside the same playable margin used
        # by move_player(). GridNavigation.world_to_cell() intentionally clamps
        # coordinates, so accepting an off-map click here used to make the
        # representative walk all the way to an unrelated edge cell.
        var bounded_target := Vector2(
            clampf(clicked.x, 40.0, WORLD_SIZE.x - 40.0),
            clampf(clicked.y, 40.0, WORLD_SIZE.y - 40.0)
        )
        # Reject infrastructure cells up front instead of entering walking for
        # one frame and discovering the collision in _process().
        if not grid_nav.world_is_walkable(bounded_target):
            walking = false
            return
        target = bounded_target
        walking = rep_pos.distance_to(target) >= 5.0

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

func _update_player_animation(moving: bool, ground_speed: float) -> void:
    if player_sprite == null:
        return
    # Keep authored foot cadence synchronized to actual world displacement. This
    # matters for the final click-to-move step, which can be shorter than a full
    # PLAYER_SPEED frame and otherwise produces a visible one-frame foot slide.
    var authored_stride_speed := PlayerSheet.WALK_FPS * (WALK_CYCLE_DISTANCE / float(PlayerSheet.WALK_FRAME_COUNT))
    player_sprite.speed_scale = clampf(ground_speed / authored_stride_speed, 0.2, 1.0) if moving else 1.0
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
    }
    for asset_id in textures.keys():
        var texture: Texture2D = textures[asset_id]
        if texture == null:
            continue
        var bounds: Rect2 = CAMPUS[asset_id]
        var fitted := _aspect_fit_rect(texture, bounds)
        var sprite := Sprite2D.new()
        sprite.name = "Infrastructure_" + str(asset_id)
        sprite.texture = texture
        sprite.centered = false
        # Y-sort compares child Node2D positions, not the bottom edge of their
        # drawn texture. Anchor each infrastructure node at its ground contact
        # and offset the pixels upward so player/building occlusion follows feet.
        sprite.position = Vector2(fitted.position.x, fitted.end.y)
        sprite.offset = Vector2(0.0, -float(texture.get_height()))
        sprite.scale = fitted.size / Vector2(texture.get_size())
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        infrastructure_sprites[asset_id] = sprite
        add_child(sprite)

    # The validated ASIC binary is a 2x2 directional sheet, not four machines.
    # Render one authored 64x64 direction through AtlasTexture while keeping the
    # original imported PNG untouched. The 80x80 live footprint preserves the
    # per-view size visible in the preceding runtime proof instead of scaling a
    # single crop to the old 160x160 whole-sheet bounds.
    if ASIC_ART != null and Vector2i(ASIC_ART.get_size()) == Vector2i(128, 128):
        var asic_bounds: Rect2 = CAMPUS.asic
        var asic_region := AtlasTexture.new()
        asic_region.atlas = ASIC_ART
        asic_region.region = Rect2(0, 0, 64, 64)
        var asic_sprite := Sprite2D.new()
        asic_sprite.name = "Infrastructure_asic"
        asic_sprite.texture = asic_region
        asic_sprite.centered = false
        var asic_fitted := _aspect_fit_rect(asic_region, asic_bounds)
        asic_sprite.position = Vector2(asic_fitted.position.x, asic_fitted.end.y)
        asic_sprite.offset = Vector2(0.0, -64.0)
        asic_sprite.scale = asic_fitted.size / Vector2(64, 64)
        asic_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        infrastructure_sprites["asic"] = asic_sprite
        add_child(asic_sprite)

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
        # Match the common infrastructure ground-anchor contract for Y-sort.
        # Offset the atlas upward so the rendered turbine remains pixel-identical.
        wind_sprite.position = Vector2(
            wind_bounds.position.x + (wind_bounds.size.x - wind_size.x) * 0.5,
            wind_bounds.end.y
        ).round()
        wind_sprite.offset = Vector2(0.0, -wind_source_size.y)
        wind_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        # The validated wind sheet still contains a rectangular source
        # backdrop. A simple threshold shader removes only near-neutral gray
        # pixels at runtime while preserving the turbine silhouette and keeps
        # the original binary/hash untouched for provenance validation.
        var wind_material := ShaderMaterial.new()
        var wind_shader := Shader.new()
        wind_shader.code = """
shader_type canvas_item;
void fragment() {
    vec4 sample_color = texture(TEXTURE, UV);
    float spread = max(sample_color.r, max(sample_color.g, sample_color.b))
        - min(sample_color.r, min(sample_color.g, sample_color.b));
    bool neutral_gray = spread < 0.055
        && sample_color.r > 0.24 && sample_color.r < 0.82;
    COLOR = neutral_gray ? vec4(sample_color.rgb, 0.0) : sample_color;
}
"""
        wind_material.shader = wind_shader
        wind_sprite.material = wind_material
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
    if not is_equal_approx(PLAYER_SPEED / PlayerSheet.WALK_FPS * float(PlayerSheet.WALK_FRAME_COUNT), WALK_CYCLE_DISTANCE):
        return false
    for facing in ["down", "left", "right", "up"]:
        if player_sprite.sprite_frames.get_frame_count(StringName("walk_" + facing)) != PlayerSheet.WALK_FRAME_COUNT:
            return false
    return true

func npc_population_ready() -> bool:
    if npc_sprites.size() != NPCS.size() or npc_origins.size() != NPCS.size():
        return false
    var palettes := {}
    for index in range(npc_sprites.size()):
        var sprite := npc_sprites[index]
        if sprite == null or not sprite.is_inside_tree() or sprite.sprite_frames == null:
            return false
        var spec: Dictionary = NPCS[index]
        palettes[str(spec.skin) + "|" + str(spec.suit) + "|" + str(spec.scouter)] = true
        if sprite.sprite_frames.get_frame_count(&"walk_left") != PlayerSheet.WALK_FRAME_COUNT:
            return false
        if sprite.sprite_frames.get_frame_count(&"walk_right") != PlayerSheet.WALK_FRAME_COUNT:
            return false
    return palettes.size() == NPCS.size()

func runtime_ready() -> bool:
    if not npc_population_ready():
        return false
    if camera == null or not camera.is_inside_tree() or not player_animation_ready():
        return false
    if grid_nav.blocked_count() < CAMPUS.size():
        return false
    for asset_id in CAMPUS.keys():
        if not infrastructure_ready(str(asset_id)):
            return false
    return PLAYER_ART != null

# Compatibility names are semantic, never release-numbered.
func debug_wind_ready() -> bool:
    return infrastructure_ready("wind")

func debug_runtime_ready() -> bool:
    return runtime_ready()
