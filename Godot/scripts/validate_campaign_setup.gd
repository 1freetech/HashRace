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

    var preview := scene.find_child("CharacterPreview", true, false)
    if preview == null:
        _fail("CharacterPreview node is missing")
        return

    var years := scene.get("years_option") as OptionButton
    if years == null or years.item_count != 100:
        _fail("campaign length selector must expose 100 yearly choices")
        return
    if years.get_item_id(years.item_count - 1) != 100:
        _fail("campaign length selector does not reach 100 years")
        return

    var skin := scene.get("skin_tone_option") as OptionButton
    var suit := scene.get("suit_color_option") as OptionButton
    var gender := scene.get("gender_option") as OptionButton
    var scouter_color := scene.get("scouter_color_option") as OptionButton
    var scouter_eye := scene.get("scouter_eye_option") as OptionButton
    if skin == null or suit == null or gender == null or scouter_color == null or scouter_eye == null:
        _fail("character selectors are missing")
        return

    skin.select(5)
    suit.select(4)
    gender.select(2)
    scouter_color.select(3)
    scouter_eye.select(0)
    scene.call("_on_character_changed", 0)
    await process_frame

    var selection: Vector2i = scene.call("debug_character_preview_selection")
    if selection != Vector2i(5, 2):
        _fail("preview did not follow edited skin/presentation values")
        return

    if int(scene.call("debug_character_preview_suit_color")) != 4:
        _fail("preview did not follow edited suit color")
        return

    var scouter_selection: Vector2i = scene.call("debug_character_preview_scouter_selection")
    if scouter_selection != Vector2i(3, 0):
        _fail("preview did not follow edited scouter color/eye values")
        return

    print("HASH RACE CAMPAIGN SETUP PASS: exact-sheet preview follows skin, suit, presentation and scouter choices; campaign length reaches 100 years.")
    quit(0)
