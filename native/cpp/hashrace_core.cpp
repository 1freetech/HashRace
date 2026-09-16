#include <algorithm>
#include <cassert>
#include <cmath>
#include <iomanip>
#include <iostream>

namespace hashrace {

double power_kw(double hashrate_th, double efficiency_jth) {
    return std::max(0.0, hashrate_th) * std::max(0.0, efficiency_jth) / 1000.0;
}

double effective_electricity_price(double base_price_per_kwh, double discount_fraction) {
    const double discount = std::clamp(discount_fraction, 0.0, 0.60);
    return std::max(0.012, base_price_per_kwh * (1.0 - discount));
}

double btc_per_day(double player_th, double network_th, double subsidy_btc,
                   double uptime = 1.0, double blocks_per_day = 144.0) {
    if (network_th <= 0.0 || subsidy_btc <= 0.0 || blocks_per_day <= 0.0) {
        return 0.0;
    }
    const double safe_uptime = std::clamp(uptime, 0.0, 1.0);
    return (std::max(0.0, player_th) / network_th) * blocks_per_day * subsidy_btc * safe_uptime;
}

double daily_power_cost(double hashrate_th, double efficiency_jth,
                        double electricity_price_per_kwh, double uptime = 1.0) {
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

}  // namespace hashrace

int main() {
    using namespace hashrace;
    assert(std::abs(power_kw(100.0, 20.0) - 2.0) < 1e-12);
    assert(power_kw(100.0, 10.0) < power_kw(100.0, 20.0));
    assert(std::abs(btc_per_day(1000.0, 100000.0, 25.0) - 36.0) < 1e-12);
    assert(std::abs(effective_electricity_price(0.06, 0.20) - 0.048) < 1e-12);
    assert(effective_electricity_price(0.01, 0.90) == 0.012);

    const double example_profit = daily_profit_usd(
        1000.0, 1000000000.0, 3.125, 60000.0, 20.0, 0.06, 0.97, 150.0);
    std::cout << std::fixed << std::setprecision(6)
              << "Hash Race C++ core passed. Example daily profit: $"
              << example_profit << '\n';
    return 0;
}
