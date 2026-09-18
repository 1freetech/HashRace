class_name HashRaceRackContainer
extends Node2D

## Reusable rack/container with explicit physical slots.
## Slots can be ASIC, COOLING, POWER, NETWORK, or ANY.

signal layout_changed
signal installed_item_changed

@export_range(1, 64, 1) var slot_count: int = 8
@export var default_slot_type: String = "ASIC"
@export var slot_spacing := Vector2(0.0, 18.0)
@export var auto_build_slots := true

var slots: Array[HashRaceRackSlot] = []

func _ready() -> void:
    if auto_build_slots and slots.is_empty():
        rebuild_slots()

func rebuild_slots() -> void:
    for slot in slots:
        if is_instance_valid(slot):
            slot.queue_free()
    slots.clear()

    var start := -slot_spacing * float(slot_count - 1) * 0.5
    for i in range(slot_count):
        var slot := HashRaceRackSlot.new()
        slot.name = "Slot_%02d" % i
        slot.slot_id = "%s:%02d" % [name, i]
        slot.slot_type = default_slot_type
        slot.position = start + slot_spacing * float(i)
        slot.item_installed.connect(_on_slot_changed)
        slot.item_removed.connect(_on_slot_changed)
        add_child(slot)
        slots.append(slot)
    layout_changed.emit()
    queue_redraw()

func first_free_slot(item: HashRaceItemResource) -> HashRaceRackSlot:
    for slot in slots:
        if slot.can_install(item):
            return slot
    return null

func install(item: HashRaceItemResource) -> bool:
    var slot := first_free_slot(item)
    return slot.install_item(item) if slot != null else false

func installed_items() -> Array[HashRaceItemResource]:
    var result: Array[HashRaceItemResource] = []
    for slot in slots:
        if slot.installed_hardware != null:
            result.append(slot.installed_hardware)
    return result

func aggregate_live_stats() -> Dictionary:
    var hashrate_ph := 0.0
    var load_mw := 0.0
    var heat_mw := 0.0
    var cooling_mw := 0.0
    for item in installed_items():
        hashrate_ph += item.base_hashrate_ph
        load_mw += item.power_draw_mw
        heat_mw += item.heat_generated_mw
        cooling_mw += item.cooling_capacity_mw
    return {
        "hashrate_ph": hashrate_ph,
        "load_mw": load_mw,
        "heat_mw": heat_mw,
        "cooling_mw": cooling_mw
    }

func _on_slot_changed(_item: HashRaceItemResource) -> void:
    installed_item_changed.emit()
    queue_redraw()

func _draw() -> void:
    var h := maxf(34.0, float(slot_count) * absf(slot_spacing.y) + 22.0)
    var rect := Rect2(-24.0, -h * 0.5, 48.0, h)
    draw_rect(rect, Color("101820"), true)
    draw_rect(rect, Color("59727d"), false, 2.0)
    draw_rect(Rect2(rect.position + Vector2(4.0, 4.0), Vector2(rect.size.x - 8.0, 5.0)), Color("2c3b43"), true)
