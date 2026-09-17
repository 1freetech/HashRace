extends "res://scripts/world_ui_compact.gd"

# Hash Race v0.052 overworld readability pass.
# - spreads interactive buildings so campuses do not visually merge
# - increases micro-texture density across grass, paths, roads, lots and water
# - reduces decorative campus building count and leaves more green space
# - removes always-on building subtitles and corridor copy from the world layer
# - gives every character one neon-green name label directly above the sprite

const BuildingPlacer = preload("res://scripts/building_placer.gd")
const TEXTURE_SPACING_REVISION: int = 1
const CHARACTER_LABEL_GREEN := Color("39ff75")
const CHARACTER_LABEL_SHADOW := Color("06120b")
const BUILDING_LABEL_DISTANCE: float = 285.0
const TOWN_LABEL_DISTANCE: float = 430.0

var clean_layout_min_spacing: float = 0.0

func _ready() -> void:
    super._ready()
    set_meta("hashrace_texture_spacing_revision", TEXTURE_SPACING_REVISION)
    queue_redraw()

func _build_entities() -> void:
    super._build_entities()

    # First move every interactive building to its wider-spaced slot.
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind: String = String(entity.get("kind", ""))
        if kind == "rival_rep" or kind == "partner_rep":
            continue
        entity["pos"] = BuildingPlacer.desired_position(entity)
        entities[i] = entity

    # Then reconnect representatives to the building they belong to.
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind: String = String(entity.get("kind", ""))
        if kind == "partner_rep":
            var partner_idx: int = int(entity.get("partner_idx", -1))
            var partner_pos: Vector2 = _entity_position_for("partner", "partner_idx", partner_idx)
            var side: float = 1.0 if partner_idx % 2 == 0 else -1.0
            entity["pos"] = partner_pos + Vector2(128.0 * side, 92.0)
            entities[i] = entity
        elif kind == "rival_rep":
            var rival_idx: int = int(entity.get("rival_idx", -1))
            var profile_idx: int = int(entity.get("profile_idx", 0))
            var rival_pos: Vector2 = _entity_position_for("rival", "rival_idx", rival_idx)
            var side: float = 1.0 if profile_idx % 2 == 0 else -1.0
            entity["pos"] = rival_pos + Vector2(138.0 * side, 104.0)
            entities[i] = entity

    _rebuild_clean_town_zones()
    clean_layout_min_spacing = BuildingPlacer.minimum_building_spacing(entities)

func _entity_position_for(kind: String, key: String, value: int) -> Vector2:
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        if String(entity.get("kind", "")) == kind and int(entity.get(key, -999)) == value:
            return entity.get("pos", Vector2.ZERO)
    return Vector2.ZERO

func _rebuild_clean_town_zones() -> void:
    town_zones.clear()
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        var kind: String = String(entity.get("kind", ""))
        if kind == "hq":
            entity["profile_idx"] = company_idx
            entity["town"] = TOWN_NAMES[company_idx]
            town_zones.append({
                "profile_idx": company_idx,
                "center": entity["pos"],
                "town": TOWN_NAMES[company_idx],
                "company": String(player["name"]),
                "player": true
            })
        elif kind == "rival":
            var profile_idx: int = int(entity.get("profile_idx", 0))
            var rival_idx: int = int(entity.get("rival_idx", 0))
            town_zones.append({
                "profile_idx": profile_idx,
                "center": entity["pos"],
                "town": TOWN_NAMES[profile_idx],
                "company": String(rivals[rival_idx]["name"]),
                "player": false
            })

# -----------------------------------------------------------------------------
# Higher-density 16x16 source textures. The parent pixel-landscape system still
# scales them with nearest-neighbor filtering, so every added source pixel stays
# crisp at the 48px world-tile size.
# -----------------------------------------------------------------------------

func _paint_grass_pixels(img: Image, palette: Array, variant: int) -> void:
    super._paint_grass_pixels(img, palette, variant)
    for i in range(10):
        var x: int = (i * 11 + variant * 5 + 3) % 15
        var y: int = (i * 7 + variant * 3 + 2) % 15
        img.set_pixel(x, y, palette[0] if i % 3 == 0 else palette[2])
        if i % 4 == 0 and x + 1 < 16:
            img.set_pixel(x + 1, y, palette[2])
    # Small two-pixel tufts make open land read as vegetation, not green noise.
    for tuft in range(3):
        var tx: int = (variant * 4 + tuft * 5 + 1) % 14
        var ty: int = (variant * 7 + tuft * 4 + 3) % 14
        img.set_pixel(tx, ty, LAND_GRASS_HI)
        img.set_pixel(tx + 1, ty + 1, palette[0])

