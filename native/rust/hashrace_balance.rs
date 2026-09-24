fn clamp(value: f64, low: f64, high: f64) -> f64 {
    value.max(low).min(high)
}

fn power_kw(hashrate_th: f64, efficiency_jth: f64) -> f64 {
    hashrate_th.max(0.0) * efficiency_jth.max(0.0) / 1000.0
}

fn btc_per_day(player_th: f64, network_th: f64, subsidy_btc: f64, uptime: f64) -> f64 {
    if network_th <= 0.0 || subsidy_btc <= 0.0 {
        return 0.0;
    }
    (player_th.max(0.0) / network_th) * 144.0 * subsidy_btc * clamp(uptime, 0.0, 1.0)
}

fn daily_power_cost(hashrate_th: f64, efficiency_jth: f64, electricity_price: f64, uptime: f64) -> f64 {
    power_kw(hashrate_th, efficiency_jth) * 24.0 * electricity_price.max(0.0) * clamp(uptime, 0.0, 1.0)
}

#[derive(Debug)]
struct YearSnapshot {
    days: u32,
    ending_cash: f64,
    mined_btc: f64,
    power_cost: f64,
}

fn simulate_year(starting_cash: f64, hashrate_th: f64, network_th: f64, subsidy_btc: f64,
                 btc_price_usd: f64, efficiency_jth: f64, electricity_price: f64,
                 uptime: f64, daily_operations_cost: f64) -> YearSnapshot {
    let daily_btc = btc_per_day(hashrate_th, network_th, subsidy_btc, uptime);
    let daily_power = daily_power_cost(hashrate_th, efficiency_jth, electricity_price, uptime);
    let daily_profit = daily_btc * btc_price_usd.max(0.0) - daily_power - daily_operations_cost.max(0.0);
    YearSnapshot {
        days: 365,
        ending_cash: starting_cash + daily_profit * 365.0,
        mined_btc: daily_btc * 365.0,
        power_cost: daily_power * 365.0,
    }
}

fn main() {
    let snapshot = simulate_year(10_000.0, 1_000.0, 1_000_000_000.0, 3.125,
                                 60_000.0, 20.0, 0.06, 0.97, 150.0);
    assert!(snapshot.days == 365);
    assert!(snapshot.mined_btc > 0.0);
    assert!(snapshot.power_cost > 0.0);
    println!("Hash Race Rust balance probe passed: {:?}", snapshot);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn mining_math_matches_contract() {
        assert!((power_kw(100.0, 20.0) - 2.0).abs() < 1e-12);
        assert!((btc_per_day(1000.0, 100000.0, 25.0, 1.0) - 36.0).abs() < 1e-12);
    }

    #[test]
    fn better_efficiency_reduces_power_cost() {
        assert!(daily_power_cost(100.0, 10.0, 0.06, 1.0) < daily_power_cost(100.0, 20.0, 0.06, 1.0));
    }
}
