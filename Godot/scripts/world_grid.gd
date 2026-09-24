extends "res://scripts/world_towns.gd"

# Hash Race navigation layer for the RPG town network.
# Keyboard movement remains free/direct. Empty-ground mouse clicks use a
# four-direction logical grid so the representative routes around buildings
# and water instead of walking through scenery.

const GridNavigation = preload("res://scripts/grid_navigation.gd")
const WorldScale = preload("res://scripts/world_scale_rules.gd")
const NAV_CELL_SIZE: float = 48.0

var grid_nav
var nav_path: Array[Vector2] = []
var nav_path_index: int = 0

func _ready() -> void:
    super._ready()
    grid_nav = GridNavigation.new()
    grid_nav.configure(WORLD_SIZE, NAV_CELL_SIZE)
    _rebuild_navigation_grid()

    # Start visibly outside the HQ instead of inside its footprint.
    if not entities.is_empty():
        var hq_pos: Vector2 = entities[0]["pos"]
        rep_pos = hq_pos + Vector2(0.0, 170.0)
        click_target = rep_pos
        has_click_target = false
        if is_instance_valid(camera):
            camera.position = rep_pos
    _open_message(
        "CITY GRID ONLINE // %s" % _current_town_name(),
        "Walk with WASD/arrows, or click open ground to route around buildings and water. Press E near a company representative or building. T uses intercity transit."
    )
    queue_redraw()

func _rebuild_navigation_grid() -> void:
    if grid_nav == null:
        return
    grid_nav.configure(WORLD_SIZE, NAV_CELL_SIZE)

    # Permanent map barriers from the visible world layer.
    grid_nav.block_rect(Rect2(0.0, 1770.0, WORLD_SIZE.x, 130.0))
    grid_nav.block_rect(Rect2(2600.0, 0.0, 400.0, 760.0))

    # Buildings are solid map cells. Representatives remain walkable targets.
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        var kind: String = String(entity["kind"])
        if kind == "rival_rep" or kind == "partner_rep":
            continue
        var pos: Vector2 = entity["pos"]
        if WorldScale.is_building_kind(kind):
            grid_nav.block_rect(WorldScale.collision_rect(kind, pos))
            # Use the same scale contract as the renderer so mouse routing lands
            # on the visible front-door apron instead of an obsolete footprint.
            grid_nav.carve_world_point(WorldScale.front_door_world_pos(kind, pos), 0)

    # The wider v0.052+ layout placed buildings on the old fixed carve points.
    # Carve only the live HQ front-door spawn and a known-open road junction so
    # the navigation helper never punches a walkable hole through a building.
    if not entities.is_empty():
        var hq_pos: Vector2 = entities[0]["pos"]
        grid_nav.carve_world_point(hq_pos + Vector2(0.0, 170.0), 0)
    grid_nav.carve_world_point(Vector2(1200.0, 990.0), 1)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
            var world_pos: Vector2 = get_global_mouse_position()
            # Clicking a company/person remains an immediate RPG interaction.
            if _entity_at(world_pos) >= 0:
                _clear_nav_path()
                super._unhandled_input(event)
                return
            _route_to(world_pos)
            get_viewport().set_input_as_handled()
            return
    super._unhandled_input(event)

func _process(delta: float) -> void:
    var manual_move: bool = (
        Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or
        Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or
        Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or
        Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
    )
    if manual_move and not nav_path.is_empty():
        _clear_nav_path()

    super._process(delta)

    # world_overworld.gd clears has_click_target whenever the current waypoint
    # is reached. Feed it the next grid waypoint until the route is complete.
    if not nav_path.is_empty() and not has_click_target:
        nav_path_index += 1
        if nav_path_index < nav_path.size():
            click_target = nav_path[nav_path_index]
            has_click_target = true
        else:
            _clear_nav_path()

func _route_to(world_pos: Vector2) -> void:
    if grid_nav == null:
        return
    nav_path = grid_nav.find_path(rep_pos, world_pos)
    nav_path_index = 0
    if nav_path.is_empty():
        has_click_target = false
        _open_message("ROUTE BLOCKED", "No walkable route reaches that tile. Try a road, sidewalk, or open lot.")
        return
    click_target = nav_path[0]
    has_click_target = true
    queue_redraw()

func _clear_nav_path() -> void:
    nav_path.clear()
    nav_path_index = 0
    has_click_target = false
    queue_redraw()

func _travel_next_town() -> void:
    _clear_nav_path()
    super._travel_next_town()

func _draw() -> void:
    super._draw()
    if nav_path.is_empty():
        return
    var previous: Vector2 = rep_pos
    for i in range(nav_path_index, nav_path.size()):
        var point: Vector2 = nav_path[i]
        draw_line(previous, point, Color("4df0ff99"), 3.0)
        draw_circle(point, 6.0, Color("64ff8ccc"))
        previous = point

func debug_grid_navigation_ready() -> bool:
    return grid_nav != null and grid_nav.blocked_count() > 0

func debug_grid_path_exists() -> bool:
    if grid_nav == null:
        return false
    var test_path: Array[Vector2] = grid_nav.find_path(Vector2(1500.0, 1290.0), Vector2(1950.0, 1290.0))
    return not test_path.is_empty()

func debug_grid_blocked_cells() -> int:
    if grid_nav == null:
        return 0
    return grid_nav.blocked_count()
