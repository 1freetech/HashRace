#include <cassert>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

namespace fs = std::filesystem;
static std::string read(const fs::path& p){ std::ifstream f(p); assert(f && "required contract file missing"); std::ostringstream s; s<<f.rdbuf(); return s.str(); }
static void has(const std::string& s,const std::string& marker){ assert(s.find(marker)!=std::string::npos); }
int main(){
  const fs::path root = fs::current_path();
  const auto power=read(root/"Godot/systems/power_dispatch_model.gd");
  const auto ai=read(root/"Godot/systems/utility_strategy_ai.gd");
  const auto v090=read(root/"Godot/scripts/world_v090.gd");
  const auto nav=read(root/"Godot/scripts/grid_navigation.gd");
  const auto battery=read(root/"Godot/data/items/battery.tres");
  const auto scene=read(root/"Godot/scenes/world.tscn");
  for(const char* m:{"BATTERY_CAPACITY_MWH_PER_UNIT","BATTERY_POWER_MW_PER_UNIT","ROUND_TRIP_EFFICIENCY","simulate_period","source_energy_mwh","battery_charge_source_mwh","curtailed_mining_mwh","debug_contract_ready"}) has(power,m);
  for(const char* m:{"FLEET EXPANSION","ASIC RESEARCH","POWER BUILDOUT","LAND BANK","CASH DEFENSE","intent","confidence","scores","debug_contract_ready"}) has(ai,m);
  for(const char* m:{"V090_STRATEGY_REVISION","battery_reserve_pct","BatteryReservePolicy","_scaled_financial_preview","ending_battery_soc_mwh","_run_rival_month","next_intent","NEXT INTENT","debug_v090_ready"}) has(v090,m);
  for(const char* m:{"AStarGrid2D","DIAGONAL_MODE_NEVER","HEURISTIC_MANHATTAN","get_id_path","debug_native_astar_ready"}) has(nav,m);
  has(battery,"effect = \"power_storage\""); has(battery,"effect_unit = \"MWh\""); has(v090,"extends \"res://scripts/world_v089.gd\"");
  const auto key=std::string("path=\"res://scripts/world_v"); const auto p=scene.find(key); assert(p!=std::string::npos); const auto start=p+6; const auto end=scene.find('"',start); const auto live_path=scene.substr(start,end-start); const auto live=read(root/"Godot"/live_path.substr(6));
  has(live,"extends \"res://scripts/world_v");
  std::cout<<"Hash Race native C++ v0.090 strategy/power/AI contract passed through "<<live_path<<".\n";
}
