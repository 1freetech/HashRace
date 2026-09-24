extends AnimatedSprite2D
class_name HashRaceDefaultPlayerVisual

# Preload the builder explicitly. The modular parse validator loads scripts in
# isolation, so relying on global class-name registration can fail before this
# script is parsed even though the class exists elsewhere in the project.
const DefaultPlayerSheet = preload("res://scripts/default_player_sprite_sheet.gd")

var facing: String = "down"
var sheet_ready: bool = false

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    centered = true
    offset = Vector2(DefaultPlayerSheet.FRAME_SIZE) * 0.5 - Vector2(DefaultPlayerSheet.FOOT_ANCHOR)

    var built: SpriteFrames = DefaultPlayerSheet.build_frames()
    if built == null:
        visible = false
        return

    sprite_frames = built
    sheet_ready = true
    visible = true
    play(&"idle_down")

func update_from_velocity(new_velocity: Vector2) -> void:
    if new_velocity.length() < 0.01:
        _play_state(false)
        return

    if absf(new_velocity.x) > absf(new_velocity.y):
        facing = "right" if new_velocity.x > 0.0 else "left"
    else:
        facing = "down" if new_velocity.y > 0.0 else "up"

    _play_state(true)

func update_from_world_state(facing_name: String, animation_state: String) -> void:
    if facing_name in ["down", "up", "left", "right"]:
        facing = facing_name
    _play_state(not animation_state.ends_with("_idle"))

func _play_state(moving: bool) -> void:
    if not sheet_ready:
        return
    var target := StringName(("walk_" if moving else "idle_") + facing)
    if animation != target:
        play(target)

func is_sheet_ready() -> bool:
    return sheet_ready
