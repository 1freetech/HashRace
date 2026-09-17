extends "res://scripts/world_character_detail.gd"

# Hash Race v0.053 composition layer.
# Keeps the v0.052 collision-safe navigation check while adding the shared
# high-detail procedural player/NPC character renderer.

func debug_grid_path_exists() -> bool:
    if grid_nav == null:
        return false
    var destination: Vector2 = rep_pos + Vector2(240.0, 0.0)
    destination.x = clampf(destination.x, 96.0, WORLD_SIZE.x - 96.0)
    var test_path: Array[Vector2] = grid_nav.find_path(rep_pos, destination)
    return not test_path.is_empty()
