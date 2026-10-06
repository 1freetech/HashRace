extends Node

# Turns the promoted service-equipment art into a light exploration objective.
# Walking close to a new prop logs it once and flashes the inspected equipment.

const INSPECTION_RADIUS := 58.0
var discovered: Dictionary = {}
var timer := 0.0

func _process(delta: float) -> void:
    timer -= delta
    if timer > 0.0:
        return
    timer = 0.2
    var world := get_parent()
    var props := world.get_node_or_null("ArchiveSpriteProps")
    if props == null:
        return
    var player_pos: Variant = world.get("rep_pos")
    var sprites: Variant = props.get("live_sprites")
    if not player_pos is Vector2 or not sprites is Array:
        return
    for item in sprites:
        var sprite := item as Sprite2D
        if sprite == null or discovered.has(String(sprite.name)):
            continue
        if (player_pos as Vector2).distance_to(sprite.position) > INSPECTION_RADIUS:
            continue
        discovered[String(sprite.name)] = true
        sprite.modulate = Color("b9ffd0")
        create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.65)
        if world.has_method("_feedback"):
            var label := String(sprite.name).trim_prefix("ArchiveProp_")
            world.call("_feedback", "SITE INSPECTION: %s logged  •  %d/33 discovered" % [label, discovered.size()])
        break

func debug_discovery_count() -> int:
    return discovered.size()
