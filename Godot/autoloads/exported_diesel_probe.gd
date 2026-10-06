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
    for _frame in range(14):
        await get_tree().process_frame

    var live_script := scene.get_script() as Script
    if live_script == null or live_script.resource_path != "res://scripts/world_v165.gd":
        _fail("world_v165 is not the exported gameplay head")
        return
    for method_name in ["debug_v165_runtime_ready", "debug_v165_runtime_state", "debug_v165_diesel_ready"]:
        if not scene.has_method(method_name):
            _fail("live v165 API missing: " + str(method_name))
            return
    if not bool(scene.call("debug_v165_runtime_ready")):
        var runtime_state: Dictionary = Dictionary(scene.call("debug_v165_runtime_state"))
        _fail("exported v0.165 runtime did not initialize: %s" % str(runtime_state))
        return

    var inventory: Variant = scene.get("infrastructure_inventory")
    var company_value: Variant = scene.get("player")
    if inventory == null or not company_value is Dictionary:
        _fail("live inventory/company missing")
        return
    var company: Dictionary = company_value
    var resource: Variant = inventory.call("item_resource", DIESEL_ID)
    if resource == null:
        _fail("diesel item resource missing from exported package")
        return
    var before_mw: float = float(company.get("mw", 0.0))

    # Grant one stored module, then exercise the same InfrastructureInventory
    # deploy path the live UI uses. This proves the exported .pck contains the
    # ItemResource, v0.165 renderer and dynamic collision implementation.
    if not bool(inventory.call("add", DIESEL_ID, 1)):
        _fail("could not add stored diesel module")
        return
    if int(inventory.call("deployed_quantity", DIESEL_ID)) != 0:
        _fail("stored diesel was incorrectly marked deployed")
        return
    if not bool(inventory.call("deploy", DIESEL_ID, company, 1)):
        _fail("exported diesel deployment failed")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(8):
        await get_tree().process_frame

    if not is_equal_approx(float(company.get("mw", 0.0)), before_mw + float(resource.get("power_output_mw"))):
        _fail("deployment did not apply the real power effect")
        return
    if not bool(scene.call("debug_v165_diesel_ready")):
        _fail("deployed diesel was not rendered and grounded in exported build")
        return

    var first_foot: Rect2 = scene.get("v165_diesel_footprint")
    var grid_nav: Variant = scene.get("grid_nav")
    if first_foot.size == Vector2.ZERO or grid_nav == null:
        _fail("deployed diesel footprint/navigation missing")
        return
    if bool(grid_nav.call("world_is_walkable", first_foot.get_center())):
        _fail("deployed diesel footprint stayed walkable")
        return

    # Undeploy must reverse MW and release exactly the collision owned by this
    # dynamic generator. This is the exported-build regression guard for the
    # invisible-obstacle bug repaired in world_v165.
    if not bool(inventory.call("undeploy", DIESEL_ID, company, 1)):
        _fail("exported diesel undeployment failed")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(6):
        await get_tree().process_frame

    if int(inventory.call("deployed_quantity", DIESEL_ID)) != 0:
        _fail("undeployed diesel remained marked deployed")
        return
    if not is_equal_approx(float(company.get("mw", 0.0)), before_mw):
        _fail("undeployment did not reverse diesel MW")
        return
    if not bool(grid_nav.call("world_is_walkable", first_foot.get_center())):
        _fail("undeployment left diesel navigation collision behind")
        return
    if bool(scene.get("v165_diesel_drawn")):
        _fail("diesel renderer remained active after undeployment")
        return

    # Redeploy once more so the captured exported screenshot proves the final
    # shipped executable can recreate the art/collision after a clean removal.
    if not bool(inventory.call("deploy", DIESEL_ID, company, 1)):
        _fail("exported diesel redeployment failed")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(8):
        await get_tree().process_frame
    if not bool(scene.call("debug_v165_diesel_ready")):
        _fail("redeployment did not restore exported diesel art/collision")
        return

    scene.process_mode = Node.PROCESS_MODE_DISABLED
    var bounds: Rect2 = scene.get("v165_diesel_rect")
    var camera_value: Variant = scene.get("camera")
    if bounds.size == Vector2.ZERO or not camera_value is Camera2D:
        _fail("exported diesel render bounds/camera missing")
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

    print("V165 DIESEL PROOF PASS: exported runtime stored/deployed/undeployed/redeployed diesel, MW effects, v165 art/collision cleanup; " + output_path)
    get_tree().quit(0)
