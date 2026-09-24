# Hash Race mining economy model

Updated September 15, 2026.

Hash Race uses a turn-based mining model where one turn equals seven operating days. The game should feel like a strategy game, but the core profitability logic follows real Bitcoin-mining relationships rather than an arbitrary revenue-per-machine number.

## Core revenue

For each company:

`BTC/day = (company hashrate TH/s / network hashrate TH/s) × 144 blocks/day × (block subsidy BTC + average fees BTC/block) × uptime`

`Sats/day = BTC/day × 100,000,000`

`Gross mining revenue/day = BTC/day × BTC price`

A treasury policy determines how much mined BTC is held as sats and how much is sold into cash. This gives the SATS stat a real purpose instead of making it a decorative score.

## Power and operating cost

Each machine has a real-style hashrate and wall-power profile. Fleet load is the sum of machine kW, plus a cooling/infrastructure overhead factor. Power expense is:

`Power cost/day = total site kW × 24 × effective $/kWh`

Cooling systems modify overhead and uptime. Air is cheap to install but has the weakest uptime bonus. Immersion costs more but improves reliability. Hydro requires more infrastructure and power capacity but supports dense high-power hardware.

Hashprice can also be used as a UI shorthand. Luxor describes miner power breakeven as hashprice divided by 24 times J/TH efficiency, which is the same economic relationship represented by the more explicit network-share model used in Hash Race.

## Machine progression anchors

These are performance references, not promises of current purchase price.

- Garage-class ASIC: fictional starter hardware, approximately 90 TH/s at 3.0 kW.
- S19j Pro-class: approximately 104 TH/s at 3.068 kW and 29.5 J/TH.
- S21-class air: approximately 200 TH/s at 3.5 kW and 17.5 J/TH.
- S21 Pro-class air: approximately 234 TH/s at 3.51 kW and 15 J/TH.
- S21 Hydro-class: approximately 335 TH/s at 5.36 kW and 16 J/TH.
- Future megawatt rack: fictional future turn technology at roughly 1 MW per rack. It requires an advanced site, hydro cooling, and captive chip manufacturing.

Game-market purchase prices are intentionally simulated and can change by turn. Real ASIC pricing moves too quickly to hard-code as a permanent truth.

## Site progression

A new industrial mining site cannot be commissioned until the company has at least:

- 100 machines,
- enough energized MW to operate the fleet,
- at least 5 acres,
- the required construction cash.

The company begins at a local garage/warehouse level. Later stages are Local Site, Industrial Campus, Regional Mining Town, and Fab-Integrated Tech Town.

## Seven major company stats

1. SATS treasury
2. Electricity cost in $/kWh
3. Energized MW
4. Machines / rack systems
5. Energy source
6. Cash and current profit
7. Total acres

Purchases, infrastructure, loans, cooling, energy contracts, partners, and machine generations all change one or more of these values.

## Energy sources

Energy is a strategic choice instead of a simple discount button.

- Grid: easiest to start, highest price volatility.
- Utility PPA: lower and more stable price but requires a utility/state relationship.
- Natural gas: lower cost and reliable, but adds maintenance and fuel-price risk.
- Hydro: low operating price and good reliability, but high construction requirements and geography limits.
- Solar + storage: low marginal energy cost and land-intensive; storage quality determines effective availability.
- Nuclear PPA: stable high-density power, but requires a large company and major commitment.

## Hosting

If a company owns more energized MW than its own fleet uses, it can host third-party mining load. Hosting earns a margin on spare kWh instead of leaving the capacity idle. The game uses the difference between the hosting customer rate and the company's effective power cost, multiplied by used spare capacity.

## Loans

Debt capacity is based on total asset value rather than cash alone. Assets include cash, sats at current BTC price, machine book value, energized MW infrastructure, land, site development, and chip-manufacturing capability. Partnerships with finance companies can increase the loan-to-asset limit. Interest is charged each turn.

## Chip progression

The semiconductor path is:

Third-party chips → strategic wafer deal → co-designed silicon → captive chip manufacturing.

Each step costs substantial capital. Higher levels reduce machine purchase cost and eventually unlock the future 1 MW rack platform.

## Sources

- BITMAIN S19j series specifications: https://support.bitmain.com/hc/en-us/articles/4403541716761-S19j-series-Specifications
- BITMAIN S21 specification: https://support.bitmain.com/hc/en-us/articles/23794895251609-S21-Specification
- BITMAIN S21 Pro user guide: https://file12.bitmain.com/shop-product-s3/firmware/793d284c-4b4c-4c00-bb6b-30f0a4902c96/2025/03/20/17/S21%20Pro%20User%20Guide-V1.1.9.pdf
- BITMAIN S21 Hydro specification: https://support.bitmain.com/hc/en-us/articles/26824251926681-S21-Hyd-Specification
- BITMAIN S21 immersion specification: https://support.bitmain.com/hc/en-us/articles/35746238371097-S21-Imm-Specifications
- Luxor Hashrate Index, power breakevens: https://hashrateindex.com/blog/firmware-features-when-to-mine-when-to-curtail-power-breakevens/
