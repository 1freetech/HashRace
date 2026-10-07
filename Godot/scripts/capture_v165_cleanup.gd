extends SceneTree

const OUTPUT := "res://../visual-proof/v165-npc-identity.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("V165 CLEANUP PROOF FAIL: " + message)
    quit(1)

func _cells_all_blocked(grid_nav, cells: Array) -> bool:
    if grid_nav == null or cells.is_empty():
        return false
    for raw_cell in cells:
        var cell: Vector2i = raw_cell
        if bool(grid_nav.call("is_walkable", cell)):
            return false
    return true

func _cells_all_walkable(grid_nav, cells: Array) -> bool:
    if grid_nav == null or cells.is_empty():
        return false
    for raw_cell in cells:
        var cell: Vector2i = raw_cell
        if not bool(grid_nav.call("is_walkable", cell)):
            return false
    return true

func _capture() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live world scene missing")
        return
    var scene := packed.instantiate()
    root.add_child(scene)
    for _frame in range(14):
        await process_frame

    var live_script := scene.get_script() as Script
    if live_script == null or live_script.resource_path != "res://scripts/world_v165.gd":
        _fail("world_v165 is not the live gameplay head")
        return
    if not scene.has_method("debug_v165_runtime_ready") or not bool(scene.call("debug_v165_runtime_ready")):
        _fail("live v0.165 runtime is not ready")
        return
    if not scene.has_method("debug_v165_npc_identity_ready") or not bool(scene.call("debug_v165_npc_identity_ready")):
        _fail("distinct NPC identity contract is not ready")
        return

    # Exercise the gameplay-side stale-collision repair before taking the visual
    # proof. Solar and wind must each own only cells that were open beforehand,
    # then release those exact cells when that source is undeployed.
    var inventory = scene.get("infrastructure_inventory")
    var company_value = scene.get("player")
    var grid_nav = scene.get("grid_nav")
    if inventory == null or not company_value is Dictionary or grid_nav == null:
        _fail("live inventory/company/navigation missing")
        return
    var company: Dictionary = company_value

    if not inventory.add("solar_array", 1) or not inventory.deploy("solar_array", company, 1):
        _fail("could not deploy solar for collision cleanup proof")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(6):
        await process_frame
    var solar_cells: Array = Array(scene.get("v165_legacy_energy_owned_blocked_cells")).duplicate()
    if not _cells_all_blocked(grid_nav, solar_cells):
        _fail("solar did not register an owned blocked footprint")
        return
    if not inventory.undeploy("solar_array", company, 1):
        _fail("could not undeploy solar")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(6):
        await process_frame
    if not _cells_all_walkable(grid_nav, solar_cells):
        _fail("solar undeploy left stale navigation cells blocked")
        return

    if not inventory.add("wind_farm", 1) or not inventory.deploy("wind_farm", company, 1):
        _fail("could not deploy wind for collision cleanup proof")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(6):
        await process_frame
    var wind_cells: Array = Array(scene.get("v165_legacy_energy_owned_blocked_cells")).duplicate()
    if not _cells_all_blocked(grid_nav, wind_cells):
        _fail("wind did not register an owned blocked footprint")
        return
    if not inventory.undeploy("wind_farm", company, 1):
        _fail("could not undeploy wind")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(6):
        await process_frame
    if not _cells_all_walkable(grid_nav, wind_cells):
        _fail("wind undeploy left stale navigation cells blocked")
        return

    var entities: Array = scene.get("entities")
    var rep_idx := -1
    var rep_entity: Dictionary = {}
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind := str(entity.get("kind", ""))
        if kind == "partner_rep" or kind == "rival_rep":
            rep_idx = i
            rep_entity = entity
            break
    if rep_idx < 0:
        _fail("no stationary representative exists for visual proof")
        return

    var npc_pos := Vector2(rep_entity.get("pos", Vector2.ZERO))
    var player_pos := npc_pos + Vector2(-92.0, 28.0)
    scene.set("rep_pos", player_pos)
    scene.set("click_target", player_pos)
    scene.set("has_click_target", false)
    scene.set("selected_entity_idx", rep_idx)

    var camera := scene.get("camera") as Camera2D
    if camera == null:
        _fail("camera missing")
        return
    camera.position_smoothing_enabled = false
    camera.position = (npc_pos + player_pos) * 0.5 + Vector2(0.0, -10.0)
    camera.zoom = Vector2(1.35, 1.35)
    camera.force_update_scroll()
    scene.queue_redraw()
    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout

    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("rendered image missing")
        return
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("could not save visual proof")
        return

    print("V165 CLEANUP PROOF PASS: solar/wind owned collision clears after undeploy; approved player sprite remains live beside a distinct named NPC renderer; " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
