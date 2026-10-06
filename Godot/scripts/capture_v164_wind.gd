extends SceneTree

# Exact-head rendered proof for the validated wind binary in the restored full
# gameplay chain. The normal campaign does not start with wind deployed, so the
# proof deliberately deploys one real wind_farm through InfrastructureInventory,
# then validates the v0.164 renderer, grounded footprint, and viewport pixels.
const OUTPUT := "res://../visual-proof/v164-wind-overview.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("V164 WIND PROOF FAIL: " + message)
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
        _fail("full v0.165 gameplay chain is not live")
        return
    if not scene.has_method("debug_v164_wind_ready"):
        _fail("v0.164 wind gameplay layer is missing from live inheritance chain")
        return

    var inventory = scene.get("infrastructure_inventory")
    var company: Dictionary = scene.get("player")
    if inventory == null or company.is_empty():
        _fail("live inventory/company state unavailable")
        return
    if inventory.item_resource("wind_farm") == null:
        _fail("wind_farm ItemResource missing")
        return
    if inventory.quantity("wind_farm") <= 0 and not inventory.add("wind_farm", 1):
        _fail("could not stage wind_farm for runtime proof")
        return
    if inventory.deployed_quantity("wind_farm") <= 0 and not inventory.deploy("wind_farm", company, 1):
        _fail("could not deploy wind_farm in live gameplay")
        return
    scene.set("player", company)
    scene.queue_redraw()
    for _frame in range(12):
        await process_frame

    if not bool(scene.call("debug_v164_wind_ready")):
        _fail("v0.164 wind PNG did not render with grounded live footprint")
        return

    var bounds: Rect2 = scene.get("v164_wind_rect")
    var footprint: Rect2 = scene.get("v164_wind_footprint")
    var grid_nav = scene.get("grid_nav")
    if bounds.size.x < 100.0 or bounds.size.y < 100.0 or footprint.size.x <= 0.0 or grid_nav == null:
        _fail("wind render bounds/ground-contact footprint missing")
        return
    if bool(grid_nav.call("world_is_walkable", footprint.get_center())):
        _fail("wind ground-contact footprint was not registered in navigation")
        return

    var camera: Camera2D = scene.get("camera")
    if camera == null:
        _fail("live gameplay camera missing")
        return
    camera.position_smoothing_enabled = false
    camera.position = bounds.get_center()
    camera.zoom = Vector2(1.18, 1.18)
    camera.force_update_scroll()
    scene.queue_redraw()
    for _frame in range(12):
        await process_frame
    await create_timer(0.25).timeout

    var image := root.get_texture().get_image()
    if image == null or image.is_empty():
        _fail("viewport image missing")
        return
    var folder := ProjectSettings.globalize_path("res://../visual-proof")
    DirAccess.make_dir_recursive_absolute(folder)
    if image.save_png(ProjectSettings.globalize_path(OUTPUT)) != OK:
        _fail("could not save wind visual proof")
        return
    print("V164 WIND PROOF PASS: deployed wind_farm rendered in full v0.165 gameplay chain with registered ground footprint; " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
