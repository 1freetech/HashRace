extends Node2D
class_name HashRaceArchiveSpriteInteraction

# Turn the promoted support-equipment sprites into lightweight operations gameplay.
# Nearby equipment highlights, E/F inspects it, surveyed equipment can develop
# deterministic turn-scaled faults, and R repairs an active fault on site.

const INSPECT_RANGE := 82.0
const HIGHLIGHT_RANGE := 126.0
const REPAIR_RANGE := 92.0
const SURVEY_MILESTONE_SIZE := 6
const MAX_OPERATIONS_BONUS := 5
const FAULT_CHECK_DAYS := 30.4375
const FAULT_BASE_MONTHLY_CHANCE := 0.18
const FAULT_MIN_MONTHLY_CHANCE := 0.08
const FAULT_MAX_MONTHLY_CHANCE := 0.25
const FAULT_UPTIME_PENALTIES := [0.015, 0.035, 0.060]
const FAULT_BASE_REPAIR_COSTS := [2000.0, 6500.0, 18000.0]
const FAULT_SEVERITY_LABELS := ["MINOR", "MAJOR", "CRITICAL"]
const HIGHLIGHT_TINT := Color("b8ffcc")
const INSPECTED_TINT := Color("eafff0")
const FAULT_TINT := Color("ff8f78")
const FAULT_HIGHLIGHT_TINT := Color("ffc0a8")

const EQUIPMENT_INFO := {
    "ArchiveProp_Ats": {"label":"ATS", "role":"automatic transfer switching for source continuity"},
    "ArchiveProp_Handhole": {"label":"Handhole", "role":"underground cable-access point"},
    "ArchiveProp_Bollards": {"label":"Bollards", "role":"impact protection around critical equipment"},
    "ArchiveProp_CoolingUnit": {"label":"Cooling Unit", "role":"heat rejection for mining infrastructure"},
    "ArchiveProp_ElectricalUnit": {"label":"Electrical Unit", "role":"local power distribution and protection"},
    "ArchiveProp_EnergyUnit": {"label":"Energy Unit", "role":"site energy support equipment"},
    "ArchiveProp_HarmonicFilter": {"label":"Harmonic Filter", "role":"power-quality control for nonlinear loads"},
    "ArchiveProp_Bench": {"label":"Service Bench", "role":"field maintenance work area"},
    "ArchiveProp_LightningProtection": {"label":"Lightning Protection", "role":"surge and lightning-path protection"},
    "ArchiveProp_LoadBank": {"label":"Load Bank", "role":"controlled electrical load for commissioning tests"},
    "ArchiveProp_Eyewash": {"label":"Eyewash", "role":"emergency personnel safety station"},
    "ArchiveProp_CableReel": {"label":"Cable Reel", "role":"temporary power and service cable management"},
    "ArchiveProp_MvEquipment": {"label":"MV Equipment", "role":"medium-voltage distribution equipment"},
    "ArchiveProp_Hydrant": {"label":"Hydrant", "role":"site fire-water access point"},
    "ArchiveProp_TruckScale": {"label":"Truck Scale", "role":"inbound logistics and weight verification"},
    "ArchiveProp_MvTermination": {"label":"MV Termination", "role":"medium-voltage cable termination point"},
    "ArchiveProp_DiagnosticStation": {"label":"Diagnostic Station", "role":"field troubleshooting and measurement station"},
    "ArchiveProp_WeatherStation": {"label":"Weather Station", "role":"environmental monitoring for operations"},
    "ArchiveProp_PowerService": {"label":"Power Service", "role":"electrical service support point"},
    "ArchiveProp_CoolingService": {"label":"Cooling Service", "role":"cooling-system maintenance connection"},
    "ArchiveProp_WashdownStation": {"label":"Washdown Station", "role":"equipment and pad cleaning support"},
    "ArchiveProp_Pump": {"label":"Pump", "role":"fluid circulation for site utilities"},
    "ArchiveProp_SaltStorage": {"label":"Salt Storage", "role":"water-treatment consumable storage"},
    "ArchiveProp_Trench": {"label":"Utility Trench", "role":"protected below-grade utility routing"},
    "ArchiveProp_SecurityFirewall": {"label":"Security Firewall", "role":"physical security boundary equipment"},
    "ArchiveProp_Cctv": {"label":"CCTV", "role":"site surveillance and incident review"},
    "ArchiveProp_OilWaterSeparator": {"label":"Oil-Water Separator", "role":"stormwater and spill-control treatment"},
    "ArchiveProp_Statcom": {"label":"STATCOM", "role":"dynamic reactive-power and voltage support"},
    "ArchiveProp_FiberPedestal": {"label":"Fiber Pedestal", "role":"campus fiber distribution access"},
    "ArchiveProp_GateControl": {"label":"Gate Control", "role":"controlled vehicle and personnel entry"},
    "ArchiveProp_Telecom": {"label":"Telecom", "role":"site communications infrastructure"},
    "ArchiveProp_CompressedAir": {"label":"Compressed Air", "role":"pneumatic service for field maintenance"},
    "ArchiveProp_Drain": {"label":"Drain", "role":"surface-water drainage and runoff control"},
}

