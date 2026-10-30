extends SceneTree

# Exercise the real campaign's two road crossings, collision and equipment
# interaction. The images are captured from the live gameplay viewport.
const OUTPUT_DIR := "res://../visual-proof/equipment-road-crossings"
const ROAD_X := 1416.0 # center of the column-29 road, in 48 px cells
const CROSSINGS := [
    {"name": "upper", "start": Vector2(ROAD_X, 456.0), "end": Vector2(ROAD_X, 696.0), "middle": 572.0},
    {"name": "lower", "start": Vector2(ROAD_X, 984.0), "end": Vector2(ROAD_X, 1128.0), "middle": 1048.0},
]

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("EQUIPMENT ROAD PROOF FAIL: " + message)
    quit(1)

func _save_frame(name: String) -> bool:
    for _frame in range(3):
        await process_frame
    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        return false
    var folder := ProjectSettings.globalize_path(OUTPUT_DIR)
    DirAccess.make_dir_recursive_absolute(folder)
    return image.save_png(folder.path_join(name + ".png")) == OK

func _run() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live world is missing")
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _frame in range(20):
        await process_frame

    var live_script := scene.get_script() as Script
    var props := scene.get_node_or_null("ArchiveSpriteProps")
    var layout := scene.get_node_or_null("ArchiveSpriteProps/LayoutTuner")
    var survey := scene.get_node_or_null("ArchiveSpriteProps/EquipmentSurvey")
    var nav: Variant = scene.get("grid_nav")
    if live_script == null or live_script.resource_path != "res://scripts/world_v165.gd" \
        or props == null or layout == null or survey == null or nav == null:
        _fail("live campaign, equipment, or navigation did not initialize")
        return
    if not bool(layout.call("debug_ready")) or not bool(props.call("debug_ready")):
        _fail("equipment layout, road clearance, or sprite integration is invalid")
        return

    var footprints: Array = props.get("collision_footprints")
    if footprints.is_empty():
        _fail("equipment has no collision footprints")
        return
    for item in footprints:
        var foot: Rect2 = item
        if bool(nav.call("world_is_walkable", foot.get_center())):
            _fail("an equipment footprint is not blocked: %s" % str(foot))
            return

    # Route across both rows using the live game's route and movement code.
    # Verify the full centerline is open first so A* cannot mask a blocked
    # crossing by silently finding an alternate route or nearest open goal.
    for crossing in CROSSINGS:
        var start: Vector2 = crossing["start"]
        var end: Vector2 = crossing["end"]
        for y in range(int(start.y), int(end.y) + 1, 16):
            if not bool(nav.call("world_is_walkable", Vector2(ROAD_X, float(y)))):
                _fail("%s road center is blocked at y=%d" % [crossing["name"], y])
                return
        scene.call("_clear_nav_path")
        scene.set("rep_pos", start)
        scene.call("_route_to", end)
        var middle_saved := false
        var arrived := false
        for _step in range(70):
            await create_timer(0.1).timeout
            var current: Vector2 = scene.get("rep_pos")
            if absf(current.x - ROAD_X) > 3.0:
                _fail("%s route left the road centerline" % crossing["name"])
                return
            if not middle_saved and current.y >= float(crossing["middle"]) - 12.0:
                if not await _save_frame(String(crossing["name"]) + "-crossing"):
                    _fail("could not save crossing screenshot")
                    return
                middle_saved = true
            if current.distance_to(end) <= 12.0:
                arrived = true
                break
        if not arrived or not middle_saved:
            _fail("player did not traverse the %s crossing" % crossing["name"])
            return
        if not await _save_frame(String(crossing["name"]) + "-cleared"):
            _fail("could not save completed crossing screenshot")
            return

    # Find a real blocking sprite with an open adjacent cell and no competing
    # entity interaction. Drive the live movement toward its blocked cell, then
    # inspect it with the game's F key path rather than calling _inspect directly.
    var sprites: Array = props.get("live_sprites")
    var chosen: Sprite2D = null
    var start_position := Vector2.ZERO
    var blocked_position := Vector2.ZERO
    for item in footprints:
        var foot: Rect2 = item
        var cell: Vector2i = nav.call("world_to_cell", foot.get_center())
        for raw_sprite in sprites:
            var sprite := raw_sprite as Sprite2D
            if sprite == null or absf(sprite.position.x - foot.get_center().x) > 1.0 \
                or absf(sprite.position.y - foot.end.y) > 1.0:
                continue
            for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
                var neighbor: Vector2i = cell + direction
                if not bool(nav.call("is_walkable", neighbor)):
                    continue
                var candidate: Vector2 = nav.call("cell_to_world", neighbor)
                if candidate.distance_to(sprite.position) > 72.0:
                    continue
                scene.set("rep_pos", candidate)
                if bool(survey.call("_entity_claims_interaction", scene)) \
                    or survey.call("_nearest_equipment", 82.0) != sprite:
                    continue
                chosen = sprite
                start_position = candidate
                blocked_position = nav.call("cell_to_world", cell)
                break
            if chosen != null:
                break
        if chosen != null:
            break
    if chosen == null:
        _fail("no inspectable equipment has a nearby open approach cell")
        return

    scene.call("_clear_nav_path")
    scene.set("rep_pos", start_position)
    scene.set("click_target", blocked_position)
    scene.set("has_click_target", true)
    await create_timer(1.0).timeout
    var stopped: Vector2 = scene.get("rep_pos")
    if stopped.distance_to(start_position) < 1.0 \
        or not bool(nav.call("world_is_walkable", stopped)) \
        or stopped.distance_to(blocked_position) < 16.0:
        _fail("live movement did not stop at a solid equipment footprint")
        return
    scene.set("has_click_target", false)
    if not await _save_frame("equipment-collision"):
        _fail("could not save equipment collision screenshot")
        return

    var focus := root.gui_get_focus_owner()
    if focus != null:
        focus.release_focus()
    var event := InputEventKey.new()
    event.keycode = KEY_F
    event.pressed = true
    Input.parse_input_event(event)
    await process_frame
    event = InputEventKey.new()
    event.keycode = KEY_F
    event.pressed = false
    Input.parse_input_event(event)
    for _frame in range(5):
        await process_frame
    var player: Dictionary = scene.get("player")
    var inspected: Array = player.get("equipment_surveys", [])
    if not inspected.has(String(chosen.name)):
        _fail("F did not persist inspection of the approached equipment")
        return
    if not await _save_frame("equipment-inspected"):
        _fail("could not save equipment inspection screenshot")
        return
    print("EQUIPMENT ROAD PROOF PASS: both live road routes traversed; %d equipment footprints blocked; movement stopped and F inspected %s" % [footprints.size(), chosen.name])
    quit(0)
