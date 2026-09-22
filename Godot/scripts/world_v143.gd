extends "res://scripts/world_v142.gd"

# Hash Race v0.143: town-network navigation pass.
# Three playability improvements: Shift+T travels backward through the ten-miner
# league, H returns directly to the player's mining HQ, and the transit button
# always names the next mining town before the player commits to the jump.
const V143_TOWN_NAVIGATION_REVISION := 1

func _ready() -> void:
    super._ready()
    _v143_refresh_transit_button()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo:
            if key_event.keycode == KEY_T and key_event.shift_pressed:
                _v143_travel_offset(-1)
                get_viewport().set_input_as_handled()
                return
            if key_event.keycode == KEY_H:
                _v143_travel_home()
                get_viewport().set_input_as_handled()
                return
    super._unhandled_input(event)

func _travel_next_town() -> void:
    _v143_travel_offset(1)

func _v143_travel_offset(offset: int) -> void:
    if town_zones.is_empty():
        return
    transit_index = posmod(transit_index + offset, town_zones.size())
    _v143_arrive_at_zone(transit_index)

func _v143_travel_home() -> void:
    if town_zones.is_empty():
        return
    var home_idx := 0
    for i in range(town_zones.size()):
        if bool((town_zones[i] as Dictionary).get("player", false)):
            home_idx = i
            break
    transit_index = home_idx
    _v143_arrive_at_zone(home_idx)

func _v143_arrive_at_zone(zone_idx: int) -> void:
    _cancel_pending_interaction()
    _clear_nav_path()
    var zone: Dictionary = town_zones[zone_idx]
    rep_pos = Vector2(zone["center"]) + Vector2(0.0, 165.0)
    click_target = rep_pos
    has_click_target = false
    rep_animation_state = RPGMovement.animation_state(rep_facing, false)
    rep_step_phase = RPGMovement.settled_step_phase(Vector2.ZERO, rep_step_phase)
    if is_instance_valid(camera):
        camera.position = rep_pos
    _refresh_scanner_cells(true)
    _refresh_interaction_prompt()
    _v143_refresh_transit_button()
    _open_message(
        "TRANSIT // %s" % String(zone["town"]),
        "Arrived at %s, home of %s. T goes to the next mining town, Shift+T goes back, and H returns to your HQ." % [String(zone["town"]), String(zone["company"])]
    )
    queue_redraw()

func _v143_refresh_transit_button() -> void:
    if not is_instance_valid(transit_button) or town_zones.is_empty():
        return
    var next_idx := posmod(transit_index + 1, town_zones.size())
    var next_zone: Dictionary = town_zones[next_idx]
    transit_button.text = "NEXT: %s  [T]" % String(next_zone["town"])
    transit_button.tooltip_text = "T: next mining town | Shift+T: previous mining town | H: your mining HQ"

func debug_v143_ready() -> bool:
    return V143_TOWN_NAVIGATION_REVISION == 1 \
        and V138_MINING_COMPANIES.size() == 10 \
        and debug_v142_ready()
