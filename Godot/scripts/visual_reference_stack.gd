extends RefCounted

# Hash Race v0.046 visual-reference utility.
# Each helper independently adapts a small, general rendering technique observed
# in reference projects. No third-party runtime, sprite, texture, or verbatim
# third-party source is bundled. Uploaded Godot-Pokemon and Naev snapshots are
# used only for general grass-interaction and layered-depth concepts.

const SOURCE_COUNT: int = 11
const SOURCE_KEYS := [
    "pixijs_round_pixels",
    "graphite_procedural_texture",
    "twojs_screen_stroke",
    "zrender_subpixel_line",
    "galacean_lerp",
    "spine_mix_concept",
    "simple2d_colored_quad",
    "luxor_regular_polygon_concept",
    "vger_layered_stroke",
    "godot_pokemon_grass_step_concept",
    "naev_multilayer_depth_concept",
]

# PixiJS element: round render positions to whole pixels for crisp sprites.
static func snap_to_pixel(pos: Vector2) -> Vector2:
    return Vector2(round(pos.x), round(pos.y))

# Graphite element: deterministic procedural texture/noise variation.
static func procedural_noise(cell: Vector2i, seed: int = 0) -> float:
    var hashed: int = absi(cell.x * 92821 + cell.y * 68917 + seed * 31337)
    return float(hashed % 1009) / 1008.0

# Naev-inspired concept: combine coarse, medium and fine deterministic fields so
# terrain gets broad patches plus local detail instead of uniform random speckle.
# This is an original integer-grid implementation, not copied Naev shader code.
static func layered_terrain_noise(cell: Vector2i, seed: int = 0) -> float:
    var coarse_cell := Vector2i(int(floor(float(cell.x) / 4.0)), int(floor(float(cell.y) / 4.0)))
    var medium_cell := Vector2i(int(floor(float(cell.x) / 2.0)), int(floor(float(cell.y) / 2.0)))
    var coarse: float = procedural_noise(coarse_cell, seed + 11)
    var medium: float = procedural_noise(medium_cell, seed + 37)
    var fine: float = procedural_noise(cell, seed + 71)
    return clampf(coarse * 0.52 + medium * 0.30 + fine * 0.18, 0.0, 1.0)

# Godot-Pokemon-inspired concept: walking vegetation can use a stable outward
# displacement based on animation phase without requiring sprite-sheet assets.
static func vegetation_step_spread(step_phase: float, moving: bool) -> float:
    if not moving:
        return 0.0
    return absf(sin(step_phase))

# Two.js element: keep a visual stroke approximately constant on screen even
# when the world camera zoom changes.
static func constant_screen_stroke(screen_width: float, camera_zoom: float) -> float:
    return maxf(1.0, screen_width / maxf(absf(camera_zoom), 0.001))

# zrender element: shift odd-width lines to a half-pixel boundary so horizontal
# and vertical marks remain crisp rather than being blurred across two pixels.
static func crisp_line(from: Vector2, to: Vector2, width: float) -> PackedVector2Array:
    var rounded_width: int = maxi(1, int(round(width)))
    var offset: float = 0.5 if rounded_width % 2 == 1 else 0.0
    return PackedVector2Array([
        Vector2(floor(from.x) + offset, floor(from.y) + offset),
        Vector2(floor(to.x) + offset, floor(to.y) + offset),
    ])

# Galacean element: explicit linear interpolation, used for visible light and
# pose transitions.
static func lerp_number(start: float, end: float, t: float) -> float:
    var blend: float = clampf(t, 0.0, 1.0)
    return start + (end - start) * blend

# Spine runtime concept only: normalized mix time. This is an independent
# implementation of the general animation-blending idea; no Spine code is copied.
static func mix_alpha(elapsed: float, duration: float) -> float:
    if duration <= 0.0:
        return 1.0
    return clampf(elapsed / duration, 0.0, 1.0)

# Simple2D element: a quad rendered from four vertices with per-corner colors.
static func quad_points(rect: Rect2) -> PackedVector2Array:
    return PackedVector2Array([
        rect.position,
        rect.position + Vector2(rect.size.x, 0.0),
        rect.end,
        rect.position + Vector2(0.0, rect.size.y),
    ])

static func quad_colors(start: Color, end: Color) -> PackedColorArray:
    return PackedColorArray([start, end, end, start])

# Luxor element concept: construct a regular n-gon from radius, side count and
# orientation. This is independently implemented geometry, not copied source.
static func regular_polygon(center: Vector2, radius: float, sides: int, orientation: float = 0.0) -> PackedVector2Array:
    var count: int = maxi(3, sides)
    var points := PackedVector2Array()
    for i in range(count):
        var angle: float = orientation + TAU * float(i) / float(count)
        points.append(center + Vector2(cos(angle), sin(angle)) * radius)
    return points

# Vger element: layered fill/stroke presentation. The actual CanvasItem drawing
# stays in world_gbc.gd; this helper returns the inset rectangle for the second
# stroke so the style remains consistent.
static func inner_stroke_rect(rect: Rect2, gap: float) -> Rect2:
    return rect.grow(-maxf(1.0, gap))

static func source_contract_ready() -> bool:
    var snapped: Vector2 = snap_to_pixel(Vector2(1.4, 2.6))
    var polygon: PackedVector2Array = regular_polygon(Vector2.ZERO, 10.0, 6)
    var noise: float = procedural_noise(Vector2i(7, 11), 3)
    var layered: float = layered_terrain_noise(Vector2i(7, 11), 3)
    return SOURCE_KEYS.size() == SOURCE_COUNT \
        and snapped == Vector2(1.0, 3.0) \
        and polygon.size() == 6 \
        and noise >= 0.0 and noise <= 1.0 \
        and layered >= 0.0 and layered <= 1.0 \
        and is_equal_approx(vegetation_step_spread(0.0, false), 0.0) \
        and is_equal_approx(lerp_number(0.0, 10.0, 0.5), 5.0) \
        and is_equal_approx(mix_alpha(0.5, 1.0), 0.5)
