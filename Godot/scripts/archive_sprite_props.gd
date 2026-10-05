extends Node2D
class_name HashRaceArchiveSpriteProps

# Promoted reference sprites are intentionally small support props. Keep every
# atlas cell at a 32 px live-map footprint so artwork never overwhelms the
# player, roads, containers, or interactive gameplay layers.
const LIVE_PROP_DISPLAY_PX := 32.0
const LIVE_PROP_COLLISION := Vector2(28.0, 8.0)

const SHEETS = [
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_ats_handhole_bollards_96x32.png","cell":32,"names":["ats","handhole","bollards"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_cooling_electrical_energy_96x32.png","cell":32,"names":["cooling_unit","electrical_unit","energy_unit"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_harmonicfilter_bench_lightning_192x64.png","cell":64,"names":["harmonic_filter","bench","lightning_protection"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_loadbank_eyewash_cablereel_96x32.png","cell":32,"names":["load_bank","eyewash","cable_reel"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_mv_hydrant_truckscale_96x32.png","cell":32,"names":["mv_equipment","hydrant","truck_scale"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_mvtermination_diag_weather_96x32.png","cell":32,"names":["mv_termination","diagnostic_station","weather_station"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_power_cooling_washdown_96x32.png","cell":32,"names":["power_service","cooling_service","washdown_station"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_pump_salt_trench_96x32.png","cell":32,"names":["pump","salt_storage","trench"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_security_firewall_cctv_oilwater_96x32.png","cell":32,"names":["security_firewall","cctv","oil_water_separator"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_statcom_fiberped_gate_96x32.png","cell":32,"names":["statcom","fiber_pedestal","gate_control"]},
    {"path":"res://art/props/hr_sprite_sheets/2026-10-04_telecom_air_drain_192x64.png","cell":64,"names":["telecom","compressed_air","drain"]},
]

const CLUSTER_ANCHORS = [
    Vector2i(400, 700), Vector2i(730, 700), Vector2i(1060, 700), Vector2i(1390, 700),
    Vector2i(400, 820), Vector2i(730, 820), Vector2i(1060, 820), Vector2i(1390, 820),
    Vector2i(400, 940), Vector2i(730, 940), Vector2i(1060, 940),
]

const NONBLOCKING = {
    "handhole": true,
    "bench": true,
    "eyewash": true,
    "hydrant": true,
    "weather_station": true,
    "cctv": true,
    "drain": true,
}

var live_sprites: Array[Sprite2D] = []
var collision_footprints: Array[Rect2] = []
var loaded_sheet_count: int = 0

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    y_sort_enabled = true
    _build_props()
    call_deferred("_connect_navigation_refresh")

func _build_props() -> void:
    for sheet_index in range(SHEETS.size()):
        var spec: Dictionary = SHEETS[sheet_index]
        var texture: Texture2D = load(String(spec["path"])) as Texture2D
        if texture == null:
            push_error("HashRaceArchiveSpriteProps: could not load %s" % String(spec["path"]))
            continue
        loaded_sheet_count += 1
        var cell: int = int(spec["cell"])
        var names: Array = Array(spec["names"])
        for cell_index in range(names.size()):
            var region := AtlasTexture.new()
            region.atlas = texture
            region.region = Rect2(float(cell_index * cell), 0.0, float(cell), float(cell))
            region.filter_clip = true

            var sprite := Sprite2D.new()
            sprite.name = "ArchiveProp_%s" % String(names[cell_index]).to_pascal_case()
            sprite.texture = region
            sprite.centered = true
            # Offset by half the source cell before scaling. This pins the visible
            # bottom edge exactly to sprite.position for predictable ground contact.
            sprite.offset = Vector2(0.0, -float(cell) * 0.5)
            sprite.scale = Vector2.ONE * (LIVE_PROP_DISPLAY_PX / float(cell))
            sprite.position = _ground_position(sheet_index, cell_index)
            sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            sprite.set_meta("hashrace_archive_sheet", String(spec["path"]))
            sprite.set_meta("hashrace_archive_cell", cell_index)
            sprite.set_meta("hashrace_live_display_px", LIVE_PROP_DISPLAY_PX)
            add_child(sprite)
            live_sprites.append(sprite)

            var prop_name: String = String(names[cell_index])
            if not NONBLOCKING.has(prop_name):
                collision_footprints.append(Rect2(
                    sprite.position.x - LIVE_PROP_COLLISION.x * 0.5,
                    sprite.position.y - LIVE_PROP_COLLISION.y,
                    LIVE_PROP_COLLISION.x,
                    LIVE_PROP_COLLISION.y
                ))

func _ground_position(sheet_index: int, cell_index: int) -> Vector2:
    var anchor: Vector2i = CLUSTER_ANCHORS[sheet_index]
    return Vector2(float(anchor.x + (cell_index - 1) * 52), float(anchor.y))

func _connect_navigation_refresh() -> void:
    var host: Node = get_parent()
    if host == null:
        return
    var inventory: Variant = host.get("infrastructure_inventory")
    var inventory_object: Object = inventory as Object
    if inventory_object != null and inventory_object.has_signal("deployment_changed"):
        var callback := Callable(self, "_register_navigation")
        if not inventory_object.is_connected("deployment_changed", callback):
            inventory_object.connect("deployment_changed", callback, CONNECT_DEFERRED)
    _register_navigation()

func _register_navigation() -> void:
    var host: Node = get_parent()
    if host == null:
        return
    var navigation: Variant = host.get("grid_nav")
    if navigation == null or not navigation.has_method("block_rect"):
        return
    for footprint in collision_footprints:
        navigation.call("block_rect", footprint)

func live_sprite_count() -> int:
    return live_sprites.size()

func live_sheet_count() -> int:
    return loaded_sheet_count

func debug_ready() -> bool:
    if loaded_sheet_count != SHEETS.size() or live_sprites.size() != 33:
        return false
    if collision_footprints.size() < 20:
        return false
    for sprite in live_sprites:
        if sprite == null or sprite.texture == null or sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
            return false
        if sprite.scale.x > 1.0 or sprite.scale.y > 1.0:
            return false
    return true