func _paint_walkway_pixels(img: Image, palette: Array, variant: int) -> void:
    super._paint_walkway_pixels(img, palette, variant)
    # Hairline cracks and chipped paver corners break up the repeated grid.
    var crack_y: int = 3 + variant * 3
    for x in range(2, 8):
        img.set_pixel(x, crack_y, palette[0])
    img.set_pixel(8, crack_y + 1, palette[0])
    img.set_pixel(13 - variant, 2 + variant, LAND_PATH_HI)
    img.set_pixel(2 + variant, 13 - variant, LAND_PATH_DARK.darkened(0.18))

func _paint_road_pixels(img: Image, palette: Array, variant: int) -> void:
    super._paint_road_pixels(img, palette, variant)
    # Fine aggregate, repaired asphalt and a tiny oil mark.
    for i in range(8):
        var x: int = (i * 9 + variant * 5 + 2) % 16
        var y: int = (i * 5 + variant * 7 + 4) % 16
        img.set_pixel(x, y, palette[0] if i % 2 == 0 else palette[2])
    var oil_x: int = 5 + variant
    img.set_pixel(oil_x, 10, LAND_ROAD_DARK.darkened(0.18))
    img.set_pixel(oil_x + 1, 10, LAND_ROAD_DARK.darkened(0.18))
    img.set_pixel(oil_x, 11, LAND_ROAD_DARK.darkened(0.18))

func _paint_lot_pixels(img: Image, palette: Array, variant: int) -> void:
    super._paint_lot_pixels(img, palette, variant)
    # Drainage grate and patch marks give industrial pads a used surface.
    for x in range(5, 11):
        img.set_pixel(x, 12, palette[0])
        if x % 2 == 0:
            img.set_pixel(x, 13, palette[2])
    img.set_pixel(2 + variant, 3, palette[2])
    img.set_pixel(3 + variant, 3, palette[2])
    img.set_pixel(12 - variant, 7, palette[0])

func _paint_water_pixels(img: Image, palette: Array, variant: int) -> void:
    super._paint_water_pixels(img, palette, variant)
    # Offset foam pixels keep the river moving visually without blur.
    for i in range(5):
        var x: int = (i * 3 + variant * 2 + 1) % 15
        var y: int = (i * 5 + variant + 2) % 15
        img.set_pixel(x, y, LAND_WATER_HI)
        if x + 1 < 16 and i % 2 == 0:
            img.set_pixel(x + 1, y, palette[2])

# -----------------------------------------------------------------------------
# Cleaner mining campuses. Three separated structures replace the older five-
# building cluster, leaving visible grass between buildings and reducing signs.
# -----------------------------------------------------------------------------

func _draw_mining_campus(center: Vector2, accent: Color) -> void:
    _campus_path(Rect2(center + Vector2(-210.0, -18.0), Vector2(420.0, 36.0)))
    _campus_path(Rect2(center + Vector2(-18.0, -150.0), Vector2(36.0, 300.0)))

    _campus_building(center + Vector2(-178.0, -102.0), Vector2(122.0, 76.0), "", accent, 0)
    _campus_building(center + Vector2(178.0, -102.0), Vector2(136.0, 82.0), "", accent, 1)
    _campus_building(center + Vector2(0.0, 126.0), Vector2(126.0, 74.0), "", Color("45b6df"), 2)

    _campus_tree(center + Vector2(-260.0, -12.0))
    _campus_tree(center + Vector2(255.0, 88.0))
    _campus_tree(center + Vector2(-240.0, 154.0))
    _campus_solar_array(center + Vector2(282.0, -158.0))
    _campus_cooling_rack(center + Vector2(278.0, -70.0), accent)

# -----------------------------------------------------------------------------
# Minimal map text: nearby town/building names only. Character names are always
# visible and always use the same neon green so the player can read people fast.
# -----------------------------------------------------------------------------

func _draw_pixel_town_labels() -> void:
    for raw_zone in town_zones:
        var zone: Dictionary = raw_zone
        var center: Vector2 = VisualStack.snap_to_pixel(zone["center"])
        if rep_pos.distance_to(center) > TOWN_LABEL_DISTANCE:
            continue
        var profile_idx: int = int(zone["profile_idx"])
        var accent: Color = COMPANY_ACCENTS[profile_idx]
        var sign_rect := Rect2(center + Vector2(-116.0, -184.0), Vector2(232.0, 25.0))
        _draw_layered_stroke_rect(sign_rect, GBC_INK, Color("020609"), accent.darkened(0.48), 2.0)
        draw_string(ThemeDB.fallback_font, center + Vector2(-108.0, -166.0), String(zone["town"]).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 216.0, 11, accent)

