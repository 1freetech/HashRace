extends "res://scripts/world_v123.gd"

# Hash Race v0.124 screenshot-match environment pass.
# This layer keeps the v0.123 authored campus/HUD and adds the missing high-level
# composition cues from the locked target: transmission tower + sagging power
# cables, a rocky shoreline/water corner, sparse tree/rock clusters, and cleaner
# depth framing around the player campus. Everything is drawn live by Godot.

const V124_VISUAL_MATCH_REVISION := 1
const V124_WATER := Color("2d82b7")
const V124_WATER_DARK := Color("185f8d")
const V124_BANK := Color("66715f")
const V124_ROCK := Color("6c7377")
const V124_ROCK_HI := Color("92989a")
const V124_TREE_DARK := Color("173f2a")
const V124_TREE := Color("2f7d43")
const V124_TREE_HI := Color("55ad55")
const V124_CABLE := Color("13181b")
const V124_TOWER := Color("5d666c")

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v124_visual_target_revision", V124_VISUAL_MATCH_REVISION)
    set_meta("hashrace_runtime_visual_proof_required", true)
    queue_redraw()

func _v115_draw_live_site(origin: Vector2) -> void:
    super._v115_draw_live_site(origin)

    # Add the large scene-shaping elements that were still missing in v0.123.
    _v124_draw_shoreline(origin + Vector2(-332.0, 218.0))
    _v124_draw_transmission_grid(origin + Vector2(320.0, -150.0), origin + Vector2(15.0, -180.0))
    _v124_draw_sparse_landscape(origin)

func _v124_draw_transmission_grid(tower_pos: Vector2, transformer_top: Vector2) -> void:
    # Lattice tower at the right edge of the campus.
    draw_ellipse_shadow(tower_pos + Vector2(0.0, 86.0), 38.0, 10.0)
    var top := tower_pos + Vector2(0.0, -122.0)
    var left_foot := tower_pos + Vector2(-34.0, 86.0)
    var right_foot := tower_pos + Vector2(34.0, 86.0)
    draw_line(top, left_foot, V124_TOWER, 5.0, true)
    draw_line(top, right_foot, V124_TOWER, 5.0, true)
    for yoff in [-82.0, -48.0, -12.0, 24.0, 58.0]:
        var half := 10.0 + (yoff + 122.0) * 0.18
        var y := tower_pos.y + yoff
        draw_line(Vector2(tower_pos.x - half, y), Vector2(tower_pos.x + half, y), V124_TOWER, 3.0, true)
        draw_line(Vector2(tower_pos.x - half, y), Vector2(tower_pos.x + half * 0.55, y + 26.0), V124_TOWER.darkened(0.14), 2.0, true)
        draw_line(Vector2(tower_pos.x + half, y), Vector2(tower_pos.x - half * 0.55, y + 26.0), V124_TOWER.darkened(0.14), 2.0, true)

    # Crossarm + three insulator drops.
    draw_line(top + Vector2(-54.0, 14.0), top + Vector2(54.0, 14.0), V124_TOWER, 5.0, true)
    for xoff in [-40.0, 0.0, 40.0]:
        var p := top + Vector2(xoff, 14.0)
        draw_line(p, p + Vector2(0.0, 18.0), Color("252b2e"), 3.0, true)
        draw_circle(p + Vector2(0.0, 20.0), 4.0, Color("202629"))

    # Three sagging power conductors visually connect the transformer area.
    for lane in range(3):
        var from := transformer_top + Vector2(-58.0 + lane * 58.0, 0.0)
        var to := top + Vector2(-40.0 + lane * 40.0, 32.0)
        _v124_draw_sagging_cable(from, to, 34.0 + lane * 5.0)

func _v124_draw_sagging_cable(a: Vector2, b: Vector2, sag: float) -> void:
    var pts := PackedVector2Array()
    for i in range(13):
        var t := float(i) / 12.0
        var p := a.lerp(b, t)
        p.y += sin(t * PI) * sag
        pts.append(p)
    draw_polyline(pts, V124_CABLE, 6.0, true)
    draw_polyline(pts, Color("2d3438"), 2.0, true)

func _v124_draw_shoreline(anchor: Vector2) -> void:
    # Bottom-left water corner with a stepped rocky bank, matching the target's
    # strong geographic anchor without replacing the underlying playable map.
    var water := Rect2(anchor + Vector2(-116.0, 0.0), Vector2(242.0, 122.0))
    draw_rect(water, V124_WATER, true)
    draw_rect(Rect2(water.position + Vector2(0, 74), Vector2(water.size.x, 48)), V124_WATER_DARK, true)

    for i in range(11):
        var x := anchor.x - 106.0 + i * 22.0
        var y := anchor.y + 4.0 + float((i * 7) % 16)
        draw_circle(Vector2(x, y), 13.0, V124_BANK)
        draw_circle(Vector2(x + 2.0, y - 4.0), 9.0, V124_ROCK)
        draw_circle(Vector2(x - 1.0, y - 7.0), 4.0, V124_ROCK_HI)

    # Simple two-line water shimmer, restrained so it stays background detail.
    for i in range(4):
        var y := water.position.y + 42.0 + i * 16.0
        draw_line(Vector2(water.position.x + 18.0, y), Vector2(water.position.x + 74.0, y), Color("67b6d9"), 2.0)
        draw_line(Vector2(water.position.x + 112.0, y + 5.0), Vector2(water.position.x + 176.0, y + 5.0), Color("4ca2cc"), 2.0)

func _v124_draw_sparse_landscape(origin: Vector2) -> void:
    # Only a few purposeful clusters; do not refill the world with noise.
    _v124_tree(origin + Vector2(-315.0, -205.0), 1.0)
    _v124_tree(origin + Vector2(-258.0, -188.0), 0.86)
    _v124_tree(origin + Vector2(252.0, 28.0), 0.92)
    _v124_tree(origin + Vector2(303.0, 35.0), 1.04)

    for p in [
        origin + Vector2(-188.0, 42.0),
        origin + Vector2(145.0, 48.0),
        origin + Vector2(178.0, 58.0),
    ]:
        draw_circle(p + Vector2(5.0, 5.0), 13.0, Color(0,0,0,0.18))
        draw_circle(p, 12.0, V124_ROCK)
        draw_circle(p + Vector2(-3.0, -4.0), 5.0, V124_ROCK_HI)

func _v124_tree(pos: Vector2, scale_value: float) -> void:
    draw_ellipse_shadow(pos + Vector2(0.0, 22.0 * scale_value), 18.0 * scale_value, 6.0 * scale_value)
    draw_rect(Rect2(pos + Vector2(-4.0, 7.0) * scale_value, Vector2(8.0, 24.0) * scale_value), Color("5e4630"), true)
    draw_circle(pos + Vector2(0.0, -8.0) * scale_value, 25.0 * scale_value, V124_TREE_DARK)
    draw_circle(pos + Vector2(-12.0, -2.0) * scale_value, 18.0 * scale_value, V124_TREE)
    draw_circle(pos + Vector2(13.0, -1.0) * scale_value, 17.0 * scale_value, V124_TREE)
    draw_circle(pos + Vector2(0.0, -18.0) * scale_value, 16.0 * scale_value, V124_TREE_HI)

func debug_v124_ready() -> bool:
    return V124_VISUAL_MATCH_REVISION == 1 \
        and bool(get_meta("hashrace_runtime_visual_proof_required", false)) \
        and debug_v123_ready()