var highlighted: Sprite2D
var inspected := {}
var prompt: Label
var active_fault_key := ""
var fault_severity := 0
var fault_repair_cost := 0.0
var next_fault_check_day := -1.0
var last_fault_check_day := -1.0

func _ready() -> void:
    set_process(true)
    set_process_unhandled_input(true)
    prompt = Label.new()
    prompt.name = "EquipmentInspectPrompt"
    prompt.visible = false
    prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
    prompt.z_index = 60
    prompt.size = Vector2(260.0, 50.0)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    prompt.add_theme_font_size_override("font_size", 11)
    prompt.add_theme_color_override("font_color", Color("8affbd"))
    prompt.add_theme_color_override("font_outline_color", Color("102019"))
    prompt.add_theme_constant_override("outline_size", 4)
    add_child(prompt)
    # Children become ready before the world root; defer restore until campaign
    # setup has initialized the authoritative player state.
    call_deferred("_restore_progress")

func _process(_delta: float) -> void:
    _update_reliability_clock()
    var next_target := _nearest_equipment(HIGHLIGHT_RANGE)
    if next_target != highlighted:
        _apply_resting_tint(highlighted)
        highlighted = next_target
    if highlighted != null:
        highlighted.self_modulate = FAULT_HIGHLIGHT_TINT if String(highlighted.name) == active_fault_key else HIGHLIGHT_TINT
    var fault_sprite := _sprite_by_key(active_fault_key)
    if fault_sprite != null and fault_sprite != highlighted:
        fault_sprite.self_modulate = FAULT_TINT
    _update_prompt()

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    var host := _world()
    if host == null or get_viewport().gui_get_focus_owner() != null or _entity_claims_interaction(host):
        return
    if key_event.keycode == KEY_R:
        if _repair_active_fault():
            get_viewport().set_input_as_handled()
        return
    if key_event.keycode not in [KEY_E, KEY_F]:
        return
    var target := _nearest_equipment(INSPECT_RANGE)
    if target == null:
        return
    _inspect(target)
    get_viewport().set_input_as_handled()

func _world() -> Node:
    var props := get_parent()
    return props.get_parent() if props != null else null

func _props() -> Node:
    return get_parent()

func _rep_position() -> Vector2:
    var host := _world()
    return host.get("rep_pos") if host != null else Vector2.ZERO

func _entity_claims_interaction(host: Node) -> bool:
    if host == null:
        return false
    if int(host.get("pending_interaction_idx")) >= 0:
        return true
    # Keep existing company/NPC interaction priority when that target is already
    # close enough to interact. Equipment remains available when companies are
    # merely visible or quick-route eligible farther away.
    if host.has_method("_nearest_entity") and host.has_method("_entity_in_interact_range"):
        var entity_idx := int(host.call("_nearest_entity"))
        return entity_idx >= 0 and bool(host.call("_entity_in_interact_range", entity_idx))
    return false

func _nearest_equipment(max_distance: float) -> Sprite2D:
    var props := _props()
    if props == null:
        return null
    var items: Variant = props.get("live_sprites")
    if not items is Array:
        return null
    var rep := _rep_position()
    var best: Sprite2D
    var best_distance := max_distance
    for item in items:
        var sprite := item as Sprite2D
        if sprite == null or not EQUIPMENT_INFO.has(String(sprite.name)):
            continue
        var distance := rep.distance_to(sprite.position)
        if distance <= best_distance:
            best_distance = distance
            best = sprite
    return best

func _sprite_by_key(key: String) -> Sprite2D:
    if key.is_empty():
        return null
    var props := _props()
    if props == null:
        return null
    var items: Variant = props.get("live_sprites")
    if not items is Array:
        return null
    for item in items:
        var sprite := item as Sprite2D
        if sprite != null and String(sprite.name) == key:
            return sprite
    return null

