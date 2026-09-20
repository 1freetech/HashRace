extends "res://scripts/world_v128.gd"

# Hash Race v0.129 capacity decision preview.
# Turns the existing MW capacity math into a compact planning answer: how many
# additional MW can be deployed safely, or how much mining load must be removed.

const V129_CAPACITY_DECISION_REVISION := 1

func capacity_decision_preview(load_mw: float = -1.0, capacity_mw: float = -1.0) -> Dictionary:
    var active_load := load_mw
    if active_load < 0.0:
        active_load = maxf(0.0, _machine_load_kw() / 1000.0)
    var active_capacity := capacity_mw
    if active_capacity < 0.0:
        active_capacity = maxf(0.0, _effective_available_mw())

    var plan := site_capacity_action(active_load, active_capacity)
    var headroom := maxf(0.0, float(plan["headroom_mw"]))
    var curtailed := maxf(0.0, float(plan["curtail_mw"]))
    var decision := "HOLD"
    var detail := "No additional mining load until more power is secured."

    if curtailed > 0.0:
        decision = "CURTAIL"
        detail = "Remove %.1f MW of mining load before advancing." % curtailed
    elif headroom > 0.05:
        decision = "DEPLOY"
        detail = "Up to %.1f MW of additional mining load fits current power." % headroom
    elif active_load <= 0.0 and active_capacity > 0.0:
        decision = "DEPLOY"
        detail = "Up to %.1f MW of mining load fits current power." % active_capacity

    return {
        "decision": decision,
        "detail": detail,
        "load_mw": active_load,
        "capacity_mw": active_capacity,
        "headroom_mw": headroom,
        "curtail_mw": curtailed,
    }

func capacity_decision_summary(load_mw: float = -1.0, capacity_mw: float = -1.0) -> String:
    var preview := capacity_decision_preview(load_mw, capacity_mw)
    return "%s • %s" % [String(preview["decision"]), String(preview["detail"])]

func _draw_mining_hq(entity: Dictionary, idx: int) -> void:
    super._draw_mining_hq(entity, idx)
    if String(entity.get("kind", "")) != "player_hq":
        return
    var pos: Vector2 = entity["pos"]
    var preview := capacity_decision_preview()
    var text_color := Color("72f29a")
    if String(preview["decision"]) == "CURTAIL":
        text_color = Color("ff8b7d")
    elif String(preview["decision"]) == "HOLD":
        text_color = Color("ffd36b")
    draw_string(
        ThemeDB.fallback_font,
        pos + Vector2(-155.0, 118.0),
        capacity_decision_summary(),
        HORIZONTAL_ALIGNMENT_CENTER,
        310.0,
        11,
        text_color
    )

func debug_v129_ready() -> bool:
    var deploy := capacity_decision_preview(6.0, 10.0)
    var curtail := capacity_decision_preview(12.0, 10.0)
    var hold := capacity_decision_preview(10.0, 10.0)
    return V129_CAPACITY_DECISION_REVISION == 1 \
        and String(deploy["decision"]) == "DEPLOY" \
        and is_equal_approx(float(deploy["headroom_mw"]), 4.0) \
        and String(curtail["decision"]) == "CURTAIL" \
        and is_equal_approx(float(curtail["curtail_mw"]), 2.0) \
        and String(hold["decision"]) == "HOLD" \
        and debug_v128_ready()
