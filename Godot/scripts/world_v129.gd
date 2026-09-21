extends "res://scripts/world_v128.gd"

# Hash Race v0.129: electrical distribution visual pass.
# Adds one authored image sheet to the live mining campus and uses it to make
# the power path readable: transformer -> switchgear -> PDU -> container.

const V129_ELECTRICAL_REVISION := 1
const ElectricalDistributionCatalog = preload("res://scripts/electrical_distribution_catalog.gd")
var v129_electrical_texture: Texture2D

func _ready() -> void:
    v129_electrical_texture = ElectricalDistributionCatalog.texture()
    super._ready()
    set_meta("hashrace_v129_electrical_asset_live", v129_electrical_texture != null)
    queue_redraw()

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)
    if v129_electrical_texture == null:
        return
    # Keep the equipment beside the road and away from the player path.
    _v129_draw_asset("switchgear", origin + Vector2(82.0, 112.0), Vector2(104.0, 104.0))
    _v129_draw_asset("pdu", origin + Vector2(-36.0, 112.0), Vector2(82.0, 82.0))
    _v129_draw_asset("junction_box", origin + Vector2(-116.0, 108.0), Vector2(62.0, 62.0))
    _v129_draw_power_path(origin)

func _v129_draw_asset(id: String, center: Vector2, size_value: Vector2) -> void:
    var source := ElectricalDistributionCatalog.region(id)
    var dest := Rect2(center - size_value * 0.5, size_value)
    draw_texture_rect_region(v129_electrical_texture, dest, Rect2(source))

func _v129_draw_power_path(origin: Vector2) -> void:
    # Dark cable overlay visually connects the distribution chain without
    # adding another road/tile layer.
    var points := PackedVector2Array([
        origin + Vector2(205.0, 145.0),
        origin + Vector2(132.0, 145.0),
        origin + Vector2(82.0, 112.0),
        origin + Vector2(-36.0, 112.0),
        origin + Vector2(-116.0, 108.0),
        origin + Vector2(-170.0, -50.0),
    ])
    draw_polyline(points, Color("161c20"), 8.0, true)
    draw_polyline(points, Color("465158"), 3.0, true)

func debug_v129_ready() -> bool:
    return V129_ELECTRICAL_REVISION == 1 and v129_electrical_texture != null and debug_v128_ready()
