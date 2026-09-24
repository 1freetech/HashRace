extends "res://scripts/world_customization.gd"

# Final v0.052 composition layer. The legacy navigation self-test used a fixed
# destination that is now occupied by the relocated land office. Test a short
# real walk from the live player spawn instead so the check follows the map.

func debug_grid_path_exists() -> bool:
    if grid_nav == null:
        return false
    var destination: Vector2 = rep_pos + Vector2(240.0, 0.0)
    destination.x = clampf(destination.x, 96.0, WORLD_SIZE.x - 96.0)
    var test_path: Array[Vector2] = grid_nav.find_path(rep_pos, destination)
    return not test_path.is_empty()
