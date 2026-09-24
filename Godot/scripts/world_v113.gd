extends "res://scripts/world_v112.gd"

# Hash Race v0.113 industrial-site replacement pass.
# Hard-removes the inherited house-like building silhouettes from the live
# overworld. Every interactive site now renders as industrial mining/power
# infrastructure even when optional imported PNG sheets are not yet present.

const V113_INDUSTRIAL_SITE_REVISION := 1
const V113_STEEL := Color("566269")
const V113_STEEL_LIGHT := Color("96a0a4")
const V113_DARK := Color("11181d")
const V113_PANEL := Color("222d33")
const V113_WARNING := Color("f6b73c")
const V113_CYAN := Color("45dff2")
const V113_GREEN := Color("39ff75")

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v113_industrial_site_revision", V113_INDUSTRIAL_SITE_REVISION)
    queue_redraw()

func _v113_draw_industrial_base(pos: Vector2, size_value: Vector2, accent: Color) -> Rect2:
    _v103_draw_building_shadow(pos, size_value)
    var rect := Rect2(
        VisualStack.snap_to_pixel(pos + Vector2(-size_value.x * 0.5, -size_value.y * 0.56)),
        size_value
    )
    draw_rect(rect.grow(4.0), Color("080d10"), true)
    draw_rect(rect, V113_STEEL, true)
    draw_rect(Rect2(rect.position + Vector2(5.0, 5.0), Vector2(rect.size.x - 10.0, 13.0)), V113_STEEL_LIGHT, true)
    draw_rect(Rect2(rect.position + Vector2(5.0, 22.0), Vector2(rect.size.x - 10.0, rect.size.y - 27.0)), V113_PANEL, true)
    draw_rect(Rect2(rect.position + Vector2(0.0, 22.0), Vector2(rect.size.x, 6.0)), accent.darkened(0.20), true)
    for i in range(4):
        var x := rect.position.x + 12.0 + float(i) * (rect.size.x - 24.0) / 3.0
        draw_rect(Rect2(Vector2(x - 2.0, rect.end.y - 8.0), Vector2(5.0, 8.0)), Color("101417"), true)
    return rect

func _v113_draw_vents(rect: Rect2, rows: int = 4) -> void:
    for row in range(rows):
        var y := rect.position.y + 34.0 + float(row) * 10.0
        draw_rect(Rect2(rect.position.x + 12.0, y, rect.size.x * 0.34, 4.0), Color("090f12"), true)
        draw_rect(Rect2(rect.position.x + rect.size.x * 0.56, y, rect.size.x * 0.28, 4.0), Color("090f12"), true)

func _v113_draw_status_bank(rect: Rect2, accent: Color) -> void:
    var p := rect.position + Vector2(rect.size.x - 48.0, 33.0)
    draw_rect(Rect2(p, Vector2(32.0, 25.0)), Color("081014"), true)
    draw_circle(p + Vector2(8.0, 8.0), 3.0, V113_GREEN)
    draw_circle(p + Vector2(18.0, 8.0), 3.0, accent)
    draw_rect(Rect2(p + Vector2(6.0, 15.0), Vector2(20.0, 4.0)), V113_CYAN.darkened(0.35), true)

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var profile_idx: int = int(entity.get("profile_idx", company_idx))
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    if String(entity.get("kind", "")) == "rival" and bool(rivals[int(entity["rival_idx"])]["merged"]):
        accent = Color("657078")
    var size_value := _v103_visual_size(pos, WorldScale.HQ_SIZE, "hq")
    _selection_ring(pos, idx, WorldScale.selection_radius("hq"))
    var rect := _v113_draw_industrial_base(pos, size_value, accent)

    # Mining-hall identity: multiple intake/fan bays and a central service door.
    var bay_w := (rect.size.x - 36.0) / 4.0
    for i in range(4):
        var bay := Rect2(rect.position + Vector2(10.0 + float(i) * bay_w, 38.0), Vector2(bay_w - 6.0, 54.0))
        draw_rect(bay, Color("0b1216"), true)
        draw_circle(bay.get_center(), minf(bay.size.x, bay.size.y) * 0.28, Color("26343b"))
        draw_circle(bay.get_center(), minf(bay.size.x, bay.size.y) * 0.20, accent.darkened(0.35), false, 3.0)
        draw_line(bay.get_center() + Vector2(-9.0, 0.0), bay.get_center() + Vector2(9.0, 0.0), Color("89969b"), 2.0)
        draw_line(bay.get_center() + Vector2(0.0, -9.0), bay.get_center() + Vector2(0.0, 9.0), Color("89969b"), 2.0)
    _v113_draw_status_bank(rect, accent)
    _draw_v088_entry_cue(String(entity.get("kind", "hq")), pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.39 + 38.0, size_value.x + 36.0)

