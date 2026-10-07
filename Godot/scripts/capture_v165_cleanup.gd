extends SceneTree

const OUTPUT := "res://../visual-proof/v165-npc-identity.png"

func _initialize() -> void:
    call_deferred("_capture")

func _fail(message: String) -> void:
    push_error("V165 CLEANUP PROOF FAIL: " + message)
    quit(1)

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

    var entities: Array = scene.get("entities")
    var rep_idx := -1
    var rep_entity: Dictionary = {}
    for i in range(entities.size()):
        var entity: Dictionary = entities[i]
        var kind := String(entity.get("kind", ""))
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
    camera.zoom = Vector2(1.8, 1.8)
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

    print("V165 CLEANUP PROOF PASS: approved player sprite remains live beside a distinct named NPC renderer; " + ProjectSettings.globalize_path(OUTPUT))
    quit(0)
