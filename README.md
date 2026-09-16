# Hash Race

**Hash Race** is a 2D Bitcoin mining strategy simulation centered on competition between fictional Bitcoin mining companies. The game combines hardware development, facility management, financial strategy, acquisitions, external partnerships, long-term company growth, seasonal competition, and progression through increasingly powerful generations of mining hardware.

The project is designed around the development of a Bitcoin mining company from a smaller operator into a large-scale industrial mining organization. Players manage hashrate, energy efficiency, electricity costs, infrastructure, research, company value, and strategic relationships while competing against rival mining companies.

## Play Hash Race

The current public desktop version is **v0.002**.

- [Download Hash Race v0.002 for Windows x64](https://github.com/1freetech/HashRace/releases/download/v0.002/HashRace-v0.002-windows-x64.zip)
- [Download Hash Race v0.002 for Linux x64](https://github.com/1freetech/HashRace/releases/download/v0.002/HashRace-v0.002-linux-x64.tar.gz)
- [View all Hash Race releases](https://github.com/1freetech/HashRace/releases)

The downloadable desktop version currently remains a self-contained C# prototype so that a playable build is available during the engine migration. The primary visual and gameplay client is being developed in **Godot 4.7.2 using GDScript**. Existing C# simulation systems are retained where they remain useful.

## Game concept

Hash Race is structured around competition between Bitcoin mining companies. All ten playable and rival companies operate as Bitcoin miners, making the central competition miner versus miner.

Organizations from other industries appear as non-player partners rather than competing mining companies. These industries include artificial intelligence, robotics, semiconductors, energy, telecommunications, real estate, finance, infrastructure, quick-service and retail businesses, and sports organizations.

External partners can provide strategic advantages such as improved technology, lower energy costs, automation, additional land, financing, network reliability, sponsorship revenue, commercial income, or infrastructure support.

## Gameplay

A typical Hash Race campaign includes the following activities:

1. Selecting one of ten fictional Bitcoin mining companies with a distinct operating strategy.
2. Operating mining hardware and generating simulated Bitcoin mining revenue.
3. Paying electricity and operating expenses.
4. Purchasing ASIC miners while remaining within facility power limits.
5. Expanding mining-site capacity as infrastructure requirements increase.
6. Funding research and development to improve mining hardware performance and efficiency.
7. Forming partnerships with external organizations in technology, energy, finance, infrastructure, real estate, telecommunications, retail, and sports.
8. Tracking seasonal standings, prestige, company value, mining efficiency, and total hashrate.
9. Acquiring weaker rival mining companies and incorporating their infrastructure and capacity.
10. Progressing from TH/s-scale operations toward PH/s and EH/s-scale mining while developing increasingly efficient hardware.

## Mining companies

Hash Race currently includes ten fictional Bitcoin mining companies. Their names use broader compute, energy, infrastructure, and technology branding rather than directly imitating real-world Bitcoin mining companies.

- **Emberline Compute** — low-cost fleet operator with a larger opening fleet
- **Helix Circuit Labs** — research-first mining operator
- **ArcCurrent Systems** — grid-responsive mining and power-optimization specialist
- **StoneGrid Infrastructure** — land and site expansion specialist
- **Meridian Node Group** — acquisition-focused mining consolidator
- **BlueLoop Compute** — cooling, uptime, and efficiency specialist
- **SignalPeak Systems** — reliability-focused mining operator
- **Parallax Digital Works** — balanced industrial miner
- **Lattice Energy Labs** — efficiency-focused fleet manager
- **Epoch Harbor Holdings** — capital-intensive mining and expansion company

Each company represents a different strategic approach to mining operations, capital allocation, infrastructure growth, energy use, or hardware development.

## External partner market

Non-player organizations can influence the development of a mining company through partnerships and commercial agreements.

- **Artificial intelligence** — research acceleration and compute-related revenue
- **Robotics** — higher uptime and reduced operating costs
- **Semiconductors** — improved J/TH and faster ASIC development
- **Energy** — lower electricity costs
- **Telecommunications** — improved network reliability and uptime
- **Real estate** — land acquisition and site expansion
- **Finance** — improved acquisition and capital economics
- **Infrastructure** — larger facilities and lower expansion costs
- **Quick service and retail** — recurring non-mining commercial revenue
- **Sports** — sponsorship revenue and company prestige

These organizations are part of the broader business environment and are not selectable mining competitors.

## Technology

Hash Race is transitioning to **[Godot](https://godotengine.org/)** as its primary game engine. The current development target is **Godot 4.7.2**.

Godot is a free and open-source game engine distributed under the [MIT License](https://github.com/godotengine/godot). It includes dedicated 2D development tools and officially supports [GDScript, C#, and C++ through GDExtension](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_languages.html).

The project uses a hybrid language structure:

- **GDScript** is used for most gameplay systems, user interface logic, maps, events, and simulation orchestration.
- **C#** is used for existing simulation systems and the transitional downloadable desktop prototype.
- **C++ and GDExtension** are reserved for systems that demonstrate a measurable need for native performance.

Additional information is available in the [engine-direction document](docs/GODOT_DIRECTION.md). Academic and technical references examined during the engine evaluation include [Holfeld 2023/2024](https://arxiv.org/abs/2401.01909) and the [JamSet/JamBench 2026](https://arxiv.org/abs/2606.19830) research project.

## Simulation model

Hash Race models Bitcoin mining operations using a combination of technical and financial variables. Major simulation metrics include:

- Hashrate
- Joules per terahash (J/TH)
- Kilowatts (kW)
- Kilowatt-hours (kWh)
- Electricity price
- Uptime
- Network hashrate
- Block subsidy
- Simulated BTC per day
- Revenue
- Power cost
- Cash
- Company value
- Research and development
- Hardware generation

The basic mining power relationship is represented as:

`power watts = hashrate TH/s × J/TH`

Simulated Bitcoin production is represented as:

`BTC/day = company hashrate ÷ network hashrate × blocks/day × block subsidy × uptime`

Protocol background is available through the [Bitcoin Developer Guide](https://developer.bitcoin.org/devguide/) and the [Bitcoin Developer Reference](https://developer.bitcoin.org/reference/).

## Repository structure

The repository contains the current game client, earlier prototypes, development tools, and supporting documentation.

- `Godot/` — primary Godot 4 game client
- `desktop/HashRace.Desktop/` — self-contained C# transitional desktop build
- `Assets/` — earlier Unity prototype retained as migration and reference code
- `tools/` — automated smoke tests and concept checks
- `.github/workflows/` — automated testing and Windows/Linux desktop release workflows
- `GAME_DESIGN.md` — canonical gameplay design document
- `docs/GODOT_DIRECTION.md` — engine and language decision documentation
- `VERSION` — current public downloadable version

## Development status

Hash Race is under active development. The current public desktop build represents an early playable version while the main gameplay client is being migrated and expanded in Godot.

Development currently focuses on preserving a playable simulation loop while expanding the visual interface, mining-company competition, hardware progression, facility management, partner systems, and long-term strategy mechanics.

## Versioning

Public playable versions begin at **v0.001** and increase by **0.001** for each completed public game update.

A Windows or Linux version is considered publicly available only after its GitHub release asset has been built and verified.
