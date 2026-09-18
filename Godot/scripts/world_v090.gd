extends "res://scripts/world_v089.gd"

# Hash Race v0.090 gameplay-first HUD pass.
# Removes the legacy decorative overworld/header, duplicate company/market
# readouts and startup instruction dialog from normal play. Actionable controls
# and contextual interaction prompts remain available.

const V090_GAMEPLAY_HUD_REVISION: int = 1

func _ready() -> void:
    super._ready()
    _simplify_overworld_hud()
    set_meta("hashrace_v090_gameplay_hud_revision", V090_GAMEPLAY_HUD_REVISION)

func _simplify_overworld_hud() -> void:
    # Move the turn button out of the verbose company card before hiding it.
    if is_instance_valid(quarter_button):
        var side := quarter_button.get_parent()
        var layer := side.get_parent() if is_instance_valid(side) else null
        if is_instance_valid(layer):
            quarter_button.reparent(layer)
            quarter_button.position = Vector2(22.0, 22.0)
            quarter_button.size = Vector2(150.0, 38.0)
            quarter_button.text = "END TURN"
        if is_instance_valid(side):
            side.visible = false

    # Hide the full-width COMPANY OVERWORLD header and duplicate top stats.
    if is_instance_valid(top_stats) and is_instance_valid(top_stats.get_parent()):
        top_stats.get_parent().visible = false

    # Hide the legacy market strip; market data remains in gameplay systems.
    if is_instance_valid(market_label) and is_instance_valid(market_label.get_parent()):
        market_label.get_parent().visible = false

    # Do not cover the map with an automatic welcome/instruction dialog.
    if is_instance_valid(dialog_panel):
        dialog_panel.visible = false

    # Context text should appear only when there is something to interact with.
    if is_instance_valid(prompt_label):
        prompt_label.text = ""

func _update_nearby_prompt() -> void:
    var idx := _nearest_entity()
    if idx < 0:
        prompt_label.text = ""
        return
    var entity: Dictionary = entities[idx]
    prompt_label.text = "E / ENTER  •  %s" % String(entity["name"])

func _open_message(title_text: String, body_text: String) -> void:
    dialog_panel.visible = true
    super._open_message(title_text, body_text)

func _open_entity(idx: int) -> void:
    dialog_panel.visible = true
    super._open_entity(idx)

func debug_v090_ready() -> bool:
    return (
        V090_GAMEPLAY_HUD_REVISION == 1
        and is_instance_valid(quarter_button)
        and quarter_button.visible
        and is_instance_valid(dialog_panel)
        and not dialog_panel.visible
    )
