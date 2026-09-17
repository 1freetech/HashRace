#pragma once

#include "../../hashrace_simulation.hpp"

#include <cstdint>
#include <random>
#include <vector>

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/string.hpp>

namespace hashrace::godot_bridge {

class HashRaceRuntime : public godot::RefCounted {
    GDCLASS(HashRaceRuntime, godot::RefCounted)

public:
    HashRaceRuntime();
    ~HashRaceRuntime() override = default;

    godot::Dictionary bootstrap(const godot::Dictionary& player,
                                const godot::Array& rivals,
                                const godot::Dictionary& market,
                                const godot::Dictionary& signed_partners,
                                bool merger_used,
                                double elapsed_days,
                                double next_halving_day,
                                int campaign_years);
    void set_culture_effects(const godot::Dictionary& effects);
    void commit_external_state(const godot::Dictionary& player,
                               const godot::Array& rivals,
                               const godot::Dictionary& signed_partners,
                               bool merger_used);

    godot::Dictionary player_snapshot() const;
    godot::Array rivals_snapshot() const;
    godot::Dictionary market_snapshot() const;
    godot::Dictionary signed_partners_snapshot() const;
    godot::Array inventory_snapshot() const;

    bool is_authoritative() const;
    godot::String runtime_revision() const;
    bool merger_used() const;
    double elapsed_days() const;
    double next_halving_day() const;

    double hashrate_th() const;
    double machine_load_kw() const;
    double effective_power_cost() const;
    double uptime() const;
    double btc_per_day_live() const;
    double asset_value() const;
    godot::Dictionary eligible_lender(const godot::Array& loan_tiers) const;
    double loan_rate(const godot::Dictionary& offer) const;
    double loan_room(const godot::Array& loan_tiers) const;
    double project_profit(double days) const;

    godot::Dictionary buy_machines(int count);
    godot::Dictionary buy_power();
    godot::Dictionary buy_land();
    godot::Dictionary upgrade_machine_tier();
    godot::Dictionary upgrade_cooling();
    godot::Dictionary upgrade_chips();
    godot::Dictionary change_energy();
    godot::Dictionary take_loan(const godot::Array& loan_tiers);
    godot::Dictionary repay_debt();
    godot::Dictionary sign_partner(int partner_idx, const godot::Array& partners);
    godot::Dictionary merge_rival(int rival_idx);
    godot::Dictionary set_hold_percent(int percent);
    godot::Dictionary sell_sats(double sats_to_sell);
    godot::Dictionary spend_cash(double amount, const godot::String& reason);
    godot::Dictionary settle_turn(double days);

protected:
    static void _bind_methods();

private:
    godot::Dictionary player_;
    godot::Array rivals_;
    godot::Dictionary market_;
    godot::Dictionary signed_partners_;
    godot::Dictionary culture_effects_;
    bool merger_used_ = false;
    bool bootstrapped_ = false;
    double elapsed_days_ = 0.0;
    double next_halving_day_ = 1461.0;
    int campaign_years_ = 4;
    int halvings_since_crash_ = 0;

    std::vector<MinerGeneration> generations_;
    std::vector<int> generation_counts_;
    FleetInventory fleet_;
    mutable std::mt19937 rng_;

    static godot::Dictionary result(bool ok, const godot::String& message);
    static double number(const godot::Dictionary& dict, const char* key, double fallback = 0.0);
    static int integer(const godot::Dictionary& dict, const char* key, int fallback = 0);
    static bool boolean(const godot::Dictionary& dict, const char* key, bool fallback = false);
    static godot::String text(const godot::Dictionary& dict, const char* key, const godot::String& fallback = "");

    void import_legacy_fleet();
    void rebuild_fleet();
    void refresh_player_derived_fields();
    CoolingType site_cooling() const;
    double cooling_overhead() const;
    double cooling_uptime_bonus() const;
    double energy_price() const;
    double energy_reliability() const;
    bool energy_clean() const;
    bool energy_offgrid() const;
    double culture_value(const char* key, double fallback) const;
    double rand_range(double low, double high);
    int rand_int(int low, int high);
    godot::String advance_market(double days, bool halving_happened);
    godot::String trigger_rare_crash();
};

}  // namespace hashrace::godot_bridge
