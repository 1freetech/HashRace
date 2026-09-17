#include "hashrace_simulation.hpp"

#include <cassert>
#include <cmath>
#include <iomanip>
#include <iostream>

namespace {

bool near(double lhs, double rhs, double tolerance = 1e-9) {
    return std::abs(lhs - rhs) <= tolerance;
}

void test_mining_math() {
    using namespace hashrace;
    assert(near(power_kw(100.0, 20.0), 2.0));
    assert(power_kw(100.0, 10.0) < power_kw(100.0, 20.0));
    assert(near(btc_per_day(1000.0, 100000.0, 25.0), 36.0));
    assert(near(effective_electricity_price(0.06, 0.20), 0.048));
    assert(near(effective_electricity_price(0.01, 0.90), 0.012));
    assert(daily_power_cost(100.0, 20.0, 0.05, 1.0) > 0.0);
}

void test_inventory_model() {
    using namespace hashrace;
    const auto generations = default_generations();
    FleetInventory fleet;

    assert(fleet.add(0, CoolingType::Air, 10));
    assert(fleet.add(2, CoolingType::Hydro, 4, 92, 95));
    assert(fleet.add(4, CoolingType::Immersion, 2, 88, 100));
    assert(fleet.count_all() == 16);
    assert(fleet.count_generation(0) == 10);
    assert(fleet.count_cooling(CoolingType::Hydro) == 4);
    assert(fleet.total_hashrate_th(generations) > 0.0);
    assert(fleet.weighted_efficiency_jth(generations) > 0.0);
    assert(fleet.power_kw(generations) > 0.0);
    assert(fleet.capital_value_usd(generations) > 0.0);
    assert(fleet.remove(0, CoolingType::Air, 3));
    assert(fleet.count_all() == 13);
}

void test_company_and_strategy_state() {
    using namespace hashrace;
    Simulation sim(21);
    assert(sim.companies().size() == 10);
    assert(sim.generations().size() == 9);
    assert(sim.partnerships().size() == 10);

    const auto started = sim.start_company(0);
    assert(started.ok);
    assert(sim.player().fleet.count_all() == sim.companies()[0].starting_fleet);
    assert(sim.player_hashrate_th() > 0.0);
    assert(sim.player_efficiency_jth() > 0.0);
    assert(sim.player_power_kw() > 0.0);
    assert(sim.league_rank() >= 1 && sim.league_rank() <= 10);

    StrategySettings extreme;
    extreme.btc_hold = 140;
    extreme.expansion = -20;
    extreme.research = 75;
    extreme.maintenance = 85;
    extreme.risk = 10;
    extreme.partnership = 101;
    assert(sim.set_strategy(extreme).ok);
    assert(sim.player().strategy.btc_hold == 100);
    assert(sim.player().strategy.expansion == 0);
    assert(sim.player().strategy.research == 75);
    assert(sim.player().strategy.maintenance == 85);
    assert(sim.player().strategy.risk == 10);
    assert(sim.player().strategy.partnership == 100);
}

void test_machine_purchase_and_capacity() {
    using namespace hashrace;
    Simulation sim(22);
    assert(sim.start_company(9).ok);
    const int before = sim.player().fleet.count_all();
    const double cash_before = sim.player().cash_usd;
    const auto buy = sim.buy_miner(0, CoolingType::Air, 2);
    assert(buy.ok);
    assert(sim.player().fleet.count_all() == before + 2);
    assert(sim.player().cash_usd < cash_before);

    const auto wrong_cooling = sim.buy_miner(0, CoolingType::Immersion, 1);
    assert(!wrong_cooling.ok);
    const auto locked_generation = sim.buy_miner(3, CoolingType::Air, 1);
    assert(!locked_generation.ok);
}

void test_research_unlock() {
    using namespace hashrace;
    Simulation sim(23);
    assert(sim.start_company(9).ok);
    assert(sim.player().unlocked_generation == 1);
    const auto research = sim.fund_research(18000.0);
    assert(research.ok);
    assert(sim.player().unlocked_generation == 2);
    assert(sim.player().research_progress_usd == 0.0);
}

void test_daily_ledger_and_treasury() {
    using namespace hashrace;
    Simulation sim(24);
    assert(sim.start_company(0).ok);

    StrategySettings strategy = sim.player().strategy;
    strategy.btc_hold = 100;
    strategy.maintenance = 80;
    assert(sim.set_strategy(strategy).ok);

    const auto ledger = sim.daily_ledger();
    assert(ledger.mined_btc > 0.0);
    assert(near(ledger.sold_btc, 0.0));
    assert(ledger.held_btc > 0.0);
    assert(ledger.electricity_cost_usd > 0.0);
    assert(ledger.operations_cost_usd > 0.0);

    const double btc_before = sim.player().btc_treasury;
    assert(sim.advance_day(31).ok);
    assert(sim.player().btc_treasury > btc_before);
    assert(sim.player().day == 31);
    assert(sim.player().season == 2);
}

}  // namespace

int main() {
    test_mining_math();
    test_inventory_model();
    test_company_and_strategy_state();
    test_machine_purchase_and_capacity();
    test_research_unlock();
    test_daily_ledger_and_treasury();

    hashrace::Simulation demo(21);
    const auto started = demo.start_company(0);
    assert(started.ok);
    const auto ledger = demo.daily_ledger();

    std::cout << std::fixed << std::setprecision(3)
              << "Hash Race C++ simulation passed. "
              << "Companies=" << demo.companies().size()
              << " generations=" << demo.generations().size()
              << " fleet=" << demo.player().fleet.count_all()
              << " hash=" << demo.player_hashrate_th() << " TH/s"
              << " J/TH=" << demo.player_efficiency_jth()
              << " daily_net=$" << ledger.net_cash_change_usd << '\n';
    return 0;
}
