# Hash Race

**Hash Race** is a 2D Bitcoin mining strategy simulation built around competition between fictional Bitcoin mining companies. The game combines hardware deployment, power and land expansion, BTC treasury management, financing, research, partnerships, mergers, company culture, market cycles, and an explorable top-down company world.

## Play Hash Race

The latest verified public desktop release is **v0.064**.

- **[Windows x64 — Hash Race v0.064](https://github.com/1freetech/HashRace/releases/download/v0.064/HashRace-v0.064-windows-x64.zip)**
- **[Linux x64 — Hash Race v0.064](https://github.com/1freetech/HashRace/releases/download/v0.064/HashRace-v0.064-linux-x64.tar.gz)**
- **[Hash Race v0.064 release page](https://github.com/1freetech/HashRace/releases/tag/v0.064)**
- **[Latest verified release page](https://github.com/1freetech/HashRace/releases/latest)**

v0.064 adds the first comprehensive infrastructure inventory foundation. The live Godot game has a categorized 30-asset equipment catalog covering mining hardware, power, energy, cooling, facilities, networking, maintenance, resilience, and strategic supply. Equipment is functional rather than decorative: purchases can change PH/s, MW, uptime, fleet efficiency, power cost, machine capacity, operating cost, equipment discounts, and risk protection. The release also retains the detailed pixel data-center infrastructure graphics pass.

The desktop game uses **Godot 4.7.2 and GDScript**. The repository preserves useful native simulation work for heavier systems while Godot remains the primary gameplay, UI, map, event, and franchise client.

## Game structure

All playable companies and league rivals are Bitcoin miners. AI, semiconductor, robotics, energy, telecommunications, finance, real-estate, infrastructure, service, sports, and other companies exist as external NPC organizations that can provide partnerships and strategic advantages.

A campaign includes mining, buying hardware, securing power, acquiring land, improving technology, managing BTC, borrowing and repaying capital, signing external deals, exploring company towns, competing with rivals, and optionally completing one merger.

## Five headline company metrics

The league comparison card uses five real-unit headline metrics while preserving deeper simulation statistics:

- **Hashrate** — PH/s or EH/s
- **Power capacity** — MW
- **Fleet efficiency** — J/TH
- **Cash** — dollars
- **Profit** — dollars per selected period

Electricity price, uptime, BTC holdings, debt, land, machine count and generations, assets, research, staff, partnerships, cooling, financing, and other detailed values remain part of the simulation.

## Infrastructure inventory

The live infrastructure catalog currently contains **30 functional assets** across nine categories: miners, power, energy, cooling, facilities, network, maintenance, resilience, and strategic supply. Examples include ASIC racks, transformers, switchgear, PDUs, gas and hydro turbines, batteries, immersion cooling, mining containers, modular halls, fiber, monitoring servers, repair equipment, backup generation, fire/security equipment, and semiconductor supply investments.

The inventory is data-driven so future updates can expand beyond 30 items without building a separate system for each object. Owned quantities are tracked separately from item definitions and inventory state supports serialization. Visual development will progressively give major infrastructure items their own original pixel representations in the world.

## Flexible turn system

The default strategic turn is **one month**, but the live game supports three clear time references:

- **Day** — one turn represents one day
- **Month** — one turn represents one average month
- **Year** — one turn represents one year

Changing turn length changes how often the player makes decisions, not the economic rules. Mining output, power cost, debt interest, recurring income, halvings, market movement, rival behavior, and company-culture development remain scaled by elapsed days.

## Ten Bitcoin mining companies

Hash Race currently includes ten fictional Bitcoin mining companies:

- **VantaGrid Mining** — power-cost and profitability strength
- **NeonForge Mining** — machines and opening cash strength
- **ArcShift Mining** — MW capacity and power-cost strength
- **IronVector Mining** — land and MW infrastructure strength
- **Meridian Zero Mining** — cash and financing strength
- **BlueNova Mining** — energy and profitability strength
- **SignalFlux Mining** — machines and operating reliability strength
- **Parallax Core Mining** — machines and MW capacity strength
- **LatticeX Mining** — efficiency, machines, and research strength
- **Epoch Vector Mining** — cash and land strength

External organizations are never league mining-company archetypes.

## Negotiations

Mining-company merger negotiations use a probabilistic acceptance system. Offer strength, relative company size, reputation, and aggression contribute to a visible 1–99% acceptance chance with LONG SHOT, UNLIKELY, MEDIUM, LIKELY, and VERY LIKELY bands. The game still performs a random roll, so a strong offer can occasionally fail and a long-shot offer can occasionally succeed.

## Controls

- **WASD / Arrow keys** — walk
- **Left click open ground** — pathfind
- **E / Enter / Space** — interact
- **T** — travel between mining towns
- **R** — toggle scanner grid
- **1** — Day turns
- **2** — Month turns
- **3** — Year turns
- **C** — cycle Day / Month / Year
- **Q** — preview the current turn
- **END TURN** — preview and confirm settlement
- **BTC Hold slider** — set hold policy from 0–100
- **INFRASTRUCTURE** — browse the functional equipment inventory

## Technology

Hash Race uses **Godot** as its primary engine:

- **GDScript** — live gameplay, UI, maps, events, franchise systems, inventory presentation, rival AI, and company culture
- **C++20** — retained for measured simulation-heavy work and future GDExtension integration
- **C#** — useful legacy prototype code remains only where it still saves migration time
- **Python / TypeScript / Rust** — validation and simulation experiments where useful

## Mining model

Real measurements remain in real units. The basic power relationship is:

`power watts = hashrate TH/s × J/TH`

Simulated Bitcoin production is:

`BTC/day = company hashrate ÷ network hashrate × blocks/day × (block subsidy + fees) × uptime`

## Verification

The repository uses source smoke tests, live Godot runtime validation, native simulation checks, and Windows/Linux export verification. A version is considered a public downloadable release only after its release assets are built and published.

## Versioning

Development versions use the `v0.001` format and increase by `0.001` for each completed repository/game update. Every completed public release must have its verified Windows and Linux download links refreshed in this README.
