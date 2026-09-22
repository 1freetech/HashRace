extends "res://scripts/world_v141.gd"

# Hash Race v0.142: transit playability pass.
# Town travel must not leave a stale click route, queued interaction, or walking
# pose behind after the representative teleports between mining-company towns.
const V142_TRANSIT_PLAYABILITY_REVISION := 1

func _travel_next_town() -> void:
    if town_zones.is_empty():
        return
    _cancel_pending_interaction()
    _clear_nav_path()
    transit_index = (transit_index + 1) % town_zones.size()
    var zone: Dictionary = town_zones[transit_index]
    var center: Vector2 = zone["center"]
    rep_pos = center + Vector2(0.0, 165.0)
    click_target = rep_pos
    has_click_target = false
    rep_animation_state = RPGMovement.animation_state(rep_facing, false)
    rep_step_phase = RPGMovement.settled_step_phase(Vector2.ZERO, rep_step_phase)
    if is_instance_valid(camera):
        camera.position = rep_pos
    _refresh_scanner_cells(true)
    _refresh_interaction_prompt()
    _open_message(
        "TRANSIT // %s" % String(zone["town"]),
        "Arrived at %s, home of %s. Walk to the HQ or its representative to inspect the company, negotiate, or explore the surrounding route." % [String(zone["town"]), String(zone["company"])]
    )
    queue_redraw()

func debug_v142_ready() -> bool:
    return V142_TRANSIT_PLAYABILITY_REVISION == 1 \
        and V091_INTERACTION_REVISION == 1 \
        and RPGMovement.debug_idle_reset() \
        and debug_v141_ready()
