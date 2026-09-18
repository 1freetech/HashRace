class_name HashRaceRackSlot
extends Node2D

## Physical hardware slot. Compatible Resource data must occupy a real slot
## before the physical deployment layer can count it.

signal item_installed(item)
signal item_removed(item)

@export var slot_type: String = "ASIC"
@export var slot_id: String = ""
@export var installed_hardware: Resource

func is_empty() -> bool:
    return installed_hardware == null

func can_install(item: Resource) -> bool:
    return (
        item != null
        and installed_hardware == null
        and item.has_method("is_compatible_with")
        and bool(item.call("is_compatible_with", slot_type))
    )

func install_item(item: Resource) -> bool:
    if not can_install(item):
        return false
    installed_hardware = item
    queue_redraw()
    item_installed.emit(item)
    return true

func remove_item() -> Resource:
    var previous := installed_hardware
    if previous == null:
        return null
    installed_hardware = null
    queue_redraw()
    item_removed.emit(previous)
    return previous

func _draw() -> void:
    var rect := Rect2(Vector2(-14.0, -7.0), Vector2(28.0, 14.0))
    var accent := Color("37f6a0") if installed_hardware != null else Color("35515d")
    draw_rect(rect, Color("061117"), true)
    draw_rect(rect, accent, false, 1.0)
    if installed_hardware != null:
        draw_rect(Rect2(-10.0, -3.0, 20.0, 6.0), accent.darkened(0.35), true)
        draw_circle(Vector2(9.0, 0.0), 2.0, accent)
