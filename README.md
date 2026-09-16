# Hash Race

**Hash Race** is a 2D Bitcoin mining strategy simulation centered on competition between fictional Bitcoin mining companies. The game combines hardware development, facility management, financial strategy, acquisitions, external partnerships, long-term company growth, quarterly competition, and progression through increasingly powerful generations of mining hardware.

The project follows a mining company from a small operator into a large-scale industrial organization. Players manage hashrate, energy efficiency, electricity costs, infrastructure, research, company value, financing, land, power and strategic relationships while competing against rival mining companies.

## Play Hash Race

The current public desktop version is **v0.014**.

- **[Download the latest playable Hash Race release](https://github.com/1freetech/HashRace/releases/latest)**
- [Download Hash Race v0.014 for Windows x64](https://github.com/1freetech/HashRace/releases/download/v0.014/HashRace-v0.014-windows-x64.zip)
- [Download Hash Race v0.014 for Linux x64](https://github.com/1freetech/HashRace/releases/download/v0.014/HashRace-v0.014-linux-x64.tar.gz)
- [View all Hash Race releases](https://github.com/1freetech/HashRace/releases)

The primary **latest release** link always points to GitHub's `/releases/latest` page, so it automatically follows the newest public playable build. The explicit version and platform links above are updated with each public release.

The downloadable desktop game is built in **Godot 4.7.2 using GDScript**. Windows and Linux builds are exported from the same live Godot project used by the current company-world gameplay. Earlier C# and Unity prototypes remain in the repository only as migration and reference material where useful.

## Game concept

Hash Race is structured around competition between Bitcoin mining companies. All ten playable and rival companies operate as Bitcoin miners.

Organizations from other industries appear as non-player partners rather than competing mining companies. These industries include artificial intelligence, robotics, semiconductors, energy, telecommunications, real estate, finance, infrastructure, quick-service and retail businesses, and sports organizations.

External partners can provide strategic advantages such as improved technology, lower energy costs, additional machines, better efficiency, automation, additional land, financing, network reliability, sponsorship revenue, commercial income, or infrastructure support.

## Gameplay

A typical Hash Race campaign includes the following activities:

1. Selecting one of ten fictional Bitcoin mining companies with distinct starting strengths.
2. Choosing a fixed campaign clock from 1 year / 4 turns through 20 years / 80 turns.
3. Walking a top-down company-world map as a company representative.
4. Visiting rival firms, banks, ASIC markets, land markets, utilities and partner organizations.
5. Purchasing ASIC miners while remaining within energized power limits.
6. Buying land and adding MW capacity as the company expands.
7. Selecting and upgrading energy, cooling and chip strategies.
8. Forming partnerships with technology, energy, finance, infrastructure, real-estate, service and sports organizations.
9. Managing debt, cash, sats, BTC treasury policy and changing market conditions.
10. Competing with rival mining companies and optionally completing one merger during the campaign.
11. Ending a quarter only after the player is ready to advance the simulation.

One turn equals one quarter. Four turns equal one year. The game models a halving every 16 turns, or approximately four in-game years.

## Mining companies

Hash Race currently includes ten fictional Bitcoin mining companies:

- **VantaGrid Mining** — power-cost and profitability strength
- **NeonForge Mining** — machines and opening cash strength
- **ArcShift Mining** — MW capacity and power-cost strength
- **IronVector Mining** — land and MW infrastructure strength
- **Meridian Zero Mining** — cash and financing strength
- **BlueNova Mining** — energy and profitability strength
- **SignalFlux Mining** — machines and energy strength
- **Parallax Core Mining** — machines and MW capacity strength
- **LatticeX Mining** — power-cost and machine strength
- **Epoch Vector Mining** — cash and land strength

Each company has its own town/HQ identity and representative. Representatives use original futuristic techwear and single-eye scanner visors.

## External partner market

Non-player organizations influence company growth through partnerships and commercial agreements.

- **Utility and energy** — cheaper electricity, PPAs, hydro access and clean-power advantages
- **Real estate** — additional land and lower future land costs
- **Infrastructure** — more MW capacity and cheaper future interconnect work
- **Semiconductors** — additional machines, fleet-efficiency gains and machine discounts
- **Finance** — more cash and improved borrowing terms
- **Food and services** — recurring commercial income
- **Sports** — sponsorship and recurring income
- **Digital finance** — treasury and sats-related advantages

These organizations are part of the wider business environment and are not selectable mining competitors.

## Financing and markets

The lender ladder begins with **Local Joker Bank**, a small high-cost lender, and progresses toward larger lower-spread commercial, infrastructure, state and federal financing sources as company assets increase.

Loan pricing is influenced by the simulated Federal rate. BTC price, land value and energy markets also move over time. Rare market shocks can affect BTC and land differently, including technology-style crashes and property/logistics-style crashes.

Asset value influences borrowing capacity. Land, cash, sats, machines, MW capacity and company development all contribute to the financing model.

## Visual, map and movement system

Hash Race uses a tile-built pixel world rather than relying only on large procedural debug rectangles. Roads, water, company lots, plazas and terrain are aligned to a logical map grid and use compact four-shade material palettes for stronger handheld-RPG readability.

The live map includes original pixel-style mining facilities, company representatives, scanner visors, solar and substation props, grid navigation and tile-aware company districts. Nearest-neighbor texture filtering is used so future sprite and tileset artwork remains sharp.

Version **v0.014** adds collision-safe RPG movement and a real scanner navigation layer. Keyboard movement respects blocked map cells, the company representative tracks up/down/left/right facing state, interactions turn the representative toward the nearby company/NPC, and the scanner visor can display nearby reachable grid cells with **R**. Click-to-walk uses four-direction A* routing with compressed straight-line waypoints.

The RPG movement helper adapts CC0 code structure from **Python-Monsters** by Clear Code Projects. Small map-painting helpers are adapted from **GB Studio** under the MIT license. Isolated tile editing operations are adapted from **Tilemap Studio** under LGPL-3.0. Licensing and attribution details are documented in [docs/THIRD_PARTY_TILEMAP.md](docs/THIRD_PARTY_TILEMAP.md) and [docs/RPG_STRATEGY_REFERENCES.md](docs/RPG_STRATEGY_REFERENCES.md).

The project also studies grid/pathfinding and turn-system architecture from LawlessPlay's Gridbased Pathfinding Tutorial, tutorial-work's Unity Turn-Based Strategy Game, and Battle for Wesnoth. Code from unlicensed or GPL reference projects is not copied into the Hash Race runtime; equivalent Hash Race systems are implemented independently.

## Technology

Hash Race uses **[Godot](https://godotengine.org/)** as its primary game engine. The current development target is **Godot 4.7.2**.

Godot is a free and open-source game engine distributed under the MIT License. The project uses a hybrid language structure:

- **GDScript** — live gameplay systems, interface logic, maps, events, navigation and simulation orchestration
- **C#** — older simulation/prototype systems retained for reference
- **C++** — selected mining-core logic and native-performance experiments
- **Rust** — deterministic/offline balance simulation work
- **TypeScript** — content and data validation tooling
- **Python** — dependency-free contract and smoke tests

Additional information is available in [docs/GODOT_DIRECTION.md](docs/GODOT_DIRECTION.md) and [docs/LANGUAGE_STACK.md](docs/LANGUAGE_STACK.md).

## Simulation model

Major simulation metrics include:

- Hashrate
- Joules per terahash (J/TH)
- Kilowatts and megawatts
- Electricity price
- Machines
- Land / acres
- Energy source
- Uptime
- Network hashrate
- Block subsidy and fees
- Sats and BTC value
- BTC market price
- Land market price
- Federal rate
- Revenue and power cost
- Cash and debt
- Company assets
- Partner boosts

The basic mining power relationship is:

`power watts = hashrate TH/s × J/TH`

Simulated Bitcoin production is:

`BTC/day = company hashrate ÷ network hashrate × blocks/day × (block subsidy + fees) × uptime`

Additional assumptions are documented in [docs/ECONOMY_MODEL.md](docs/ECONOMY_MODEL.md).

## Controls

- **WASD / Arrow keys** — walk
- **Left click open ground** — route to a reachable location
- **E / Enter / Space** — interact with a nearby company, representative or building
- **T** — travel to the next mining-company town
- **R** — toggle the scanner reachable-grid overlay
- **END QUARTER** — advance the company simulation by one quarter

## Repository structure

- `Godot/` — primary Godot 4 game client
- `desktop/HashRace.Desktop/` — earlier C# desktop prototype retained for reference
- `Assets/` — earlier Unity prototype retained as migration/reference code
- `native/` — C++ and Rust simulation experiments
- `tools/` — automated smoke tests and content checks
- `.github/workflows/` — automated testing and Windows/Linux release workflows
- `GAME_DESIGN.md` — canonical gameplay design document
- `docs/` — engine, economy, language, design and third-party-code documentation
- `VERSION` — current public downloadable version

## Verification

Public builds are checked with source boot tests, a live overworld runtime validator, Python/C++/Rust/TypeScript checks, Windows/Linux exports, an exported Linux executable boot and an actual rendered gameplay screenshot. The rendered-frame test exists specifically to prevent a blank world from being published as a successful build.

## Development status

Hash Race is under active development. The current focus is replacing remaining procedural placeholders with stronger sprite/tile artwork, improving company-town composition, animating representatives, adding richer NPC/company memory, expanding building interiors and strengthening the turn-based business strategy layer underneath the explorable RPG world.

## Versioning

Public playable versions begin at **v0.001** and increase by **0.001** for each completed public game update.

A Windows or Linux version is considered publicly available only after its GitHub release asset has been built and verified. The README's primary download link remains the stable **latest release** URL so players are not sent to an outdated build.
