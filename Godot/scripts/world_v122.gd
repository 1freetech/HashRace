extends "res://scripts/world_v121.gd"

# Hash Race v0.122 interaction-target clarity.
# The nearest in-range gameplay target now gets a restrained pulsing field marker
# so the player can immediately see which company, partner, property, or deal
# will open when E is pressed. This reuses the existing interaction range and
# entity selection logic instead of adding a second targeting system.

const V122_INTERACTION_MARKER_REVISION := 1
const V122_MARKER_RADIUS := 34.0
const V122_MARKER_PULSE := 4.0

func _process(delta: float) -> void:
    super._process(delta)
    # The marker pulse is visual only, but redraw while a valid interaction is
    # nearby so the cue remains alive without repainting an idle empty world.
    var idx := _nearest_entity()
    if idx >= 0 and _entity_in_interact_range(idx):
        queue_redraw()

func _draw() -> void:
    super._draw()
    _v122_draw_interaction_target()

func _v122_draw_interaction_target() -> void:
    var idx := _nearest_entity()
    if idx < 0 or not _entity_in_interact_range(idx):
        return
    var entity: Dictionary = entities[idx]
    var target := Vector2(entity.get("pos", rep_pos))
    var pulse := (sin(Time.get_ticks_msec() * 0.006) + 1.0) * 0.5
    var radius := V122_MARKER_RADIUS + pulse * V122_MARKER_PULSE
    var marker := Color("8affbd")
    marker.a = 0.42 + pulse * 0.20
    draw_arc(target, radius, 0.0, TAU, 32, marker, 3.0, true)
    draw_line(target + Vector2(-10.0, -radius - 8.0), target + Vector2(10.0, -radius - 8.0), marker, 3.0, true)
    draw_line(target + Vector2(0.0, -radius - 18.0), target + Vector2(0.0, -radius + 2.0), marker, 3.0, true)

func debug_v122_ready() -> bool:
    return V122_INTERACTION_MARKER_REVISION == 1 and V122_MARKER_RADIUS > 0.0 and debug_v121_ready()
