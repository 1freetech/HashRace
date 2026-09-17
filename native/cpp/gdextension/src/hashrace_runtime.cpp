#include "hashrace_runtime.hpp"

#include <algorithm>
#include <cmath>
#include <limits>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string_name.hpp>

namespace hashrace::godot_bridge {
namespace {

constexpr double kSatsPerBtc = 100000000.0;
constexpr double kQuarterDays = 91.3125;
constexpr double kDaysPerYear = 365.25;
constexpr double kHalvingDays = 1461.0;

const double kEnergyPrices[] = {0.078, 0.055, 0.046, 0.036, 0.030, 0.042};
const double kEnergyReliability[] = {0.0, 0.008, 0.004, 0.012, -0.012, 0.018};
const double kEnergyCapex[] = {0.0, 70000.0, 180000.0, 420000.0, 600000.0, 2500000.0};
const bool kEnergyClean[] = {false, false, false, true, true, true};
const bool kEnergyOffgrid[] = {false, false, true, true, true, false};
const char* kEnergyNames[] = {"Grid", "Utility PPA", "Natural Gas", "Hydro", "Solar + Storage", "Nuclear PPA"};

int clamp_energy(int value) {
    return std::clamp(value, 0, 5);
}

int clamp_cooling(int value) {
    return std::clamp(value, 0, 2);
}

}  // namespace

HashRaceRuntime::HashRaceRuntime()
    : generations_(default_generations()),
      generation_counts_(generations_.size(), 0),
      rng_(21) {
    culture_effects_["uptime_bonus"] = 0.0;
    culture_effects_["financing_rate_adjustment"] = 0.0;
    culture_effects_["partner_cost_multiplier"] = 1.0;
    culture_effects_["research_cost_multiplier"] = 1.0;
    culture_effects_["expansion_cost_multiplier"] = 1.0;
    culture_effects_["merger_cost_multiplier"] = 1.0;
}

void HashRaceRuntime::_bind_methods() {
    using godot::ClassDB;
    using godot::D_METHOD;

    ClassDB::bind_method(D_METHOD("bootstrap", "player", "rivals", "market", "signed_partners", "merger_used", "elapsed_days", "next_halving_day", "campaign_years"), &HashRaceRuntime::bootstrap);
    ClassDB::bind_method(D_METHOD("set_culture_effects", "effects"), &HashRaceRuntime::set_culture_effects);
    ClassDB::bind_method(D_METHOD("commit_external_state", "player", "rivals", "signed_partners", "merger_used"), &HashRaceRuntime::commit_external_state);
    ClassDB::bind_method(D_METHOD("player_snapshot"), &HashRaceRuntime::player_snapshot);
    ClassDB::bind_method(D_METHOD("rivals_snapshot"), &HashRaceRuntime::rivals_snapshot);
    ClassDB::bind_method(D_METHOD("market_snapshot"), &HashRaceRuntime::market_snapshot);
    ClassDB::bind_method(D_METHOD("signed_partners_snapshot"), &HashRaceRuntime::signed_partners_snapshot);
    ClassDB::bind_method(D_METHOD("inventory_snapshot"), &HashRaceRuntime::inventory_snapshot);
    ClassDB::bind_method(D_METHOD("is_authoritative"), &HashRaceRuntime::is_authoritative);
    ClassDB::bind_method(D_METHOD("runtime_revision"), &HashRaceRuntime::runtime_revision);
    ClassDB::bind_method(D_METHOD("merger_used"), &HashRaceRuntime::merger_used);
    ClassDB::bind_method(D_METHOD("elapsed_days"), &HashRaceRuntime::elapsed_days);
    ClassDB::bind_method(D_METHOD("next_halving_day"), &HashRaceRuntime::next_halving_day);
    ClassDB::bind_method(D_METHOD("hashrate_th"), &HashRaceRuntime::hashrate_th);
    ClassDB::bind_method(D_METHOD("machine_load_kw"), &HashRaceRuntime::machine_load_kw);
    ClassDB::bind_method(D_METHOD("effective_power_cost"), &HashRaceRuntime::effective_power_cost);
    ClassDB::bind_method(D_METHOD("uptime"), &HashRaceRuntime::uptime);
    ClassDB::bind_method(D_METHOD("btc_per_day_live"), &HashRaceRuntime::btc_per_day_live);
    ClassDB::bind_method(D_METHOD("asset_value"), &HashRaceRuntime::asset_value);
    ClassDB::bind_method(D_METHOD("eligible_lender", "loan_tiers"), &HashRaceRuntime::eligible_lender);
    ClassDB::bind_method(D_METHOD("loan_rate", "offer"), &HashRaceRuntime::loan_rate);
    ClassDB::bind_method(D_METHOD("loan_room", "loan_tiers"), &HashRaceRuntime::loan_room);
    ClassDB::bind_method(D_METHOD("project_profit", "days"), &HashRaceRuntime::project_profit);
    ClassDB::bind_method(D_METHOD("buy_machines", "count"), &HashRaceRuntime::buy_machines);
    ClassDB::bind_method(D_METHOD("buy_power"), &HashRaceRuntime::buy_power);
    ClassDB::bind_method(D_METHOD("buy_land"), &HashRaceRuntime::buy_land);
    ClassDB::bind_method(D_METHOD("upgrade_machine_tier"), &HashRaceRuntime::upgrade_machine_tier);
    ClassDB::bind_method(D_METHOD("upgrade_cooling"), &HashRaceRuntime::upgrade_cooling);
    ClassDB::bind_method(D_METHOD("upgrade_chips"), &HashRaceRuntime::upgrade_chips);
    ClassDB::bind_method(D_METHOD("change_energy"), &HashRaceRuntime::change_energy);
    ClassDB::bind_method(D_METHOD("take_loan", "loan_tiers"), &HashRaceRuntime::take_loan);
    ClassDB::bind_method(D_METHOD("repay_debt"), &HashRaceRuntime::repay_debt);
    ClassDB::bind_method(D_METHOD("sign_partner", "partner_idx", "partners"), &HashRaceRuntime::sign_partner);
    ClassDB::bind_method(D_METHOD("merge_rival", "rival_idx"), &HashRaceRuntime::merge_rival);
    ClassDB::bind_method(D_METHOD("set_hold_percent", "percent"), &HashRaceRuntime::set_hold_percent);
    ClassDB::bind_method(D_METHOD("sell_sats", "sats_to_sell"), &HashRaceRuntime::sell_sats);
    ClassDB::bind_method(D_METHOD("spend_cash", "amount", "reason"), &HashRaceRuntime::spend_cash);
    ClassDB::bind_method(D_METHOD("settle_turn", "days"), &HashRaceRuntime::settle_turn);
}

godot::Dictionary HashRaceRuntime::result(bool ok, const godot::String& message) {
    godot::Dictionary out;
    out["ok"] = ok;
    out["message"] = message;
    return out;
}

double HashRaceRuntime::number(const godot::Dictionary& dict, const char* key, double fallback) {
    return static_cast<double>(dict.get(godot::String(key), fallback));
}

int HashRaceRuntime::integer(const godot::Dictionary& dict, const char* key, int fallback) {
    return static_cast<int>(static_cast<std::int64_t>(dict.get(godot::String(key), fallback)));
}

bool HashRaceRuntime::boolean(const godot::Dictionary& dict, const char* key, bool fallback) {
    return static_cast<bool>(dict.get(godot::String(key), fallback));
}

godot::String HashRaceRuntime::text(const godot::Dictionary& dict, const char* key, const godot::String& fallback) {
    return static_cast<godot::String>(dict.get(godot::String(key), fallback));
}

godot::Dictionary HashRaceRuntime::bootstrap(const godot::Dictionary& player,
                                               const godot::Array& rivals,
                                               const godot::Dictionary& market,
                                               const godot::Dictionary& signed_partners,
                                               bool merger_used_value,
                                               double elapsed_days_value,
                                               double next_halving_day_value,
                                               int campaign_years_value) {
    player_ = player.duplicate(true);
    rivals_ = rivals.duplicate(true);
    market_ = market.duplicate(true);
    signed_partners_ = signed_partners.duplicate(true);
    merger_used_ = merger_used_value;
    elapsed_days_ = std::max(0.0, elapsed_days_value);
    next_halving_day_ = std::max(kHalvingDays, next_halving_day_value);
    campaign_years_ = std::clamp(campaign_years_value, 1, 20);
    halvings_since_crash_ = integer(market_, "halvings_since_crash", 0);
    import_legacy_fleet();
    bootstrapped_ = true;
    refresh_player_derived_fields();
    godot::Dictionary out = result(true, "C++ runtime bootstrapped and authoritative.");
    out["revision"] = runtime_revision();
    out["machines"] = fleet_.count_all();
    out["hashrate_th"] = hashrate_th();
    return out;
}

void HashRaceRuntime::set_culture_effects(const godot::Dictionary& effects) {
    culture_effects_ = effects.duplicate(true);
}

void HashRaceRuntime::commit_external_state(const godot::Dictionary& player,
                                             const godot::Array& rivals,
                                             const godot::Dictionary& signed_partners,
                                             bool merger_used_value) {
    const int before = fleet_.count_all();
    player_ = player.duplicate(true);
    rivals_ = rivals.duplicate(true);
    signed_partners_ = signed_partners.duplicate(true);
    merger_used_ = merger_used_value;
    const int mirrored = std::max(0, integer(player_, "machines", before));
    if (mirrored != before) {
        const int tier = std::clamp(integer(player_, "machine_tier", 0), 0,
                                    static_cast<int>(generations_.size()) - 1);
        if (mirrored > before) {
            generation_counts_[static_cast<std::size_t>(tier)] += mirrored - before;
        } else {
            int to_remove = before - mirrored;
            for (int i = static_cast<int>(generation_counts_.size()) - 1; i >= 0 && to_remove > 0; --i) {
                const int take = std::min(to_remove, generation_counts_[static_cast<std::size_t>(i)]);
                generation_counts_[static_cast<std::size_t>(i)] -= take;
                to_remove -= take;
            }
        }
        rebuild_fleet();
    }
    refresh_player_derived_fields();
}

godot::Dictionary HashRaceRuntime::player_snapshot() const {
    return player_.duplicate(true);
}

godot::Array HashRaceRuntime::rivals_snapshot() const {
    return rivals_.duplicate(true);
}

godot::Dictionary HashRaceRuntime::market_snapshot() const {
    return market_.duplicate(true);
}

godot::Dictionary HashRaceRuntime::signed_partners_snapshot() const {
    return signed_partners_.duplicate(true);
}

godot::Array HashRaceRuntime::inventory_snapshot() const {
    godot::Array out;
    for (std::size_t i = 0; i < generation_counts_.size() && i < generations_.size(); ++i) {
        if (generation_counts_[i] <= 0) {
            continue;
        }
        godot::Dictionary item;
        item["generation"] = static_cast<std::int64_t>(i);
        item["name"] = godot::String(generations_[i].model_name.c_str());
        item["count"] = generation_counts_[i];
        item["hashrate_th_each"] = generations_[i].hashrate_th;
        item["efficiency_jth"] = generations_[i].efficiency_jth;
        item["cooling"] = integer(player_, "cooling_level", 0);
        out.push_back(item);
    }
    return out;
}

bool HashRaceRuntime::is_authoritative() const {
    return bootstrapped_;
}

godot::String HashRaceRuntime::runtime_revision() const {
    return "v0.046-cpp-authoritative";
}

bool HashRaceRuntime::merger_used() const {
    return merger_used_;
}

double HashRaceRuntime::elapsed_days() const {
    return elapsed_days_;
}

double HashRaceRuntime::next_halving_day() const {
    return next_halving_day_;
}

void HashRaceRuntime::import_legacy_fleet() {
    generation_counts_.assign(generations_.size(), 0);
    const int tier = std::clamp(integer(player_, "machine_tier", 0), 0,
                                static_cast<int>(generations_.size()) - 1);
    const int machines = std::max(0, integer(player_, "machines", 0));
    generation_counts_[static_cast<std::size_t>(tier)] = machines;
    rebuild_fleet();
}

CoolingType HashRaceRuntime::site_cooling() const {
    const int level = clamp_cooling(integer(player_, "cooling_level", 0));
    if (level == 1) {
        return CoolingType::Immersion;
    }
    if (level == 2) {
        return CoolingType::Hydro;
    }
    return CoolingType::Air;
}

void HashRaceRuntime::rebuild_fleet() {
    fleet_ = FleetInventory{};
    for (std::size_t i = 0; i < generation_counts_.size(); ++i) {
        if (generation_counts_[i] > 0) {
            fleet_.add(i, site_cooling(), generation_counts_[i]);
        }
    }
}

void HashRaceRuntime::refresh_player_derived_fields() {
    if (player_.is_empty()) {
        return;
    }
    player_["machines"] = fleet_.count_all();
    player_["inventory"] = inventory_snapshot();
    player_["native_runtime"] = true;
    player_["native_runtime_revision"] = runtime_revision();
}

double HashRaceRuntime::cooling_overhead() const {
    static const double values[] = {1.06, 1.04, 1.035};
    return values[clamp_cooling(integer(player_, "cooling_level", 0))];
}

double HashRaceRuntime::cooling_uptime_bonus() const {
    static const double values[] = {0.0, 0.012, 0.020};
    return values[clamp_cooling(integer(player_, "cooling_level", 0))];
}

double HashRaceRuntime::energy_price() const {
    return kEnergyPrices[clamp_energy(integer(player_, "energy_idx", 0))];
}

double HashRaceRuntime::energy_reliability() const {
    return kEnergyReliability[clamp_energy(integer(player_, "energy_idx", 0))];
}

bool HashRaceRuntime::energy_clean() const {
    return kEnergyClean[clamp_energy(integer(player_, "energy_idx", 0))];
}

bool HashRaceRuntime::energy_offgrid() const {
    return kEnergyOffgrid[clamp_energy(integer(player_, "energy_idx", 0))];
}

double HashRaceRuntime::culture_value(const char* key, double fallback) const {
    return number(culture_effects_, key, fallback);
}

double HashRaceRuntime::hashrate_th() const {
    if (!bootstrapped_) {
        return 0.0;
    }
    return fleet_.total_hashrate_th(generations_);
}

double HashRaceRuntime::machine_load_kw() const {
    if (!bootstrapped_) {
        return 0.0;
    }
    const double efficiency_bonus = std::clamp(number(player_, "machine_efficiency_bonus", 0.0), 0.0, 0.20);
    return fleet_.power_kw(generations_, 1.0 - efficiency_bonus) * cooling_overhead();
}

double HashRaceRuntime::effective_power_cost() const {
    if (!bootstrapped_) {
        return 0.078;
    }
    double base = energy_price();
    const int energy = clamp_energy(integer(player_, "energy_idx", 0));
    if (energy == 0 || energy == 2) {
        base *= std::clamp(number(market_, "energy_market_index", 1.0), 0.25, 3.0);
    }
    base -= number(player_, "power_discount", 0.0);
    if (energy_clean() && energy_offgrid()) {
        base -= 0.003 + number(player_, "clean_credit_bonus", 0.0);
    } else if (energy_clean()) {
        base -= 0.0015 + number(player_, "clean_credit_bonus", 0.0);
    }
    return std::max(0.018, base);
}

double HashRaceRuntime::uptime() const {
    const double culture = culture_value("uptime_bonus", 0.0);
    return std::clamp(0.955 + energy_reliability() + cooling_uptime_bonus() + culture, 0.80, 0.997);
}

double HashRaceRuntime::btc_per_day_live() const {
    const double network = number(market_, "network_hashrate_th", 850000000.0);
    const double subsidy = number(market_, "block_subsidy_btc", 3.125);
    const double fees = number(market_, "average_fees_btc", 0.15);
    return hashrace::btc_per_day(hashrate_th(), network, subsidy + fees, uptime());
}

double HashRaceRuntime::asset_value() const {
    const double btc_price = number(market_, "btc_price", 118000.0);
    const double land_price = number(market_, "land_price_per_acre", 8000.0);
    const double cash = std::max(0.0, number(player_, "cash", 0.0));
    const double sats_value = number(player_, "sats", 0.0) / kSatsPerBtc * btc_price;
    const double machine_book = fleet_.capital_value_usd(generations_) * 0.70;
    const double land_value = number(player_, "acres", 0.0) * land_price;
    const double mw_value = number(player_, "mw", 0.0) * 90000.0;
    const double tech_value = integer(player_, "chip_level", 0) * 500000.0;
    return cash + sats_value + machine_book + land_value + mw_value + tech_value;
}

godot::Dictionary HashRaceRuntime::eligible_lender(const godot::Array& loan_tiers) const {
    godot::Dictionary best;
    const double assets = asset_value();
    for (std::int64_t i = 0; i < loan_tiers.size(); ++i) {
        godot::Dictionary tier = static_cast<godot::Dictionary>(loan_tiers[i]);
        if (assets >= number(tier, "min_assets", std::numeric_limits<double>::max())) {
            best = tier.duplicate(true);
        }
    }
    return best;
}

double HashRaceRuntime::loan_rate(const godot::Dictionary& offer) const {
    if (offer.is_empty()) {
        return 0.0;
    }
    const double federal_rate = number(market_, "federal_rate", 0.045);
    const double spread = number(offer, "spread", 0.12) - number(player_, "lender_spread_discount", 0.0);
    const double culture = culture_value("financing_rate_adjustment", 0.0);
    return std::clamp(federal_rate + std::max(0.0025, spread) + culture, 0.02, 0.30);
}

double HashRaceRuntime::loan_room(const godot::Array& loan_tiers) const {
    const godot::Dictionary offer = eligible_lender(loan_tiers);
    if (offer.is_empty()) {
        return 0.0;
    }
    const double ltv = std::min(0.72, number(offer, "ltv", 0.15) + number(player_, "loan_bonus", 0.0));
    const double capacity = std::min(number(offer, "cap", 0.0), asset_value() * ltv);
    return std::max(0.0, capacity - number(player_, "debt", 0.0));
}

double HashRaceRuntime::project_profit(double days) const {
    if (!bootstrapped_ || days <= 0.0) {
        return 0.0;
    }
    const double mined_btc = btc_per_day_live() * days;
    const double hold = std::clamp(number(player_, "treasury_hold", 0.30), 0.0, 1.0);
    const double sold_btc = mined_btc * (1.0 - hold);
    const double recurring = number(player_, "recurring_income", 0.0) * (days / kQuarterDays);
    const double revenue = sold_btc * number(market_, "btc_price", 118000.0) + recurring;
    const double power = machine_load_kw() * 24.0 * days * effective_power_cost() * uptime();
    const double ops = static_cast<double>(fleet_.count_all()) * 0.38 * days;
    const double debt = number(player_, "debt", 0.0) * number(player_, "debt_rate", 0.0) * (days / 365.0);
    return revenue - power - ops - debt;
}

godot::Dictionary HashRaceRuntime::buy_machines(int count) {
    if (!bootstrapped_ || count <= 0) {
        return result(false, "Invalid native machine order.");
    }
    const int tier = std::clamp(integer(player_, "machine_tier", 0), 0,
                                std::min(4, static_cast<int>(generations_.size()) - 1));
    const double discount = std::clamp(number(player_, "machine_discount", 0.0), 0.0, 0.25);
    const double expansion = std::clamp(culture_value("expansion_cost_multiplier", 1.0), 0.80, 1.25);
    const double cost = generations_[static_cast<std::size_t>(tier)].purchase_price_usd * count * (1.0 - discount) * expansion;
    if (number(player_, "cash", 0.0) < cost) {
        return result(false, "Not enough cash for that C++ machine order.");
    }

    generation_counts_[static_cast<std::size_t>(tier)] += count;
    rebuild_fleet();
    if (machine_load_kw() > number(player_, "mw", 0.0) * 1000.0 + 1e-9) {
        generation_counts_[static_cast<std::size_t>(tier)] -= count;
        rebuild_fleet();
        return result(false, "Not enough energized MW. Expand power first.");
    }
    player_["cash"] = number(player_, "cash", 0.0) - cost;
    refresh_player_derived_fields();
    return result(true, "C++ installed the new mining machines and updated native inventory.");
}

godot::Dictionary HashRaceRuntime::buy_power() {
    const double mw = number(player_, "mw", 0.0);
    const double capex_discount = std::clamp(number(player_, "power_capex_discount", 0.0), 0.0, 0.30);
    const double expansion = std::clamp(culture_value("expansion_cost_multiplier", 1.0), 0.80, 1.25);
    const double cost = (26000.0 + mw * 42000.0) * (1.0 - capex_discount) * expansion;
    if (number(player_, "cash", 0.0) < cost) {
        return result(false, "Not enough cash for +0.25 MW.");
    }
    player_["cash"] = number(player_, "cash", 0.0) - cost;
    player_["mw"] = mw + 0.25;
    return result(true, "C++ expanded the energized interconnect by 0.25 MW.");
}

godot::Dictionary HashRaceRuntime::buy_land() {
    const double discount = std::clamp(number(player_, "land_discount", 0.0), 0.0, 0.35);
    const double expansion = std::clamp(culture_value("expansion_cost_multiplier", 1.0), 0.80, 1.25);
    const double cost = (number(market_, "land_price_per_acre", 8000.0) * 5.0 * (1.0 - discount) + 5000.0) * expansion;
    if (number(player_, "cash", 0.0) < cost) {
        return result(false, "Not enough cash for the next five-acre parcel.");
    }
    player_["cash"] = number(player_, "cash", 0.0) - cost;
    player_["acres"] = number(player_, "acres", 0.0) + 5.0;
    return result(true, "C++ purchased five acres for the mining company.");
}

godot::Dictionary HashRaceRuntime::upgrade_machine_tier() {
    const int tier = std::clamp(integer(player_, "machine_tier", 0), 0, 4);
    if (tier >= 4) {
        return result(false, "Top currently playable machine platform is already unlocked.");
    }
    if (tier == 3 && integer(player_, "cooling_level", 0) < 2) {
        return result(false, "Hydro-class miners require Hydro Cooling first.");
    }
    const double research = std::clamp(culture_value("research_cost_multiplier", 1.0), 0.80, 1.25);
    const double cost = generations_[static_cast<std::size_t>(tier + 1)].research_cost_usd * research;
    if (number(player_, "cash", 0.0) < cost) {
        return result(false, "Not enough cash for the next machine platform R&D cycle.");
    }
    player_["cash"] = number(player_, "cash", 0.0) - cost;
    player_["machine_tier"] = tier + 1;
    return result(true, "C++ unlocked the next ASIC generation. Existing machines remain in native inventory.");
}

godot::Dictionary HashRaceRuntime::upgrade_cooling() {
    const int level = clamp_cooling(integer(player_, "cooling_level", 0));
    if (level >= 2) {
        return result(false, "Hydro Cooling is already installed.");
    }
    const double costs[] = {160000.0, 650000.0};
    const double cost = costs[level];
    if (number(player_, "cash", 0.0) < cost) {
        return result(false, "Not enough cash for the next cooling system.");
    }
    player_["cash"] = number(player_, "cash", 0.0) - cost;
    player_["cooling_level"] = level + 1;
    rebuild_fleet();
    refresh_player_derived_fields();
    return result(true, "C++ upgraded site cooling and recalculated fleet efficiency.");
}

godot::Dictionary HashRaceRuntime::upgrade_chips() {
    const int level = std::clamp(integer(player_, "chip_level", 0), 0, 3);
    if (level >= 3) {
        return result(false, "Captive chip manufacturing is already online.");
    }
    const double base_costs[] = {150000.0, 700000.0, 4000000.0};
    const double discounts[] = {0.06, 0.12, 0.22};
    const double research = std::clamp(culture_value("research_cost_multiplier", 1.0), 0.80, 1.25);
    const double cost = base_costs[level] * research;
    if (number(player_, "cash", 0.0) < cost) {
        return result(false, "Not enough cash for the next chip strategy level.");
    }
    player_["cash"] = number(player_, "cash", 0.0) - cost;
    player_["chip_level"] = level + 1;
    player_["machine_discount"] = std::max(number(player_, "machine_discount", 0.0), discounts[level]);
    return result(true, "C++ advanced the chip strategy and hardware discount.");
}

godot::Dictionary HashRaceRuntime::change_energy() {
    const int current = clamp_energy(integer(player_, "energy_idx", 0));
    const int next = (current + 1) % 6;
    if (next == 1 && !boolean(player_, "utility_access", false)) {
        return result(false, "Utility PPA requires the utility partnership.");
    }
    if (next == 3 && !boolean(player_, "hydro_access", false)) {
        return result(false, "Hydro requires the energy-authority partnership.");
    }
    if (next == 4 && number(player_, "acres", 0.0) < 30.0) {
        return result(false, "Solar + Storage requires at least 30 acres.");
    }
    if (next == 5 && number(player_, "mw", 0.0) < 10.0) {
        return result(false, "Nuclear PPA requires at least 10 MW of company scale.");
    }
    const double cost = kEnergyCapex[next];
    if (number(player_, "cash", 0.0) < cost) {
        return result(false, "Not enough cash for that energy project.");
    }
    player_["cash"] = number(player_, "cash", 0.0) - cost;
    player_["energy_idx"] = next;
    return result(true, godot::String("C++ changed company energy to ") + kEnergyNames[next] + ".");
}

godot::Dictionary HashRaceRuntime::take_loan(const godot::Array& loan_tiers) {
    const godot::Dictionary offer = eligible_lender(loan_tiers);
    if (offer.is_empty()) {
        return result(false, "No lender will approve new debt yet.");
    }
    const double room = loan_room(loan_tiers);
    if (room < 5000.0) {
        return result(false, "No useful new borrowing room right now.");
    }
    const double amount = std::min(room, std::max(10000.0, asset_value() * 0.15));
    const double rate = loan_rate(offer);
    const double old_debt = number(player_, "debt", 0.0);
    const double old_rate = number(player_, "debt_rate", 0.0);
    const double new_debt = old_debt + amount;
    double blended = rate;
    if (old_debt > 0.0 && old_rate > 0.0) {
        blended = ((old_debt * old_rate) + (amount * rate)) / new_debt;
    }
    player_["cash"] = number(player_, "cash", 0.0) + amount;
    player_["debt"] = new_debt;
    player_["debt_rate"] = blended;
    player_["debt_source"] = text(offer, "name", "Lender");
    return result(true, "C++ closed the asset-backed loan and updated debt state.");
}

godot::Dictionary HashRaceRuntime::repay_debt() {
    const double debt = number(player_, "debt", 0.0);
    if (debt <= 0.0) {
        return result(false, "The company has no debt.");
    }
    const double available = std::max(0.0, number(player_, "cash", 0.0) - 10000.0);
    if (available < 1000.0) {
        return result(false, "Keep at least $10,000 operating cash before repaying debt.");
    }
    const double payment = std::min(debt, std::min(available, std::max(5000.0, debt * 0.25)));
    player_["cash"] = number(player_, "cash", 0.0) - payment;
    const double remaining = debt - payment;
    player_["debt"] = remaining <= 0.01 ? 0.0 : remaining;
    if (remaining <= 0.01) {
        player_["debt_rate"] = 0.0;
        player_["debt_source"] = "No lender";
    }
    return result(true, "C++ applied the debt payment.");
}

godot::Dictionary HashRaceRuntime::sign_partner(int partner_idx, const godot::Array& partners) {
    if (partner_idx < 0 || partner_idx >= partners.size()) {
        return result(false, "Invalid partnership selection.");
    }
    const godot::Dictionary partner = static_cast<godot::Dictionary>(partners[partner_idx]);
    const godot::String id = text(partner, "id", "");
    if (id.is_empty()) {
        return result(false, "Partnership has no stable ID.");
    }
    if (signed_partners_.has(id)) {
        return result(false, "That partnership is already active.");
    }
    const double multiplier = std::clamp(culture_value("partner_cost_multiplier", 1.0), 0.80, 1.25);
    const double cost = number(partner, "cost", 0.0) * multiplier;
    if (number(player_, "cash", 0.0) < cost) {
        return result(false, "Not enough cash for that partnership.");
    }
    player_["cash"] = number(player_, "cash", 0.0) - cost;
    signed_partners_[id] = true;

    if (id == "utility") {
        player_["power_discount"] = number(player_, "power_discount", 0.0) + 0.012;
        player_["utility_access"] = true;
    } else if (id == "land") {
        player_["acres"] = number(player_, "acres", 0.0) + 10.0;
        player_["land_discount"] = 0.15;
    } else if (id == "infra") {
        player_["mw"] = number(player_, "mw", 0.0) + 0.25;
        player_["power_capex_discount"] = 0.12;
    } else if (id == "semi") {
        const int tier = std::clamp(integer(player_, "machine_tier", 0), 0,
                                    static_cast<int>(generation_counts_.size()) - 1);
        generation_counts_[static_cast<std::size_t>(tier)] += 10;
        rebuild_fleet();
        player_["machine_efficiency_bonus"] = 0.06;
        player_["machine_discount"] = 0.05;
    } else if (id == "finance") {
        player_["cash"] = number(player_, "cash", 0.0) + 60000.0;
        player_["loan_bonus"] = number(player_, "loan_bonus", 0.0) + 0.10;
        player_["lender_spread_discount"] = 0.01;
    } else if (id == "food") {
        player_["recurring_income"] = number(player_, "recurring_income", 0.0) + 6000.0;
    } else if (id == "sports") {
        player_["recurring_income"] = number(player_, "recurring_income", 0.0) + 10000.0;
    } else if (id == "energy") {
        player_["hydro_access"] = true;
        player_["clean_credit_bonus"] = 0.002;
    } else if (id == "treasury") {
        player_["sats"] = number(player_, "sats", 0.0) + 20000000.0;
    }
    refresh_player_derived_fields();
    return result(true, "C++ signed the partnership and applied its native state effects.");
}

godot::Dictionary HashRaceRuntime::merge_rival(int rival_idx) {
    if (merger_used_) {
        return result(false, "The one-time campaign merger has already been used.");
    }
    if (rival_idx < 0 || rival_idx >= rivals_.size()) {
        return result(false, "Invalid rival selection.");
    }
    godot::Dictionary rival = static_cast<godot::Dictionary>(rivals_[rival_idx]);
    if (boolean(rival, "merged", false)) {
        return result(false, "That rival has already been merged.");
    }
    const double rival_assets = number(rival, "cash", 0.0) +
        number(rival, "sats", 0.0) / kSatsPerBtc * number(market_, "btc_price", 118000.0) +
        number(rival, "mw", 0.0) * 90000.0 +
        number(rival, "acres", 0.0) * number(market_, "land_price_per_acre", 8000.0) +
        integer(rival, "machines", 0) * 700.0;
    if (rival_assets > asset_value() * 1.25) {
        return result(false, "That rival is too large for a one-time merger right now.");
    }
    const double multiplier = std::clamp(culture_value("merger_cost_multiplier", 1.0), 0.80, 1.25);
    const double price = std::max(100000.0, rival_assets * 0.70) * multiplier;
    if (number(player_, "cash", 0.0) < price) {
        return result(false, "Not enough cash to close the merger.");
    }

    player_["cash"] = number(player_, "cash", 0.0) - price + number(rival, "cash", 0.0) * 0.50;
    player_["sats"] = number(player_, "sats", 0.0) + number(rival, "sats", 0.0);
    player_["mw"] = number(player_, "mw", 0.0) + number(rival, "mw", 0.0);
    player_["acres"] = number(player_, "acres", 0.0) + number(rival, "acres", 0.0);
    const int tier = std::clamp(integer(player_, "machine_tier", 0), 0,
                                static_cast<int>(generation_counts_.size()) - 1);
    generation_counts_[static_cast<std::size_t>(tier)] += std::max(0, integer(rival, "machines", 0));
    rebuild_fleet();
    rival["merged"] = true;
    rivals_[rival_idx] = rival;
    merger_used_ = true;
    refresh_player_derived_fields();
    return result(true, "C++ completed the one-time mining-company merger.");
}

godot::Dictionary HashRaceRuntime::set_hold_percent(int percent) {
    const int safe = std::clamp(percent, 0, 100);
    player_["treasury_hold"] = static_cast<double>(safe) / 100.0;
    return result(true, "C++ updated the BTC hold policy.");
}

godot::Dictionary HashRaceRuntime::sell_sats(double sats_to_sell) {
    const double held = std::max(0.0, number(player_, "sats", 0.0));
    const double sold = std::clamp(std::floor(sats_to_sell), 0.0, held);
    if (sold < 1.0) {
        return result(false, "No held Bitcoin was available to sell.");
    }
    const double cash_raised = sold / kSatsPerBtc * number(market_, "btc_price", 118000.0);
    player_["sats"] = held - sold;
    player_["cash"] = number(player_, "cash", 0.0) + cash_raised;
    godot::Dictionary out = result(true, "C++ sold BTC treasury into operating cash.");
    out["sats_sold"] = sold;
    out["cash_raised"] = cash_raised;
    return out;
}

godot::Dictionary HashRaceRuntime::spend_cash(double amount, const godot::String& reason) {
    if (amount <= 0.0) {
        return result(false, "Cash spend must be positive.");
    }
    if (number(player_, "cash", 0.0) < amount) {
        return result(false, "Not enough cash for that action.");
    }
    player_["cash"] = number(player_, "cash", 0.0) - amount;
    return result(true, godot::String("C++ paid for ") + reason + ".");
}

double HashRaceRuntime::rand_range(double low, double high) {
    std::uniform_real_distribution<double> dist(low, high);
    return dist(rng_);
}

int HashRaceRuntime::rand_int(int low, int high) {
    std::uniform_int_distribution<int> dist(low, high);
    return dist(rng_);
}

godot::String HashRaceRuntime::trigger_rare_crash() {
    if (rand_int(0, 1) == 0) {
        market_["btc_price"] = std::max(6000.0, number(market_, "btc_price", 118000.0) * rand_range(0.45, 0.62));
        market_["land_price_per_acre"] = std::max(1500.0, number(market_, "land_price_per_acre", 8000.0) * rand_range(0.92, 0.98));
        market_["federal_rate"] = std::max(0.005, number(market_, "federal_rate", 0.045) - 0.010);
        market_["last_market_event"] = "DOT-COM-STYLE TECH CRASH";
        return "DOT-COM-STYLE TECH CRASH: BTC took the main hit.";
    }
    market_["land_price_per_acre"] = std::max(1500.0, number(market_, "land_price_per_acre", 8000.0) * rand_range(0.60, 0.76));
    market_["btc_price"] = std::max(6000.0, number(market_, "btc_price", 118000.0) * rand_range(0.84, 0.95));
    market_["energy_market_index"] = std::min(1.55, number(market_, "energy_market_index", 1.0) * 1.12);
    market_["federal_rate"] = std::max(0.005, number(market_, "federal_rate", 0.045) - 0.0075);
    market_["last_market_event"] = "COVID-STYLE PROPERTY / LOGISTICS CRASH";
    return "COVID-STYLE PROPERTY / LOGISTICS CRASH: land took the main hit.";
}

godot::String HashRaceRuntime::advance_market(double days, bool halving_happened) {
    const double volatility = std::sqrt(std::max(0.0001, days / kQuarterDays));
    double rate_move = rand_range(-0.0035, 0.0035) * volatility;
    if (rand_range(0.0, 1.0) < 0.12 * std::min(1.0, days / kQuarterDays)) {
        rate_move += rand_range(-0.005, 0.005) * volatility;
    }
    const double federal = std::clamp(number(market_, "federal_rate", 0.045) + rate_move, 0.005, 0.085);
    market_["federal_rate"] = federal;
    const double rate_headwind = std::max(-0.02, federal - 0.04);
    const double btc_return = rand_range(-0.12, 0.18) * volatility - rate_headwind * 0.90 * (days / kQuarterDays);
    const double land_return = rand_range(-0.025, 0.040) * volatility - rate_headwind * 0.35 * (days / kQuarterDays);
    market_["btc_price"] = std::max(8000.0, number(market_, "btc_price", 118000.0) * std::max(0.72, 1.0 + btc_return));
    market_["land_price_per_acre"] = std::max(1800.0, number(market_, "land_price_per_acre", 8000.0) * std::max(0.80, 1.0 + land_return));
    market_["energy_market_index"] = std::clamp(number(market_, "energy_market_index", 1.0) * (1.0 + rand_range(-0.06, 0.07) * volatility), 0.72, 1.45);
    market_["network_hashrate_th"] = number(market_, "network_hashrate_th", 850000000.0) * std::max(0.90, 1.0 + rand_range(-0.015, 0.075) * volatility);
    market_["average_fees_btc"] = std::clamp(number(market_, "average_fees_btc", 0.15) * std::max(0.50, 1.0 + rand_range(-0.28, 0.38) * volatility), 0.04, 0.85);
    market_["last_market_event"] = "Normal market";

    godot::String note = "C++ market settlement complete.";
    if (halving_happened) {
        ++halvings_since_crash_;
        const bool crash_due = halvings_since_crash_ >= 3 || (halvings_since_crash_ >= 2 && rand_range(0.0, 1.0) < 0.55);
        if (crash_due) {
            note = trigger_rare_crash();
            halvings_since_crash_ = 0;
        }
    }
    market_["halvings_since_crash"] = halvings_since_crash_;
    return note;
}

godot::Dictionary HashRaceRuntime::settle_turn(double days) {
    if (!bootstrapped_ || days <= 0.0) {
        return result(false, "Invalid native turn duration.");
    }
    const double mined_btc = btc_per_day_live() * days;
    const double mined_sats = mined_btc * kSatsPerBtc;
    const double hold = std::clamp(number(player_, "treasury_hold", 0.30), 0.0, 1.0);
    const double held_sats = mined_sats * hold;
    const double sold_btc = mined_btc * (1.0 - hold);
    const double recurring = number(player_, "recurring_income", 0.0) * (days / kQuarterDays);
    const double revenue = sold_btc * number(market_, "btc_price", 118000.0) + recurring;
    const double power = machine_load_kw() * 24.0 * days * effective_power_cost() * uptime();
    const double ops = static_cast<double>(fleet_.count_all()) * 0.38 * days;
    const double debt = number(player_, "debt", 0.0) * number(player_, "debt_rate", 0.0) * (days / 365.0);
    const double profit = revenue - power - ops - debt;

    player_["sats"] = number(player_, "sats", 0.0) + held_sats;
    player_["cash"] = number(player_, "cash", 0.0) + profit;
    player_["last_profit"] = profit;
    elapsed_days_ += days;

    bool halving = false;
    while (elapsed_days_ + 1e-9 >= next_halving_day_) {
        market_["block_subsidy_btc"] = number(market_, "block_subsidy_btc", 3.125) * 0.5;
        next_halving_day_ += kHalvingDays;
        halving = true;
    }
    const godot::String market_note = advance_market(days, halving);
    refresh_player_derived_fields();

    godot::Dictionary out = result(true, "C++ settled the mining turn and market state.");
    out["mined_btc"] = mined_btc;
    out["mined_sats"] = mined_sats;
    out["held_sats"] = held_sats;
    out["sold_btc"] = sold_btc;
    out["revenue"] = revenue;
    out["power_cost"] = power;
    out["operations_cost"] = ops;
    out["debt_cost"] = debt;
    out["profit"] = profit;
    out["halving_happened"] = halving;
    out["market_note"] = market_note;
    out["elapsed_days"] = elapsed_days_;
    out["next_halving_day"] = next_halving_day_;
    out["campaign_years"] = campaign_years_;
    return out;
}

}  // namespace hashrace::godot_bridge
