#pragma once

#include <cstddef>
#include <cstdint>
#include <random>
#include <string>
#include <string_view>
#include <unordered_set>
#include <vector>

namespace hashrace {

constexpr double kBlocksPerDay = 144.0;

// Ratings use the Hash Race universal 0-100 scale. Physical values such as
// dollars, MW, TH/s and J/TH keep their real-world units.
struct StrategySettings {
    int btc_hold = 50;
    int expansion = 50;
    int research = 50;
    int maintenance = 50;
    int risk = 50;
    int partnership = 50;
};

enum class CoolingType : std::uint8_t {
    Air = 0,
    Hydro = 1,
    Immersion = 2,
};

std::string_view cooling_name(CoolingType cooling);

struct MinerGeneration {
    int generation = 1;
    std::string model_name;
    double hashrate_th = 0.0;
    double efficiency_jth = 0.0;
    double purchase_price_usd = 0.0;
    double research_cost_usd = 0.0;
    bool supports_air = true;
    bool supports_hydro = false;
    bool supports_immersion = false;
};

struct CompanyProfile {
    std::string name;
    std::string archetype;
    std::string trait;
    std::string partnership_affinity;
    double starting_cash_usd = 0.0;
    int starting_fleet = 0;
    double efficiency_multiplier = 1.0;
    double power_cost_multiplier = 1.0;
    double research_multiplier = 1.0;
    double acquisition_cost_multiplier = 1.0;
    double uptime_bonus = 0.0;
    double starting_site_mw = 0.05;
    StrategySettings default_strategy{};
};

struct StrategicPartnership {
    std::string category;
    std::string partner_name;
    std::string benefit;
    double cost_usd = 0.0;
    double required_company_value_usd = 0.0;
    int required_generation = 1;
};

struct FleetItem {
    std::size_t generation_index = 0;
    CoolingType cooling = CoolingType::Air;
    int count = 0;
    int condition = 100;
    int utilization = 100;
};

class FleetInventory {
public:
    bool add(std::size_t generation_index, CoolingType cooling, int count,
             int condition = 100, int utilization = 100);
    bool remove(std::size_t generation_index, CoolingType cooling, int count);
    int count_all() const;
    int count_generation(std::size_t generation_index) const;
    int count_cooling(CoolingType cooling) const;
    double total_hashrate_th(const std::vector<MinerGeneration>& generations) const;
    double weighted_efficiency_jth(const std::vector<MinerGeneration>& generations,
                                   double efficiency_multiplier = 1.0) const;
    double power_kw(const std::vector<MinerGeneration>& generations,
                    double efficiency_multiplier = 1.0) const;
    double capital_value_usd(const std::vector<MinerGeneration>& generations) const;
    const std::vector<FleetItem>& items() const;

private:
    std::vector<FleetItem> items_;
};

struct MarketState {
    double bitcoin_price_usd = 1000.0;
    double network_hashrate_th = 50000.0;
    double block_subsidy_btc = 25.0;
    double electricity_price_per_kwh = 0.060;
};

struct DailyLedger {
    double mined_btc = 0.0;
    double sold_btc = 0.0;
    double held_btc = 0.0;
    double mining_revenue_usd = 0.0;
    double partner_revenue_usd = 0.0;
    double electricity_cost_usd = 0.0;
    double operations_cost_usd = 0.0;
    double net_cash_change_usd = 0.0;
};

struct RivalCompany {
    std::string name;
    double hashrate_th = 0.0;
    double cash_usd = 0.0;
    double efficiency_jth = 85.0;
    int generation = 1;
    int overall = 60;
    std::string partnership = "None";
    bool acquired = false;

    double value_usd() const;
};

struct CompanyState {
    std::size_t profile_index = 0;
    double cash_usd = 0.0;
    double btc_treasury = 0.0;
    double site_capacity_mw = 0.05;
    int site_expansion_level = 0;
    int unlocked_generation = 1;
    double research_progress_usd = 0.0;
    int acquisitions = 0;
    int franchise_overall = 60;
    int day = 0;
    int season = 1;
    bool game_over = false;
    StrategySettings strategy{};
    FleetInventory fleet{};
    std::unordered_set<std::string> active_partnerships{};
};

struct ActionResult {
    bool ok = false;
    std::string message;
};

double power_kw(double hashrate_th, double efficiency_jth);
double effective_electricity_price(double base_price_per_kwh, double discount_fraction);
double btc_per_day(double player_th, double network_th, double subsidy_btc,
                   double uptime = 1.0, double blocks_per_day = kBlocksPerDay);
double daily_power_cost(double hashrate_th, double efficiency_jth,
                        double electricity_price_per_kwh, double uptime = 1.0);
double daily_profit_usd(double player_th, double network_th, double subsidy_btc,
                        double btc_price_usd, double efficiency_jth,
                        double electricity_price_per_kwh, double uptime,
                        double operations_cost_usd);

std::vector<MinerGeneration> default_generations();
std::vector<CompanyProfile> default_companies();
std::vector<StrategicPartnership> default_partnerships();

class Simulation {
public:
    explicit Simulation(std::uint32_t seed = 21);

    ActionResult start_company(std::size_t profile_index);
    ActionResult buy_miner(std::size_t generation_index, CoolingType cooling, int count = 1);
    ActionResult fund_research(double requested_spend_usd);
    ActionResult sign_partnership(std::string_view category);
    ActionResult expand_site();
    ActionResult acquire_rival(std::size_t rival_index);
    ActionResult set_strategy(const StrategySettings& strategy);
    ActionResult advance_day(int days = 1);

    DailyLedger daily_ledger() const;
    double player_hashrate_th() const;
    double player_efficiency_jth() const;
    double player_power_kw() const;
    double effective_site_capacity_mw() const;
    double effective_uptime() const;
    double effective_power_price_per_kwh() const;
    double company_value_usd() const;
    int league_rank() const;

    const CompanyState& player() const;
    const MarketState& market() const;
    const std::vector<RivalCompany>& rivals() const;
    const std::vector<MinerGeneration>& generations() const;
    const std::vector<CompanyProfile>& companies() const;
    const std::vector<StrategicPartnership>& partnerships() const;
    const std::string& event_text() const;

private:
    bool started_ = false;
    CompanyState player_{};
    MarketState market_{};
    std::vector<MinerGeneration> generations_;
    std::vector<CompanyProfile> companies_;
    std::vector<StrategicPartnership> partnerships_;
    std::vector<RivalCompany> rivals_;
    std::string event_text_ = "Choose a Bitcoin mining company and enter the Hash Race.";
    mutable std::mt19937 rng_;

    const CompanyProfile& profile() const;
    bool partnership_active(std::string_view category) const;
    double generation_efficiency_jth(std::size_t generation_index) const;
    double research_target_usd(std::size_t generation_index) const;
    double daily_partner_revenue_usd() const;
    double daily_operations_cost_usd() const;
    double acquisition_price_usd(const RivalCompany& rival) const;
    bool cooling_supported(const MinerGeneration& generation, CoolingType cooling) const;
    void setup_rivals();
    void process_one_day();
    void move_market();
    void move_rivals();
    void apply_season_boundary();
    void apply_world_event();
};

}  // namespace hashrace
