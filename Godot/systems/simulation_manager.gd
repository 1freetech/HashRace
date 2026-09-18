class_name HashRaceSimulationManager
extends Node

## Fixed-tick real-time simulation/telemetry engine.
## The strategic turn system remains authoritative for campaign settlement, while
## this node owns live power/thermal/hashrate state used by world feedback/UI.

signal tick_processed(stats: Dictionary)
signal power_state_changed(state: StringName)

@export_range(0.1, 10.0, 0.1) var tick_rate: float = 1.0

var world: Node
var timer: Timer
var last_stats: Dictionary = {}
var _last_power_state: StringName = &""

func bind_world(world_node: Node) -> void:
    world = world_node
    if timer == null:
        _install_timer()
    process_tick()

func _ready() -> void:
    _install_timer()

func _install_timer() -> void:
    if timer != null:
        timer.wait_time = tick_rate
        return
    timer = Timer.new()
    timer.name = "SimulationTick"
    timer.wait_time = tick_rate
    timer.one_shot = false
    timer.autostart = true
    timer.timeout.connect(process_tick)
    add_child(timer)

func process_tick() -> void:
    if world == null or not is_instance_valid(world):
        return

    var raw_hashrate_th := _world_float("_hashrate_th")
    var load_mw := _world_float("_machine_load_kw") / 1000.0
    var available_mw := _world_float("_effective_available_mw")
    var temperature_c := _world_float("_facility_temperature_c", 25.0)
    var uptime := clampf(_world_float("_uptime", 1.0), 0.0, 1.0)

    var power_ratio := 1.0
    if load_mw > 0.0001:
        power_ratio = clampf(available_mw / load_mw, 0.0, 1.0)

    var thermal_factor := 1.0
    if temperature_c > 68.0:
        thermal_factor = clampf(1.0 - (temperature_c - 68.0) / 108.0, 0.72, 1.0)

    var effective_hashrate_th := raw_hashrate_th * power_ratio * thermal_factor
    var power_state: StringName = &"online"
    if load_mw > available_mw + 0.001:
        power_state = &"brownout"
    elif temperature_c >= 82.0:
        power_state = &"thermal"
    elif load_mw <= 0.001:
        power_state = &"idle"

    var player := _player_dict()
    var btc := float(player.get("sats", 0.0)) / 100000000.0
    var cash := float(player.get("cash", 0.0))
    var efficiency_jth := (load_mw * 1000000.0 / raw_hashrate_th) if raw_hashrate_th > 0.001 else 0.0

    last_stats = {
        "hashrate": raw_hashrate_th,
        "effective_hashrate": effective_hashrate_th,
        "power": maxf(0.0, available_mw),
        "load_mw": maxf(0.0, load_mw),
        "power_ratio": power_ratio,
        "efficiency": maxf(0.0, efficiency_jth),
        "uptime": uptime * 100.0,
        "temperature_c": temperature_c,
        "thermal_factor": thermal_factor,
        "btc": maxf(0.0, btc),
        "cash": cash,
        "power_state": String(power_state)
    }

    if power_state != _last_power_state:
        _last_power_state = power_state
        power_state_changed.emit(power_state)
    tick_processed.emit(last_stats.duplicate(true))

func snapshot() -> Dictionary:
    return last_stats.duplicate(true)

func _world_float(method_name: String, fallback := 0.0) -> float:
    if world != null and world.has_method(method_name):
        return float(world.call(method_name))
    return fallback

func _player_dict() -> Dictionary:
    if world == null:
        return {}
    var raw: Variant = world.get("player")
    return raw if raw is Dictionary else {}

func debug_ready() -> bool:
    return timer != null and tick_rate >= 0.1
