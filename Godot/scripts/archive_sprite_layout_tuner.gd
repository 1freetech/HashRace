extends Node2D
class_name HashRaceArchiveSpriteLayoutTuner

# Keep every promoted sprite-sheet object in the live world, but stop presenting
# them as a rigid proof grid. This helper runs after ArchiveSpriteProps builds its
# 33 Sprite2D children, applies authored relative scale, hand-places them into
# functional campus service zones, and rebuilds navigation from the final ground
# contacts. The source PNGs and archive-sprite renderer remain untouched.

# Two deliberate service verges use the negative space between the authored
# building rows and roads. Equipment is grouped by function, with small y offsets
# so the campus reads as operating infrastructure rather than a sprite lineup.
const POSITION_BY_NODE := {
    # Upper service verge: keep ground contacts north of the building roof line
    # so these later-added child sprites never paint over the root-drawn buildings.
    "ArchiveProp_Ats": Vector2(245, 572),
    "ArchiveProp_Handhole": Vector2(318, 588),
    "ArchiveProp_Bollards": Vector2(392, 566),
    "ArchiveProp_CoolingUnit": Vector2(510, 576),
    "ArchiveProp_ElectricalUnit": Vector2(592, 562),
    "ArchiveProp_EnergyUnit": Vector2(676, 586),
    "ArchiveProp_HarmonicFilter": Vector2(790, 570),
    "ArchiveProp_Bench": Vector2(870, 590),
    "ArchiveProp_LightningProtection": Vector2(958, 562),
    "ArchiveProp_LoadBank": Vector2(1085, 582),
    "ArchiveProp_Eyewash": Vector2(1170, 565),
    "ArchiveProp_CableReel": Vector2(1252, 590),
    "ArchiveProp_MvEquipment": Vector2(1390, 568),
    "ArchiveProp_Hydrant": Vector2(1470, 590),
    "ArchiveProp_TruckScale": Vector2(1572, 560),
    "ArchiveProp_Telecom": Vector2(1660, 586),

    # Lower service verge: move off the roadway into the grass/service strip
    # between the road and the next building row.
    "ArchiveProp_MvTermination": Vector2(245, 1038),
    "ArchiveProp_DiagnosticStation": Vector2(325, 1062),
    "ArchiveProp_WeatherStation": Vector2(407, 1030),
    "ArchiveProp_PowerService": Vector2(515, 1052),
    "ArchiveProp_CoolingService": Vector2(600, 1030),
    "ArchiveProp_WashdownStation": Vector2(687, 1064),
    "ArchiveProp_Pump": Vector2(810, 1038),
    "ArchiveProp_SaltStorage": Vector2(895, 1062),
    "ArchiveProp_Trench": Vector2(982, 1030),
    "ArchiveProp_SecurityFirewall": Vector2(1095, 1056),
    "ArchiveProp_Cctv": Vector2(1175, 1030),
    "ArchiveProp_OilWaterSeparator": Vector2(1260, 1066),
    "ArchiveProp_Statcom": Vector2(1385, 1036),
    "ArchiveProp_FiberPedestal": Vector2(1465, 1062),
    "ArchiveProp_GateControl": Vector2(1548, 1030),
    "ArchiveProp_CompressedAir": Vector2(1640, 1060),
    "ArchiveProp_Drain": Vector2(1710, 1030),
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

# Small semi-transparent gravel/concrete islands keep equipment grounded without
# reading like giant proof rectangles or visually painting over nearby buildings.
# Gaps preserve the authored grass texture and make the infrastructure feel placed
# into the campus rather than laid on top of it.
const SERVICE_PADS := [
    Rect2(500, 544, 190, 48),
    Rect2(785, 544, 190, 48),
    Rect2(1080, 544, 190, 48),
    Rect2(1380, 544, 200, 48),
    Rect2(500, 1016, 190, 48),
    Rect2(800, 1016, 190, 48),
    Rect2(1080, 1016, 190, 48),
    Rect2(1375, 1016, 190, 48),
]

func _ready() -> void:
    # Keep the pads at normal canvas depth. ArchiveSpriteProps is created after
    # the root world draw, and its y-sorted children then render equipment over
    # these pads. A negative z-index hid the pads behind the terrain.
    z_index = 0
    call_deferred("_apply_layout")
    queue_redraw()

func _draw() -> void:
    for pad in SERVICE_PADS:
        draw_rect(pad, Color("66746070"))
        draw_rect(pad, Color("8a968188"), false, 1.0)

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
