extends Node2D
const Scale = preload("res://scripts/world_scale_rules.gd")
func _draw() -> void:
    var world := get_parent()
    if world == null:
        return
    var value: Variant = world.get("entities")
    if not value is Array:
        return
    for entity in value:
        var kind := String(entity.get("kind", ""))
        if not Scale.is_building_kind(kind):
            continue
        var rect := Scale.visual_rect(kind, Vector2(entity.get("pos", Vector2.ZERO)))
        var label := "CAMPUS"
        match kind:
            "hq": label = "COMMAND"
            "machines": label = "ASIC MARKET"
            "power": label = "POWER GRID"
            "bank": label = "FINANCE"
            "land": label = "LAND OFFICE"
            "partner": label = "PARTNER"
            "rival": label = "RIVAL MINER"
        var crown := Rect2(rect.position + Vector2(8.0, -6.0), Vector2(rect.size.x - 16.0, 8.0))
        draw_rect(crown, Color("719a82"), true)
        var sign := Rect2(Vector2(rect.get_center().x - 60.0, rect.position.y + 30.0), Vector2(120.0, 20.0))
        draw_rect(sign, Color("101b21"), true)
        draw_rect(sign, Color("71d5a0"), false, 2.0)
        draw_string(ThemeDB.fallback_font, sign.position + Vector2(0.0, 14.0), label, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 11, Color("71d5a0"))
        if kind == "machines" or kind == "power":
            for i in range(3):
                var x := rect.position.x + 23.0 + float(i) * 31.0
                var vent := Rect2(Vector2(x, rect.position.y + 86.0), Vector2(23.0, 24.0))
                draw_rect(vent, Color("182b31"), true)
                draw_circle(vent.get_center(), 6.0, Color("68898a"))
        if kind == "hq":
            var mast := Vector2(rect.end.x - 34.0, rect.position.y - 6.0)
            draw_line(mast, mast + Vector2(0.0, -24.0), Color("71d5a0"), 3.0)
        var nav = world.get("grid_nav")
        for side in [-1, 1]:
            var x := rect.position.x - 28.0 if side < 0 else rect.end.x + 28.0
            var p := Vector2(x, rect.end.y - 21.0)
            if nav != null and not bool(nav.call("world_is_walkable", p)):
                continue
            draw_circle(p, 9.0, Color("345d40"))
            draw_circle(p + Vector2(-2.0, -2.0), 5.0, Color("6a9c5e"))
