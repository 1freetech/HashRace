extends "res://scripts/world_v161.gd"

# v0.162 runtime TileMap cleanup.
# The v0.161 gameplay proof still showed a detached dark rectangular pad in the
# grass around the live infrastructure.  The authored static sprites already
# carry their own ground contact/shadow treatment, so inherited generic pads
# make the map look tiled and can survive visually when a sprite is small.
const V162_TILEMAP_CLEANUP_REVISION := 1

func _ready() -> void:
    super._ready()
    set_meta("hashrace_v162_detached_live_site_foundations_removed", true)
    queue_redraw()

# Suppress only the generic v0.157 live-site backing rectangles.  Do not alter
# building foundations, roads, terrain, simulation placement, collision, or the
# individual valid-binary infrastructure sprites.
func _v157_draw_foundation(_center: Vector2, _size_value: Vector2) -> void:
    pass

func debug_v162_ready() -> bool:
    return V162_TILEMAP_CLEANUP_REVISION == 1 \
        and bool(get_meta("hashrace_v162_detached_live_site_foundations_removed", false)) \
        and debug_v161_solar_ready()
