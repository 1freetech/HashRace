extends "res://scripts/world_v067.gd"

# Hash Race v0.068 modular architecture pass.
# - native ItemResource catalog
# - fixed-tick SimulationManager
# - physical rack/slot deployment layer
# - one consolidated upper-right Mining Ops HUD

const SimulationManager = preload("res://systems/simulation_manager.gd")
const PhysicalPlacementGrid = preload("res://systems/physical_placement_grid.gd")
const RackContainer = preload("res://components/building/rack_container.gd")
const MachineStateController = preload("res://components/state_machine/machine_state_controller.gd")

const MODULAR_ARCHITECTURE_REVISION: int = 1
const MAX_VISIBLE_PHYSICAL_RACKS: int = 12

var simulation_manager = null
var physical_placement_grid = null
var machine_state_controller = null
var physical_racks: Array[Node2D] = []
var latest_simulation_snapshot: Dictionary = {}

func _ready() -> void:
    super._ready()
    _install_modular_architecture()
    _consolidate_persistent_hud()
    set_meta("hashrace_modular_architecture_revision", MODULAR_ARCHITECTURE_REVISION)

func _install_modular_architecture() -> void:
    simulation_manager = SimulationManager.new()
    simulation_manager.name = "SimulationManager"
    simulation_manager.tick_rate = 1.0
    add_child(simulation_manager)
    simulation_manager.tick_processed.connect(_on_simulation_tick)
    simulation_manager.bind_world(self)

    physical_placement_grid = PhysicalPlacementGrid.new()
    physical_placement_grid.name = "PhysicalPlacementGrid"
    physical_placement_grid.grid_size = Vector2i(48, 48)
    physical_placement_grid.maximum_place_distance = 99999.0
    add_child(physical_placement_grid)

    machine_state_controller = MachineStateController.new()
    machine_state_controller.name = "MachineStateController"
    add_child(machine_state_controller)

    if not infrastructure_inventory.deployment_changed.is_connected(_sync_physical_racks):
        infrastructure_inventory.deployment_changed.connect(_sync_physical_racks)

    _sync_physical_racks()
    simulation_manager.process_tick()

func _on_simulation_tick(stats: Dictionary) -> void:
    latest_simulation_snapshot = stats.duplicate(true)
    if is_instance_valid(mining_ops_widget):
        mining_ops_widget.call("apply_simulation_snapshot", latest_simulation_snapshot)

    if is_instance_valid(machine_state_controller):
        machine_state_controller.update_from_operating_values(
            float(stats.get("load_mw", 0.0)),
            float(stats.get("power", 0.0)),
            float(stats.get("temperature_c", 25.0)),
            float(stats.get("uptime", 0.0)) / 100.0
        )
        var status_color := machine_state_controller.status_color()
        for rack in physical_racks:
            if is_instance_valid(rack):
                rack.modulate = Color.WHITE.lerp(status_color, 0.22)

func _sync_physical_racks() -> void:
    if not is_instance_valid(physical_placement_grid):
        return

    physical_placement_grid.clear_all()
    physical_racks.clear()

    var hq := _player_hq_center()
    var base := hq + Vector2(-264.0, 228.0)
    base.x = clampf(base.x, 150.0, WORLD_SIZE.x - 350.0)
    base.y = clampf(base.y, 150.0, WORLD_SIZE.y - 250.0)

    var visible_count := 0
    for raw in infrastructure_inventory.catalog_resources():
        var item = raw
        if item == null or String(item.get("category")) != "MINERS":
            continue
        var deployed_count := infrastructure_inventory.deployed_quantity(String(item.get("id")))
        for _instance in range(deployed_count):
            if visible_count >= MAX_VISIBLE_PHYSICAL_RACKS:
                return
            var rack := RackContainer.new()
            rack.name = "PhysicalRack_%02d_%s" % [visible_count, String(item.get("id"))]
            rack.slot_count = 1
            rack.default_slot_type = String(item.get("slot_type"))
            rack.auto_build_slots = false

            var col := visible_count % 4
            var row := int(visible_count / 4)
            var target := base + Vector2(float(col) * 58.0, float(row) * 76.0)
            if not physical_placement_grid.place(rack, target, target):
                rack.queue_free()
                continue

            rack.rebuild_slots()
            rack.install(item)
            rack.set_meta("hashrace_item_id", String(item.get("id")))
            physical_racks.append(rack)
            visible_count += 1

func _consolidate_persistent_hud() -> void:
    if is_instance_valid(top_stats):
        top_stats.visible = false
    if is_instance_valid(energy_status_label):
        energy_status_label.visible = false
    if is_instance_valid(mining_ops_widget):
        mining_ops_widget.call("mount_top_right")
    _refresh_compact_status()

func _refresh_compact_status() -> void:
    if not is_instance_valid(drawer_status):
        return
    drawer_status.text = "Live company metrics are consolidated in the upper-right Mining Ops panel."
    _refresh_menu_button_text()

func _refresh_ui() -> void:
    super._refresh_ui()
    if is_instance_valid(top_stats):
        top_stats.visible = false
    if is_instance_valid(energy_status_label):
        energy_status_label.visible = false
    if is_instance_valid(simulation_manager):
        simulation_manager.process_tick()

func debug_simulation_snapshot() -> Dictionary:
    if not latest_simulation_snapshot.is_empty():
        return latest_simulation_snapshot.duplicate(true)
    if is_instance_valid(simulation_manager):
        return simulation_manager.snapshot()
    return {}

func debug_modular_architecture_ready() -> bool:
    return (
        MODULAR_ARCHITECTURE_REVISION == 1
        and infrastructure_inventory.debug_resource_catalog_ready()
        and is_instance_valid(simulation_manager)
        and simulation_manager.debug_ready()
        and is_instance_valid(physical_placement_grid)
        and physical_placement_grid.debug_ready()
        and is_instance_valid(machine_state_controller)
    )

func debug_physical_rack_count() -> int:
    return physical_racks.size()

func debug_hud_consolidated() -> bool:
    if not is_instance_valid(mining_ops_widget):
        return false
    var top_hidden := not is_instance_valid(top_stats) or not top_stats.visible
    var energy_hidden := not is_instance_valid(energy_status_label) or not energy_status_label.visible
    return top_hidden and energy_hidden and int(mining_ops_widget.get("mount_slot")) == 1
