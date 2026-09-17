extends "res://scripts/live_treasury_controls.gd"

# UI stays in GDScript; treasury state mutations are owned by HashRaceRuntime.

func _on_hold_policy_changed(value: float) -> void:
    var percent := clampi(int(round(value)), 0, 100)
    if world == null or not world.has_method("_native_set_hold_percent"):
        push_error("Native BTC hold-policy endpoint is missing.")
        return
    var action: Dictionary = world.call("_native_set_hold_percent", percent) as Dictionary
    if not bool(action.get("ok", false)):
        _feedback(String(action.get("message", "Could not update native BTC hold policy.")))
        return
    _reset_turn_preview()
    if world.has_method("_refresh_ui"):
        world.call("_refresh_ui")
    _refresh_status()

func _sell_sats(sats_to_sell: float) -> float:
    if world == null or not world.has_method("_native_sell_sats"):
        push_error("Native BTC treasury-sale endpoint is missing.")
        return 0.0
    var action: Dictionary = world.call("_native_sell_sats", sats_to_sell) as Dictionary
    if not bool(action.get("ok", false)):
        return 0.0
    _reset_turn_preview()
    if world.has_method("_refresh_ui"):
        world.call("_refresh_ui")
    return float(action.get("cash_raised", 0.0))

func debug_native_treasury_ready() -> bool:
    return world != null and world.has_method("_native_runtime_active") and bool(world.call("_native_runtime_active"))
