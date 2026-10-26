extends SceneTree

const WORLD_SCENE := "res://scenes/world.tscn"
const EXPECTED_WORLD_SCRIPT := "res://scripts/world_v165.gd"
const OUTPUT_DIR := "res://../visual-proof"

func _initialize() -> void:
    call_deferred("_run")

func _require(condition: bool, message: String) -> bool:
    if condition:
        return true
    push_error("V166 PARTNER CONTRACT PROOF FAIL: " + message)
    quit(1)
    return false

func _wait_frames(count: int) -> void:
    for _frame in range(count):
        await process_frame

func _capture(filename: String) -> bool:
    var viewport_image := root.get_texture().get_image()
    if viewport_image == null or viewport_image.is_empty():
        return _require(false, "rendered frame was empty: " + filename)
    var output_folder := ProjectSettings.globalize_path(OUTPUT_DIR)
    DirAccess.make_dir_recursive_absolute(output_folder)
    var output_path := ProjectSettings.globalize_path(OUTPUT_DIR + "/" + filename)
    if viewport_image.save_png(output_path) != OK:
        return _require(false, "could not save " + output_path)
    return true

func _run() -> void:
    var packed := load(WORLD_SCENE) as PackedScene
    if not _require(packed != null, "live world scene missing"):
        return

    var world := packed.instantiate()
    if not _require(world != null, "live world scene did not instantiate"):
        return
    root.add_child(world)
    await _wait_frames(16)

    var live_script := world.get_script() as Script
    if not _require(live_script != null and live_script.resource_path == EXPECTED_WORLD_SCRIPT, "world_v165 is not the active gameplay head"):
        return
    if not _require(bool(world.call("debug_v165_runtime_ready")), "live world readiness assertion failed"):
        return
    var runtime_state: Dictionary = world.call("debug_v165_runtime_state")
    if not _require(bool(runtime_state.get("npc_contracts", false)), "partner contract readiness flag is false"):
        return

    var entities: Array = world.get("entities")
    var partner_idx := -1
    var representative: Dictionary = {}
    for raw_entity in entities:
        var entity: Dictionary = raw_entity
        if String(entity.get("kind", "")) == "partner_rep" and int(entity.get("partner_idx", -1)) == 0:
            partner_idx = 0
            representative = entity
            break
    if not _require(partner_idx == 0, "utility partner representative is missing"):
        return

    var player: Dictionary = world.get("player")
    player["cash"] = 0.0
    var relationships: Dictionary = player.get("partner_relationships", {}).duplicate(true)
    relationships["utility"] = 80
    player["partner_relationships"] = relationships
    world.set("player", player)
    world.set("player_personality", {
        "aggression": 86,
        "risk": 86,
        "growth": 86,
        "research": 86,
        "treasury": 86,
        "operations": 86,
        "reputation": 86
    })

    world.call("_open_partner_rep", representative)
    await _wait_frames(2)
    var dialog_text := world.get("dialog_text") as Label
    var dialog_title := world.get("dialog_title") as Label
    var action_row := world.get("action_row") as HBoxContainer
    if not _require(dialog_text != null and dialog_title != null and action_row != null, "representative dialogue controls are missing"):
        return
    if not _require(dialog_text.text.contains("Relationship 80/100") and dialog_text.text.contains("AVAILABLE"), "initial relationship and contract terms are not shown"):
        return
    if not _require(action_row.get_child_count() == 1 and (action_row.get_child(0) as Button).text == "NEGOTIATE CONTRACT", "representative does not expose the negotiate action"):
        return
    if not _capture("v166-partner-representative.png"):
        return

    var negotiation_manager := world.get("negotiation_manager") as Node
    var first_scene := world.call("_v165_start_partner_negotiation", partner_idx) as Node
    if not _require(negotiation_manager != null and first_scene != null, "partner contract negotiation did not launch"):
        return
    var first_context: Dictionary = negotiation_manager.get("active_context")
    if not _require(String(first_context.get("deal_type", "")) == "partner_contract" and String(first_context.get("partner_id", "")) == "utility", "partner identity was not preserved in negotiation context"):
        return
    if not _require(int(first_context.get("player_leverage", -1)) == 100, "stored relationship did not contribute to initial leverage"):
        return
    await create_timer(0.9).timeout
    first_scene.call("debug_force_open")
    await _wait_frames(2)
    if not _capture("v166-partner-negotiation-open.png"):
        return

    # Drive the normal offer button with no cash. The negotiation UI converts
    # its accepted terms into an insufficient-cash result, which lowers trust.
    for _offer in range(8):
        if bool(first_scene.get("resolved")):
            break
        first_scene.call("_make_offer")
        await _wait_frames(1)
    if not _require(bool(first_scene.get("resolved")), "cash-constrained offer did not resolve"):
        return
    var failed_result: Dictionary = world.get("negotiation_last_result")
    if not _require(not bool(failed_result.get("success", true)) and String(failed_result.get("outcome", "")) == "insufficient_cash", "cash-constrained result was not reported as a no-deal"):
        return
    if not _require(int(world.call("_v165_partner_relationship", "utility")) == 78, "failed contract did not apply the two-point relationship consequence"):
        return
    var signed_partners: Dictionary = world.get("signed_partners")
    if not _require(not signed_partners.has("utility"), "failed contract incorrectly activated the partner"):
        return
    if not _capture("v166-partner-contract-stalled.png"):
        return

    negotiation_manager.call("close_active")
    await _wait_frames(3)
    player = world.get("player")
    player["cash"] = 2000000.0
    world.set("player", player)
    world.call("_open_partner_rep", representative)
    await _wait_frames(2)
    if not _require(dialog_text.text.contains("Relationship 78/100") and dialog_text.text.contains("AVAILABLE"), "updated relationship did not persist into the next representative encounter"):
        return

    var cash_before := float(player.get("cash", 0.0))
    var utility_bonus_before := float(player.get("power_discount", 0.0))
    var second_scene := world.call("_v165_start_partner_negotiation", partner_idx) as Node
    if not _require(second_scene != null, "representative could not reopen contract talks"):
        return
    var second_context: Dictionary = negotiation_manager.get("active_context")
    if not _require(int(second_context.get("player_leverage", -1)) == 99, "reduced relationship was not reflected in the next negotiation's leverage"):
        return
    await create_timer(0.9).timeout
    second_scene.call("debug_force_open")
    await _wait_frames(2)
    if not _capture("v166-partner-contract-open.png"):
        return

    # The ordinary counteroffer control closes this deterministic test deal.
    for _counter in range(6):
        if bool(second_scene.get("resolved")):
            break
        second_scene.call("_counter_offer")
        await _wait_frames(1)
    if not _require(bool(second_scene.get("resolved")), "counteroffer did not resolve"):
        return
    var closed_result: Dictionary = world.get("negotiation_last_result")
    if not _require(bool(closed_result.get("success", false)) and float(closed_result.get("final_cost_usd", 0.0)) > 0.0, "counteroffer did not close at a negotiated price"):
        return

    player = world.get("player")
    signed_partners = world.get("signed_partners")
    var final_cost := float(closed_result.get("final_cost_usd", 0.0))
    if not _require(signed_partners.has("utility"), "successful contract did not activate the inherited partner effect"):
        return
    if not _require(is_equal_approx(float(player.get("cash", 0.0)), cash_before - final_cost), "player cash did not decrease by the negotiated contract price"):
        return
    if not _require(is_equal_approx(float(player.get("power_discount", 0.0)), utility_bonus_before + 0.012) and bool(player.get("utility_access", false)), "utility contract bonus did not feed live company state"):
        return
    if not _require(int(world.call("_v165_partner_relationship", "utility")) == 86, "successful contract did not improve persistent representative relationship"):
        return
    var result_label := second_scene.get("result_label") as RichTextLabel
    if not _require(result_label != null and result_label.text.contains("DEAL CLOSED"), "successful outcome is not visibly shown"):
        return
    await _wait_frames(2)
    if not _capture("v166-partner-contract-closed.png"):
        return

    negotiation_manager.call("close_active")
    await _wait_frames(3)
    world.call("_open_partner_rep", representative)
    await _wait_frames(2)
    if not _require(dialog_text.text.contains("Relationship 86/100") and dialog_text.text.contains("SIGNED"), "signed state and improved relationship did not persist in the live representative interaction"):
        return
    if not _require(action_row.get_child_count() == 0, "signed partner still offers a second contract action"):
        return
    if not _capture("v166-partner-contract-signed.png"):
        return

    print("V166 PARTNER CONTRACT PROOF PASS: live representative interaction, stored leverage, failed-deal penalty, negotiated close, cash accounting, utility effect, and signed relationship state.")
    quit(0)
