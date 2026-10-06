extends Node2D
class_name HashRaceArchiveSpriteLayoutTuner

# Keep every promoted sprite-sheet object in the live world while avoiding
# them as a rigid proof grid. This helper runs after ArchiveSpriteProps builds its
# 33 Sprite2D children, applies authored relative scale, hand-places them into
# functional campus service zones, and rebuilds navigation from the final ground
# contacts. The source PNGs and archive-sprite renderer remain untouched.

const POSITION_BY_NODE := {
    "ArchiveProp_Ats": Vector2(170, 705),
    "ArchiveProp_Handhole": Vector2(260, 727),
    "ArchiveProp_Bollards": Vector2(345, 695),
    "ArchiveProp_CoolingUnit": Vector2(490, 720),
    "ArchiveProp_ElectricalUnit": Vector2(590, 700),
    "ArchiveProp_EnergyUnit": Vector2(685, 732),
    "ArchiveProp_HarmonicFilter": Vector2(820, 708),
    "ArchiveProp_Bench": Vector2(925, 738),
    "ArchiveProp_LightningProtection": Vector2(1025, 696),
    "ArchiveProp_LoadBank": Vector2(1180, 730),
    "ArchiveProp_Eyewash": Vector2(1285, 706),
    "ArchiveProp_CableReel": Vector2(1380, 742),
    "ArchiveProp_MvEquipment": Vector2(1515, 704),
    "ArchiveProp_Hydrant": Vector2(1610, 735),
    "ArchiveProp_TruckScale": Vector2(1700, 692),
    "ArchiveProp_MvTermination": Vector2(190, 850),
    "ArchiveProp_DiagnosticStation": Vector2(305, 822),
    "ArchiveProp_WeatherStation": Vector2(410, 858),
    "ArchiveProp_PowerService": Vector2(565, 842),
    "ArchiveProp_CoolingService": Vector2(665, 870),
    "ArchiveProp_WashdownStation": Vector2(775, 832),
    "ArchiveProp_Pump": Vector2(930, 858),
    "ArchiveProp_SaltStorage": Vector2(1038, 826),
    "ArchiveProp_Trench": Vector2(1148, 872),
    "ArchiveProp_SecurityFirewall": Vector2(1295, 830),
    "ArchiveProp_Cctv": Vector2(1405, 866),
    "ArchiveProp_OilWaterSeparator": Vector2(1518, 820),
    "ArchiveProp_Statcom": Vector2(1650, 858),
    "ArchiveProp_FiberPedestal": Vector2(1710, 905),
    "ArchiveProp_GateControl": Vector2(1590, 936),
    "ArchiveProp_Telecom": Vector2(430, 995),
    "ArchiveProp_CompressedAir": Vector2(565, 1020),
    "ArchiveProp_Drain": Vector2(700, 988),
}

# The archive renderer deliberately gives every crop enough pixels to be legible.
# These multipliers then restore relative real-world hierarchy: access/safety
# details stay visible without reading as the same physical size as switchgear.
const SCALE_BY_NODE := {
    "ArchiveProp_Handhole": 0.72,
    "ArchiveProp_Bollards": 0.78,
    "ArchiveProp_Bench": 0.78,
    "ArchiveProp_Eyewash": 0.76,
    "ArchiveProp_CableReel": 0.82,
    "ArchiveProp_Hydrant": 0.82,
    "ArchiveProp_WeatherStation": 0.84,
    "ArchiveProp_Cctv": 0.76,
    "ArchiveProp_FiberPedestal": 0.80,
    "ArchiveProp_GateControl": 0.86,
    "ArchiveProp_Drain": 0.76,
    "ArchiveProp_Trench": 0.82,
    "ArchiveProp_DiagnosticStation": 0.90,
    "ArchiveProp_WashdownStation": 0.90,
    "ArchiveProp_CompressedAir": 0.94,
    "ArchiveProp_Telecom": 0.94,
}

const NONBLOCKING_NODES := {
    "ArchiveProp_Handhole": true,
    "ArchiveProp_Bench": true,
    "ArchiveProp_Eyewash": true,
    "ArchiveProp_Hydrant": true,
    "ArchiveProp_WeatherStation": true,
    "ArchiveProp_Cctv": true,
    "ArchiveProp_Drain": true,
}

# A few restrained service pads visually tie the heaviest support equipment into
# the existing campus without adding a second road system or carpeting the grass.
const SERVICE_PADS := [
    Rect2(450, 676, 275, 88),
    Rect2(790, 674, 275, 92),
    Rect2(1148, 682, 278, 92),
    Rect2(1500, 674, 245, 98),
    Rect2(530, 808, 280, 92),
    Rect2(895, 808, 285, 102),
]

func _ready() -> void:
    z_index = -2
    call_deferred("_apply_layout")
    queue_redraw()

func _draw() -> void:
    for pad in SERVICE_PADS:
        draw_rect(pad, Color("667460"))
        draw_rect(pad, Color("7b8875"), false, 2.0)

func _apply_layout() -> void:
    var props := get_parent()
    if props == null:
        return
    var sprites_value: Variant = props.get("live_sprites")
    if not sprites_value is Array:
        return
    var sprites: Array = sprites_value
    if sprites.is_empty():
        return

    for item in sprites:
        var sprite := item as Sprite2D
        if sprite == null:
            continue
        var node_name := String(sprite.name)
        if POSITION_BY_NODE.has(node_name):
            sprite.position = POSITION_BY_NODE[node_name]
        var scale_multiplier := float(SCALE_BY_NODE.get(node_name, 1.0))
        sprite.scale *= scale_multiplier
        sprite.set_meta("hashrace_layout_scale_multiplier", scale_multiplier)
        sprite.set_meta("hashrace_layout_tuned", true)

    _rebuild_collision_footprints(props, sprites)

func _rebuild_collision_footprints(props: Node, sprites: Array) -> void:
    var footprints: Array[Rect2] = []
    for item in sprites:
        var sprite := item as Sprite2D
        if sprite == null or sprite.texture == null:
            continue
        var node_name := String(sprite.name)
        if NONBLOCKING_NODES.has(node_name):
            continue
        var displayed_size := sprite.texture.get_size() * sprite.scale
        var collision_width := clampf(displayed_size.x * 0.62, 24.0, 64.0)
        var collision_height := clampf(displayed_size.y * 0.16, 10.0, 16.0)
        footprints.append(Rect2(
            sprite.position.x - collision_width * 0.5,
            sprite.position.y - collision_height,
            collision_width,
            collision_height
        ))
    props.set("collision_footprints", footprints)
