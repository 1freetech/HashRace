extends "res://scripts/world_v090.gd"

# Hash Race v0.091 live character-creator release entry point.
# Character creation is handled before this scene loads; this versioned world
# keeps VERSION, the live scene, and version-forward validation aligned.

func debug_live_character_creator_ready() -> bool:
	return true