func _inspect(sprite: Sprite2D) -> void:
    var key := String(sprite.name)
    var info: Dictionary = EQUIPMENT_INFO.get(key, {})
    if info.is_empty():
        return
    var old_count := inspected.size()
    var first_time := not inspected.has(key)
    if first_time:
        inspected[key] = true
        sprite.set_meta("hashrace_equipment_inspected", true)
        _persist_progress()
    var bonus_text := ""
    if first_time:
        var old_milestones := mini(int(float(old_count) / float(SURVEY_MILESTONE_SIZE)), MAX_OPERATIONS_BONUS)
        var new_milestones := mini(int(float(inspected.size()) / float(SURVEY_MILESTONE_SIZE)), MAX_OPERATIONS_BONUS)
        if new_milestones > old_milestones and _award_operations_point():
            bonus_text = "  •  OPS +1"
    _apply_resting_tint(sprite)
    sprite.self_modulate = FAULT_HIGHLIGHT_TINT if key == active_fault_key else HIGHLIGHT_TINT
    var host := _world()
    if host != null and host.has_method("_feedback"):
        host.call("_feedback", "%s: %s  •  SURVEY %d/%d%s" % [
            String(info.get("label", "Equipment")),
            String(info.get("role", "site support equipment")),
            inspected.size(), EQUIPMENT_INFO.size(), bonus_text
        ])

func _award_operations_point() -> bool:
    var host := _world()
    if host == null:
        return false
    var personality: Variant = host.get("player_personality")
    if not personality is Dictionary or personality.is_empty():
        return false
    var current := int(personality.get("operations", 50))
    if current >= 100:
        return false
    personality["operations"] = mini(100, current + 1)
    host.set("player_personality", personality)
    return true

func _operations_rating() -> float:
    var host := _world()
    if host == null:
        return 50.0
    var personality: Variant = host.get("player_personality")
    if not personality is Dictionary or personality.is_empty():
        return 50.0
    return clampf(float(personality.get("operations", 50)), 0.0, 100.0)

func _monthly_fault_chance() -> float:
    return clampf(
        FAULT_BASE_MONTHLY_CHANCE - (_operations_rating() - 50.0) * 0.0014,
        FAULT_MIN_MONTHLY_CHANCE,
        FAULT_MAX_MONTHLY_CHANCE
    )

func _update_reliability_clock() -> void:
    var host := _world()
    if host == null:
        return
    var player_value: Variant = host.get("player")
    if not player_value is Dictionary or player_value.is_empty():
        return
    var elapsed := float(host.get("elapsed_campaign_days"))
    if next_fault_check_day < 0.0:
        last_fault_check_day = elapsed
        next_fault_check_day = elapsed + FAULT_CHECK_DAYS
        _persist_fault_state()
        return
    if elapsed + 0.001 < next_fault_check_day:
        return

    var days_since_check := maxf(FAULT_CHECK_DAYS, elapsed - last_fault_check_day)
    last_fault_check_day = elapsed
    next_fault_check_day = elapsed + FAULT_CHECK_DAYS
    _persist_fault_state()
    if not active_fault_key.is_empty() or inspected.is_empty():
        return

    var monthly_chance := _monthly_fault_chance()
    var periods := maxf(1.0, days_since_check / FAULT_CHECK_DAYS)
    var turn_chance := clampf(1.0 - pow(1.0 - monthly_chance, periods), 0.0, 0.92)
    var seed := _fault_seed(elapsed)
    var roll := float(posmod(seed, 1000)) / 1000.0
    if roll >= turn_chance:
        return

    var candidates: Array = inspected.keys()
    candidates.sort()
    if candidates.is_empty():
        return
    var key := String(candidates[posmod(seed / 7 + int(round(elapsed)), candidates.size())])
    var severity_roll := posmod(seed * 37 + int(round(elapsed * 11.0)), 1000)
    var severity := 0
    if severity_roll >= 900:
        severity = 2
    elif severity_roll >= 650:
        severity = 1
    _trigger_fault(key, severity)

func _fault_seed(elapsed: float) -> int:
    var host := _world()
    if host == null:
        return 1
    var player_value: Variant = host.get("player")
    if not player_value is Dictionary:
        return 1
    return absi(
        int(round(elapsed * 10.0)) * 97
        + int(player_value.get("machines", 0)) * 17
        + inspected.size() * 71
        + int(round(_operations_rating())) * 13
        + int(host.get("turn")) * 43
    ) + 1

