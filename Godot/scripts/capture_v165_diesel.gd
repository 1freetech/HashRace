extends SceneTree

const OUTPUT := "res://../visual-proof/v165-diesel-overview.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("V165 DIESEL PROOF FAIL: " + message)
    quit(1)

func _capture() -> void:
    var packed := load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live scene missing")
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
        _fail("live v0.165 runtime did not initialize")
        return

    var inventory = scene.get("infrastructure_inventory")
    var company_value = scene.get("player")
    if inventory == null or not company_value is Dictionary:
        _fail("live inventory/company missing")
        return
    var company: Dictionary = company_value
    var resource = inventory.item_resource("diesel_generator")
    if resource == null:
        _fail("diesel ItemResource missing")
        return
    var before_mw := float(company.get("mw", 0.0))

    # Controlled scenario: grant one stored module, then exercise the exact same
    # InfrastructureInventory deploy/undeploy path used by the live inventory UI.
    if not inventory.add("diesel_generator", 1):
        _fail("could not add stored diesel module")
        return
    if inventory.deployed_quantity("diesel_generator") != 0:
        _fail("stored diesel was incorrectly marked deployed")
        return
    if not inventory.deploy("diesel_generator", company, 1):
        _fail("live inventory diesel deployment failed")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(8):
        await process_frame

    if not is_equal_approx(float(company.get("mw", 0.0)), before_mw + float(resource.get("power_output_mw"))):
        _fail("diesel deployment did not apply its real MW effect")
        return
    if not scene.has_method("debug_v165_diesel_ready") or not bool(scene.call("debug_v165_diesel_ready")):
        _fail("deployed diesel was not rendered and grounded by the live v0.165 world")
        return
    var first_foot: Rect2 = scene.get("v165_diesel_footprint")
    var grid_nav = scene.get("grid_nav")
    if first_foot.size == Vector2.ZERO or grid_nav == null or bool(grid_nav.call("world_is_walkable", first_foot.get_center())):
        _fail("deployed diesel ground footprint is not blocked")
        return

    # Undeployment must reverse MW and clear only the collision owned by diesel.
    if not inventory.undeploy("diesel_generator", company, 1):
        _fail("live inventory diesel undeployment failed")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(6):
        await process_frame
    if inventory.deployed_quantity("diesel_generator") != 0:
        _fail("undeployed diesel remained marked deployed")
        return
    if not is_equal_approx(float(company.get("mw", 0.0)), before_mw):
        _fail("diesel undeployment did not reverse the MW effect")
        return
    if not bool(grid_nav.call("world_is_walkable", first_foot.get_center())):
        _fail("diesel undeployment left its navigation footprint blocked")
        return
    if bool(scene.get("v165_diesel_drawn")):
        _fail("diesel renderer remained active after undeployment")
        return

    # Redeploy to prove the live render/collision can be created again after a
    # clean removal, then capture that final gameplay state.
    if not inventory.deploy("diesel_generator", company, 1):
        _fail("diesel redeployment failed")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(8):
        await process_frame
    if not bool(scene.call("debug_v165_diesel_ready")):
        _fail("diesel redeployment did not restore live art/collision")
        return

    scene.process_mode = Node.PROCESS_MODE_DISABLED
    var bounds: Rect2 = scene.get("v165_diesel_rect")
    var camera: Camera2D = scene.get("camera")
    if bounds.size == Vector2.ZERO or camera == null:
        _fail("diesel render bounds/camera missing")
        return
    camera.position_smoothing_enabled = false
    camera.position = bounds.get_center() + Vector2(130, 70)
    camera.zoom = Vector2(1.25, 1.25)
    camera.force_update_scroll()
    scene.queue_redraw()
    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout

    var image := root.get_texture().get_image()
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image == null or image.is_empty() or image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("could not save proof")
        return
    print("V165 DIESEL PROOF PASS: live inventory stored/deployed/undeployed/redeployed, MW effects, exact atlas render and owned collision cleanup; " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
