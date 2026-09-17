extends "res://scripts/world_v055.gd"

# Hash Race v0.059 infrastructure-detail pass.
# Adapts the user-supplied Godot rack/PSU/switch drawing approach and the
# supplied pixel-rack references into compact mining-site infrastructure that
# reads clearly at overworld scale without adding more labels or map clutter.

const INFRASTRUCTURE_DETAIL_REVISION: int = 1
const INFRA_DETAIL_RADIUS: float = 760.0
const RACK_LED_GREEN := Color("5dff76")
const RACK_LED_BLUE := Color("5ec8ff")
const RACK_LED_ORANGE := Color("ffab45")
const CABLE_BLUE := Color("3f9cff")
const CABLE_GREEN := Color("55e978")
const CABLE_ORANGE := Color("ff9a3f")
const CABLE_DARK := Color("11171b")
const RACK_FRAME := Color("66757d")
const RACK_FACE := Color("172126")
const RACK_RECESS := Color("0b1115")

func _ready() -> void:
    super._ready()
    set_meta("hashrace_infrastructure_detail_revision", INFRASTRUCTURE_DETAIL_REVISION)
    queue_redraw()

func _draw_world_props_pixel() -> void:
    super._draw_world_props_pixel()

    # Extra cable/switch detail is proximity-gated. The detailed rack pods and
    # power cabinets replace the older simple props everywhere, while the
    # brighter cable tray only appears around the town currently being explored.
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = VisualStack.snap_to_pixel(zone["center"])
        if rep_pos.distance_to(center) > INFRA_DETAIL_RADIUS:
            continue
        var profile_idx: int = int(zone["profile_idx"])
        var accent: Color = COMPANY_ACCENTS[profile_idx]
        _draw_campus_data_bus(center, accent, profile_idx)

func _draw_site_container(center: Vector2, accent: Color) -> void:
    # Compact 4-rack compute pod. This replaces the old corrugated rectangle
    # with recognizable server faces, status LEDs, patch cables and cooling.
    var body := Rect2(center + Vector2(-61.0, -34.0), Vector2(122.0, 68.0))
    draw_rect(Rect2(body.position + Vector2(4.0, 6.0), body.size), Color(0.02, 0.03, 0.04, 0.55), true)
    draw_rect(body, WARM_OUTLINE, true)
    draw_rect(Rect2(body.position + Vector2(3.0, 3.0), body.size - Vector2(6.0, 6.0)), STEEL_BASE, true)
    draw_rect(Rect2(body.position + Vector2(6.0, 6.0), Vector2(110.0, 7.0)), STEEL_LIGHT.darkened(0.08), true)
    draw_rect(Rect2(body.position + Vector2(6.0, 14.0), Vector2(110.0, 45.0)), Color("121b20"), true)
    draw_rect(Rect2(body.position + Vector2(6.0, 60.0), Vector2(110.0, 4.0)), accent.darkened(0.25), true)

    for rack in range(4):
        var rack_center := body.position + Vector2(22.0 + float(rack) * 26.0, 37.0)
        _draw_micro_server_rack(rack_center, accent, rack)

    # Cooling fan on the left wall and a small distribution fan on the right.
    _draw_micro_fan(body.position + Vector2(11.0, 37.0), 8.0, accent)
    _draw_micro_fan(body.position + Vector2(111.0, 37.0), 7.0, accent)

    # Internal colored patch leads mirror the supplied rack reference but stay
    # short enough to keep the overworld clean.
    _draw_patch_lead(body.position + Vector2(44.0, 28.0), body.position + Vector2(58.0, 51.0), CABLE_BLUE, -5.0)
    _draw_patch_lead(body.position + Vector2(70.0, 28.0), body.position + Vector2(61.0, 51.0), CABLE_GREEN, 3.0)
    _draw_patch_lead(body.position + Vector2(88.0, 28.0), body.position + Vector2(65.0, 51.0), CABLE_ORANGE, 7.0)

    # Company-color status strip. No extra text is drawn here by design.
    draw_rect(Rect2(body.position + Vector2(9.0, 7.0), Vector2(22.0, 3.0)), accent, true)
    _draw_status_led(body.position + Vector2(103.0, 9.0), RACK_LED_GREEN, 2.0)
    _draw_status_led(body.position + Vector2(110.0, 9.0), RACK_LED_BLUE, 2.0)

