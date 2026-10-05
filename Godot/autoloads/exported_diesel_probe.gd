extends Node

const PROOF_ARG := "--exported-diesel-proof"
const DIESEL_ID := "diesel_generator"
const OUTPUT := "user://v165-diesel-overview.png"

func _ready() -> void:
    if not OS.get_cmdline_user_args().has(PROOF_ARG):
        return
    call_deferred("_run_probe")

func _fail(message: String) -> void:
    push_error("V165 DIESEL PROOF FAIL: " + message)
    get_tree().quit(1)

func _run_probe() -> void:
    var active_scene: Node = get_tree().current_scene
    if active_scene != null:
        active_scene.queue_free()
        await get_tree().process_frame

    var packed: PackedScene = load("res://scenes/world.tscn") as PackedScene
    if packed == null:
        _fail("live scene missing from exported package")
        return

    var scene: Node = packed.instantiate()
    get_tree().root.add_child(scene)
    get_tree().current_scene = scene
    for _frame in range(12):
        await get_tree().process_frame

    for method_name in ["runtime_ready", "deploy_infrastructure", "undeploy_infrastructure", "infrastructure_ready", "infrastructure_rect", "infrastructure_footprint"]:
        if not scene.has_method(method_name):
            _fail("live API missing: " + str(method_name))
            return
    if not bool(scene.call("runtime_ready")):
        _fail("live runtime did not initialize")
        return

    var inventory: Variant = scene.get("infrastructure_inventory")
    var company_value: Variant = scene.get("player")
    if inventory == null or not company_value is Dictionary:
        _fail("live inventory/company missing")
        return
    var company: Dictionary = company_value
    var before_mw: float = float(company.get("mw", 0.0))

    if not bool(inventory.call("add", DIESEL_ID, 1)):
        _fail("could not add stored diesel module")
        return
    if bool(scene.call("infrastructure_ready", DIESEL_ID)):
        _fail("stored diesel was incorrectly rendered as deployed")
        return
    if not bool(scene.call("deploy_infrastructure", DIESEL_ID)):
        _fail("actual diesel deployment failed")
        return

    var resource: Variant = inventory.call("item_resource", DIESEL_ID)
    if resource == null:
        _fail("diesel item resource missing")
        return
    if not is_equal_approx(float(company.get("mw", 0.0)), before_mw + float(resource.get("power_output_mw"))):
        _fail("deployment did not apply the real power effect")
        return
    if not bool(scene.call("infrastructure_ready", DIESEL_ID)):
        _fail("deployed diesel was not textured/grounded")
        return

    if not bool(scene.call("undeploy_infrastructure", DIESEL_ID)):
        _fail("diesel undeployment failed")
        return
    var foot: Rect2 = scene.call("infrastructure_footprint", DIESEL_ID)
    var grid_nav: Variant = scene.get("grid_nav")
    if grid_nav == null:
        _fail("grid navigation missing")
        return
    if bool(scene.call("infrastructure_ready", DIESEL_ID)) or not bool(grid_nav.call("world_is_walkable", foot.get_center())) or not is_equal_approx(float(company.get("mw", 0.0)), before_mw):
        _fail("undeployment left diesel art, collision, or power effect")
        return

    if not bool(scene.call("deploy_infrastructure", DIESEL_ID)):
        _fail("diesel redeployment failed")
        return

    scene.process_mode = Node.PROCESS_MODE_DISABLED
    var bounds: Rect2 = scene.call("infrastructure_rect", DIESEL_ID)
    var camera_value: Variant = scene.get("camera")
    if not camera_value is Camera2D:
        _fail("live camera missing")
        return
    var camera: Camera2D = camera_value
    camera.position_smoothing_enabled = false
    camera.position = bounds.get_center() + Vector2(130.0, 70.0)
    camera.zoom = Vector2(1.25, 1.25)
    camera.force_update_scroll()
    scene.queue_redraw()
    for _frame in range(12):
        await get_tree().process_frame
    await get_tree().create_timer(0.25).timeout

    var image: Image = get_tree().root.get_texture().get_image()
    var output_path: String = ProjectSettings.globalize_path(OUTPUT)
    if image == null or image.is_empty() or image.save_png(output_path) != OK:
        _fail("could not save exported-build proof")
        return

    print("V165 DIESEL PROOF PASS: exported runtime stored/deployed/undeployed/redeployed diesel, power effects, live atlas Sprite2D, collision; " + output_path)
    get_tree().quit(0)
