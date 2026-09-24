# Hash Race — Gameplay Design

## Core idea

**Hash Race** is a 2D Bitcoin mining strategy game about building a mining company across many simulated years. Every selectable company and every league rival is a fictional Bitcoin miner. Other industries exist as non-player partners, suppliers, financiers, landlords, technology firms, utilities, sponsors, and service organizations.

The player competes through hashrate, J/TH, power cost, uptime, land, energized MW, hardware, R&D, financing, BTC treasury policy, partnerships, mergers, company culture, and long-term asset value.

## Non-negotiable company rule

**Playable companies = Bitcoin mining companies. Rival companies = Bitcoin mining companies.**

AI, robotics, semiconductor, energy, telecom, real estate, finance, infrastructure, food/service, sports, and other industries belong to the external NPC economy. They can materially improve a mining company but do not replace the mining-company league.

## Campaign clock

The campaign is selected in years. The default strategic turn is **one month**, but the player can change the live turn length to:

- Day
- Week
- Month
- Quarter

Mining output, power cost, debt interest, recurring income, rival behavior, company-culture development, halvings, and market movement use elapsed days so changing the turn length changes decision frequency rather than changing the underlying economics.

## Primary gameplay pillars

### Mining and infrastructure

Hashrate is constrained by physical power. The player buys ASICs, land, and MW capacity while managing energy cost, uptime, cooling, and machine efficiency.

### Hardware and R&D

The player moves through stronger machine platforms and chip-development stages. R&D, operations quality, supplier relationships, and capital availability influence how quickly the company can improve.

### Capital allocation

Cash competes for machines, sites, power, land, partnerships, research, debt service, treasury accumulation, and mergers. A company can grow quickly and become fragile, or preserve liquidity and lose ground to faster rivals.

### Dynamic company culture

Every mining company starts with a fictional history, a founding controversy, and seven 0–100 ratings:

- Aggression
- Risk
- Growth
- R&D
- Treasury
- Operations
- Reputation

Aggression and Risk determine whether the current posture reads as Aggressive, Moderate, or Conservative. Ratings are not fixed classes. Player actions, rival decisions, profit, losses, debt, expansion, research, partnerships, and controversies move them over time.

Ratings affect gameplay. Operations influences uptime. Treasury and Reputation influence financing. Reputation influences partnership cost. R&D and Operations influence chip-development cost. Growth and Operations influence expansion execution. Aggression and Reputation influence merger negotiation. Aggression and Risk also increase controversy exposure.

### Rival AI

Rivals no longer receive only generic random growth. Each rival uses its current ratings to compare expansion, research, infrastructure, and treasury choices roughly once per in-game month. A formerly aggressive rival can become more conservative after losses, while a disciplined miner can become more expansionary after sustained profitability.

### Partnerships

External partnerships form a second business/technology tree. Utilities, semiconductor firms, infrastructure providers, lenders, land organizations, service companies, sports groups, and digital-finance organizations can change costs, access, assets, recurring income, and treasury strength.

### Company world

The strategy layer is presented through an explorable top-down company world. The representative can walk or pathfind between mining towns, rival headquarters, partner organizations, banks, land markets, ASIC markets, and power offices. The world supports collision-safe movement, scanner navigation, town transit, and interaction dialogue.

## Ten starting Bitcoin mining companies

| Company | Starting identity | Initial posture |
| --- | --- | --- |
| VantaGrid Mining | Power cost + profit | Aggressive |
| NeonForge Mining | Machines + cash | Aggressive |
| ArcShift Mining | MW + power cost | Moderate |
| IronVector Mining | Acres + MW | Conservative |
| Meridian Zero Mining | Cash + financing | Moderate |
| BlueNova Mining | Energy + profit | Conservative |
| SignalFlux Mining | Machines + energy | Moderate |
| Parallax Core Mining | Machines + MW | Aggressive |
| LatticeX Mining | Power cost + machines | Moderate |
| Epoch Vector Mining | Cash + acres | Conservative |

Each company has an original history and controversy that explains its starting ratings. These values form the opening template only; they can diverge substantially during a long campaign.

## Mining economics

Core formulas remain grounded in Bitcoin-mining concepts:

`power watts = hashrate TH/s × J/TH`

`BTC/day = company hashrate ÷ network hashrate × blocks/day × (block subsidy + fees) × uptime`

Electricity, equipment efficiency, uptime, network hashrate, subsidy, fees, Bitcoin price, debt, land, and operating costs determine whether expansion is actually profitable.

## Strategy controls

Where a value represents a game rating or strategic preference, Hash Race uses the universal **0–100 scale** when practical. The BTC hold policy is directly adjustable from 0 to 100 rather than being limited to a few presets.

Real-world units remain real-world units: MW, kW, J/TH, TH/s, PH/s, dollars, sats, acres, interest rates, and elapsed days are not converted into ratings.

## Balance rule

Company culture should create differences, not predetermined winners. v0.021 therefore bounds player culture modifiers to modest ranges. A highly rated company receives useful advantages, but market conditions, power, capital, hardware, and player decisions remain more important than any one personality score.

## Engine architecture

The primary engine is Godot 4.7.2 with GDScript for live gameplay. C#, C++, Rust, TypeScript, and Python remain in the repository for earlier prototypes, native experiments, balance work, validation, and testing where useful.

## Verification

The project uses a source smoke test and a live Godot runtime validator. The validator checks the world, movement, scanner, town population, company representatives, partner representatives, company personality state, 0–100 rating bounds, material culture effects, BTC treasury controls, and two-step turn settlement.

## Current build priorities

1. Keep the miner-versus-miner company model stable.
2. Make company ratings produce understandable consequences in the live economy.
3. Strengthen rival long-term strategy and memory.
4. Improve sprite, building, and town visual quality.
5. Expand facility engineering, rack placement, cooling, substations, and maintenance.
6. Split R&D into deeper engineering branches.
7. Add staff, contracts, negotiation, and management layers.
8. Add multiple sites, regions, and power markets.
9. Add richer league history, rivalries, records, and dynasty systems.
10. Preserve automated boot, smoke, runtime, and release verification as the game expands.
