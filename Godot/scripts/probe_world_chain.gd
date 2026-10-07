extends SceneTree

const LAYERS := [
    "res://scripts/world_v159.gd",
    "res://scripts/world_v160.gd",
    "res://scripts/world_v161.gd",
    "res://scripts/world_v162.gd",
    "res://scripts/world_v163.gd",
    "res://scripts/world_v164.gd",
    "res://scripts/world_v165.gd",
]

func _initialize() -> void:
    for path in LAYERS:
        print("WORLD CHAIN PROBE: loading " + path)
        var script = load(path)
        if script == null:
            push_error("WORLD CHAIN PROBE FAIL: " + path)
            quit(1)
            return
        print("WORLD CHAIN PROBE PASS: " + path)
    quit(0)