func _draw_stationary_rep(entity: Dictionary) -> void:
    var pos: Vector2 = entity["pos"]
    var accent: Color = entity.get("accent", CYAN)
    var scanner: String = String(entity.get("scanner", "left"))
    _draw_tech_rep(pos, accent, scanner, false)
    _draw_neon_character_name(pos, String(entity["name"]))

func _draw_rep() -> void:
    var rep: Dictionary = COMPANY_REPS[company_idx]
    var accent: Color = COMPANY_ACCENTS[company_idx]
    _draw_tech_rep(rep_pos, accent, String(rep["scanner"]), true)
    _draw_neon_character_name(rep_pos, String(rep["name"]))

func _draw_neon_character_name(pos: Vector2, character_name: String) -> void:
    var width: float = 180.0
    var base: Vector2 = VisualStack.snap_to_pixel(pos + Vector2(-width * 0.5, -82.0))
    draw_string(ThemeDB.fallback_font, base + Vector2(1.0, 1.0), character_name, HORIZONTAL_ALIGNMENT_CENTER, width, 12, CHARACTER_LABEL_SHADOW)
    draw_string(ThemeDB.fallback_font, base, character_name, HORIZONTAL_ALIGNMENT_CENTER, width, 12, CHARACTER_LABEL_GREEN)

func _show_building_name(pos: Vector2, idx: int) -> bool:
    return idx == selected_entity_idx or rep_pos.distance_to(pos) <= BUILDING_LABEL_DISTANCE

func _draw_building_name(entity: Dictionary, idx: int, accent: Color, y_offset: float, width: float = 220.0) -> void:
    var pos: Vector2 = entity["pos"]
    if not _show_building_name(pos, idx):
        return
    var base := Vector2(pos.x - width * 0.5, pos.y + y_offset)
    draw_string(ThemeDB.fallback_font, base + Vector2(1.0, 1.0), String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, width, 11, Color("020609"))
    draw_string(ThemeDB.fallback_font, base, String(entity["name"]), HORIZONTAL_ALIGNMENT_CENTER, width, 11, accent.lightened(0.18))

func _draw_facility_surface_detail(pos: Vector2, size_value: Vector2, accent: Color, seed: int) -> void:
    var left: float = pos.x - size_value.x * 0.5
    var top: float = pos.y - size_value.y * 0.62
    # Roof vents.
    for i in range(4):
        var x: float = left + 22.0 + float(i) * ((size_value.x - 44.0) / 4.0)
        draw_rect(Rect2(x, top + 6.0, 10.0, 5.0), Color("26343b"), true)
        draw_rect(Rect2(x + 2.0, top + 7.0, 6.0, 2.0), Color("72838a"), true)
    # Wall seams and service pixels.
    for i in range(3):
        var y: float = top + 36.0 + float(i) * 19.0
        draw_line(Vector2(left + 8.0, y), Vector2(left + size_value.x - 8.0, y), Color("17242a88"), 1.0)
    var box_x: float = left + 12.0 + float((seed * 23) % maxi(12, int(size_value.x - 40.0)))
    draw_rect(Rect2(box_x, top + size_value.y - 25.0, 16.0, 12.0), accent.darkened(0.55), true)
    draw_rect(Rect2(box_x + 4.0, top + size_value.y - 22.0, 8.0, 3.0), accent, true)

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var profile_idx: int = int(entity.get("profile_idx", company_idx))
    var accent: Color = COMPANY_ACCENTS[profile_idx]
    if String(entity["kind"]) == "rival" and bool(rivals[int(entity["rival_idx"])]["merged"]):
        accent = Color("657078")
    _selection_ring(pos, idx, 122.0)
    var size_value := Vector2(208.0, 118.0)
    _draw_pixel_facility(pos, size_value, accent, 3, "")
    _draw_facility_surface_detail(pos, size_value, accent, profile_idx + 7)
    # Hash-hall intake strip.
    for i in range(5):
        var x: float = pos.x - 78.0 + float(i) * 39.0
        draw_rect(Rect2(x, pos.y + 22.0, 24.0, 8.0), Color("081116"), true)
        draw_rect(Rect2(x + 4.0, pos.y + 24.0, 16.0, 3.0), accent.darkened(0.18), true)
    _draw_building_name(entity, idx, accent, 82.0, 230.0)

func _draw_partner_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var partner_idx: int = int(entity["partner_idx"])
    var accent: Color = PARTNER_ACCENTS[partner_idx]
    _selection_ring(pos, idx, 106.0)
    var size_value := Vector2(170.0, 104.0)
    _draw_pixel_facility(pos, size_value, accent, 2, "")
    _draw_facility_surface_detail(pos, size_value, accent, partner_idx + 31)
    _draw_building_name(entity, idx, accent, 76.0, 210.0)