func _draw_transformer_bank(center: Vector2, accent: Color) -> void:
    # Three power/cooling cabinets with vents, fan faces, warning stripes and
    # live status lights. These are deliberately taller and more mechanical
    # than the earlier plain transformer blocks.
    for i in range(3):
        var p := center + Vector2(float(i) * 31.0 - 31.0, 0.0)
        var outer := Rect2(p + Vector2(-13.0, -29.0), Vector2(26.0, 56.0))
        draw_rect(Rect2(outer.position + Vector2(3.0, 5.0), outer.size), Color(0.02, 0.03, 0.04, 0.5), true)
        draw_rect(outer, WARM_OUTLINE, true)
        draw_rect(Rect2(outer.position + Vector2(3.0, 3.0), outer.size - Vector2(6.0, 6.0)), Color("4a5960"), true)
        draw_rect(Rect2(p + Vector2(-8.0, -23.0), Vector2(16.0, 7.0)), Color("202b30"), true)
        _draw_status_led(p + Vector2(-4.0, -20.0), RACK_LED_GREEN if i != 1 else RACK_LED_ORANGE, 2.0)
        _draw_status_led(p + Vector2(3.0, -20.0), accent.lightened(0.18), 2.0)

        for slit in range(4):
            draw_rect(Rect2(p + Vector2(-8.0, -10.0 + float(slit) * 5.0), Vector2(16.0, 2.0)), Color("172126"), true)

        _draw_micro_fan(p + Vector2(0.0, 14.0), 7.0, accent)
        draw_rect(Rect2(p + Vector2(-3.0, -35.0), Vector2(6.0, 7.0)), accent.darkened(0.12), true)
        draw_rect(Rect2(p + Vector2(-1.0, -39.0), Vector2(2.0, 5.0)), Color("dce9e9"), true)

        # Hazard pixels make the equipment read as electrical infrastructure.
        for stripe in range(4):
            var stripe_color: Color = HAZARD_YELLOW if stripe % 2 == 0 else Color("20282c")
            draw_rect(Rect2(p + Vector2(-10.0 + float(stripe) * 5.0, 23.0), Vector2(5.0, 2.0)), stripe_color, true)

func _draw_campus_data_bus(center: Vector2, accent: Color, seed: int) -> void:
    # A single cable tray below the mining HQ visually connects compute,
    # networking and power while remaining outside the main building footprint.
    var bus_center := VisualStack.snap_to_pixel(center + Vector2(0.0, 118.0))
    var tray := Rect2(bus_center + Vector2(-104.0, -9.0), Vector2(208.0, 18.0))
    draw_rect(Rect2(tray.position + Vector2(2.0, 4.0), tray.size), Color(0.02, 0.03, 0.04, 0.45), true)
    draw_rect(tray, WARM_OUTLINE, true)
    draw_rect(Rect2(tray.position + Vector2(3.0, 3.0), tray.size - Vector2(6.0, 6.0)), Color("28363d"), true)

    # Three parallel cable paths are enough to show data/power routing without
    # filling the map with loose cords.
    draw_line(bus_center + Vector2(-94.0, -3.0), bus_center + Vector2(94.0, -3.0), CABLE_BLUE, 2.0)
    draw_line(bus_center + Vector2(-94.0, 1.0), bus_center + Vector2(94.0, 1.0), CABLE_GREEN, 2.0)
    draw_line(bus_center + Vector2(-94.0, 5.0), bus_center + Vector2(94.0, 5.0), CABLE_ORANGE, 2.0)

    # Compact network switch in the center with blinking activity ports.
    var switch_rect := Rect2(bus_center + Vector2(-31.0, -16.0), Vector2(62.0, 15.0))
    draw_rect(switch_rect, WARM_OUTLINE, true)
    draw_rect(Rect2(switch_rect.position + Vector2(2.0, 2.0), switch_rect.size - Vector2(4.0, 4.0)), RACK_FACE, true)
    var pulse: int = int(Time.get_ticks_msec() / 260) % 3
    for port in range(8):
        var px: float = switch_rect.position.x + 6.0 + float(port) * 7.0
        draw_rect(Rect2(px, switch_rect.position.y + 5.0, 4.0, 4.0), Color("090f12"), true)
        var live: bool = (port + seed + pulse) % 3 != 0
        if live:
            var led_color: Color = RACK_LED_GREEN if port % 2 == 0 else RACK_LED_BLUE
            draw_rect(Rect2(px + 1.0, switch_rect.position.y + 3.0, 2.0, 1.0), led_color, true)

    draw_rect(Rect2(bus_center + Vector2(-3.0, -14.0), Vector2(6.0, 2.0)), accent, true)

    # Short bundled drops connect the existing compute pod and power cabinets to
    # the shared tray. Their arcs are based on the user's supplied cable code.
    _draw_cable_bundle(center + Vector2(-99.0, 38.0), bus_center + Vector2(-77.0, -7.0), -1.0)
    _draw_cable_bundle(center + Vector2(105.0, 40.0), bus_center + Vector2(76.0, -7.0), 1.0)

