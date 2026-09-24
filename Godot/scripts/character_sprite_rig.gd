extends Node2D
class_name HashRaceCharacterSpriteRig

# Optional production sprite-sheet path for Hash Race. All layers use the same
# atlas geometry so body, hair, visor and armor stay frame-perfect. The live
# game still has a procedural fallback, but imported 96x128 (or similar) sheets
# can be dropped into this rig without multiplying sheets for color variants.

const PALETTE_SHADER: Shader = preload("res://shaders/character_palette_swap.gdshader")
const LAYER_NAMES: Array[StringName] = [&"body", &"hair", &"visor", &"armor"]
const POSE_ROWS: Dictionary = {
    &"idle_down": 0,
    &"idle_up": 1,
    &"idle_side": 2,
    &"walk_down": 3,
    &"walk_up": 4,
    &"walk_side": 5,
    &"run_down": 6,
    &"run_up": 7,
    &"run_side": 8,
    &"mining": 9,
    &"victory": 10,
}

@export var frame_size: Vector2i = Vector2i(96, 128)
@export_range(1, 12, 1) var frames_per_pose: int = 6
@export_range(1.0, 24.0, 0.5) var animation_fps: float = 10.0
@export var playing: bool = true

var _layers: Dictionary = {}
var _materials: Dictionary = {}
var _pose: StringName = &"idle_down"
var _frame: int = 0
var _elapsed: float = 0.0
var _flip_side: bool = false

func _ready() -> void:
    for layer_name in LAYER_NAMES:
        var sprite := Sprite2D.new()
        sprite.name = String(layer_name).capitalize()
        sprite.centered = true
        sprite.region_enabled = true
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.z_index = _layer_z(layer_name)
        add_child(sprite)
        _layers[layer_name] = sprite

        var material := ShaderMaterial.new()
        material.shader = PALETTE_SHADER
        sprite.material = material
        _materials[layer_name] = material
    _apply_frame()

func set_layer_texture(layer_name: StringName, texture: Texture2D) -> void:
    var sprite: Sprite2D = _layers.get(layer_name) as Sprite2D
    if sprite == null:
        return
    sprite.texture = texture
    sprite.visible = texture != null
    _apply_frame_to(sprite)

func set_pose(pose_name: StringName, flip_side: bool = false, restart: bool = false) -> void:
    if not POSE_ROWS.has(pose_name):
        return
    if restart or pose_name != _pose:
        _frame = 0
        _elapsed = 0.0
    _pose = pose_name
    _flip_side = flip_side
    _apply_frame()

func set_directional_state(action: StringName, facing: StringName, restart: bool = false) -> void:
    var pose_name: StringName = &"idle_down"
    var flip_side := false
    match facing:
        &"up":
            pose_name = StringName("%s_up" % String(action))
        &"left":
            pose_name = StringName("%s_side" % String(action))
            flip_side = true
        &"right":
            pose_name = StringName("%s_side" % String(action))
        _:
            pose_name = StringName("%s_down" % String(action))
    if not POSE_ROWS.has(pose_name):
        pose_name = &"idle_down"
    set_pose(pose_name, flip_side, restart)

func set_palette(skin: Color, hair: Color, suit: Color, accent: Color) -> void:
    var targets := {
        "target_skin_dark": skin.darkened(0.42),
        "target_skin_mid": skin,
        "target_skin_high": skin.lightened(0.28),
        "target_hair_dark": hair.darkened(0.42),
        "target_hair_mid": hair,
        "target_hair_high": hair.lightened(0.24),
        "target_suit_dark": suit.darkened(0.42),
        "target_suit_mid": suit,
        "target_suit_high": suit.lightened(0.24),
        "target_accent_dark": accent.darkened(0.46),
        "target_accent_mid": accent,
        "target_accent_high": accent.lightened(0.34),
    }
    for raw_material in _materials.values():
        var material := raw_material as ShaderMaterial
        if material == null:
            continue
        for key in targets.keys():
            material.set_shader_parameter(StringName(String(key)), targets[key])

func set_palette_tolerance(value: float) -> void:
    var safe_value := clampf(value, 0.0, 0.12)
    for raw_material in _materials.values():
        var material := raw_material as ShaderMaterial
        if material != null:
            material.set_shader_parameter("tolerance", safe_value)

func _process(delta: float) -> void:
    if not playing or frames_per_pose <= 1 or animation_fps <= 0.0:
        return
    _elapsed += delta
    var frame_time := 1.0 / animation_fps
    while _elapsed >= frame_time:
        _elapsed -= frame_time
        _frame = (_frame + 1) % frames_per_pose
        _apply_frame()

func _apply_frame() -> void:
    for raw_sprite in _layers.values():
        var sprite := raw_sprite as Sprite2D
        if sprite != null:
            _apply_frame_to(sprite)

func _apply_frame_to(sprite: Sprite2D) -> void:
    var row: int = int(POSE_ROWS.get(_pose, 0))
    var fw := float(frame_size.x)
    var fh := float(frame_size.y)
    sprite.region_rect = Rect2(float(_frame) * fw, float(row) * fh, fw, fh)
    sprite.flip_h = _flip_side

func _layer_z(layer_name: StringName) -> int:
    match layer_name:
        &"body":
            return 0
        &"hair":
            return 10
        &"visor":
            return 20
        &"armor":
            return 30
        _:
            return 0

func debug_sprite_rig_ready() -> bool:
    return _layers.size() == LAYER_NAMES.size() and PALETTE_SHADER != null and POSE_ROWS.has(&"walk_side")