func _repair_cost_for_severity(severity: int) -> float:
    var host := _world()
    if host == null:
        return float(FAULT_BASE_REPAIR_COSTS[clampi(severity, 0, 2)])
    var player_value: Variant = host.get("player")
    var machines := 20
    if player_value is Dictionary:
        machines = maxi(1, int(player_value.get("machines", 20)))
    var fleet_scale := clampf(sqrt(float(machines) / 20.0), 1.0, 8.0)
    var operations_factor := clampf(1.08 - (_operations_rating() - 50.0) / 500.0, 0.98, 1.18)
    var raw_cost := float(FAULT_BASE_REPAIR_COSTS[clampi(severity, 0, 2)]) * fleet_scale * operations_factor
    return round(raw_cost / 50.0) * 50.0

func _trigger_fault(key: String, severity: int) -> bool:
    if not EQUIPMENT_INFO.has(key) or not active_fault_key.is_empty():
        return false
    var host := _world()
    if host == null:
        return false
    active_fault_key = key
    fault_severity = clampi(severity, 0, 2)
    fault_repair_cost = _repair_cost_for_severity(fault_severity)
    var player_value: Variant = host.get("player")
    if player_value is Dictionary:
        player_value["equipment_uptime_penalty"] = float(FAULT_UPTIME_PENALTIES[fault_severity])
        player_value["equipment_fault_key"] = active_fault_key
        player_value["equipment_fault_severity"] = fault_severity
        player_value["equipment_fault_repair_cost"] = fault_repair_cost
        host.set("player", player_value)
    var sprite := _sprite_by_key(key)
    if sprite != null:
        sprite.self_modulate = FAULT_TINT
    _persist_fault_state()
    var info: Dictionary = EQUIPMENT_INFO.get(key, {})
    if host.has_method("_feedback"):
        host.call("_feedback", "EQUIPMENT FAULT • %s • %s • uptime -%.1f%% until repaired. Walk to the highlighted unit and press R. Estimated repair $%d." % [
            String(info.get("label", "Equipment")),
            String(FAULT_SEVERITY_LABELS[fault_severity]),
            float(FAULT_UPTIME_PENALTIES[fault_severity]) * 100.0,
            int(fault_repair_cost)
        ])
    return true

func _repair_active_fault() -> bool:
    if active_fault_key.is_empty():
        return false
    var sprite := _sprite_by_key(active_fault_key)
    if sprite == null or _rep_position().distance_to(sprite.position) > REPAIR_RANGE:
        return false
    var host := _world()
    if host == null:
        return false
    var player_value: Variant = host.get("player")
    if not player_value is Dictionary:
        return false
    var cash := float(player_value.get("cash", 0.0))
    if cash < fault_repair_cost:
        if host.has_method("_feedback"):
            host.call("_feedback", "Repair requires $%d; available cash is $%d." % [int(fault_repair_cost), int(cash)])
        return true

    var repaired_key := active_fault_key
    var repaired_cost := fault_repair_cost
    player_value["cash"] = cash - repaired_cost
    player_value["equipment_uptime_penalty"] = 0.0
    player_value["equipment_fault_key"] = ""
    player_value["equipment_fault_severity"] = 0
    player_value["equipment_fault_repair_cost"] = 0.0
    player_value["equipment_faults_resolved"] = int(player_value.get("equipment_faults_resolved", 0)) + 1
    host.set("player", player_value)
    active_fault_key = ""
    fault_severity = 0
    fault_repair_cost = 0.0
    _apply_resting_tint(sprite)
    _persist_fault_state()
    if host.has_method("_refresh_ui"):
        host.call("_refresh_ui")
    if host.has_method("_feedback"):
        var info: Dictionary = EQUIPMENT_INFO.get(repaired_key, {})
        host.call("_feedback", "REPAIRED • %s • $%d • full equipment availability restored. Resolved faults: %d." % [
            String(info.get("label", "Equipment")), int(repaired_cost), int(player_value["equipment_faults_resolved"])
        ])
    return true

