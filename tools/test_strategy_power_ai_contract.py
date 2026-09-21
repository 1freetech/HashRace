#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
power=(ROOT/"Godot/systems/power_dispatch_model.gd").read_text()
ai=(ROOT/"Godot/systems/utility_strategy_ai.gd").read_text()
world=(ROOT/"Godot/scripts/world_v090.gd").read_text()
nav=(ROOT/"Godot/scripts/grid_navigation.gd").read_text()
battery=(ROOT/"Godot/data/items/battery.tres").read_text()
scene=(ROOT/"Godot/scenes/world.tscn").read_text()
modular=(ROOT/"Godot/scripts/validate_modular_scripts.gd").read_text()
version=(ROOT/"VERSION").read_text().strip()

assert version.startswith("v0."),version
assert int(version.split(".")[1]) >= 90,version
# world.tscn should point only at the current live layer. Historical v0.090
# retention belongs to the modular parser contract, not a scene comment.
assert "world_v131.gd" in scene
assert '"res://scripts/world_v090.gd"' in modular
assert 'extends "res://scripts/world_v089.gd"' in world

for marker in ["BATTERY_CAPACITY_MWH_PER_UNIT","BATTERY_POWER_MW_PER_UNIT","ROUND_TRIP_EFFICIENCY","simulate_period","source_energy_mwh","battery_charge_source_mwh","curtailed_mining_mwh","debug_contract_ready"]:
    assert marker in power,marker
for marker in ["FLEET EXPANSION","ASIC RESEARCH","POWER BUILDOUT","LAND BANK","CASH DEFENSE","intent","confidence","scores","debug_contract_ready"]:
    assert marker in ai,marker
for marker in ["V090_STRATEGY_REVISION","battery_reserve_pct","BatteryReservePolicy","_scaled_financial_preview","ending_battery_soc_mwh","_run_rival_month","next_intent","NEXT INTENT","debug_v090_ready"]:
    assert marker in world,marker
for marker in ["AStarGrid2D","DIAGONAL_MODE_NEVER","HEURISTIC_MANHATTAN","get_id_path","debug_native_astar_ready"]:
    assert marker in nav,marker

assert 'effect = "power_storage"' in battery
assert 'effect_unit = "MWh"' in battery

CAP=4.0
PWR=2.0
EFF=0.90**0.5

def dispatch(gen,mining,count,soc,reserve_pct,hours):
    capacity=count*CAP
    reserve=capacity*reserve_pct/100.0
    generated=gen*hours
    need=mining*hours
    direct=min(generated,need)
    generated-=direct
    short=need-direct
    deliverable=min(max(0.0,soc-reserve)*EFF,count*PWR*hours)
    batt=min(short,deliverable)
    soc-=batt/EFF if EFF else 0.0
    room=max(0.0,capacity-soc)
    charge=min(generated,count*PWR*hours,room/EFF if EFF else 0.0)
    soc+=charge*EFF
    return ((direct+batt)/need if need else 1.0),soc,direct+charge

assert dispatch(1,2,0,0,0,1)[0]==0.5
assert dispatch(1,2,1,4,0,1)[0]>0.99
assert dispatch(0,2,1,4,100,1)[0]==0.0
assert dispatch(0,2,1,4,0,24*30)[0]<0.01
_,soc,source=dispatch(3,1,1,0,0,1)
assert soc>0.0 and source>1.0

print("Hash Race v0.090 strategy/power/AI contract passed.")
