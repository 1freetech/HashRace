extends SceneTree

const SCRIPTS: Array[String] = [
    "res://data/item_resource.gd",
    "res://data/item_library.gd",
    "res://components/building/placement_feedback.gd",
    "res://components/building/rack_slot.gd",
    "res://components/building/rack_container.gd",
    "res://components/state_machine/machine_state_controller.gd",
    "res://systems/physical_placement_grid.gd",
    "res://systems/simulation_manager.gd",
    "res://scripts/mining_ops_widget.gd",
    "res://scripts/negotiation_scene.gd",
    "res://systems/negotiation_manager.gd",
    "res://scripts/world_v068.gd",
    "res://scripts/world_v070.gd",
    "res://scripts/world_v072.gd",
    "res://scripts/world_v073.gd",
    "res://scripts/world_v080.gd",
    "res://scripts/world_v082.gd",
    "res://scripts/world_v085.gd",
    "res://scripts/world_v086.gd",
    "res://scripts/character_sprite_rig.gd",
    "res://scripts/world_v087.gd",
]

func _initialize() -> void:
    for path in SCRIPTS:
        print("MODULAR PARSE: ", path)
        var script: Script = load(path) as Script
        if script == null or not script.can_instantiate():
            push_error("MODULAR PARSE FAIL: " + path)
            quit(1)
            return
    print("MODULAR PARSE PASS")
    quit(0)
