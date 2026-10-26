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
    var radius := V122_MARKER_RADIUS * 0.70 + pulse * V122_MARKER_PULSE * 0.35
    var marker := Color("8affbd")
    marker.a = 0.34 + pulse * 0.14
    var kind := String(entity.get("kind", ""))
    if WorldScale.is_building_kind(kind):
        # Anchor building focus to its service apron. The old upright reticle
        # crossed roofs and doors, competing with the sprite art and interaction.
        var size := WorldScale.size_for_kind(kind)
        var center := target + Vector2(0.0, size.y * 0.38 + 13.0)
        var radius_x := size.x * 0.47
        var radius_y := 8.0 + pulse * 1.5
        var points := PackedVector2Array()
        for step in range(33):
            var angle := TAU * float(step) / 32.0
            points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
        draw_polyline(points, marker, 2.0, true)
    else:
        # Keep a compact foot ring for people and non-building interaction targets.
        draw_arc(target + Vector2(0.0, 38.0), radius, 0.0, TAU, 28, marker, 2.0, true)

func debug_v122_ready() -> bool:
    return V122_INTERACTION_MARKER_REVISION == 1 and V122_MARKER_RADIUS > 0.0 and debug_v121_ready()