func _restore_progress() -> void:
    var host := _world()
    if host == null:
        return
    var player_value: Variant = host.get("player")
    if not player_value is Dictionary:
        return
    var saved: Variant = player_value.get("equipment_surveys", [])
    if saved is Array:
        for raw_key in saved:
            var key := String(raw_key)
            if EQUIPMENT_INFO.has(key):
                inspected[key] = true

    var elapsed := float(host.get("elapsed_campaign_days"))
    active_fault_key = String(player_value.get("equipment_fault_key", ""))
    if not active_fault_key.is_empty() and not EQUIPMENT_INFO.has(active_fault_key):
        active_fault_key = ""
    fault_severity = clampi(int(player_value.get("equipment_fault_severity", 0)), 0, 2)
    fault_repair_cost = float(player_value.get("equipment_fault_repair_cost", 0.0))
    if not active_fault_key.is_empty() and fault_repair_cost <= 0.0:
        fault_repair_cost = _repair_cost_for_severity(fault_severity)
    last_fault_check_day = float(player_value.get("equipment_last_fault_check_day", elapsed))
    next_fault_check_day = float(player_value.get("equipment_next_fault_check_day", elapsed + FAULT_CHECK_DAYS))
    player_value["equipment_uptime_penalty"] = float(FAULT_UPTIME_PENALTIES[fault_severity]) if not active_fault_key.is_empty() else 0.0
    host.set("player", player_value)

    var props := _props()
    if props != null:
        var items: Variant = props.get("live_sprites")
        if items is Array:
            for item in items:
                var sprite := item as Sprite2D
                if sprite != null:
                    _apply_resting_tint(sprite)
    _persist_fault_state()

func _persist_progress() -> void:
    var host := _world()
    if host == null:
        return
    var player_value: Variant = host.get("player")
    if not player_value is Dictionary:
        return
    player_value["equipment_surveys"] = inspected.keys()
    player_value["equipment_survey_count"] = inspected.size()
    host.set("player", player_value)

func _persist_fault_state() -> void:
    var host := _world()
    if host == null:
        return
    var player_value: Variant = host.get("player")
    if not player_value is Dictionary:
        return
    player_value["equipment_fault_key"] = active_fault_key
    player_value["equipment_fault_severity"] = fault_severity
    player_value["equipment_fault_repair_cost"] = fault_repair_cost
    player_value["equipment_last_fault_check_day"] = last_fault_check_day
    player_value["equipment_next_fault_check_day"] = next_fault_check_day
    if active_fault_key.is_empty():
        player_value["equipment_uptime_penalty"] = 0.0
    host.set("player", player_value)

func _apply_resting_tint(sprite: Sprite2D) -> void:
    if sprite == null:
        return
    var key := String(sprite.name)
    if key == active_fault_key:
        sprite.self_modulate = FAULT_TINT
    else:
        sprite.self_modulate = INSPECTED_TINT if inspected.has(key) else Color.WHITE

func _update_prompt() -> void:
    if prompt == null:
        return
    var host := _world()
    if host == null or get_viewport().gui_get_focus_owner() != null or _entity_claims_interaction(host):
        prompt.visible = false
        return
    var target := _nearest_equipment(INSPECT_RANGE)
    if target == null:
        prompt.visible = false
        return
    var key := String(target.name)
    var info: Dictionary = EQUIPMENT_INFO.get(key, {})
    var label := String(info.get("label", "EQUIPMENT")).to_upper()
    if key == active_fault_key:
        prompt.add_theme_color_override("font_color", Color("ffb7a4"))
        prompt.text = "[R] REPAIR • %s\n%s • -%.1f%% UPTIME • $%d" % [
            label,
            String(FAULT_SEVERITY_LABELS[fault_severity]),
            float(FAULT_UPTIME_PENALTIES[fault_severity]) * 100.0,
            int(fault_repair_cost)
        ]
    else:
        prompt.add_theme_color_override("font_color", Color("8affbd"))
        var state := "SURVEYED" if inspected.has(key) else "NEW"
        prompt.text = "[E/F] INSPECT • %s\n%s • %d/%d" % [label, state, inspected.size(), EQUIPMENT_INFO.size()]
    prompt.position = target.position + Vector2(-130.0, -108.0)
    prompt.visible = true

func nearest_equipment_name() -> String:
    var target := _nearest_equipment(HIGHLIGHT_RANGE)
    return String(target.name) if target != null else ""

func active_fault_name() -> String:
    return active_fault_key

func debug_force_fault(key: String, severity: int = 1) -> bool:
    if not EQUIPMENT_INFO.has(key):
        return false
    if not inspected.has(key):
        inspected[key] = true
        _persist_progress()
    if not active_fault_key.is_empty():
        return active_fault_key == key
    return _trigger_fault(key, severity)

func debug_ready() -> bool:
    var props := _props()
    var host := _world()
    if props == null or host == null or EQUIPMENT_INFO.size() != 33:
        return false
    if not props.has_method("live_sprite_count") or int(props.call("live_sprite_count")) != 33:
        return false
    return host.has_method("_feedback") \
        and host.has_method("debug_v165_diesel_ready") \
        and host.has_method("_uptime_without_grid_penalty") \
        and FAULT_UPTIME_PENALTIES.size() == FAULT_SEVERITY_LABELS.size()
