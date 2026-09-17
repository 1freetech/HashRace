#include "hashrace_simulation.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <numeric>
#include <sstream>

namespace hashrace {
namespace {

int clamp_rating(int value) {
    return std::clamp(value, 0, 100);
}

double cooling_efficiency_multiplier(CoolingType cooling) {
    switch (cooling) {
        case CoolingType::Air:
            return 1.00;
        case CoolingType::Hydro:
            return 0.97;
        case CoolingType::Immersion:
            return 0.94;
    }
    return 1.00;
}

double item_availability(const FleetItem& item) {
    const double condition = std::clamp(item.condition, 0, 100) / 100.0;
    const double utilization = std::clamp(item.utilization, 0, 100) / 100.0;
    return (0.75 + condition * 0.25) * utilization;
}

double item_efficiency_penalty(const FleetItem& item) {
    const double missing_condition = 1.0 - std::clamp(item.condition, 0, 100) / 100.0;
    return 1.0 + missing_condition * 0.12;
}

std::string dollars(double value) {
    std::ostringstream out;
    out.setf(std::ios::fixed);
    out.precision(0);
    out << '$' << value;
    return out.str();
}

}  // namespace

std::string_view cooling_name(CoolingType cooling) {
    switch (cooling) {
        case CoolingType::Air:
            return "Air";
        case CoolingType::Hydro:
            return "Hydro";
        case CoolingType::Immersion:
            return "Immersion";
    }
    return "Unknown";
}

bool FleetInventory::add(std::size_t generation_index, CoolingType cooling, int count,
                         int condition, int utilization) {
    if (count <= 0) {
        return false;
    }
    condition = clamp_rating(condition);
    utilization = clamp_rating(utilization);

    for (auto& item : items_) {
        if (item.generation_index == generation_index && item.cooling == cooling &&
            item.condition == condition && item.utilization == utilization) {
            if (item.count > std::numeric_limits<int>::max() - count) {
                return false;
            }
            item.count += count;
            return true;
        }
    }

    items_.push_back({generation_index, cooling, count, condition, utilization});
    return true;
}

bool FleetInventory::remove(std::size_t generation_index, CoolingType cooling, int count) {
    if (count <= 0) {
        return false;
    }

    int available = 0;
    for (const auto& item : items_) {
        if (item.generation_index == generation_index && item.cooling == cooling) {
            available += item.count;
        }
    }
    if (available < count) {
        return false;
    }

    int remaining = count;
    for (auto& item : items_) {
        if (remaining == 0) {
            break;
        }
        if (item.generation_index != generation_index || item.cooling != cooling) {
            continue;
        }
        const int take = std::min(item.count, remaining);
        item.count -= take;
        remaining -= take;
    }

    std::erase_if(items_, [](const FleetItem& item) { return item.count <= 0; });
    return true;
}

int FleetInventory::count_all() const {
    return std::accumulate(items_.begin(), items_.end(), 0,
                           [](int total, const FleetItem& item) { return total + item.count; });
}

int FleetInventory::count_generation(std::size_t generation_index) const {
    int count = 0;
    for (const auto& item : items_) {
        if (item.generation_index == generation_index) {
            count += item.count;
        }
    }
    return count;
}

int FleetInventory::count_cooling(CoolingType cooling) const {
    int count = 0;
    for (const auto& item : items_) {
        if (item.cooling == cooling) {
            count += item.count;
        }
    }
    return count;
}

double FleetInventory::total_hashrate_th(const std::vector<MinerGeneration>& generations) const {
    double total = 0.0;
    for (const auto& item : items_) {
        if (item.generation_index >= generations.size() || item.count <= 0) {
            continue;
        }
        const auto& generation = generations[item.generation_index];
        total += generation.hashrate_th * static_cast<double>(item.count) * item_availability(item);
    }
    return total;
}

double FleetInventory::weighted_efficiency_jth(
    const std::vector<MinerGeneration>& generations, double efficiency_multiplier) const {
    double weighted_joules = 0.0;
    double weighted_hashrate = 0.0;

    for (const auto& item : items_) {
        if (item.generation_index >= generations.size() || item.count <= 0) {
            continue;
        }
        const auto& generation = generations[item.generation_index];
        const double hashrate = generation.hashrate_th * static_cast<double>(item.count) *
                                item_availability(item);
        const double efficiency = generation.efficiency_jth * efficiency_multiplier *
                                  cooling_efficiency_multiplier(item.cooling) *
                                  item_efficiency_penalty(item);
        weighted_joules += hashrate * efficiency;
        weighted_hashrate += hashrate;
    }

    if (weighted_hashrate <= 0.0) {
        return 0.0;
    }
    return weighted_joules / weighted_hashrate;
}

double FleetInventory::power_kw(const std::vector<MinerGeneration>& generations,
                                double efficiency_multiplier) const {
    double total = 0.0;
    for (const auto& item : items_) {
        if (item.generation_index >= generations.size() || item.count <= 0) {
            continue;
        }
        const auto& generation = generations[item.generation_index];
        const double hashrate = generation.hashrate_th * static_cast<double>(item.count) *
                                item_availability(item);
        const double efficiency = generation.efficiency_jth * efficiency_multiplier *
                                  cooling_efficiency_multiplier(item.cooling) *
                                  item_efficiency_penalty(item);
        total += hashrate * efficiency / 1000.0;
    }
    return total;
}

double FleetInventory::capital_value_usd(
    const std::vector<MinerGeneration>& generations) const {
    double total = 0.0;
    for (const auto& item : items_) {
        if (item.generation_index >= generations.size() || item.count <= 0) {
            continue;
        }
        const double condition_fraction = std::clamp(item.condition, 0, 100) / 100.0;
        const double resale_fraction = 0.35 + condition_fraction * 0.65;
        total += generations[item.generation_index].purchase_price_usd *
                 static_cast<double>(item.count) * resale_fraction;
    }
    return total;
}

const std::vector<FleetItem>& FleetInventory::items() const {
    return items_;
}

double RivalCompany::value_usd() const {
    const double technology_premium = std::max(2.0, 125.0 / std::max(0.5, efficiency_jth));
    const double partnership_premium = partnership == "None" ? 1.0 : 1.12;
    return std::max(0.0, cash_usd) + hashrate_th * technology_premium * partnership_premium;
}

double power_kw(double hashrate_th, double efficiency_jth) {
    return std::max(0.0, hashrate_th) * std::max(0.0, efficiency_jth) / 1000.0;
}

double effective_electricity_price(double base_price_per_kwh, double discount_fraction) {
    const double discount = std::clamp(discount_fraction, 0.0, 0.60);
    return std::max(0.012, base_price_per_kwh * (1.0 - discount));
}

double btc_per_day(double player_th, double network_th, double subsidy_btc,
                   double uptime, double blocks_per_day) {
    if (network_th <= 0.0 || subsidy_btc <= 0.0 || blocks_per_day <= 0.0) {
        return 0.0;
    }
    const double safe_uptime = std::clamp(uptime, 0.0, 1.0);
    return (std::max(0.0, player_th) / network_th) * blocks_per_day * subsidy_btc * safe_uptime;
}

double daily_power_cost(double hashrate_th, double efficiency_jth,
                        double electricity_price_per_kwh, double uptime) {
    const double safe_uptime = std::clamp(uptime, 0.0, 1.0);
    return power_kw(hashrate_th, efficiency_jth) * 24.0 *
           std::max(0.0, electricity_price_per_kwh) * safe_uptime;
}

double daily_profit_usd(double player_th, double network_th, double subsidy_btc,
                        double btc_price_usd, double efficiency_jth,
                        double electricity_price_per_kwh, double uptime,
                        double operations_cost_usd) {
    const double revenue = btc_per_day(player_th, network_th, subsidy_btc, uptime) *
                           std::max(0.0, btc_price_usd);
    const double power = daily_power_cost(player_th, efficiency_jth,
                                          electricity_price_per_kwh, uptime);
    return revenue - power - std::max(0.0, operations_cost_usd);
}

Simulation::Simulation(std::uint32_t seed)
    : generations_(default_generations()),
      companies_(default_companies()),
      partnerships_(default_partnerships()),
      rng_(seed) {}

ActionResult Simulation::start_company(std::size_t profile_index) {
    if (profile_index >= companies_.size()) {
        return {false, "Company index is outside the playable league."};
    }

    player_ = CompanyState{};
    player_.profile_index = profile_index;
    player_.cash_usd = companies_[profile_index].starting_cash_usd;
    player_.site_capacity_mw = companies_[profile_index].starting_site_mw;
    player_.strategy = companies_[profile_index].default_strategy;
    player_.unlocked_generation = 1;
    player_.fleet.add(0, CoolingType::Air, companies_[profile_index].starting_fleet);
    market_ = MarketState{};
    started_ = true;
    setup_rivals();
    event_text_ = companies_[profile_index].name +
                  " entered the Hash Race as a Bitcoin mining company.";
    return {true, event_text_};
}

bool Simulation::cooling_supported(const MinerGeneration& generation, CoolingType cooling) const {
    switch (cooling) {
        case CoolingType::Air:
            return generation.supports_air;
        case CoolingType::Hydro:
            return generation.supports_hydro;
        case CoolingType::Immersion:
            return generation.supports_immersion;
    }
    return false;
}

ActionResult Simulation::buy_miner(std::size_t generation_index, CoolingType cooling, int count) {
    if (!started_) {
        return {false, "Choose a company before buying machines."};
    }
    if (count <= 0 || generation_index >= generations_.size()) {
        return {false, "Invalid machine order."};
    }
    if (generation_index + 1 > static_cast<std::size_t>(player_.unlocked_generation)) {
        return {false, "That machine generation is not unlocked yet."};
    }

    const auto& generation = generations_[generation_index];
    if (!cooling_supported(generation, cooling)) {
        return {false, generation.model_name + " does not support " +
                           std::string(cooling_name(cooling)) + " cooling."};
    }

    const double cost = generation.purchase_price_usd * static_cast<double>(count);
    if (player_.cash_usd < cost) {
        return {false, "Not enough cash for that machine order."};
    }

    double machine_efficiency = generation_efficiency_jth(generation_index) *
                                cooling_efficiency_multiplier(cooling);
    const double added_power_mw = power_kw(generation.hashrate_th * count, machine_efficiency) / 1000.0;
    if (player_power_kw() / 1000.0 + added_power_mw > effective_site_capacity_mw() + 1e-12) {
        return {false, "Site power capacity is full. Expand before installing more machines."};
    }

    player_.cash_usd -= cost;
    player_.fleet.add(generation_index, cooling, count);
    event_text_ = "Installed " + std::to_string(count) + " x " + generation.model_name +
                  " using " + std::string(cooling_name(cooling)) + " cooling.";
    return {true, event_text_};
}

ActionResult Simulation::fund_research(double requested_spend_usd) {
    if (!started_) {
        return {false, "Choose a company before funding research."};
    }
    if (player_.unlocked_generation >= static_cast<int>(generations_.size())) {
        return {false, "All current machine generations are unlocked."};
    }
    if (requested_spend_usd <= 0.0 || player_.cash_usd <= 0.0) {
        return {false, "Research spend must be greater than zero."};
    }

    const std::size_t target_index = static_cast<std::size_t>(player_.unlocked_generation);
    const double target = research_target_usd(target_index);
    const double remaining = std::max(0.0, target - player_.research_progress_usd);
    const double spend = std::min({requested_spend_usd, player_.cash_usd, remaining});
    if (spend <= 0.0) {
        return {false, "No research spend was available."};
    }

    player_.cash_usd -= spend;
    player_.research_progress_usd += spend;

    if (player_.research_progress_usd + 1e-9 >= target) {
        ++player_.unlocked_generation;
        player_.research_progress_usd = 0.0;
        player_.franchise_overall = std::min(100, player_.franchise_overall + 2);
        const auto& unlocked = generations_[target_index];
        event_text_ = "HARDWARE EVOLUTION: unlocked " + unlocked.model_name + ".";
        return {true, event_text_};
    }

    event_text_ = "Invested " + dollars(spend) + " in machine R&D.";
    return {true, event_text_};
}

ActionResult Simulation::sign_partnership(std::string_view category) {
    if (!started_) {
        return {false, "Choose a company before signing partnerships."};
    }
    const auto it = std::find_if(partnerships_.begin(), partnerships_.end(),
                                 [category](const StrategicPartnership& p) {
                                     return p.category == category;
                                 });
    if (it == partnerships_.end()) {
        return {false, "Unknown partnership category."};
    }
    if (partnership_active(category)) {
        return {false, std::string(category) + " partnership is already active."};
    }
    if (player_.unlocked_generation < it->required_generation) {
        return {false, "Machine generation requirement has not been reached."};
    }
    if (company_value_usd() < it->required_company_value_usd) {
        return {false, "Company value requirement has not been reached."};
    }
    if (player_.cash_usd < it->cost_usd) {
        return {false, "Not enough cash for that partnership."};
    }

    player_.cash_usd -= it->cost_usd;
    player_.active_partnerships.insert(it->category);
    if (it->category == "Sports") {
        player_.franchise_overall = std::min(100, player_.franchise_overall + 5);
    }
    event_text_ = "Signed " + it->partner_name + ": " + it->benefit;
    return {true, event_text_};
}

ActionResult Simulation::expand_site() {
    if (!started_) {
        return {false, "Choose a company before expanding a site."};
    }

    double cost = 15000.0 * std::pow(1.60, static_cast<double>(player_.site_expansion_level));
    if (partnership_active("Real Estate")) {
        cost *= 0.65;
    }
    if (partnership_active("Infrastructure")) {
        cost *= 0.75;
    }

    const double expansion_bias = 1.05 - static_cast<double>(player_.strategy.expansion) / 1000.0;
    cost *= expansion_bias;
    if (player_.cash_usd < cost) {
        return {false, "Not enough cash to expand the mining site."};
    }

    const double base_increment = std::max(0.05, profile().starting_site_mw * 0.75);
    const double scale = 1.0 + static_cast<double>(player_.site_expansion_level) * 0.15;
    player_.cash_usd -= cost;
    player_.site_capacity_mw += base_increment * scale;
    ++player_.site_expansion_level;
    event_text_ = "Expanded site capacity to " + std::to_string(player_.site_capacity_mw) + " MW.";
    return {true, event_text_};
}

ActionResult Simulation::acquire_rival(std::size_t rival_index) {
    if (!started_) {
        return {false, "Choose a company before making acquisitions."};
    }
    if (rival_index >= rivals_.size()) {
        return {false, "Rival index is outside the league."};
    }
    auto& rival = rivals_[rival_index];
    if (rival.acquired) {
        return {false, "That rival has already been acquired."};
    }

    const double price = acquisition_price_usd(rival);
    if (player_.cash_usd < price) {
        return {false, "Not enough cash for that acquisition."};
    }

    const std::size_t generation_index = static_cast<std::size_t>(
        std::clamp(rival.generation - 1, 0, static_cast<int>(generations_.size()) - 1));
    const auto& generation = generations_[generation_index];
    const int inherited_machines = std::max(
        1, static_cast<int>(std::lround(rival.hashrate_th / std::max(0.001, generation.hashrate_th))));
    CoolingType cooling = CoolingType::Air;
    if (!generation.supports_air && generation.supports_hydro) {
        cooling = CoolingType::Hydro;
    } else if (!generation.supports_air && !generation.supports_hydro) {
        cooling = CoolingType::Immersion;
    }

    const double inherited_power_mw = power_kw(rival.hashrate_th, rival.efficiency_jth) / 1000.0;
    player_.cash_usd -= price;
    player_.cash_usd += std::max(0.0, rival.cash_usd) * 0.20;
    player_.site_capacity_mw += inherited_power_mw * 1.15;
    player_.fleet.add(generation_index, cooling, inherited_machines, 84, 92);
    player_.unlocked_generation = std::max(player_.unlocked_generation, rival.generation);
    ++player_.acquisitions;
    player_.franchise_overall = std::min(100, player_.franchise_overall + 2);
    rival.acquired = true;
    event_text_ = "Acquired " + rival.name + " for " + dollars(price) +
                  " and inherited its mining fleet.";
    return {true, event_text_};
}

ActionResult Simulation::set_strategy(const StrategySettings& strategy) {
    if (!started_) {
        return {false, "Choose a company before changing strategy."};
    }
    player_.strategy = {
        clamp_rating(strategy.btc_hold),
        clamp_rating(strategy.expansion),
        clamp_rating(strategy.research),
        clamp_rating(strategy.maintenance),
        clamp_rating(strategy.risk),
        clamp_rating(strategy.partnership),
    };
    event_text_ = "Updated company strategy on the universal 0-100 scale.";
    return {true, event_text_};
}

ActionResult Simulation::advance_day(int days) {
    if (!started_) {
        return {false, "Choose a company before advancing time."};
    }
    if (days <= 0) {
        return {false, "Days to advance must be greater than zero."};
    }
    for (int i = 0; i < days && !player_.game_over; ++i) {
        process_one_day();
    }
    return {true, event_text_};
}

DailyLedger Simulation::daily_ledger() const {
    DailyLedger ledger;
    if (!started_) {
        return ledger;
    }

    const double uptime = effective_uptime();
    ledger.mined_btc = btc_per_day(player_hashrate_th(), market_.network_hashrate_th,
                                   market_.block_subsidy_btc, uptime);
    const double hold_fraction = static_cast<double>(player_.strategy.btc_hold) / 100.0;
    ledger.held_btc = ledger.mined_btc * hold_fraction;
    ledger.sold_btc = ledger.mined_btc - ledger.held_btc;
    ledger.mining_revenue_usd = ledger.sold_btc * market_.bitcoin_price_usd;
    ledger.partner_revenue_usd = daily_partner_revenue_usd();
    ledger.electricity_cost_usd = player_power_kw() * 24.0 *
                                  effective_power_price_per_kwh() * uptime;
    ledger.operations_cost_usd = daily_operations_cost_usd();
    ledger.net_cash_change_usd = ledger.mining_revenue_usd + ledger.partner_revenue_usd -
                                 ledger.electricity_cost_usd - ledger.operations_cost_usd;
    return ledger;
}

double Simulation::player_hashrate_th() const {
    return player_.fleet.total_hashrate_th(generations_);
}

double Simulation::player_efficiency_jth() const {
    double multiplier = profile().efficiency_multiplier;
    if (partnership_active("Semiconductor")) {
        multiplier *= 0.90;
    }
    return player_.fleet.weighted_efficiency_jth(generations_, multiplier);
}

double Simulation::player_power_kw() const {
    double multiplier = profile().efficiency_multiplier;
    if (partnership_active("Semiconductor")) {
        multiplier *= 0.90;
    }
    return player_.fleet.power_kw(generations_, multiplier);
}

double Simulation::effective_site_capacity_mw() const {
    double value = player_.site_capacity_mw;
    if (partnership_active("Infrastructure")) {
        value *= 1.35;
    }
    if (partnership_active("Real Estate")) {
        value *= 1.20;
    }
    return value;
}

double Simulation::effective_uptime() const {
    double uptime = 0.955 + profile().uptime_bonus;
    uptime += (static_cast<double>(player_.strategy.maintenance) - 50.0) * 0.00025;
    if (partnership_active("Robotics")) {
        uptime += 0.020;
    }
    if (partnership_active("Telecom")) {
        uptime += 0.010;
    }
    return std::clamp(uptime, 0.85, 0.995);
}

double Simulation::effective_power_price_per_kwh() const {
    double price = market_.electricity_price_per_kwh * profile().power_cost_multiplier;
    if (partnership_active("Energy")) {
        price *= 0.78;
    }
    return std::max(0.012, price);
}

double Simulation::company_value_usd() const {
    if (!started_) {
        return 0.0;
    }
    const double fleet_value = player_.fleet.capital_value_usd(generations_);
    const double treasury_value = player_.btc_treasury * market_.bitcoin_price_usd;
    const double site_value = player_.site_capacity_mw * 350000.0;
    const double efficiency = std::max(0.5, player_efficiency_jth());
    const double technology_value = player_hashrate_th() * std::max(2.0, 120.0 / efficiency);
    return std::max(0.0, player_.cash_usd) + treasury_value + fleet_value + site_value +
           technology_value + static_cast<double>(player_.acquisitions) * 50000.0;
}

int Simulation::league_rank() const {
    if (!started_) {
        return 0;
    }
    int rank = 1;
    const double player_value = company_value_usd();
    for (const auto& rival : rivals_) {
        if (!rival.acquired && rival.value_usd() > player_value) {
            ++rank;
        }
    }
    return rank;
}

const CompanyState& Simulation::player() const {
    return player_;
}

const MarketState& Simulation::market() const {
    return market_;
}

const std::vector<RivalCompany>& Simulation::rivals() const {
    return rivals_;
}

const std::vector<MinerGeneration>& Simulation::generations() const {
    return generations_;
}

const std::vector<CompanyProfile>& Simulation::companies() const {
    return companies_;
}

const std::vector<StrategicPartnership>& Simulation::partnerships() const {
    return partnerships_;
}

const std::string& Simulation::event_text() const {
    return event_text_;
}

const CompanyProfile& Simulation::profile() const {
    if (player_.profile_index < companies_.size()) {
        return companies_[player_.profile_index];
    }
    return companies_.front();
}

bool Simulation::partnership_active(std::string_view category) const {
    return player_.active_partnerships.find(std::string(category)) !=
           player_.active_partnerships.end();
}

double Simulation::generation_efficiency_jth(std::size_t generation_index) const {
    if (generation_index >= generations_.size()) {
        return 0.0;
    }
    double value = generations_[generation_index].efficiency_jth * profile().efficiency_multiplier;
    if (partnership_active("Semiconductor")) {
        value *= 0.90;
    }
    return value;
}

double Simulation::research_target_usd(std::size_t generation_index) const {
    if (generation_index >= generations_.size()) {
        return 0.0;
    }
    double target = generations_[generation_index].research_cost_usd /
                    std::max(0.10, profile().research_multiplier);
    if (partnership_active("AI")) {
        target *= 0.75;
    }
    if (partnership_active("Semiconductor")) {
        target *= 0.85;
    }
    const double strategy_factor = 1.10 - static_cast<double>(player_.strategy.research) * 0.002;
    return std::max(0.0, target * strategy_factor);
}

double Simulation::daily_partner_revenue_usd() const {
    double revenue = 0.0;
    if (partnership_active("AI")) {
        revenue += 75.0 + player_hashrate_th() * 0.002;
    }
    if (partnership_active("Quick Service")) {
        revenue += 180.0;
    }
    if (partnership_active("Sports")) {
        revenue += 120.0;
    }
    if (partnership_active("Finance")) {
        revenue += 35.0;
    }
    if (partnership_active("Real Estate")) {
        revenue += 30.0;
    }
    return revenue;
}

double Simulation::daily_operations_cost_usd() const {
    double cost = 70.0 + static_cast<double>(player_.fleet.count_all()) * 6.0 +
                  player_power_kw() * 0.012 + player_.site_capacity_mw * 40.0;
    const double maintenance_factor = 0.80 +
                                      static_cast<double>(player_.strategy.maintenance) * 0.004;
    cost *= maintenance_factor;
    if (partnership_active("Robotics")) {
        cost *= 0.75;
    }
    if (partnership_active("Telecom")) {
        cost *= 0.90;
    }
    return std::max(0.0, cost);
}

double Simulation::acquisition_price_usd(const RivalCompany& rival) const {
    double price = rival.value_usd() * profile().acquisition_cost_multiplier;
    if (partnership_active("Finance")) {
        price *= 0.80;
    }
    const double risk_discount = 1.05 - static_cast<double>(player_.strategy.risk) * 0.001;
    return std::max(0.0, price * risk_discount);
}

void Simulation::setup_rivals() {
    rivals_.clear();
    std::uniform_real_distribution<double> hash_scale(0.90, 1.20);
    std::uniform_real_distribution<double> cash_scale(0.80, 1.15);
    std::uniform_int_distribution<int> ovr_roll(58, 67);

    for (std::size_t i = 0; i < companies_.size(); ++i) {
        if (i == player_.profile_index) {
            continue;
        }
        const auto& company = companies_[i];
        RivalCompany rival;
        rival.name = company.name;
        rival.hashrate_th = company.starting_fleet * generations_[0].hashrate_th * hash_scale(rng_);
        rival.cash_usd = company.starting_cash_usd * cash_scale(rng_);
        rival.efficiency_jth = generations_[0].efficiency_jth * company.efficiency_multiplier;
        rival.generation = 1;
        rival.overall = ovr_roll(rng_);
        rivals_.push_back(rival);
    }
}

void Simulation::process_one_day() {
    const DailyLedger ledger = daily_ledger();
    player_.cash_usd += ledger.net_cash_change_usd;
    player_.btc_treasury += ledger.held_btc;
    ++player_.day;

    move_market();
    move_rivals();

    if (player_.day % 30 == 0) {
        apply_season_boundary();
    } else {
        apply_world_event();
    }

    if (player_.cash_usd < -25000.0) {
        player_.game_over = true;
        event_text_ = "Company failed after debt passed $25,000.";
    }
}

void Simulation::move_market() {
    std::uniform_real_distribution<double> unit(0.0, 1.0);
    const double price_move = (unit(rng_) - 0.48) * 0.035;
    market_.bitcoin_price_usd = std::max(50.0, market_.bitcoin_price_usd * (1.0 + price_move));

    const double network_move = 0.001 + unit(rng_) * 0.004;
    market_.network_hashrate_th *= 1.0 + network_move;

    const double power_move = (unit(rng_) - 0.50) * 0.004;
    market_.electricity_price_per_kwh = std::clamp(
        market_.electricity_price_per_kwh + power_move, 0.015, 0.20);
}

void Simulation::move_rivals() {
    std::uniform_real_distribution<double> unit(0.0, 1.0);
    for (auto& rival : rivals_) {
        if (rival.acquired) {
            continue;
        }

        const double uptime = 0.95;
        const double mined = btc_per_day(rival.hashrate_th, market_.network_hashrate_th,
                                         market_.block_subsidy_btc, uptime);
        const double revenue = mined * market_.bitcoin_price_usd;
        const double power = daily_power_cost(rival.hashrate_th, rival.efficiency_jth,
                                              market_.electricity_price_per_kwh, uptime);
        rival.cash_usd += revenue - power - 85.0;

        if (unit(rng_) < 0.25 && rival.cash_usd > 1500.0) {
            const double growth = 1.02 + unit(rng_) * 0.04;
            rival.hashrate_th *= growth;
            rival.cash_usd -= 500.0;
        }
        if (unit(rng_) < 0.04) {
            rival.efficiency_jth = std::max(0.70, rival.efficiency_jth * 0.97);
        }
        if (rival.generation < static_cast<int>(generations_.size()) &&
            rival.cash_usd > generations_[static_cast<std::size_t>(rival.generation)].purchase_price_usd * 6.0 &&
            unit(rng_) < 0.015) {
            ++rival.generation;
            rival.efficiency_jth = generations_[static_cast<std::size_t>(rival.generation - 1)].efficiency_jth;
        }
        rival.overall = std::clamp(
            static_cast<int>(55.0 + std::log10(std::max(10.0, rival.value_usd())) * 5.0),
            55, 100);
    }
}

void Simulation::apply_season_boundary() {
    const int finished_season = player_.season;
    ++player_.season;
    const int rank = league_rank();
    player_.franchise_overall = std::clamp(
        player_.franchise_overall + std::max(0, 5 - rank), 50, 100);
    event_text_ = "Season " + std::to_string(finished_season) + " finished. League rank #" +
                  std::to_string(rank) + "; Season " + std::to_string(player_.season) +
                  " begins at OVR " + std::to_string(player_.franchise_overall) + ".";
}

void Simulation::apply_world_event() {
    static const std::vector<std::string> events = {
        "Power markets moved today.",
        "A rival announced new mining capacity.",
        "Engineers found a small firmware optimization.",
        "Commercial partners are watching the league table.",
        "Property prices around mining sites are changing.",
        "Cooling maintenance reduced avoidable downtime across the fleet.",
    };
    std::uniform_int_distribution<std::size_t> pick(0, events.size() - 1);
    event_text_ = events[pick(rng_)];
}

}  // namespace hashrace
