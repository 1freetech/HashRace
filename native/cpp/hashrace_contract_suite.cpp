#include <filesystem>
#include <fstream>
#include <iostream>
#include <regex>
#include <sstream>
#include <string>
#include <vector>
namespace fs=std::filesystem;
static int failures=0;
static std::string read(const fs::path&p){std::ifstream f(p,std::ios::binary);std::ostringstream s;s<<f.rdbuf();return s.str();}
static void need(bool ok,const std::string&m){if(!ok){std::cerr<<"FAIL: "<<m<<"\n";++failures;}}
static void has(const std::string&t,const std::string&x,const std::string&label){need(t.find(x)!=std::string::npos,label+" missing: "+x);}
int main(){
 const std::string version=read("VERSION"); need(std::regex_search(version,std::regex("^v0\\.[0-9]{3}")),"VERSION format");
 const int live=std::stoi(version.substr(3,3)); need(live>=129,"native contract suite requires v0.129+");
 const auto scene=read("Godot/scenes/world.tscn"); has(scene,"world_v"+std::to_string(live)+".gd","live scene");
 need(fs::exists("Godot/scripts/world_v"+std::to_string(live)+".gd"),"live world exists");
 const std::vector<int> layers={91,92,93,94,102,103,104,105,106,107,110,111,112,113,114,115,116,117,118,119,120,122,123,124,125,126,127,128,129};
 for(int n:layers){auto p=fs::path("Godot/scripts")/("world_v"+std::to_string(n)+".gd");need(fs::exists(p),"historical world_v"+std::to_string(n)+" exists");}
 const auto v129=read("Godot/scripts/world_v129.gd");
 for(auto x:{"extends \"res://scripts/world_v128.gd\"","capacity_decision_preview","capacity_decision_summary","site_capacity_action(active_load, active_capacity)","debug_v129_ready"}) has(v129,x,"v0.129");
 const auto v128=read("Godot/scripts/world_v128.gd");
 for(auto x:{"extends \"res://scripts/world_v127.gd\"","_v128_draw_city_road","_draw_mining_hq","debug_v128_ready"}) has(v128,x,"v0.128");
 const auto league=read("Godot/scripts/world_league_standings.gd");
 for(auto x:{"STANDINGS","_league_rows","_player_league_rank","debug_league_standings_ready"}) has(league,x,"league");
 const auto life=read("Godot/scripts/world_life_ops.gd");
 for(auto x:{"operator_energy","operator_focus","operator_social","_life_score","RECOVER","TRAIN","NETWORK","debug_life_ops_ready"}) has(life,x,"life ops");
 const auto burnout=read("Godot/scripts/world_burnout.gd");
 for(auto x:{"BURNOUT_START_RATING","_burnout_risk","TRAIN LOCKED","debug_burnout_ready"}) has(burnout,x,"burnout");
 const auto inventory=read("Godot/scripts/infrastructure_inventory.gd");
 for(auto x:{"var deployed: Dictionary = {}","func deploy(","func undeploy(","total_deployed_hashrate_ph","current_energy_output_mw","ItemLibrary.load_catalog"}) has(inventory,x,"deployment");
 const auto energy=read("Godot/scripts/world_v065.gd");
 for(auto x:{"_draw_energy_campus","_draw_solar_unit","_draw_wind_unit","_draw_smr_unit","_grid_stability_ratio","debug_energy_visuals_ready"}) has(energy,x,"energy");
 // Threaten was intentionally removed; protect both controller and scene without assuming a stale path.
 for(auto p:{"Godot/scripts/negotiation.gd","Godot/scripts/negotiation_controller.gd","Godot/scenes/negotiation.tscn"}){
   if(fs::exists(p)){auto t=read(p);need(t.find("THREATEN")==std::string::npos&&t.find("ThreatenButton")==std::string::npos&&t.find("_threaten")==std::string::npos,std::string("threaten remains removed: ")+p);}
 }
 size_t item_count=0; for(auto&e:fs::directory_iterator("Godot/data/items")) if(e.path().extension()==".tres") ++item_count;
 need(item_count>=34,"34+ ItemResource files");
 for(auto id:{"battery","solar_array","wind_farm","gas_turbine","hydro_turbine","oil_field","coal_plant","nuclear_smr","methane_generator","diesel_generator","geothermal_generator","lpg_generator","hydrogen_fuel_cell"}){
   auto p=fs::path("Godot/data/items")/(std::string(id)+".tres"); need(fs::exists(p),"energy resource "+std::string(id)); if(fs::exists(p))has(read(p),"id = \""+std::string(id)+"\"","energy resource");
 }
 for(auto p:{"Godot/art/buildings/c01_mining_container.svg","Godot/art/characters/default_player_sheet.png","Godot/art/energy/wind_turbine_directional_sheet.png","Godot/art/machines/asic_air_s19j_directional.png","Godot/art/props/utility_props_sheet.png","Godot/art/terrain/dirt_road_tilesheet.png","Godot/art/terrain/grass_terrain_tilesheet.png","Godot/art/terrain/industrial_road_tilesheet.png","Godot/assets/imported/v115/semiconductor_fab.jpg"}) need(fs::exists(p)&&fs::file_size(p)>0,std::string("asset ")+p);
 const auto validator=read("Godot/scripts/validate_modular_scripts.gd"); has(validator,"world_v129.gd","validator");
 for(auto&e:fs::directory_iterator("tools")) if(e.is_regular_file()&&e.path().extension()==".py") need(false,"Python contract remains: "+e.path().string());
 if(failures){std::cerr<<failures<<" native contract failure(s)\n";return 1;}
 std::cout<<"Hash Race native C++ contract suite PASS: gameplay, historical layers, energy, assets, and v0.129 are intact.\n"; return 0;
}
