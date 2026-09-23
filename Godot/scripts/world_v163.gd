extends "res://scripts/world_v162.gd"

# v0.163: replace the live procedural facility renderer with a decoded original
# overhead industrial PNG atlas; preserve all inherited simulation and selection.
const V163_ATLAS := "res://art/buildings/industrial_overhead_atlas.png"
const V163_ATLAS_SIZE := Vector2i(192, 64)
const V163_CELL := Vector2(64.0, 64.0)
const V163_REVISION := 1
var v163_industrial_texture: Texture2D

func _ready() -> void:
    # Virtual renderers can run during inherited startup; decode first.
    v163_industrial_texture = _v128_load_texture(V163_ATLAS)
    if v163_industrial_texture == null or Vector2i(v163_industrial_texture.get_size()) != V163_ATLAS_SIZE:
        push_error("HASH RACE v163: original overhead atlas missing or has invalid dimensions")
    super._ready()
    set_meta("hashrace_v163_industrial_atlas_live", _v163_valid_atlas())
    set_meta("hashrace_v163_road_plan", "one through road and one campus connector")
    queue_redraw()

func _v163_valid_atlas() -> bool:
    return v163_industrial_texture != null and Vector2i(v163_industrial_texture.get_size()) == V163_ATLAS_SIZE

# Remove the three-horizontal-road residential grid from v0.158. Keep one
# horizontal through route and one perpendicular connector ending at it.
# Preserve water and existing terrain cells from all inherited layers.
func _build_art_tilemap() -> void:
    super._build_art_tilemap()
    for raw_cell in art_cells.keys():
        var cell: Vector2i = raw_cell
        if int(art_cells[cell]) == TILE_ROAD:
            art_cells[cell] = TILE_GRASS
    GBPaint.paint_line(art_cells, Vector2i(2, 19), Vector2i(60, 19), 1, TILE_ROAD, art_columns, art_rows)
    GBPaint.paint_line(art_cells, Vector2i(29, 9), Vector2i(29, 19), 1, TILE_ROAD, art_columns, art_rows)
    set_meta("hashrace_v163_canonical_road_tiles", debug_gbc_road_tiles())

# A single 192x64 source contains exactly three original 64x64 transparent
# overhead modules: Command Center (0), cooling facility (1), power and
# distribution facility (2). No rectangle-roof/house/door fallback.
func _v163_draw_industrial(kind_index: int, pos: Vector2, size_value: Vector2) -> void:
    if not _v163_valid_atlas():
        return
    var source := Rect2(Vector2(float(clampi(kind_index, 0, 2)) * V163_CELL.x, 0.0), V163_CELL)
    var dest := Rect2(
        VisualStack.snap_to_pixel(pos - size_value * Vector2(0.5, 0.68)),
        size_value
    )
    draw_ellipse_shadow(pos + Vector2(0.0, size_value.y * 0.24), size_value.x * 0.43, maxf(5.0, size_value.y * 0.08))
    draw_texture_rect_region(v163_industrial_texture, dest, source)

# v0.158 previously routed ALL HQs back into the generic procedural facility.
# Restore the approved, validated C-01 container art for both player and rival
# mining HQs; dimensions remain capacity-aware through inherited world rules.
func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity.get("pos", Vector2.ZERO)
    var profile_idx := int(entity.get("profile_idx", company_idx))
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    if String(entity.get("kind", "")) == "rival" and bool(rivals[int(entity["rival_idx"])]["merged"]):
        accent = Color("657078")
    var capacity_mw := _v114_capacity_mw_for_site(pos)
    var size_value := _v128_container_size(capacity_mw)
    _selection_ring(pos, idx, WorldScale.selection_radius("hq"))
    _v128_draw_container_sprite(pos + Vector2(0.0, -8.0), capacity_mw, accent, size_value)
    _draw_building_name(entity, idx, accent, size_value.y * 0.48 + 30.0, size_value.x + 24.0)

func _v163_facility_kind(entity: Dictionary) -> int:
    var kind := String(entity.get("kind", ""))
    if kind == "bank" or kind == "power":
        return 2
    if kind == "market" or kind == "land":
        return 0
    if kind == "partner":
        # Stable, differentiated overhead silhouettes; no duplicate roofs.
        return [1, 2, 0][posmod(int(entity.get("partner_idx", 0)), 3)]
    return 1

# All non-HQ interactive facilities routed through inherited
# _draw_partner_building/_draw_machine_market/_draw_power_building/etc.
func _v158_draw_facility(entity: Dictionary, idx: int, accent: Color) -> void:
    var pos: Vector2 = entity.get("pos", Vector2.ZERO)
    var kind := String(entity.get("kind", "partner"))
    var size_value := WorldScale.size_for_kind(kind)
    _selection_ring(pos, idx, WorldScale.selection_radius(kind))
    _v163_draw_industrial(_v163_facility_kind(entity), pos, size_value)
    _draw_building_name(entity, idx, accent, size_value.y * 0.43 + 32.0, size_value.x + 28.0)

# Replace the final inherited procedural residential-looking command hut with
# the original command-center image inside the same capacity-aware campus.
func _v128_draw_command_hut(pos: Vector2, _accent: Color) -> void:
    _v163_draw_industrial(0, pos, Vector2(112.0, 100.0))

# The detached v0.159 cable-tray shadow/strip is not a functional load; do not
# render it on grass. Keep the checked source PNG and loading contract intact.
func _v159_draw_cable_tray(_center: Vector2) -> void:
    pass

func debug_v163_ready() -> bool:
    return V163_REVISION == 1 \
        and _v163_valid_atlas() \
        and _v114_footprint_tiles(1.0) == 2 \
        and _v114_footprint_tiles(10.0) == 4 \
        and _v114_footprint_tiles(25.0) == 6 \
        and _v114_footprint_tiles(100.0) == 8 \
        and debug_v162_ready()
