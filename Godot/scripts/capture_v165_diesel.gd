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
    for _frame in range(12):
        await process_frame
    for method in ["runtime_ready", "deploy_infrastructure", "undeploy_infrastructure", "infrastructure_ready", "infrastructure_rect", "infrastructure_footprint"]:
        if not scene.has_method(method):
            _fail("live API missing: " + method)
            return
    if not scene.call("runtime_ready"):
        _fail("live runtime did not initialize")
        return
    var inventory = scene.get("infrastructure_inventory")
    var company_value = scene.get("player")
    if inventory == null or not company_value is Dictionary:
        _fail("live inventory/company missing")
        return
    var company: Dictionary = company_value
    var before_mw := float(company.get("mw", 0))
    # Controlled scenario: grant one STORED module, then deploy through the
    # actual world API. The sprite must not exist merely because it is owned.
    if not inventory.add("diesel_generator", 1):
        _fail("could not add stored module")
        return
    if scene.call("infrastructure_ready", "diesel_generator"):
        _fail("stored equipment was incorrectly rendered as deployed")
        return
    if not scene.call("deploy_infrastructure", "diesel_generator"):
        _fail("actual deployment failed")
        return
    var resource = inventory.item_resource("diesel_generator")
    if not is_equal_approx(float(company.mw), before_mw + float(resource.power_output_mw)):
        _fail("deployment did not apply the real power effect")
        return
    if not scene.call("infrastructure_ready", "diesel_generator"):
        _fail("deployed module was not textured/grounded")
        return
    # Undeployment must remove both art and collision, and reverse the effect.
    if not scene.call("undeploy_infrastructure", "diesel_generator"):
        _fail("undeployment failed")
        return
    var foot: Rect2 = scene.call("infrastructure_footprint", "diesel_generator")
    if scene.call("infrastructure_ready", "diesel_generator") or not scene.grid_nav.world_is_walkable(foot.get_center()) or not is_equal_approx(float(company.mw), before_mw):
        _fail("undeployment left art, collision or a power effect")
        return
    if not scene.call("deploy_infrastructure", "diesel_generator"):
        _fail("redeployment failed")
        return
    scene.process_mode = Node.PROCESS_MODE_DISABLED
    var bounds: Rect2 = scene.call("infrastructure_rect", "diesel_generator")
    var camera: Camera2D = scene.get("camera")
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
    print("V165 DIESEL PROOF PASS: stored/deployed/undeployed/redeployed, power effects, live atlas Sprite2D, collision; " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