func _draw_micro_server_rack(center: Vector2, accent: Color, variant: int) -> void:
    var rect := Rect2(center + Vector2(-10.0, -20.0), Vector2(20.0, 40.0))
    draw_rect(rect, RACK_FRAME.darkened(0.18), true)
    draw_rect(Rect2(rect.position + Vector2(2.0, 2.0), rect.size - Vector2(4.0, 4.0)), RACK_RECESS, true)
    draw_rect(Rect2(rect.position + Vector2(3.0, 3.0), Vector2(14.0, 4.0)), Color("263239"), true)

    for tray in range(5):
        var y: float = rect.position.y + 9.0 + float(tray) * 5.0
        draw_rect(Rect2(Vector2(rect.position.x + 3.0, y), Vector2(14.0, 4.0)), RACK_FACE, true)
        draw_rect(Rect2(Vector2(rect.position.x + 4.0, y + 1.0), Vector2(7.0, 1.0)), Color("43545c"), true)
        var led_color: Color = RACK_LED_GREEN
        if (tray + variant) % 4 == 0:
            led_color = RACK_LED_ORANGE
        elif (tray + variant) % 3 == 0:
            led_color = RACK_LED_BLUE
        _draw_status_led(Vector2(rect.position.x + 15.0, y + 2.0), led_color, 1.25)

    # Bottom intake grille and company-color service tab.
    for slit in range(4):
        draw_rect(Rect2(rect.position + Vector2(4.0 + float(slit) * 3.0, 34.0), Vector2(2.0, 2.0)), Color("34434a"), true)
    draw_rect(Rect2(rect.position + Vector2(2.0, 37.0), Vector2(6.0, 2.0)), accent.darkened(0.08), true)

func _draw_micro_fan(center: Vector2, radius: float, accent: Color) -> void:
    draw_circle(center, radius, Color("0a1013"))
    draw_circle(center, radius - 2.0, Color("202b30"), false, 2.0)
    draw_line(center + Vector2(-radius + 2.0, 0.0), center + Vector2(radius - 2.0, 0.0), Color("65747b"), 1.5)
    draw_line(center + Vector2(0.0, -radius + 2.0), center + Vector2(0.0, radius - 2.0), Color("65747b"), 1.5)
    draw_line(center + Vector2(-radius * 0.6, -radius * 0.6), center + Vector2(radius * 0.6, radius * 0.6), accent.darkened(0.28), 1.0)
    draw_line(center + Vector2(-radius * 0.6, radius * 0.6), center + Vector2(radius * 0.6, -radius * 0.6), accent.darkened(0.28), 1.0)
    draw_circle(center, 2.0, RACK_FRAME)

func _draw_status_led(pos: Vector2, color: Color, size: float) -> void:
    draw_circle(pos, size + 0.75, Color("091013"))
    draw_circle(pos, size, color)
    if size >= 2.0:
        draw_circle(pos + Vector2(-0.5, -0.5), maxf(0.75, size * 0.36), color.lightened(0.32))

func _draw_patch_lead(from: Vector2, to: Vector2, color: Color, curve: float) -> void:
    var points := PackedVector2Array()
    var steps: int = 6
    for i in range(steps + 1):
        var t: float = float(i) / float(steps)
        var p: Vector2 = from.lerp(to, t)
        p.x += sin(t * PI) * curve
        points.append(VisualStack.snap_to_pixel(p))
    draw_polyline(points, CABLE_DARK, 4.0, false)
    draw_polyline(points, color, 2.0, false)

func _draw_cable_bundle(from: Vector2, to: Vector2, bend_sign: float) -> void:
    var colors: Array[Color] = [CABLE_BLUE, CABLE_GREEN, CABLE_DARK]
    for lane in range(3):
        var start: Vector2 = from + Vector2(0.0, float(lane) * 3.0)
        var finish: Vector2 = to + Vector2(0.0, float(lane) * 3.0)
        var points := PackedVector2Array()
        for i in range(7):
            var t: float = float(i) / 6.0
            var p: Vector2 = start.lerp(finish, t)
            p.y += sin(t * PI) * 15.0 * bend_sign
            points.append(VisualStack.snap_to_pixel(p))
        draw_polyline(points, Color("060a0d"), 4.0, false)
        draw_polyline(points, colors[lane], 2.0, false)

func debug_infrastructure_detail_ready() -> bool:
    return INFRASTRUCTURE_DETAIL_REVISION >= 1 and INFRA_DETAIL_RADIUS <= 800.0 and town_zones.size() == 10
