extends "res://scripts/world_v053.gd"

# Hash Race v0.055 building-render pass.
# Replaces flat facility blocks with cached procedural RGBA facades generated
# from code. The existing v0.052 spacing and proximity-gated labels stay intact.

const BuildingRenderer = preload("res://scripts/procedural_building_renderer.gd")
const BUILDING_RENDER_REVISION: int = 1
const BUILDING_TEXTURE_SIZE := Vector2i(96, 128)

var building_texture_cache: Dictionary = {}

func _ready() -> void:
    super._ready()
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    set_meta("hashrace_building_render_revision", BUILDING_RENDER_REVISION)
    queue_redraw()

func _building_texture(style: String, accent: Color, seed: int) -> Texture2D:
    var key: String = "%s_%s_%d" % [style, accent.to_html(false), seed]
    if building_texture_cache.has(key):
        return building_texture_cache[key]
    var texture: ImageTexture = BuildingRenderer.create_building_texture(accent, style, seed)
    building_texture_cache[key] = texture
    return texture

func _draw_procedural_building(pos: Vector2, footprint: Vector2, style: String, accent: Color, seed: int) -> void:
    var texture: Texture2D = _building_texture(style, accent, seed)
    var draw_height: float = round(footprint.y * 1.45)
    var draw_width: float = round(draw_height * (float(BUILDING_TEXTURE_SIZE.x) / float(BUILDING_TEXTURE_SIZE.y)))
    var draw_pos: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(-draw_width * 0.5, -draw_height * 0.58))
    draw_texture_rect(texture, Rect2(draw_pos, Vector2(draw_width, draw_height)), false)

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var profile_idx: int = int(entity.get("profile_idx", company_idx))
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    if String(entity["kind"]) == "rival" and bool(rivals[int(entity["rival_idx"])]["merged"]):
        accent = Color("657078")
    _selection_ring(pos, idx, 122.0)
    _draw_procedural_building(pos, Vector2(208.0, 118.0), "hq", accent, profile_idx + 7)
    _draw_building_name(entity, idx, accent, 82.0, 230.0)

func _draw_partner_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var partner_idx: int = int(entity["partner_idx"])
    var accent: Color = PARTNER_ACCENTS[partner_idx]
    _selection_ring(pos, idx, 106.0)
    _draw_procedural_building(pos, Vector2(170.0, 104.0), "partner", accent, partner_idx + 31)
    _draw_building_name(entity, idx, accent, 76.0, 210.0)

func _draw_machine_market(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("bd8cff")
    _selection_ring(pos, idx, 106.0)
    _draw_procedural_building(pos, Vector2(184.0, 108.0), "machine", accent, 51)
    _draw_building_name(entity, idx, accent, 79.0, 224.0)

func _draw_power_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("ffd36e")
    _selection_ring(pos, idx, 106.0)
    _draw_procedural_building(pos, Vector2(180.0, 104.0), "power", accent, 63)
    _draw_building_name(entity, idx, accent, 77.0, 224.0)

func _draw_bank_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent: Color = ORANGE
    _selection_ring(pos, idx, 104.0)
    _draw_procedural_building(pos, Vector2(168.0, 108.0), "bank", accent, 79)
    _draw_building_name(entity, idx, accent, 79.0, 224.0)

func _draw_land_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("8ed06c")
    _selection_ring(pos, idx, 104.0)
    _draw_procedural_building(pos, Vector2(166.0, 102.0), "land", accent, 91)
    _draw_building_name(entity, idx, accent, 75.0, 218.0)

func debug_procedural_building_render_ready() -> bool:
    var probe: Image = BuildingRenderer.create_building_image(Color("39ff75"), "hq", 1)
    return BUILDING_RENDER_REVISION >= 1 and probe.get_width() == BUILDING_TEXTURE_SIZE.x and probe.get_height() == BUILDING_TEXTURE_SIZE.y
