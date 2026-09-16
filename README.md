# Hash Race

**Hash Race** is a 2D Bitcoin mining strategy simulation centered on competition between fictional Bitcoin mining companies. The game combines hardware development, facility management, financial strategy, acquisitions, external partnerships, long-term company growth, quarterly competition, and progression through increasingly powerful generations of mining hardware.

The project is designed around the development of a Bitcoin mining company from a smaller operator into a large-scale industrial mining organization. Players manage hashrate, energy efficiency, electricity costs, infrastructure, research, company value, and strategic relationships while competing against rival mining companies.

## Play Hash Race

The current public desktop version is **v0.006**.

- **[Download the latest playable Hash Race release](https://github.com/1freetech/HashRace/releases/latest)**
- [Download Hash Race v0.006 for Windows x64](https://github.com/1freetech/HashRace/releases/download/v0.006/HashRace-v0.006-windows-x64.zip)
- [Download Hash Race v0.006 for Linux x64](https://github.com/1freetech/HashRace/releases/download/v0.006/HashRace-v0.006-linux-x64.tar.gz)
- [View all Hash Race releases](https://github.com/1freetech/HashRace/releases)

The primary **latest release** link above always points to GitHub's `/releases/latest` page, so it automatically follows the newest public playable build. Whenever a new public version is published, the explicit version number and platform-specific links in this section should also be updated.

The current downloadable desktop game is built in **Godot 4.7.2 using GDScript**. Windows and Linux builds are exported from the same live Godot project that contains the current company-world gameplay. Earlier C# and Unity prototypes remain in the repository only as migration and reference material where useful.

## Game concept

Hash Race is structured around competition between Bitcoin mining companies. All ten playable and rival companies operate as Bitcoin miners, making the central competition miner versus miner.

Organizations from other industries appear as non-player partners rather than competing mining companies. These industries include artificial intelligence, robotics, semiconductors, energy, telecommunications, real estate, finance, infrastructure, quick-service and retail businesses, and sports organizations.

External partners can provide strategic advantages such as improved technology, lower energy costs, automation, additional land, financing, network reliability, sponsorship revenue, commercial income, or infrastructure support.

## Gameplay

A typical Hash Race campaign includes the following activities:

1. Selecting one of ten fictional Bitcoin mining companies with a distinct operating strategy.
2. Choosing a fixed campaign clock from 1 year / 4 turns through 20 years / 80 turns.
3. Walking a top-down company-world map as a company representative and visiting rival firms, banks, markets, utilities, and partner organizations.
4. Operating mining hardware and generating simulated Bitcoin mining revenue.
5. Paying electricity and operating expenses.
6. Purchasing ASIC miners while remaining within facility power limits.
7. Buying land and expanding mining-site capacity as infrastructure requirements increase.
8. Forming partnerships with external organizations in technology, energy, finance, infrastructure, real estate, telecommunications, retail, and sports.
9. Managing financing, debt, energy contracts, cooling, chips, treasury policy, and market conditions.
10. Competing with rival mining companies, with one merger available during a campaign.

## Mining companies

Hash Race currently includes ten fictional Bitcoin mining companies. Their names use broader compute, energy, infrastructure, and technology branding rather than directly imitating real-world Bitcoin mining companies.

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

Each company represents a different strategic approach to mining operations, capital allocation, infrastructure growth, energy use, or hardware development.

## External partner market

Non-player organizations can influence the development of a mining company through partnerships and commercial agreements.

- **Utility and energy** — cheaper electricity, PPAs, hydro access, and clean-power advantages
- **Real estate** — additional land and lower future land costs
- **Infrastructure** — more MW capacity and cheaper future interconnect work
- **Semiconductors** — additional machines, fleet-efficiency gains, and machine discounts
- **Finance** — more cash and improved borrowing terms
- **Food and services** — recurring commercial income
- **Sports** — sponsorship and recurring income
- **Digital finance** — treasury and sats-related advantages

These organizations are part of the broader business environment and are not selectable mining competitors.

## Technology

Hash Race uses **[Godot](https://godotengine.org/)** as its primary game engine. The current development target is **Godot 4.7.2**.

Godot is a free and open-source game engine distributed under the [MIT License](https://github.com/godotengine/godot). It includes dedicated 2D development tools and officially supports [GDScript, C#, and C++ through GDExtension](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_languages.html).

The project uses a hybrid language structure:

- **GDScript** is used for the live gameplay systems, user interface logic, maps, events, navigation, and simulation orchestration.
- **C#** is retained for older simulation/prototype systems that remain useful as reference material.
- **C++** is used for selected mining-core logic and native-performance experiments.
- **Rust** is used for deterministic/offline balance simulation work.
- **TypeScript** is used for content and data validation tooling.

Additional information is available in the [engine-direction document](docs/GODOT_DIRECTION.md).

## Simulation model

Hash Race models Bitcoin mining operations using a combination of technical and financial variables. Major simulation metrics include:

- Hashrate
- Joules per terahash (J/TH)
- Kilowatts (kW)
- Kilowatt-hours (kWh)
- Electricity price
- MW capacity
- Machines
- Land / acres
- Energy source
- Uptime
- Network hashrate
- Block subsidy
- Simulated BTC and sats
- BTC market price
- Land market price
- Federal rate
- Revenue
- Power cost
- Cash
- Debt
- Company assets
- Partner boosts

The basic mining power relationship is represented as:

`power watts = hashrate TH/s × J/TH`

Simulated Bitcoin production is represented as:

`BTC/day = company hashrate ÷ network hashrate × blocks/day × (block subsidy + fees) × uptime`

Protocol background is available through the [Bitcoin Developer Guide](https://developer.bitcoin.org/devguide/) and the [Bitcoin Developer Reference](https://developer.bitcoin.org/reference/).

## Repository structure

The repository contains the current game client, earlier prototypes, development tools, and supporting documentation.

- `Godot/` — primary Godot 4 game client
- `desktop/HashRace.Desktop/` — earlier C# desktop prototype retained for reference
- `Assets/` — earlier Unity prototype retained as migration and reference code
- `native/` — C++ and Rust simulation experiments
- `tools/` — automated smoke tests and content checks
- `.github/workflows/` — automated testing and Windows/Linux desktop release workflows
- `GAME_DESIGN.md` — canonical gameplay design document
- `docs/` — engine, economy, language, and design documentation
- `VERSION` — current public downloadable version

## Development status

Hash Race is under active development. The current public build uses the live Godot client and includes the company-selection screen, fixed quarterly campaign clock, top-down company world, rival and partner representatives, machine/land/power markets, financing, energy choices, mergers, market movement, and verified Windows/Linux exports.

Current development is focused heavily on improving the world presentation: replacing debug-style procedural geometry with stronger tile/sprite-based towns, better map composition, clearer company identity, richer NPC behavior, collision/pathfinding, and a more polished RPG-style interface.

## Versioning

Public playable versions begin at **v0.001** and increase by **0.001** for each completed public game update.

A Windows or Linux version is considered publicly available only after its GitHub release asset has been built and verified. The README's primary download link must always remain the stable **latest release** URL so players are not sent to an outdated build.