func _draw_machine_market(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("bd8cff")
    _selection_ring(pos, idx, 106.0)
    var size_value := Vector2(184.0, 108.0)
    _draw_pixel_facility(pos, size_value, accent, 2, "")
    _draw_facility_surface_detail(pos, size_value, accent, 51)
    for col in range(4):
        for row in range(3):
            var rack := Rect2(pos + Vector2(-66.0 + float(col) * 42.0, -29.0 + float(row) * 18.0), Vector2(26.0, 11.0))
            draw_rect(rack, Color("071018"), true)
            draw_rect(Rect2(rack.position + Vector2(4.0, 3.0), Vector2(5.0, 4.0)), CHARACTER_LABEL_GREEN, true)
            draw_rect(Rect2(rack.position + Vector2(12.0, 3.0), Vector2(9.0, 2.0)), Color("53626b"), true)
    _draw_building_name(entity, idx, accent, 79.0, 224.0)

func _draw_power_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("ffd36e")
    _selection_ring(pos, idx, 106.0)
    var size_value := Vector2(180.0, 104.0)
    _draw_pixel_facility(pos, size_value, accent, 2, "")
    _draw_facility_surface_detail(pos, size_value, accent, 63)
    for x in [-48.0, 0.0, 48.0]:
        draw_rect(Rect2(pos + Vector2(x - 12.0, -15.0), Vector2(24.0, 24.0)), Color("101820"), true)
        draw_rect(Rect2(pos + Vector2(x - 7.0, -10.0), Vector2(14.0, 14.0)), accent, false, 3.0)
        draw_line(pos + Vector2(x, -24.0), pos + Vector2(x, -36.0), Color("9aa7ad"), 2.0)
    _draw_building_name(entity, idx, accent, 77.0, 224.0)

func _draw_bank_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent: Color = ORANGE
    _selection_ring(pos, idx, 104.0)
    var size_value := Vector2(168.0, 108.0)
    _draw_pixel_facility(pos, size_value, accent, 2, "")
    _draw_facility_surface_detail(pos, size_value, accent, 79)
    for x in [-45.0, -15.0, 15.0, 45.0]:
        draw_rect(Rect2(pos + Vector2(x - 4.0, -26.0), Vector2(8.0, 54.0)), accent.darkened(0.40), true)
        draw_rect(Rect2(pos + Vector2(x - 2.0, -24.0), Vector2(4.0, 50.0)), accent.lightened(0.05), true)
    _draw_building_name(entity, idx, accent, 79.0, 224.0)

func _draw_land_building(entity: Dictionary, idx: int) -> void:
    var pos: Vector2 = entity["pos"]
    var accent := Color("8ed06c")
    _selection_ring(pos, idx, 104.0)
    var size_value := Vector2(166.0, 102.0)
    _draw_pixel_facility(pos, size_value, accent, 2, "")
    _draw_facility_surface_detail(pos, size_value, accent, 91)
    for gx in range(3):
        for gy in range(2):
            var parcel := Rect2(pos + Vector2(-48.0 + float(gx) * 35.0, -19.0 + float(gy) * 25.0), Vector2(25.0, 16.0))
            draw_rect(parcel, accent.darkened(0.58), false, 2.0)
            draw_rect(Rect2(parcel.position + Vector2(4.0, 4.0), Vector2(5.0, 4.0)), accent.darkened(0.18), true)
    _draw_building_name(entity, idx, accent, 75.0, 218.0)

# Rebuild the draw order without the old always-on two-line corridor caption.
# Navigation and scanner overlays are preserved explicitly.
func _draw() -> void:
    _draw_pixel_tile_world()
    _draw_pixel_town_labels()
    _draw_world_props_pixel()
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        _draw_entity(entity, i)
    _draw_rep()
    if scanner_overlay_enabled:
        _draw_scanner_overlay()
    _draw_clean_navigation_path()

func _draw_clean_navigation_path() -> void:
    if nav_path.is_empty():
        return
    var previous: Vector2 = rep_pos
    for i in range(nav_path_index, nav_path.size()):
        var point: Vector2 = nav_path[i]
        draw_line(previous, point, Color("4df0ff99"), 3.0)
        draw_circle(point, 5.0, Color("64ff8ccc"))
        previous = point

func debug_texture_spacing_ready() -> bool:
    return clean_layout_min_spacing >= BuildingPlacer.MIN_TARGET_SPACING and TEXTURE_SPACING_REVISION >= 1

func debug_clean_layout_min_spacing() -> float:
    return clean_layout_min_spacing
