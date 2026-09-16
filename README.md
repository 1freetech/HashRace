# Hash Race

**Hash Race** is a 2D Bitcoin mining strategy simulation about winning the hardware race. The design combines long-form technology strategy, business acquisitions, hardware evolution, facility management, life-sim choices, and sports-franchise-style seasons, standings, budgets, rivalries, progression, legacy, and dynasty goals.

## Play Hash Race

Current public desktop version: **v0.002**

- [Download Hash Race v0.002 for Windows x64](https://github.com/1freetech/HashRace/releases/download/v0.002/HashRace-v0.002-windows-x64.zip)
- [Download Hash Race v0.002 for Linux x64](https://github.com/1freetech/HashRace/releases/download/v0.002/HashRace-v0.002-linux-x64.tar.gz)
- [View all Hash Race releases](https://github.com/1freetech/HashRace/releases)

The downloadable desktop build remains a self-contained C# prototype so the game stays playable during the engine migration. The primary visual/gameplay client is now being built in **Godot 4.7.2 + GDScript**. Working C# simulation logic is being preserved where useful instead of being discarded.

## Corrected game concept

**All ten playable and rival companies are Bitcoin mining companies.** The race is miner versus miner.

AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, quick-service/retail, and sports organizations are **outside NPC partners**. They can provide technology, cheaper power, automation, land, capital, connectivity, sponsorships, commercial revenue, or other strategic advantages, but they are not selectable mining competitors.

## Current playable loop

1. Choose one of ten fictional Bitcoin mining companies with a different mining strategy.
2. Run miners and earn simulated Bitcoin mining revenue.
3. Pay electricity and operating costs.
4. Buy ASICs while staying inside facility power limits.
5. Expand site capacity when infrastructure becomes the bottleneck.
6. Fund R&D and evolve through faster and more efficient ASIC generations.
7. Sign external NPC partners in AI, robotics, semiconductors, energy, finance, infrastructure, real estate, telecom, commercial food/retail, or sports.
8. Track seasons, league position, prestige, company value, efficiency, and hashrate.
9. Acquire weaker rival Bitcoin miners and absorb their capacity.
10. Progress from TH/s toward PH/s, EH/s, and eventually sub-1 J/TH hardware.

## Ten mining companies

- **BlockForge Mining** — low-cost operator with a larger opening fleet
- **Northstar Hash** — research-first miner
- **VoltHash Mining** — grid-optimization specialist
- **TerraHash Industries** — land and site expansion specialist
- **Frontier Mining Co.** — acquisition-focused consolidator
- **HydroBlock Mining** — cooling, uptime, and efficiency specialist
- **IronPeak Digital Mining** — reliability-first operator
- **Atlas Hashworks** — balanced industrial miner
- **Cascade Mining Systems** — efficiency-focused fleet manager
- **DeepCore Bitcoin Mining** — capital-heavy expansion miner

## External partner market

- **AI** — faster research and compute-contract revenue
- **Robotics** — higher uptime and lower operating costs
- **Semiconductor** — lower J/TH and faster ASIC development
- **Energy** — lower electricity cost
- **Telecom** — better network reliability and uptime
- **Real Estate** — land, property, and site expansion
- **Finance** — stronger acquisition economics
- **Infrastructure** — larger sites and cheaper expansion
- **Quick Service / Retail** — recurring non-mining commercial revenue
- **Sports** — sponsorship income and franchise prestige

## Engine direction

Hash Race is moving to **[Godot](https://godotengine.org/)** as the primary engine. The current stable target is **Godot 4.7.2**. Godot is [free and open source under the MIT license](https://github.com/godotengine/godot), has dedicated 2D tooling, and officially supports [GDScript, C#, and C++ through GDExtension](https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_languages.html).

The project uses a hybrid language strategy:

- **GDScript** for most gameplay, UI, map, event, and simulation orchestration.
- **C#** for proven systems we already built and for the downloadable transitional prototype.
- **C++/GDExtension** only when profiling proves a native-performance need.

See [the engine-direction document](docs/GODOT_DIRECTION.md) for the reasoning and research links. Godot has also been examined in academic work on indie-engine relevance, and 2026 research built a benchmark from thousands of verified Godot projects: [Holfeld 2023/2024](https://arxiv.org/abs/2401.01909) and [JamSet/JamBench 2026](https://arxiv.org/abs/2606.19830).

## Mining metrics

Hash Race uses hashrate, J/TH, kW, kWh, electricity price, uptime, network hashrate, block subsidy, simulated BTC/day, revenue, power cost, cash, company value, R&D, and hardware generation.

`power watts = hashrate TH/s × J/TH`

`BTC/day = company hashrate ÷ network hashrate × blocks/day × block subsidy × uptime`

For protocol background, see the [Bitcoin Developer Guide](https://developer.bitcoin.org/devguide/) and [Bitcoin developer reference](https://developer.bitcoin.org/reference/).

## Repository layout

- `Godot/` — new primary Godot 4 game client
- `desktop/HashRace.Desktop/` — self-contained C# transitional desktop build
- `Assets/` — earlier Unity prototype retained as migration/reference code
- `tools/` — automated smoke and concept checks
- `.github/workflows/` — automated tests and Windows/Linux desktop releases
- `GAME_DESIGN.md` — canonical gameplay direction
- `docs/GODOT_DIRECTION.md` — engine/language decision and references
- `VERSION` — current public downloadable version

## Version rule

Public playable versions start at **v0.001** and increase by **0.001** for each completed public game update. A Windows or Linux download is only treated as live after the GitHub release asset has been built and verified.
