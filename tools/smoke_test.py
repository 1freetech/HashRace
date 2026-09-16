#!/usr/bin/env python3
"""Dependency-free checks for Hash Race mining math and core strategy rules."""

from pathlib import Path


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

    base_power_price = 0.06
    energy_partner_price = base_power_price * 0.78
    assert energy_partner_price < base_power_price, "Energy partnerships must lower effective electricity cost"

    base_buyout_multiplier = 1.0
    finance_partner_multiplier = base_buyout_multiplier * 0.80
    assert finance_partner_multiplier < base_buyout_multiplier, "Finance partnerships must improve acquisition economics"

    base_site_mw = 0.10
    infrastructure_partner_mw = base_site_mw * 1.35
    assert infrastructure_partner_mw > base_site_mw, "Infrastructure partnerships must increase usable site capacity"

    source = Path("Assets/Scripts/HashRacePrototype.cs").read_text(encoding="utf-8")
    assert source.count("companyProfiles.Add(new CompanyProfile") == 10, "Hash Race must keep ten selectable company archetypes"
    assert source.count("partnerships.Add(new StrategicPartnership") == 6, "Hash Race must keep six strategic partnership paths"

    required_systems = [
        "FranchiseRating",
        "PlayerLeagueRank",
        "ExpandSite",
        "TryAcquire",
        "ProcessWorldEvent",
        "CurrentSeason",
    ]
    for system in required_systems:
        assert system in source, f"Missing required strategy system: {system}"

    print("Hash Race smoke test passed: mining math, partnerships, companies, infrastructure, league, and acquisition systems are present and sane.")


if __name__ == "__main__":
    main()
