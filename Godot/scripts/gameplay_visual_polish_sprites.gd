extends "res://scripts/gameplay_visual_polish.gd"
class_name HashRaceGameplayVisualPolishSprites

# The base polish pass still owns road and interaction feedback. Building-body
# detail is intentionally omitted because authored sprite-sheet facilities now
# provide their own roofs, windows, vents, doors, and silhouette language.
const SPRITE_POLISH_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_sprite_building_polish_revision", SPRITE_POLISH_REVISION)

func _draw() -> void:
    var world := get_parent()
    if world == null:
        return
    _draw_road_readability(world)
    _draw_interaction_feedback(world)
    _draw_click_target(world)

func debug_ready() -> bool:
    var world := get_parent()
    return world != null \
        and SPRITE_POLISH_REVISION == 1 \
        and world.has_method("debug_v166_sprite_buildings_ready") \
        and bool(world.call("debug_v166_sprite_buildings_ready"))
