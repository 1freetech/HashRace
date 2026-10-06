extends Node2D
class_name HashRaceArchiveSpriteInteraction

# Turn the promoted support-equipment sprites into lightweight exploration
# gameplay without touching the proven world_v165 inheritance chain. Nearby
# equipment highlights, E/F inspects it, and every six unique inspections
# improves the player's Operations rating by one point (max +5 per campaign).

const INSPECT_RANGE := 82.0
const HIGHLIGHT_RANGE := 126.0
const SURVEY_MILESTONE_SIZE := 6
const MAX_OPERATIONS_BONUS := 5
const HIGHLIGHT_TINT := Color("b8ffcc")
const INSPECTED_TINT := Color("eafff0")

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

func _ready() -> void:
    set_process(true)
    set_process_unhandled_input(true)
    _restore_progress()
    prompt = Label.new()
    prompt.name = "EquipmentInspectPrompt"
    prompt.visible = false
    prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
    prompt.z_index = 60
    prompt.add_theme_font_size_override("font_size", 12)
    prompt.add_theme_color_override("font_color", Color("8affbd"))
    prompt.add_theme_color_override("font_outline_color", Color("102019"))
    prompt.add_theme_constant_override("outline_size", 4)
    add_child(prompt)

func _process(_delta: float) -> void:
    var next := _nearest_equipment(HIGHLIGHT_RANGE)
    if next != highlighted:
        _apply_resting_tint(highlighted)
        highlighted = next
    if highlighted != null:
        highlighted.self_modulate = HIGHLIGHT_TINT
    _update_prompt()

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo or key_event.keycode not in [KEY_E, KEY_F]:
        return
    var host := _world()
    if host == null or get_viewport().gui_get_focus_owner() != null:
        return
    if int(host.get("pending_interaction_idx")) >= 0:
        return
    # Preserve existing company/NPC interactions when they are actually in
    # interaction range. Equipment only takes E/F when it is the local target.
    if host.has_method("_nearest_entity") and host.has_method("_entity_in_interact_range"):
        var entity_idx := int(host.call("_nearest_entity"))
        if entity_idx >= 0 and bool(host.call("_entity_in_interact_range", entity_idx)):
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
    sprite.self_modulate = HIGHLIGHT_TINT
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

func _apply_resting_tint(sprite: Sprite2D) -> void:
    if sprite == null:
        return
    sprite.self_modulate = INSPECTED_TINT if inspected.has(String(sprite.name)) else Color.WHITE

func _update_prompt() -> void:
    if prompt == null:
        return
    var target := _nearest_equipment(INSPECT_RANGE)
    if target == null:
        prompt.visible = false
        return
    var info: Dictionary = EQUIPMENT_INFO.get(String(target.name), {})
    var label := String(info.get("label", "EQUIPMENT")).to_upper()
    var state := "SURVEYED" if inspected.has(String(target.name)) else "NEW"
    prompt.text = "[E/F] INSPECT  •  %s  •  %s  •  %d/%d" % [label, state, inspected.size(), EQUIPMENT_INFO.size()]
    prompt.position = target.position + Vector2(-72.0, -86.0)
    prompt.visible = true

func nearest_equipment_name() -> String:
    var target := _nearest_equipment(HIGHLIGHT_RANGE)
    return String(target.name) if target != null else ""

func debug_ready() -> bool:
    var props := _props()
    var host := _world()
    if props == null or host == null or EQUIPMENT_INFO.size() != 33:
        return false
    if not props.has_method("live_sprite_count") or int(props.call("live_sprite_count")) != 33:
        return false
    return host.has_method("_feedback") and host.has_method("debug_v165_diesel_ready")
