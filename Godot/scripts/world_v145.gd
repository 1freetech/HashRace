extends "res://scripts/world_v144.gd"

# Hash Race v0.145: field interaction clarity pass.
# Keep the mining-company league unchanged while making the moment-to-moment
# RPG loop easier to read and faster to operate.
const V145_INTERACTION_UX_REVISION := 1

func _ready() -> void:
    super._ready()
    if is_instance_valid(scanner_button):
        scanner_button.text = "SCANNER: ON  [R]"
        scanner_button.tooltip_text = "R toggles the reachable-cell scanner overlay."
    if is_instance_valid(interact_label):
        interact_label.tooltip_text = "Walk within %d units and press E, Enter, Space, or F to interact." % int(INTERACT_RANGE)
    set_meta("hashrace_v145_interaction_ux_revision", V145_INTERACTION_UX_REVISION)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event := event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F:
            if _v145_try_interact_nearest():
                get_viewport().set_input_as_handled()
                return
            _feedback("No interaction in range. Follow the nearest-target distance cue, then press F.")
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)

func _v145_try_interact_nearest() -> bool:
    var idx := _nearest_entity()
    if idx < 0 or not _entity_in_interact_range(idx):
        return false
    _invalidate_quarter_preview("Turn preview cancelled because you opened a new interaction.")
    var entity: Dictionary = entities[idx]
    rep_facing = RPGMovement.face_target(rep_pos, Vector2(entity["pos"]), rep_facing)
    rep_animation_state = RPGMovement.animation_state(rep_facing, false)
    rep_step_phase = RPGMovement.settled_step_phase(Vector2.ZERO, rep_step_phase)
    _clear_nav_path()
    _open_entity(idx)
    return true

func _refresh_interaction_prompt() -> void:
    if not is_instance_valid(interact_label):
        return
    var idx := _nearest_entity()
    if idx < 0:
        interact_label.text = ""
        return
    var entity: Dictionary = entities[idx]
    var label := String(entity.get("name", entity.get("label", "target"))).to_upper()
    var distance := rep_pos.distance_to(Vector2(entity["pos"]))
    if distance <= INTERACT_RANGE:
        interact_label.text = "[E/F] INTERACT // %s // %dm" % [label, int(round(distance))]
    elif distance <= INTERACT_RANGE * 2.5:
        interact_label.text = "NEAREST // %s // %dm" % [label, int(round(distance))]
    else:
        interact_label.text = ""

func debug_v145_ready() -> bool:
    return V145_INTERACTION_UX_REVISION == 1 \
        and V138_MINING_COMPANIES.size() == 10 \
        and debug_v144_ready()
