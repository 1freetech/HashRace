# Hash Race

**Hash Race** is a 2D Bitcoin mining strategy simulation about winning the hardware race.

You begin with slow, inefficient mining hardware and compete against rival mining companies. The goal is to improve hashrate, lower J/TH, control power cost, keep uptime high, fund research, buy better machines, survive changing Bitcoin economics, and reach future hardware milestones before your competitors.

## First playable direction

Hash Race is being built as a **2D Unity game in C#**. The first prototype uses simple built-in UI so the mining simulation can become playable before art, animation, maps, or final menus are added.

The main loop is:

1. Run miners and earn simulated mining revenue.
2. Pay electricity and operating costs.
3. Buy more machines or save cash.
4. Fund R&D to unlock the next ASIC generation.
5. Improve J/TH, hashrate, uptime, cooling, and scale.
6. Race AI mining companies to major milestones.
7. Acquire rivals when they are weak or accept a buyout when the offer is worth it.
8. Progress from TH/s hardware toward PH/s and eventually EH/s-class systems.

## Metrics used by the simulation

- Hashrate in TH/s, PH/s, and EH/s
- Machine efficiency in J/TH
- Power draw in kW and energy use in kWh
- Electricity price in $/kWh
- Uptime
- Bitcoin price
- Network hashrate
- Block subsidy
- Estimated BTC mined per day
- Revenue, power cost, profit, cash, and company value
- R&D progress and hardware generation

The basic power formula is:

`power watts = hashrate TH/s × J/TH`

The basic mining-share model is:

`BTC/day = player hashrate ÷ network hashrate × blocks/day × block subsidy × uptime`

The game will later add difficulty eras, transaction-fee variation, cooling limits, infrastructure, failure rates, financing, hosting, mergers, market cycles, and more detailed rival behavior.

## Prototype controls

The first prototype is code-driven and uses Unity's built-in immediate-mode UI so it can be tested without art assets.

- **Buy Miner** — adds one unit of the currently unlocked ASIC.
- **Fund R&D** — spends cash toward the next hardware generation.
- **Sell Miner** — removes one miner for partial resale value.
- **1x / 5x / 20x** — changes simulation speed.
- **Pause** — stops simulation time.

## Project status

**Prototype 0.01 — simulation foundation.**

The first build focuses on getting the mining math, hardware progression, time simulation, rivals, and business loop working before visual polish.
