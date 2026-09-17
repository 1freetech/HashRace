# Hash Race

**Hash Race** is a 2D Bitcoin mining strategy simulation built around competition between fictional Bitcoin mining companies. The game combines hardware deployment, power and land expansion, BTC treasury management, financing, research, partnerships, mergers, company culture, market cycles, and an explorable top-down company world.

The player begins as one of ten mining companies and attempts to build a stronger operation across a multi-year campaign. Rival miners continue making their own decisions while Bitcoin price, network hashrate, energy markets, land values, interest rates, and halvings change around them.

## Play Hash Race

The latest verified public desktop release is **v0.055**.

- **[Windows x64 — Hash Race v0.055](https://github.com/1freetech/HashRace/releases/download/v0.055/HashRace-v0.055-windows-x64.zip)**
- **[Linux x64 — Hash Race v0.055](https://github.com/1freetech/HashRace/releases/download/v0.055/HashRace-v0.055-linux-x64.tar.gz)**
- **[Hash Race v0.055 release page](https://github.com/1freetech/HashRace/releases/tag/v0.055)**
- **[Latest verified release page](https://github.com/1freetech/HashRace/releases/latest)**

v0.055 adds code-generated detailed building facades to the live overworld. Headquarters, partner offices, machine markets, power facilities, banks, and land offices now use transparent procedural pixel textures with roofs, foundations, windows or equipment intakes, doors, masonry or panel detail, shadows, and company-colored accents. The wider campus spacing and proximity-gated labels remain in place so the map stays readable.

The desktop game uses **Godot 4.7.2 and GDScript**. The repository is now moving simulation-heavy state, inventory, mining math, machine generations, research, partnerships, acquisitions, and long-run economic calculations into a tested C++20 core. Large obsolete C# simulation prototypes are being retired instead of maintained in parallel.

## Game structure

All playable companies and league rivals are Bitcoin miners. AI, semiconductor, robotics, energy, telecommunications, finance, real-estate, infrastructure, service, sports, and other companies exist as external NPC organizations that can provide partnerships and strategic advantages.

A campaign includes mining, buying hardware, securing power, acquiring land, improving technology, managing BTC, borrowing and repaying capital, signing external deals, exploring company towns, competing with rivals, and optionally completing one merger.

## Flexible turn system

A campaign is selected in years. The default strategic turn is **one month**, but the live game can switch between:

- **Day**
- **Week**
- **Month**
- **Quarter**

Changing turn length changes how often the player makes decisions. Mining output, power cost, debt interest, recurring income, halvings, market movement, rival behavior, and company-culture development are all scaled by elapsed days so the underlying economics remain consistent.

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

Each miner has a fictional company history, a past controversy, a starting strategy, a representative, and a home town. The histories use common business and mining-industry problems without copying a specific real company.

## Dynamic company personality

Each mining company uses seven ratings on a **0–100 scale**:

- Aggression
- Risk
- Growth
- R&D
- Treasury
- Operations
- Reputation

Aggression and Risk produce the company's current **Aggressive, Moderate, or Conservative** posture. These ratings are not permanent classes. Expansion, debt, research, BTC policy, profitability, partnerships, controversies, and other decisions move them over time.

Rival AI uses the current ratings when deciding whether to expand the fleet, invest in research, add infrastructure, preserve cash, or pursue a partnership. A company can therefore change strategy during a campaign instead of following the same script forever.

### Material gameplay effects

The live ratings affect actual game economics.

- **Operations** modifies effective mining uptime.
- **Treasury + Reputation** modify borrowing rates.
- **Reputation** modifies partnership costs.
- **R&D + Operations** modify chip-development costs.
- **Growth + Operations** modify ASIC, MW, and land expansion costs.
- Very high **Aggression + Risk** can create a rush premium during expansion.
- **Aggression + Reputation** modify merger negotiation costs.
- **Aggression + Risk** increase controversy exposure.

The modifiers are intentionally bounded so company culture shapes strategy without becoming more important than power, hardware, cash, market conditions, or player decisions. Detailed rules are documented in [docs/COMPANY_PERSONALITY_SYSTEM.md](docs/COMPANY_PERSONALITY_SYSTEM.md).

## External partner market

External organizations form a second business and technology tree.

- **Utility / energy** — lower power costs, PPAs, hydro access, clean-power advantages
- **Real estate** — land and site expansion
- **Infrastructure** — MW and interconnect capacity
- **Semiconductors** — machines, efficiency, and hardware discounts
- **Finance** — cash, borrowing capacity, and lower financing friction
- **Food / services** — recurring commercial revenue
- **Sports** — sponsorship and recurring revenue
- **Digital finance** — BTC and sats treasury advantages
- **Telecommunications** — connectivity and operational reliability

These organizations are not mining competitors.

## Mining and market model

Major simulation values include:

- Hashrate
- J/TH
- Machines
- Cooling type
- Machine generation
- Machine condition and utilization
- kW and MW
- Electricity price
- Land and acres
- Uptime
- BTC price
- Network hashrate
- Block subsidy and fees
- Sats and BTC treasury
- Cash and debt
- Federal interest rate
- Partner income
- Company assets
- Company culture ratings

The basic power relationship is:

`power watts = hashrate TH/s × J/TH`

Simulated Bitcoin production is:

`BTC/day = company hashrate ÷ network hashrate × blocks/day × (block subsidy + fees) × uptime`

Additional economic assumptions are documented in [docs/ECONOMY_MODEL.md](docs/ECONOMY_MODEL.md).

## BTC treasury strategy

The BTC hold policy uses the game's universal strategy scale and is adjustable from **0 to 100** in one-point steps. The player can therefore choose any hold/sell balance instead of selecting from a small set of presets.

Treasury controls remain tied to the flexible turn system so projected income and liquidity use the currently selected day/week/month/quarter duration.

## Financing

Lending begins with expensive small-business debt and progresses toward larger commercial, infrastructure, state, and federal financing as asset value increases.

Loan pricing moves with the simulated Federal rate. Company Treasury and Reputation ratings also affect the live borrowing rate, representing lender confidence and financial discipline.

## Company world

Hash Race uses an explorable top-down pixel-style company world. The map contains mining towns, rival headquarters, partner companies, ASIC markets, land markets, banks, power offices, roads, water, substations, solar infrastructure, and cooling infrastructure.

The representative can move with keyboard controls or click-to-pathfind around blocked map cells. The scanner overlay displays nearby reachable grid cells. Town transit allows fast travel between mining-company districts.

## Controls

- **WASD / Arrow keys** — walk
- **Left click open ground** — pathfind to a reachable location
- **E / Enter / Space** — interact
- **T** — travel between mining towns
- **R** — toggle scanner grid
- **C** — cycle Day / Week / Month / Quarter turn length
- **Q** — preview the current turn before settlement
- **Turn Length control** — cycle Day / Week / Month / Quarter
- **END TURN** — preview and then confirm settlement for the selected turn length
- **BTC Hold slider** — set the hold policy anywhere from 0–100

## Technology

Hash Race uses **Godot** as its primary engine. The repository uses a hybrid development stack:

- **GDScript** — live gameplay, UI, world, simulation orchestration, rival AI, and company culture
- **C++20** — typed simulation core for mining math, machine catalogs, fleet inventory, cooling, company state, market state, BTC treasury, research, partnerships, acquisitions, season progression, and future high-volume simulation work
- **Rust** — deterministic balance and simulation experiments
- **TypeScript** — validation tooling
- **Python** — source smoke tests
- **C#** — only small legacy Unity/editor remnants remain; the large duplicate simulation prototypes have been retired

The C++ share is intended to grow as the simulation becomes heavier, while GDScript remains the practical presentation and orchestration layer. More information is available in [docs/GODOT_DIRECTION.md](docs/GODOT_DIRECTION.md) and [docs/LANGUAGE_STACK.md](docs/LANGUAGE_STACK.md).

## Repository structure

- `Godot/` — primary live Godot game
- `native/cpp/` — C++20 simulation, inventory, catalogs, math, and native test gate
- `native/rust/` — deterministic balance experiments
- `Assets/` — small remaining Unity/editor migration reference; the large Unity C# simulation has been removed
- `tools/` — smoke tests and validation utilities
- `.github/workflows/` — automated test and release workflows
- `GAME_DESIGN.md` — canonical gameplay design
- `docs/` — technical and gameplay documentation
- `VERSION` — current public/development version marker

## C++ simulation migration

The native C++ core is deliberately dependency-free so it can be compiled quickly in CI and later exposed to Godot through GDExtension without rewriting the simulation again. Current native types include:

- machine generations with TH/s, J/TH, purchase price, research cost, and supported cooling
- fleet inventory slots by generation, cooling, machine count, condition, and utilization
- real-unit company state for cash, BTC, MW, hash rate, efficiency, research, acquisitions, and days/seasons
- universal 0–100 company strategy settings
- market state for BTC price, network hash rate, subsidy, and electricity price
- rival company state and valuation
- daily ledger output for mined BTC, sold BTC, held BTC, mining revenue, partner revenue, electricity, operations, and net cash change

The migration keeps real measurements in real units rather than forcing values such as MW, TH/s, BTC, dollars, or J/TH into the 0–100 rating scale.

## Verification

The repository uses several layers of verification. Source smoke tests check required gameplay contracts and files. A live Godot runtime validator boots the company world and checks movement, pathfinding, scanner navigation, company and partner populations, BTC treasury controls, flexible turn confirmation, company personality state, 0–100 rating bounds, and material company-culture modifiers.

The native C++ gate compiles the simulation with C++20, `-Wall -Wextra -Werror -pedantic`, then tests mining math, inventory, cooling, strategy bounds, purchases, research unlocks, BTC treasury behavior, and season advancement. Release workflows separately support Windows/Linux Godot exports and playable-build verification.

## Development direction

Current development priorities include stronger company strategy, improved rival memory, deeper mining-facility engineering, more detailed R&D, better town and character artwork, additional management systems, multiple regions and power markets, and longer-term league history.

The C++ core is intended to absorb the most data-heavy and simulation-heavy systems over time, especially large machine inventories, long-horizon economy simulation, rival-company state, detailed equipment health, and high-volume stat calculations. GDScript remains the fast iteration layer for scenes, visuals, UI, interactions, and game-world orchestration.

## Versioning

Development versions use the `v0.001` format and increase by `0.001` for each completed repository/game update. A version is considered a public downloadable release only after its release assets have been built and published. Every completed public release must have its verified Windows and Linux download links refreshed in this README.
