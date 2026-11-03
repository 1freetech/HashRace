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

func _all_blocked(cells: Array, grid_nav) -> bool:
    for raw_cell in cells:
        if bool(grid_nav.is_walkable(Vector2i(raw_cell))):
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
    if not _all_blocked(Array(physical.call("_cells_for_rect", large_container)), grid_nav) \
        or not _all_blocked(Array(scene.call("_v160_cells_for_rect", large_transformer)), grid_nav):
        _fail("a grown campus footprint contains walkable grid cells")
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
    # The real campus already contains roads, props and other blocked cells.
    # The wider sprites do not necessarily gain *owned* cells, because this
    # system owns only previously walkable cells. Check all live footprint cells
    # stay blocked, and verify any actual release without requiring a new claim.
    if not _all_walkable(container_released, grid_nav):
        _fail("container shrink left its released live cells blocked")
        return
    if not _all_walkable(transformer_released, grid_nav):
        _fail("transformer shrink left its released live cells blocked")
        return
    var restored_container: Rect2 = restored_snapshot.get("container_rect", Rect2())
    var restored_transformer: Rect2 = scene.get("v160_transformer_collision_rect")
    if restored_container != small_container or restored_transformer != small_transformer:
        _fail("restored art and collision footprint differ from starting tier")
        return
    if not _all_blocked(Array(physical.call("_cells_for_rect", restored_container)), grid_nav) \
        or not _all_blocked(Array(scene.call("_v160_cells_for_rect", restored_transformer)), grid_nav):
        _fail("a restored campus footprint contains walkable grid cells")
        return

    # Independently exercise *the same ownership methods* on an empty,
    # configured navigation grid. The live campus's preblocked infrastructure
    # otherwise masks the release path; isolated grid cells make an actual
    # small -> large -> small stale-cell regression observable.
    var probe_script = load("res://scripts/physical_campus_collision.gd")
    var grid_script = load("res://scripts/grid_navigation.gd")
    if probe_script == null or grid_script == null:
        _fail("collision isolation probe scripts missing")
        return
    var probe_nav = grid_script.new()
    probe_nav.configure(Vector2(3000.0, 1900.0))
    var probe = probe_script.new()
    probe.set("grid_nav", probe_nav)
    var container_probe_owned: Array[Vector2i] = []
    var transformer_probe_owned: Array[Vector2i] = []
    probe.call("_sync_owned_rect", small_container, Rect2(), container_probe_owned)
    probe.call("_sync_owned_rect", small_transformer, Rect2(), transformer_probe_owned)
    if container_probe_owned.is_empty() or transformer_probe_owned.is_empty():
        _fail("empty-grid small-tier collision ownership missing")
        return
    probe.call("_sync_owned_rect", large_container, small_container, container_probe_owned)
    probe.call("_sync_owned_rect", large_transformer, small_transformer, transformer_probe_owned)
    var isolated_large_container: Array = container_probe_owned.duplicate()
    var isolated_large_transformer: Array = transformer_probe_owned.duplicate()
    if not _all_blocked(Array(probe.call("_cells_for_rect", large_container)), probe_nav) \
        or not _all_blocked(Array(probe.call("_cells_for_rect", large_transformer)), probe_nav):
        _fail("empty-grid grown collision footprint has walk-through cells")
        return
    probe.call("_sync_owned_rect", restored_container, large_container, container_probe_owned)
    probe.call("_sync_owned_rect", restored_transformer, large_transformer, transformer_probe_owned)
    var isolated_container_released := _released_cells(isolated_large_container, container_probe_owned)
    var isolated_transformer_released := _released_cells(isolated_large_transformer, transformer_probe_owned)
    if isolated_container_released.is_empty() or isolated_transformer_released.is_empty():
        _fail("empty-grid capacity test did not exercise distinct released cells")
        return
    if not _all_walkable(isolated_container_released, probe_nav) \
        or not _all_walkable(isolated_transformer_released, probe_nav):
        _fail("empty-grid capacity shrink left stale owned cells blocked")
        return
    if not _all_blocked(Array(probe.call("_cells_for_rect", restored_container)), probe_nav) \
        or not _all_blocked(Array(probe.call("_cells_for_rect", restored_transformer)), probe_nav):
        _fail("empty-grid restored footprint has walk-through cells")
        return
    probe.call("_clear_owned", container_probe_owned)
    probe.call("_clear_owned", transformer_probe_owned)
    if probe_nav.blocked_count() != 0:
        _fail("empty-grid teardown leaked owned collision cells")
        return
    print("PHYSICAL CAPACITY OWNERSHIP PASS: live container/transformer footprints blocked; isolated growth/shrink released %d container and %d transformer cells" % [isolated_container_released.size(), isolated_transformer_released.size()])
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
