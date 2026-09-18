extends "res://scripts/world_v087.gd"

# Hash Race v0.088 world-scale and camera pass.
# Buildings gain materially larger footprints while characters keep their
# detailed source art. A wider CITY camera view handles screen real estate,
# painter depth uses the same scale contract as navigation, and front doors get
# clear visual entry cues. Node-based interiors can use SceneManager/Doorway.

const CameraProportionController = preload("res://scripts/camera_proportion_controller.gd")

const V088_WORLD_SCALE_REVISION: int = 1
const V088_ENTRY_DARK := Color("020509")
const V088_ENTRY_LIGHT := Color("f1f6f5")
const V088_ENTRY_MAT := Color("25343a")

var camera_proportion_controller: Node

func _ready() -> void:
    super._ready()
    _install_camera_proportion_controller()
    set_meta("hashrace_v088_world_scale_revision", V088_WORLD_SCALE_REVISION)
    set_meta("hashrace_world_tile_px", WorldScale.WORLD_TILE)
    set_meta("hashrace_default_camera_mode", "CITY")
    queue_redraw()

func _install_camera_proportion_controller() -> void:
    if is_instance_valid(camera_proportion_controller):
        return
    camera_proportion_controller = CameraProportionController.new()
    camera_proportion_controller.name = "CameraProportionController"
    add_child(camera_proportion_controller)
    camera_proportion_controller.bind(camera, WORLD_SIZE, 0)

func _v080_entity_depth(entity: Dictionary) -> float:
    var kind := String(entity.get("kind", ""))
    var pos: Vector2 = entity.get("pos", Vector2.ZERO)
    if WorldScale.is_building_kind(kind):
        # Procedural buildings cannot fade individual roof Sprite2D nodes.
        # When the player walks immediately behind one, move the building just
        # before the player in painter order to create a clean roof-cutaway
        # effect. Node-based buildings use roof_fade_area.gd instead.
        if _v088_player_behind_building(kind, pos):
            return rep_pos.y - 1.0
        return WorldScale.depth_y(kind, pos)
    return super._v080_entity_depth(entity)

func _v088_player_behind_building(kind: String, pos: Vector2) -> bool:
    var rect := WorldScale.visual_rect(kind, pos).grow(16.0)
    return (
        rep_pos.x >= rect.position.x
        and rep_pos.x <= rect.end.x
        and rep_pos.y >= rect.position.y - 28.0
        and rep_pos.y <= pos.y + 4.0
    )

func _entity_at(world_pos: Vector2) -> int:
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind := String(entity.get("kind", ""))
        var pos: Vector2 = entity.get("pos", Vector2.ZERO)
        if WorldScale.is_building_kind(kind):
            if WorldScale.visual_rect(kind, pos).grow(18.0).has_point(world_pos):
                return i
        elif pos.distance_to(world_pos) <= 105.0:
            return i
    return -1

func _nearest_entity() -> int:
    var best_idx: int = -1
    var best_distance: float = INTERACT_DISTANCE
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind := String(entity.get("kind", ""))
        var pos: Vector2 = entity.get("pos", Vector2.ZERO)
        var target := pos
        if WorldScale.is_building_kind(kind):
            target = WorldScale.front_door_world_pos(kind, pos)
        var distance := rep_pos.distance_to(target)
        if distance < best_distance:
            best_distance = distance
            best_idx = i
    return best_idx

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var kind := String(entity.get("kind", "hq"))
    var profile_idx: int = int(entity.get("profile_idx", company_idx))
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    if kind == "rival" and bool(rivals[int(entity["rival_idx"])]["merged"]):
        accent = Color("657078")
    var size_value := WorldScale.size_for_kind(kind)
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))
    _draw_pixel_facility(pos, size_value, accent, 4, "")
    _draw_facility_surface_detail(pos, size_value, accent, profile_idx + 807)
    _draw_v088_hashhall_detail(pos, size_value, accent)
    _draw_v088_entry_cue(kind, pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 44.0)

func _draw_partner_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var kind := "partner"
    var partner_idx: int = int(entity["partner_idx"])
    var accent: Color = PARTNER_ACCENTS[partner_idx]
    var size_value := WorldScale.PARTNER_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))
    _draw_pixel_facility(pos, size_value, accent, 3, "")
    _draw_facility_surface_detail(pos, size_value, accent, partner_idx + 831)
    _draw_v088_entry_cue(kind, pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 42.0)

func _draw_machine_market(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var kind := "machines"
    var accent := Color("bd8cff")
    var size_value := WorldScale.SERVICE_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))
    _draw_pixel_facility(pos, size_value, accent, 3, "")
    _draw_facility_surface_detail(pos, size_value, accent, 851)
    for col in range(4):
        for row in range(3):
            var rack := Rect2(pos + Vector2(-92.0 + float(col) * 58.0, -38.0 + float(row) * 24.0), Vector2(38.0, 15.0))
            draw_rect(rack, Color("071018"), true)
            draw_rect(Rect2(rack.position + Vector2(5.0, 4.0), Vector2(7.0, 5.0)), CHARACTER_LABEL_GREEN, true)
            draw_rect(Rect2(rack.position + Vector2(16.0, 4.0), Vector2(15.0, 3.0)), Color("53626b"), true)
    _draw_v088_entry_cue(kind, pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 40.0)

