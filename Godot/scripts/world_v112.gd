extends "res://scripts/world_v111.gd"

# Hash Race v0.112 imported sprite integration.
#
# This layer switches the live overworld to the supplied directional character
# sheets and supplied infrastructure art when those files exist. It keeps the
# procedural v0.111 renderer as a safe fallback so source validation never
# becomes dependent on optional binary art being present.
#
# Character contract:
#   4 columns x 4 rows
#   row 0 = down, row 1 = up, row 2 = left, row 3 = right
#   4 walk frames per direction, 8 FPS source cadence.
#
# Site contract:
#   each mining site gets one readable mining module, one power source, one
#   transformer/distribution object, one command/control object, and restrained
#   landscaping. Stationary infrastructure uses a single sensible view from its
#   source sheet rather than animating through orientations.

const ImportedArt = preload("res://systems/imported_art_v112.gd")

const V112_IMPORTED_ART_REVISION := 1
const V112_CHARACTER_FPS := 8.0
const V112_CHARACTER_SIZE := Vector2(88.0, 112.0)
const V112_SITE_ICON := Vector2(92.0, 92.0)
const V112_TRANSFORMER_ICON := Vector2(86.0, 86.0)
const V112_COMMAND_ICON := Vector2(96.0, 76.0)
const V112_TREE_ICON := Vector2(78.0, 92.0)

var v112_textures: Dictionary = {}

func _ready() -> void:
    _v112_load_imported_textures()
    super._ready()
    set_meta("hashrace_v112_imported_art_revision", V112_IMPORTED_ART_REVISION)
    set_meta("hashrace_v112_imported_asset_count", v112_textures.size())
    queue_redraw()

func _v112_load_imported_textures() -> void:
    v112_textures.clear()
    for raw_id in ImportedArt.ASSETS.keys():
        var asset_id := String(raw_id)
        var texture := ImportedArt.load_texture(asset_id)
        if texture != null:
            v112_textures[asset_id] = texture

func _v112_texture(asset_id: String) -> Texture2D:
    return v112_textures.get(asset_id) as Texture2D

func _v112_character_row(facing: String) -> int:
    match facing:
        "up": return 1
        "left": return 2
        "right": return 3
        _: return 0

func _v112_character_frame(moving: bool) -> int:
    if not moving:
        return 0
    var phase := fmod(rep_step_phase, TAU) / TAU
    return clampi(int(floor(phase * 4.0)), 0, 3)

func _v112_draw_sheet_frame(texture: Texture2D, grid: Vector2i, frame: Vector2i, center: Vector2, size_value: Vector2, anchor_y: float = 0.50) -> void:
    if texture == null:
        return
    var cell := Vector2(float(texture.get_width()) / float(grid.x), float(texture.get_height()) / float(grid.y))
    var src := Rect2(Vector2(float(frame.x) * cell.x, float(frame.y) * cell.y), cell)
    var dest := Rect2(center + Vector2(-size_value.x * 0.5, -size_value.y * anchor_y), size_value)
    draw_texture_rect_region(texture, dest, src)

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    var key := "char_greenfinal" if is_player else ImportedArt.character_for_index(absi(int(pos.x + pos.y)))
    var texture := _v112_texture(key)
    if texture == null:
        super._draw_tech_rep(pos, accent, scanner, is_player)
        return

    var facing := rep_facing if is_player else _v073_npc_facing(pos, _v073_seed(pos, accent))
    var moving := is_player and not rep_animation_state.ends_with("_idle")
    var frame := _v112_character_frame(moving) if is_player else 0
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 42.0)), 28.0, 8.0)
    _v112_draw_sheet_frame(texture, Vector2i(4, 4), Vector2i(frame, _v112_character_row(facing)), VisualStack.snap_to_pixel(pos), V112_CHARACTER_SIZE, 0.60)

func _draw_mining_campus(center: Vector2, accent: Color) -> void:
    # Deliberately sparse: four essential objects with large negative space.
    # This replaces decorative support-house repetition from early builds.
    _v112_draw_site_asset("asic_air", center + Vector2(-152.0, 84.0), V112_SITE_ICON, 0, 4)
    _v112_draw_site_asset(ImportedArt.energy_for_index(absi(int(center.x + center.y)) / 100), center + Vector2(148.0, 82.0), V112_SITE_ICON, 0, 2)
    _v112_draw_site_asset("transformer", center + Vector2(152.0, -102.0), V112_TRANSFORMER_ICON, 0, 4)
    _v112_draw_site_asset("command_center", center + Vector2(-148.0, -102.0), V112_COMMAND_ICON, 0, 4)

    var tree := _v112_texture("tree")
    if tree != null:
        _v112_draw_sheet_frame(tree, Vector2i(2, 2), Vector2i(0, 0), center + Vector2(-268.0, 40.0), V112_TREE_ICON, 0.55)
    else:
        _v102_tree_if_land(center + Vector2(-268.0, 40.0))

    if center.distance_to(_player_hq_center()) <= 8.0:
        _v107_draw_site_marker(center + Vector2(270.0, 108.0), accent)

func _v112_draw_site_asset(asset_id: String, pos: Vector2, size_value: Vector2, column: int, columns: int) -> void:
    var texture := _v112_texture(asset_id)
    if texture == null:
        return
    # Most supplied stationary sheets are 2x2 or 4x4. Pick one readable,
    # front-facing cell and hold it still; infrastructure does not "walk."
    var rows := 2
    if texture.get_width() >= texture.get_height() * 3:
        rows = 1
    elif columns == 4 and texture.get_height() > 0:
        rows = 4
    var safe_col := clampi(column, 0, columns - 1)
    var safe_row := 0
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, size_value.y * 0.40)), size_value.x * 0.36, size_value.y * 0.09)
    _v112_draw_sheet_frame(texture, Vector2i(columns, rows), Vector2i(safe_col, safe_row), VisualStack.snap_to_pixel(pos), size_value, 0.54)

func _draw_power_building(entity: Dictionary, idx: int) -> void:
    var transformer := _v112_texture("transformer")
    if transformer == null:
        super._draw_power_building(entity, idx)
        return
    var pos: Vector2 = entity["pos"]
    var accent := Color("ffd36e")
    var size_value := _v103_visual_size(pos, WorldScale.SERVICE_SIZE, "power")
    _selection_ring(pos, idx, WorldScale.selection_radius("power"))
    _v103_draw_building_shadow(pos, size_value)
    _v112_draw_sheet_frame(transformer, Vector2i(4, 4), Vector2i(0, 0), pos + Vector2(0.0, -4.0), Vector2(size_value.x * 0.72, size_value.y * 0.96), 0.52)
    _draw_v088_entry_cue("power", pos, size_value, accent)
    _draw_building_name(entity, idx, accent, size_value.y * 0.38 + 34.0, size_value.x + 40.0)

func debug_v112_ready() -> bool:
    return V112_IMPORTED_ART_REVISION == 1         and ImportedArt.debug_ready()         and V112_CHARACTER_FPS >= 8.0         and V112_CHARACTER_SIZE.y > WorldScale.CHARACTER_VISUAL_HEIGHT         and debug_v111_ready()
