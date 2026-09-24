extends "res://scripts/world_v101.gd"

# Hash Race v0.102 visual-declutter + infrastructure ownership pass.
# The gameplay systems remain intact, but decorative industrial props are no
# longer welded to every company home. Infrastructure appears when it is owned
# and deployed, while town art keeps one clear building silhouette per parcel.

const V102_VISUAL_CLEANUP_REVISION := 1

var v102_suppress_power_route := false

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v102_visual_cleanup_revision", V102_VISUAL_CLEANUP_REVISION)
    queue_redraw()

# The old energy campus drew a large dark equipment slab near the player's home.
# Keep energy generation and market simulation, but remove that permanent
# overworld object. Purchased energy still affects the live simulation.
func _draw_energy_campus(_origin: Vector2) -> void:
    pass

# v0.096 added a decorative route between the power service building and HQ.
# Suppress it only while the world-prop stack is drawing; debug/state queries
# still see the real power/HQ positions.
func _draw_world_props_pixel() -> void:
    v102_suppress_power_route = true
    super._draw_world_props_pixel()
    v102_suppress_power_route = false

func _v096_entity_pos(kind_name: String) -> Vector2:
    if v102_suppress_power_route and kind_name == "power":
        return Vector2.INF
    return super._v096_entity_pos(kind_name)

# Every town used to receive a wide compute pod, transformer bank, fence,
# bollards and a cable tray regardless of ownership. Those props are now
# inventory-driven. Only the player's deployed AI rack gets a world sprite.
func _draw_site_container(center: Vector2, accent: Color) -> void:
    var town_center := center + Vector2(152.0, -22.0)
    if town_center.distance_to(_player_hq_center()) > 8.0:
        return
    if infrastructure_inventory.deployed_quantity("ai_rack_system") <= 0:
        return

    # Reuse the engineered pixel-rack language introduced in v0.059, but render
    # one rack only. The narrow footprint sits fully beside the home.
    var rack_center := VisualStack.snap_to_pixel(center)
    draw_rect(
        Rect2(rack_center + Vector2(-14.0, 22.0), Vector2(28.0, 5.0)),
        Color(0.02, 0.03, 0.04, 0.42),
        true
    )
    _draw_micro_server_rack(rack_center, accent, 0)
    draw_rect(
        Rect2(rack_center + Vector2(-10.0, -24.0), Vector2(20.0, 3.0)),
        accent.darkened(0.18),
        true
    )
    _draw_status_led(rack_center + Vector2(7.0, -22.5), RACK_LED_BLUE, 1.25)

func _draw_transformer_bank(_center: Vector2, _accent: Color) -> void:
    pass

func _draw_site_fence(_center: Vector2, _accent: Color) -> void:
    pass

func _draw_bollards(_center: Vector2, _accent: Color) -> void:
    pass

func _draw_campus_data_bus(_center: Vector2, _accent: Color, _seed: int) -> void:
    pass

# Remove the two decorative support houses that were repeated behind every
# company HQ. Minimal landscaping is retained only on valid land.
func _draw_mining_campus(center: Vector2, _accent: Color) -> void:
    _v102_tree_if_land(center + Vector2(-270.0, -14.0))
    _v102_tree_if_land(center + Vector2(260.0, 75.0))

func _v102_tree_if_land(pos: Vector2) -> void:
    var cell := _world_to_art_cell(pos)
    var tile := int(art_cells.get(cell, TILE_WATER))
    if tile == TILE_WATER or tile == TILE_ROAD:
        return
    _campus_tree(pos)

# Rebuild every entrance path after the inherited art tilemap is complete.
# Walks are one tile wide, start at the front-center of the building, and only
# extend in a straight line when they can actually reach a road without water.
func _build_art_tilemap() -> void:
    super._build_art_tilemap()
    _v102_rebuild_entry_walks()

func _v102_rebuild_entry_walks() -> void:
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        var kind := String(entity.get("kind", ""))
        if not WorldScale.is_building_kind(kind):
            continue

        var c := _world_to_art_cell(Vector2(entity.get("pos", Vector2.ZERO)))

        # Remove the inherited disconnected foundation/path pixels immediately
        # around this building. Roads and water are never overwritten.
        for y in range(c.y - 3, c.y + 4):
            for x in range(c.x - 3, c.x + 4):
                var cell := Vector2i(x, y)
                if not art_cells.has(cell):
                    continue
                var current := int(art_cells[cell])
                if current == TILE_PLAZA or current == TILE_LOT:
                    art_cells[cell] = TILE_GRASS_DARK if (x + y) % 11 == 0 else TILE_GRASS

        # Keep a restrained five-tile foundation under the facade.
        for x in range(c.x - 2, c.x + 3):
            _v102_set_land_tile(Vector2i(x, c.y + 1), TILE_LOT)

        var entrance := Vector2i(c.x, c.y + 2)
        if not _v102_connect_straight_walk(entrance):
            _v102_set_land_tile(entrance, TILE_PLAZA)

func _v102_set_land_tile(cell: Vector2i, tile_id: int) -> void:
    if not art_cells.has(cell):
        return
    var current := int(art_cells[cell])
    if current == TILE_WATER or current == TILE_ROAD:
        return
    art_cells[cell] = tile_id

func _v102_connect_straight_walk(start: Vector2i) -> bool:
    # Front/down first keeps entrances visually consistent. Side/up connections
    # are only fallbacks for parcels whose road geometry requires them.
    var directions: Array[Vector2i] = [
        Vector2i(0, 1),
        Vector2i(1, 0),
        Vector2i(-1, 0),
        Vector2i(0, -1),
    ]
    for direction in directions:
        var trail: Array[Vector2i] = []
        var cursor := start
        for _distance in range(8):
            if not art_cells.has(cursor):
                break
            var tile := int(art_cells[cursor])
            if tile == TILE_WATER:
                break
            if tile == TILE_ROAD:
                for trail_cell in trail:
                    _v102_set_land_tile(trail_cell, TILE_PLAZA)
                return true
            trail.append(cursor)
            cursor += direction
    return false

func debug_v102_ready() -> bool:
    var ai_rack := infrastructure_inventory.item("ai_rack_system")
    return (
        V102_VISUAL_CLEANUP_REVISION == 1
        and debug_v101_ready()
        and not ai_rack.is_empty()
        and String(ai_rack.get("visual", "")) == "ai_rack"
    )
