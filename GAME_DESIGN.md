# Hash Race — Gameplay Design

## Core idea

Hash Race is a 2D Bitcoin mining strategy game about building the strongest mining company over many simulated years. Every selectable company and every league rival is a Bitcoin miner. The player competes on hashrate, J/TH, power cost, uptime, facilities, R&D, capital allocation, partnerships, acquisitions, and long-term company value.

The game uses original companies, art, names, maps, events, interfaces, and rules. Its broad design influences come from empire strategy, property/deal games, hardware evolution, life-sim management, city-building infrastructure, and sports franchise modes.

## Non-negotiable company rule

**Playable companies = Bitcoin mining companies. Rival companies = Bitcoin mining companies.**

AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, food/retail, and sports organizations belong to the external NPC partnership economy. They can become suppliers, sponsors, landlords, financiers, technology allies, customers, or strategic partners, but they are not part of the starting mining league.

## Primary gameplay pillars

### Long technology race

The player moves through Garage, Industrial ASIC, Infrastructure, Hyperscale, and Exahash eras. Rivals continue to improve while the player makes decisions. R&D should eventually split into silicon, boards, PSU/power delivery, firmware, cooling, packaging, networking, reliability, and facility design.

### Property, deals, and acquisitions

Money competes for ASICs, sites, land, expansion, partnerships, research, debt service, and acquisitions. Buying another miner can change the standings immediately but can also leave the player overleveraged or stuck with inefficient hardware.

### Physical infrastructure

Hashrate is limited by physical power and cooling. Sites have MW limits. Future maps add substations, transformers, PDUs, cooling, water, network capacity, rack/floor space, repair areas, staff, reliability, local power prices, and multiple regions.

### Hardware evolution

ASIC generations should feel collectible and exciting while remaining grounded in mining metrics. Machines move from inefficient TH/s-class hardware toward PH/s and EH/s-class systems while J/TH declines. The player chooses when to keep old hardware, sell it, repurpose it, or retire it.

### Franchise mode

Mining companies compete like franchises in a league. Track seasons, standings, company value, hashrate, J/TH, prestige/OVR, rivalries, historical records, staff, budgets, owner goals, awards, engineering talent, scouting, contracts, and dynasty records.

### Living world

World events create outages, grid opportunities, site deals, financing, component shortages, maintenance failures, sponsor offers, network problems, and technology breakthroughs. Future top-down maps can let the player inspect facilities, walk a campus, visit partner locations, and interact with engineers and executives without turning the game into an action game.

## Ten starting Bitcoin mining companies

| Company | Mining identity | Main starting advantage |
| --- | --- | --- |
| BlockForge Mining | Low-cost operator | Cheaper power and larger opening fleet |
| Northstar Hash | R&D miner | Faster research |
| VoltHash Mining | Grid optimizer | Lower effective electricity burden |
| TerraHash Industries | Site scaler | More land/capacity leverage |
| Frontier Mining Co. | Consolidator | More cash and cheaper acquisitions |
| HydroBlock Mining | Cooling specialist | Higher uptime and better initial efficiency |
| IronPeak Digital Mining | Reliability operator | Better uptime and stable operations |
| Atlas Hashworks | Balanced industrial miner | Small advantages across several systems |
| Cascade Mining Systems | Efficiency specialist | Best opening J/TH profile |
| DeepCore Bitcoin Mining | Capital-heavy scaler | More cash and site-growth leverage |

The player selects one. The other nine remain active AI-controlled Bitcoin mining competitors.

## External NPC partnerships

Partnerships are effectively a second technology/business tree. They must change real game systems.

### AI — NeuralPeak AI
- Faster R&D
- Compute-contract revenue
- Future predictive maintenance and market-forecast tools

### Robotics — Atlas Robotics
- Higher uptime
- Lower operations cost
- Future autonomous inspection and repair

### Semiconductor — SilicaWorks Foundry
- Better effective J/TH
- Faster ASIC research
- Future node/process access and tape-out events

### Energy — VoltRiver Energy
- Lower electricity price
- Grid-response opportunities
- Future PPAs, storage, generation, curtailment, and heat reuse

### Telecom — FiberGrid Communications
- Higher network uptime
- Future carrier redundancy, private fiber, latency, and outage systems

### Real Estate — MetroLand Development
- Cheaper land/site expansion
- More usable capacity
- Future leases, zoning, taxes, land appreciation, and property portfolios

### Finance — Frontier Capital
- Cheaper acquisitions and better deal access
- Future debt, equity, IPOs, covenants, and takeover financing

### Infrastructure — SkyStack Infrastructure
- Larger sites and cheaper expansions
- Future modular data centers, substations, construction schedules, and commissioning

### Quick Service / Retail — QuickBite Franchise Network
- Recurring non-mining cash flow
- Brand visibility
- Future franchise, location, sponsorship, and heat-reuse opportunities

### Sports — Pro Sports Alliance
- Sponsorship revenue
- Franchise prestige
- Future team/league partnerships, naming rights, seasonal marketing, and venue deals

## Mining economics

Core formulas remain grounded in mining concepts:

`power watts = hashrate TH/s × J/TH`

`BTC/day = company hashrate ÷ network hashrate × blocks/day × block subsidy × uptime`

Electricity, uptime, equipment efficiency, network hashrate, block subsidy, Bitcoin price, fees, and operating costs determine whether capacity is actually profitable.

## Engine architecture

The primary engine is **Godot 4.7.2 stable**. Most new gameplay work should use GDScript because it is tightly integrated with Godot and fast to iterate. Existing useful C# systems are preserved and can be ported or integrated. C++ through GDExtension is reserved for measured performance bottlenecks.

This is intentionally a hybrid migration. Gameplay quality and iteration speed matter more than rewriting working systems just to use one language everywhere.

References:

- https://github.com/godotengine/godot
- https://godotengine.org/download/archive/
- https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_languages.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html
- https://arxiv.org/abs/2401.01909
- https://arxiv.org/abs/2606.19830

## Dynasty goals

Hash Race should not have only one victory screen. Long-term goals include becoming #1 by company value, reaching 1 PH/s, 10 PH/s, 100 PH/s and 1 EH/s, unlocking sub-10/sub-5/sub-1 J/TH hardware, building multiple strategic partnerships, acquiring rivals, surviving downturns, and setting long-term season records.

## Immediate build order

1. Keep the corrected miner-versus-miner company model stable.
2. Make the Godot build directly playable and visually readable.
3. Add a real top-down facility map and rack placement.
4. Split R&D into engineering branches.
5. Give rival miners stronger personalities and long-term strategies.
6. Add staff/front-office management and contracts.
7. Add multiple sites, regions, and power markets.
8. Add negotiation, debt, sellout, and takeover systems.
9. Add season history, awards, rivalries, and dynasty records.
10. Add mobile-friendly UI after the desktop loop is proven.
