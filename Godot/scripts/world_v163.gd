extends "res://scripts/world_v162.gd"

# v0.163: promote the already validated directional wind-turbine binary from
# decorative live-site art to the actual wind_farm energy-source renderer.
# One asset only: all other inherited energy renderers remain unchanged.
const V163Wind = preload("res://scripts/wind_turbine_catalog.gd")
const V163_WIND_REVISION := 2
var v163_wind_texture: Texture2D
var v163_wind_drawn := false
var v163_wind_rect := Rect2()
var v163_wind_footprint := Rect2()
var v163_wind_footprint_registered := false
var v163_npc_textures: Dictionary = {}
const V163_NPC_SUIT_VARIANTS := [Color("f0f2f1"), Color("ff7a12")]
const V163_NPC_SCOUTER := Color("42f55a")

func _ready() -> void:
    # Match the proven v0.161 pattern: the inherited live-site renderer can run
    # during the base ready chain, so load the exact binary first.
    v163_wind_texture = V163Wind.load_texture()
    super._ready()
    set_meta("hashrace_v163_wind_binary_live", v163_wind_texture != null)
    set_meta("hashrace_v163_wind_asset_path", V163Wind.SHEET_PATH)
    queue_redraw()

func _v114_draw_energy_source(asset_id: String, pos: Vector2, capacity_mw: float, orientation: String = "up") -> void:
    if asset_id != "wind_farm" or v163_wind_texture == null:
        super._v114_draw_energy_source(asset_id, pos, capacity_mw, orientation)
        return

    var footprint_tiles := _v114_footprint_tiles(capacity_mw)
    var side := clampf(72.0 + float(footprint_tiles) * 14.0, 100.0, 184.0)
    var size_value := Vector2(side, side)
    var dest := Rect2(VisualStack.snap_to_pixel(pos - size_value * 0.5), size_value)
    var foot := Rect2(
        Vector2(dest.position.x + dest.size.x * 0.27, dest.position.y + dest.size.y * 0.72),
        Vector2(dest.size.x * 0.46, dest.size.y * 0.20)
    )
    v163_wind_rect = dest
    v163_wind_footprint = foot
    v163_wind_drawn = true
    if not v163_wind_footprint_registered and grid_nav != null:
        grid_nav.block_rect(foot)
        v163_wind_footprint_registered = true

    var source := V163Wind.region(orientation)
    _v127_draw_region(v163_wind_texture, source, dest)

func debug_v163_wind_ready() -> bool:
    # Do not call debug_v162_ready() here. Its inherited v0.161 proof requires
    # solar_array to have been drawn in the same frame, which is mutually
    # exclusive with a real wind_farm being the selected primary source. Check
    # the preserved v0.162 cleanup contract directly, then the older independent
    # transformer/runtime chain.
    return V163_WIND_REVISION == 2 \
        and v163_wind_texture != null \
        and V163Wind.debug_ready() \
        and v163_wind_drawn \
        and v163_wind_rect.size.x >= 100.0 \
        and v163_wind_footprint.size.x > 0.0 \
        and v163_wind_footprint_registered \
        and grid_nav != null \
        and not grid_nav.world_is_walkable(v163_wind_footprint.get_center()) \
        and V162_TILEMAP_CLEANUP_REVISION == 1 \
        and bool(get_meta("hashrace_v162_detached_live_site_foundations_removed", false)) \
        and debug_v160_transformer_ready()


# NPCs now use the same validated authored character sheet and exact crop/foot
# anchoring path as the player, but receive deterministic palette variants.
# This replaces the old behavior where every NPC reused the player's derived
# texture. The two suit treatments follow the inspected Library operator art.
func _v163_npc_texture(pos: Vector2, accent: Color) -> Texture2D:
    var seed := _v073_seed(pos, accent)
    var variant := seed % V163_NPC_SUIT_VARIANTS.size()
    var skin: Color = V073_NPC_SKINS[seed % V073_NPC_SKINS.size()]
    var key := "%d:%s" % [variant, skin.to_html(false)]
    if not v163_npc_textures.has(key):
        v163_npc_textures[key] = DefaultPlayerSheetV144.build_customized_texture(
            skin,
            V163_NPC_SUIT_VARIANTS[variant],
            V163_NPC_SCOUTER
        )
    return v163_npc_textures[key] as Texture2D

func _draw_tech_rep(pos: Vector2, accent: Color, scanner: String, is_player: bool) -> void:
    if is_player:
        super._draw_tech_rep(pos, accent, scanner, true)
        return
    var texture := _v163_npc_texture(pos, accent)
    if texture == null:
        super._draw_tech_rep(pos, accent, scanner, false)
        return
    var seed := _v073_seed(pos, accent)
    var facing := _v073_npc_facing(pos, seed)
    var region := DefaultPlayerSheetV144.frame_region(facing, 0)
    var scale_value := PLAYER_PIXEL_SCALE
    var foot := VisualStack.snap_to_pixel(pos + Vector2(0.0, 43.0))
    var dest := Rect2(
        VisualStack.snap_to_pixel(foot + (DefaultPlayerSheetV144.frame_offset(region) - Vector2(DefaultPlayerSheetV144.FOOT_ANCHOR)) * scale_value),
        Vector2(region.size) * scale_value
    )
    draw_ellipse_shadow(VisualStack.snap_to_pixel(pos + Vector2(0.0, 42.0)), 28.0, 8.0)
    draw_texture_rect_region(texture, dest, Rect2(region))
    draw_rect(Rect2(foot + Vector2(-6.0, -52.0), Vector2(12.0, 4.0)), accent, true)

func debug_v163_npc_variants_ready() -> bool:
    var first := _v163_npc_texture(Vector2(160.0, 160.0), Color("ff8c24"))
    var second := _v163_npc_texture(Vector2(640.0, 320.0), Color("4fc3f7"))
    return first != null and second != null and DefaultPlayerSheetV144.debug_ready()
