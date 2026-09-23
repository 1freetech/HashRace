extends "res://scripts/world_v154.gd"

# Hash Race v0.155: remove the mismatched center grass-tile carpet.
# The authored v0.126 grass sheet was drawn as a rectangular campus underlay on
# top of the world's native grass. In the live frame this reads as a pasted-on
# checkerboard rather than a blended terrain transition. Keep the single v0.128
# road layer and the deliberate four-object live site, but stop drawing that
# duplicate rectangular terrain patch.
const V155_TILEMAP_BLEND_REVISION := 1

func _v125_draw_terrain_underlay(_campus: Rect2) -> void:
    # Intentionally empty: the world already supplies continuous grass here.
    # Static infrastructure remains grounded by its own shadow/footprint and the
    # single city-road composition; no second grass tile carpet is necessary.
    pass

func debug_v155_ready() -> bool:
    return V155_TILEMAP_BLEND_REVISION == 1 \
        and V154_CENTER_DECLUTTER_REVISION == 1 \
        and bool(get_meta("hashrace_v128_single_road_stack", false)) \
        and debug_v154_ready()
