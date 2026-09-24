extends "res://scripts/world_v068.gd" # release inheritance

# Hash Race v0.070 release layer.
# Preserves the v0.069 maintenance fixes while making the modular architecture
# pass the live world entry point.

const V070_RELEASE_REVISION: int = 1

func debug_v070_ready() -> bool:
    return V070_RELEASE_REVISION == 1 and debug_modular_architecture_ready() and debug_hud_consolidated()
