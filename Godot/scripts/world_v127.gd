extends "res://scripts/world_v126.gd"

# Hash Race v0.127 live mining-capacity feedback.
# Shows the active Bitcoin mine's electrical headroom and the existing capacity
# action directly in the playable world before the player expands hardware.

const V127_CAPACITY_FEEDBACK_REVISION := 1
const V127_PANEL_SIZE := Vector2(286.0, 74.0)
const V127_REFRESH_SECONDS := 0.25

var v127_refresh_elapsed := 0.0

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v127_capacity_feedback_revision", V127_CAPACITY_FEEDBACK_REVISION)
    queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)
    v127_refresh_elapsed += delta
    if v127_refresh_elapsed >= V127_REFRESH_SECONDS:
        v127_refresh_elapsed = 0.0
        queue_redraw()

func _draw() -> void:
    super._draw()
    _v127_draw_capacity_feedback()

func _v127_draw_capacity_feedback() -> void:
    var load_mw := maxf(0.0, _machine_load_kw() / 1000.0)
    var capacity_mw := maxf(0.0, _effective_available_mw())
    var plan := site_capacity_action(load_mw, capacity_mw)
    var viewport_size := get_viewport_rect().size
    var panel := Rect2(Vector2(18.0, viewport_size.y - V127_PANEL_SIZE.y - 18.0), V127_PANEL_SIZE)

    draw_rect(panel, Color(0.025, 0.045, 0.055, 0.92), true)
    draw_rect(panel, Color("32d17d"), false, 2.0)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 21.0), "MINING CAPACITY", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("dff7e8"))

    var status := String(plan["status"])
    var status_color := Color("63e69a")
    if status == "OVER CAPACITY" or status == "NO POWER":
        status_color = Color("ff6b5f")
    elif status == "EXPAND NOW" or status == "PLAN EXPANSION":
        status_color = Color("ffd166")

    draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 43.0), "%s  %.1f / %.1f MW" % [status, load_mw, capacity_mw], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, status_color)
    draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 63.0), String(plan["action"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("d5dde1"))

func debug_v127_ready() -> bool:
    var overloaded := site_capacity_action(12.0, 10.0)
    return V127_CAPACITY_FEEDBACK_REVISION == 1 \
        and String(overloaded["action"]) == "CURTAIL 2.0 MW" \
        and debug_v126_ready()
