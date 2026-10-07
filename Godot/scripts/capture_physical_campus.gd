extends SceneTree

const OUTPUT := "res://../visual-proof/physical-campus-collision.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("PHYSICAL CAMPUS PROOF FAIL: " + message)
    quit(1)

func _released_cells(previous_cells: Array, current_cells: Array) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for raw_cell in previous_cells:
        var cell: Vector2i = raw_cell
        if not current_cells.has(cell):
            result.append(cell)
    return result

func _all_walkable(cells: Array, grid_nav) -> bool:
    for raw_cell in cells:
        if not bool(grid_nav.is_walkable(Vector2i(raw_cell))):
            return false
    return true

func _capture() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live world scene missing")
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _frame in range(18):
        await process_frame

    var live_script := scene.get_script() as Script
    if live_script == null or live_script.resource_path != "res://scripts/world_v165.gd":
        _fail("world_v165 is not the live gameplay head")
        return
    var physical := scene.get_node_or_null("PhysicalCampusCollision")
    var grid_nav = scene.get("grid_nav")
    if physical == null or grid_nav == null or not physical.has_method("debug_ready") or not bool(physical.call("debug_ready")):
        _fail("physical campus collision did not initialize")
        return
    if not scene.has_method("debug_v160_transformer_ready") or not bool(scene.call("debug_v160_transformer_ready")):
        _fail("transformer collision did not initialize")
        return

    var small_snapshot: Dictionary = physical.call("debug_snapshot")
    var small_container: Rect2 = small_snapshot.get("container_rect", Rect2())
    var command_rect: Rect2 = small_snapshot.get("command_rect", Rect2())
    var small_transformer: Rect2 = scene.get("v160_transformer_collision_rect")
    if small_container.size == Vector2.ZERO or command_rect.size == Vector2.ZERO or small_transformer.size == Vector2.ZERO:
        _fail("initial campus footprints missing")
        return
    if bool(grid_nav.world_is_walkable(small_container.get_center())) \
        or bool(grid_nav.world_is_walkable(command_rect.get_center())) \
        or bool(grid_nav.world_is_walkable(small_transformer.get_center())):
        _fail("visible campus structure is still walk-through at initial capacity")
        return

    var player: Dictionary = scene.get("player")
    var original_mw := float(player.get("mw", 0.0))
    var origin: Vector2 = scene.call("_energy_campus_origin")
    scene.set("rep_pos", origin + Vector2(0.0, 330.0))
    var camera := scene.get("camera") as Camera2D
    if camera != null:
        camera.position_smoothing_enabled = false
        camera.position = origin
        camera.force_update_scroll()

    # Force the live site across capacity tiers. Both the container and authored
    # transformer must enlarge physically, not just visually.
    player["mw"] = 120.0
    scene.set("player", player)
    scene.queue_redraw()
    for _frame in range(14):
        await process_frame

    var large_snapshot: Dictionary = physical.call("debug_snapshot")
    var large_container: Rect2 = large_snapshot.get("container_rect", Rect2())
    var large_container_cells: Array = Array(large_snapshot.get("container_cells", [])).duplicate()
    var large_transformer: Rect2 = scene.get("v160_transformer_collision_rect")
    var large_transformer_cells: Array = Array(scene.get("v160_transformer_owned_cells")).duplicate()
    if large_container.size.x <= small_container.size.x or large_transformer.size.x <= small_transformer.size.x:
        _fail("capacity growth enlarged art without enlarging physical footprint")
        return
    if bool(grid_nav.world_is_walkable(large_container.get_center())) or bool(grid_nav.world_is_walkable(large_transformer.get_center())):
        _fail("grown campus footprint is not blocked")
        return

    # Shrink back and compare the exact owner sets. Every cell present only in
    # the large tier must become walkable; cells retained by the small tier are
    # intentionally still blocked and must never be misclassified as stale.
    player["mw"] = original_mw
    scene.set("player", player)
    scene.queue_redraw()
    for _frame in range(14):
        await process_frame

    var restored_snapshot: Dictionary = physical.call("debug_snapshot")
    var restored_container_cells: Array = Array(restored_snapshot.get("container_cells", [])).duplicate()
    var restored_transformer_cells: Array = Array(scene.get("v160_transformer_owned_cells")).duplicate()
    var container_released := _released_cells(large_container_cells, restored_container_cells)
    var transformer_released := _released_cells(large_transformer_cells, restored_transformer_cells)
    if container_released.is_empty() or transformer_released.is_empty():
        _fail("capacity tiers did not produce distinct owned collision cells")
        return
    if not _all_walkable(container_released, grid_nav):
        _fail("container shrink left genuinely released cells blocked")
        return
    if not _all_walkable(transformer_released, grid_nav):
        _fail("transformer shrink left genuinely released cells blocked")
        return
    if bool(grid_nav.world_is_walkable(command_rect.get_center())):
        _fail("Command Center lost physical collision during capacity change")
        return

    # Return to the large tier for a fresh screenshot of the actual scaled site.
    player["mw"] = 120.0
    scene.set("player", player)
    scene.set("rep_pos", origin + Vector2(0.0, 330.0))
    scene.queue_redraw()
    for _frame in range(12):
        await process_frame
    if camera == null:
        _fail("camera missing")
        return
    camera.position = origin + Vector2(0.0, 25.0)
    camera.zoom = Vector2(1.05, 1.05)
    camera.force_update_scroll()
    scene.queue_redraw()
    for _frame in range(10):
        await process_frame
    await create_timer(0.2).timeout

    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("rendered image missing")
        return
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("could not save campus proof")
        return

    print("PHYSICAL CAMPUS PROOF PASS: container + Command Center block movement; container/transformer collision grows and shrinks with visible capacity tier and releases stale cells; " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
