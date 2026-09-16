#!/usr/bin/env python3
"""Tiny dependency-free checks for Hash Race's core mining equations."""


def power_kw(hashrate_th, efficiency_jth):
    return hashrate_th * efficiency_jth / 1000.0


def btc_per_day(player_th, network_th, subsidy, uptime=1.0):
    return (player_th / network_th) * 144.0 * subsidy * uptime


def power_cost_day(hashrate_th, efficiency_jth, electricity_kwh, uptime=1.0):
    return power_kw(hashrate_th, efficiency_jth) * 24.0 * electricity_kwh * uptime


def close(a, b, tolerance=1e-9):
    return abs(a - b) <= tolerance


def main():
    assert close(power_kw(100.0, 20.0), 2.0), "100 TH/s at 20 J/TH should draw 2 kW"
    assert close(power_cost_day(100.0, 20.0, 0.05), 2.4), "2 kW for 24h at $0.05/kWh should cost $2.40"
    assert close(btc_per_day(1000.0, 100000.0, 25.0), 36.0), "1% of a 25 BTC/block network should earn 36 BTC/day at 144 blocks/day"
    assert power_kw(100.0, 10.0) < power_kw(100.0, 20.0), "Lower J/TH must use less power at equal hashrate"
    print("Hash Race smoke test passed: power, revenue share, and efficiency math are sane.")


if __name__ == "__main__":
    main()