func _draw_power_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var kind := "power"
    var accent := Color("ffd36e")
    var size_value := WorldScale.SERVICE_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))
    _draw_pixel_facility(pos, size_value, accent, 3, "")
    _draw_facility_surface_detail(pos, size_value, accent, 863)
    for x in [-72.0, 0.0, 72.0]:
        draw_rect(Rect2(pos + Vector2(x - 15.0, -22.0), Vector2(30.0, 30.0)), Color("101820"), true)
        draw_rect(Rect2(pos + Vector2(x - 9.0, -16.0), Vector2(18.0, 18.0)), accent, false, 3.0)
        draw_line(pos + Vector2(x, -31.0), pos + Vector2(x, -48.0), Color("9aa7ad"), 3.0)
    _draw_v088_entry_cue(kind, pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 40.0)

func _draw_bank_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var kind := "bank"
    var accent: Color = ORANGE
    var size_value := WorldScale.SERVICE_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))
    _draw_pixel_facility(pos, size_value, accent, 3, "")
    _draw_facility_surface_detail(pos, size_value, accent, 879)
    for x in [-72.0, -24.0, 24.0, 72.0]:
        draw_rect(Rect2(pos + Vector2(x - 5.0, -42.0), Vector2(10.0, 72.0)), accent.darkened(0.42), true)
        draw_rect(Rect2(pos + Vector2(x - 2.0, -39.0), Vector2(4.0, 66.0)), accent.lightened(0.06), true)
    _draw_v088_entry_cue(kind, pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 40.0)

func _draw_land_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var kind := "land"
    var accent := Color("8ed06c")
    var size_value := WorldScale.SERVICE_SIZE
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))
    _draw_pixel_facility(pos, size_value, accent, 3, "")
    _draw_facility_surface_detail(pos, size_value, accent, 891)
    for gx in range(3):
        for gy in range(2):
            var parcel := Rect2(pos + Vector2(-78.0 + float(gx) * 58.0, -32.0 + float(gy) * 36.0), Vector2(42.0, 24.0))
            draw_rect(parcel, accent.darkened(0.58), false, 2.0)
            draw_rect(Rect2(parcel.position + Vector2(6.0, 6.0), Vector2(8.0, 5.0)), accent.darkened(0.18), true)
    _draw_v088_entry_cue(kind, pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 40.0)

func _draw_v088_hashhall_detail(pos: Vector2, size_value: Vector2, accent: Color) -> void:
    var width := size_value.x - 72.0
    for i in range(5):
        var x := pos.x - width * 0.5 + float(i) * (width / 4.0) - 14.0
        draw_rect(Rect2(Vector2(x, pos.y + 22.0), Vector2(28.0, 10.0)), Color("081116"), true)
        draw_rect(Rect2(Vector2(x + 5.0, pos.y + 25.0), Vector2(18.0, 3.0)), accent.darkened(0.18), true)

func _draw_v088_entry_cue(kind: String, pos: Vector2, size_value: Vector2, accent: Color) -> void:
    var bottom_y := pos.y + size_value.y * 0.38
    var door_h := minf(WorldScale.DOOR_VISUAL_HEIGHT, size_value.y * 0.58)
    var door_w := WorldScale.DOOR_VISUAL_WIDTH
    var door_rect := Rect2(
        Vector2(pos.x - door_w * 0.5, bottom_y - door_h),
        Vector2(door_w, door_h)
    )
    draw_rect(door_rect, V088_ENTRY_DARK, true)
    draw_rect(door_rect.grow(-4.0), accent.darkened(0.50), true)
    draw_rect(Rect2(door_rect.position + Vector2(6.0, 8.0), Vector2(door_w - 12.0, 6.0)), accent.lightened(0.16), true)
    draw_rect(Rect2(Vector2(door_rect.end.x - 12.0, door_rect.position.y + door_h * 0.55), Vector2(4.0, 4.0)), V088_ENTRY_LIGHT, true)

    var mat := Rect2(Vector2(pos.x - 34.0, bottom_y + 8.0), Vector2(68.0, 18.0))
    draw_rect(mat, V088_ENTRY_MAT, true)
    draw_rect(mat.grow(-3.0), accent.darkened(0.42), false, 2.0)

    var door_target := WorldScale.front_door_world_pos(kind, pos)
    if rep_pos.distance_to(door_target) <= INTERACT_DISTANCE + 36.0:
        var pulse := 0.55 + 0.45 * absf(sin(float(Time.get_ticks_msec()) / 220.0))
        var glow := Color(accent.r, accent.g, accent.b, pulse)
        draw_circle(Vector2(pos.x, bottom_y + 37.0), 12.0, glow, false, 3.0)
        draw_line(Vector2(pos.x - 6.0, bottom_y + 37.0), Vector2(pos.x + 6.0, bottom_y + 37.0), V088_ENTRY_LIGHT, 2.0)

func apply_scene_spawn(spawn_name: String, payload: Dictionary) -> void:
    # SceneManager can restore the live procedural world without creating a
    # duplicate Player node. Interiors may return a direct world position.
    if payload.has("world_position"):
        rep_pos = VisualStack.snap_to_pixel(Vector2(payload["world_position"]))
        click_target = rep_pos
        has_click_target = false
        if is_instance_valid(camera):
            camera.position = rep_pos
        queue_redraw()

func debug_v088_ready() -> bool:
    return (
        V088_WORLD_SCALE_REVISION == 1
        and WorldScale.proportions_ready()
        and is_instance_valid(camera_proportion_controller)
        and camera_proportion_controller.debug_camera_proportion_ready()
    )
