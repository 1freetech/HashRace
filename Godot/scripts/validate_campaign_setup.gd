extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("HASH RACE CAMPAIGN SETUP FAIL: " + message)
    quit(1)

func _run() -> void:
    var packed := load("res://scenes/campaign_setup.tscn") as PackedScene
    if packed == null:
        _fail("campaign_setup.tscn did not load")
        return

    var scene := packed.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    if not scene.has_method("debug_character_preview_ready") or not bool(scene.call("debug_character_preview_ready")):
        _fail("live character preview did not initialize")
        return

    var preview := scene.get_node_or_null("CharacterPreview")
    if preview == null:
        _fail("CharacterPreview node is missing")
        return

    var skin := scene.get("skin_tone_option") as OptionButton
    var gender := scene.get("gender_option") as OptionButton
    if skin == null or gender == null:
        _fail("character selectors are missing")
        return

    skin.select(5)
    gender.select(2)
    scene.call("_on_character_changed", 0)
    await process_frame

    var selection: Vector2i = scene.call("debug_character_preview_selection")
    if selection != Vector2i(5, 2):
        _fail("preview did not follow edited skin/presentation values")
        return

    print("HASH RACE CAMPAIGN SETUP PASS: live player preview follows customization controls.")
    quit(0)
