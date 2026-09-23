extends "res://scripts/world_v153.gd"

# Hash Race v0.154: central-campus declutter.
# The legacy v0.065 energy yard draws a second electrical pad at the same
# campus origin later reused by the deliberate four-object v0.115 live site.
# Suppress that inherited duplicate yard so the center keeps one coherent
# terrain/road composition and one grounded infrastructure cluster.
const V154_CENTER_DECLUTTER_REVISION := 1

func _draw_energy_campus(_origin: Vector2) -> void:
    # Intentionally empty. v0.115 remains the authoritative live-site renderer:
    # container, one energy source, transformer, and command/control only.
    pass

func debug_v154_ready() -> bool:
    return V154_CENTER_DECLUTTER_REVISION == 1 and debug_v153_ready()