func _draw_partner_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var partner_idx: int = int(entity["partner_idx"])
    var accent: Color = PARTNER_ACCENTS[partner_idx]
    var size_value := _v103_visual_size(pos, WorldScale.PARTNER_SIZE, "partner")
    _selection_ring(pos, idx, WorldScale.selection_radius("partner"))
    var rect := _v113_draw_industrial_base(pos, size_value, accent)
    _v113_draw_vents(rect, 5)
    _v113_draw_status_bank(rect, accent)
    _draw_v088_entry_cue("partner", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.39 + 34.0, size_value.x + 34.0)

func _draw_machine_market(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("bd8cff")
    var size_value := _v103_visual_size(pos, WorldScale.SERVICE_SIZE, "machines")
    _selection_ring(pos, idx, WorldScale.selection_radius("machines"))
    var rect := _v113_draw_industrial_base(pos, size_value, accent)
    for col in range(5):
        var rack := Rect2(rect.position + Vector2(12.0 + float(col) * ((rect.size.x - 24.0) / 5.0), 36.0), Vector2((rect.size.x - 34.0) / 5.0, 62.0))
        draw_rect(rack, Color("070d11"), true)
        for row in range(4):
            draw_rect(Rect2(rack.position + Vector2(5.0, 7.0 + float(row) * 12.0), Vector2(rack.size.x - 10.0, 6.0)), Color("28333a"), true)
            draw_circle(rack.position + Vector2(rack.size.x - 8.0, 10.0 + float(row) * 12.0), 2.0, V113_GREEN)
    _draw_v088_entry_cue("machines", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.39 + 34.0, size_value.x + 34.0)

func _draw_power_building(entity: Dictionary, idx: int) -> void:
    var transformer := _v112_texture("transformer")
    if transformer != null:
        super._draw_power_building(entity, idx)
        return
    var pos: Vector2 = entity["pos"]
    var accent := Color("ffd36e")
    var size_value := _v103_visual_size(pos, WorldScale.SERVICE_SIZE, "power")
    _selection_ring(pos, idx, WorldScale.selection_radius("power"))
    var rect := _v113_draw_industrial_base(pos, size_value, accent)
    for i in range(3):
        var x := rect.position.x + 48.0 + float(i) * 58.0
        draw_rect(Rect2(Vector2(x - 18.0, rect.position.y + 38.0), Vector2(36.0, 61.0)), Color("39454b"), true)
        draw_circle(Vector2(x, rect.position.y + 55.0), 13.0, Color("11171b"))
        draw_circle(Vector2(x, rect.position.y + 55.0), 8.0, accent, false, 3.0)
        draw_line(Vector2(x, rect.position.y + 38.0), Vector2(x, rect.position.y + 24.0), V113_STEEL_LIGHT, 3.0)
        draw_circle(Vector2(x, rect.position.y + 21.0), 4.0, accent)
    _draw_v088_entry_cue("power", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.39 + 34.0, size_value.x + 34.0)

func _draw_bank_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := ORANGE
    var size_value := _v103_visual_size(pos, WorldScale.SERVICE_SIZE, "bank")
    _selection_ring(pos, idx, WorldScale.selection_radius("bank"))
    var rect := _v113_draw_industrial_base(pos, size_value, accent)
    # Data/finance operations center rather than a classical house/bank facade.
    for i in range(3):
        var p := rect.position + Vector2(18.0 + float(i) * 72.0, 38.0)
        draw_rect(Rect2(p, Vector2(54.0, 48.0)), Color("071016"), true)
        for row in range(3):
            draw_rect(Rect2(p + Vector2(6.0, 8.0 + float(row) * 11.0), Vector2(30.0 + float((i + row) % 2) * 10.0, 4.0)), V113_CYAN.darkened(0.15), true)
    _v113_draw_status_bank(rect, accent)
    _draw_v088_entry_cue("bank", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.39 + 34.0, size_value.x + 34.0)

func _draw_land_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("8ed06c")
    var size_value := _v103_visual_size(pos, WorldScale.SERVICE_SIZE, "land")
    _selection_ring(pos, idx, WorldScale.selection_radius("land"))
    var rect := _v113_draw_industrial_base(pos, size_value, accent)
    # Survey/site-development office: plot display + field equipment.
    draw_rect(Rect2(rect.position + Vector2(18.0, 38.0), Vector2(rect.size.x * 0.50, 58.0)), Color("0c1812"), true)
    for gx in range(4):
        for gy in range(3):
            var p := rect.position + Vector2(25.0 + float(gx) * 24.0, 45.0 + float(gy) * 15.0)
            draw_rect(Rect2(p, Vector2(18.0, 10.0)), accent.darkened(0.45), false, 2.0)
    _v113_draw_status_bank(rect, accent)
    _draw_v088_entry_cue("land", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.39 + 34.0, size_value.x + 34.0)

func debug_v113_ready() -> bool:
    return V113_INDUSTRIAL_SITE_REVISION == 1 and debug_v112_ready()
