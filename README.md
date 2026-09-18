# Hash Race

**Hash Race** is a 2D Bitcoin mining strategy simulation built around competition between fictional Bitcoin mining companies. The game combines hardware deployment, power and land expansion, BTC treasury management, financing, research, partnerships, mergers, company culture, market cycles, and an explorable top-down company world.

## Play Hash Race

The latest verified public desktop release is **v0.073**. The current **main** development build is **v0.073**.

- **[Windows x64 — Hash Race v0.073](https://github.com/1freetech/HashRace/releases/download/v0.073/HashRace-v0.073-windows-x64.zip)**
- **[Linux x64 — Hash Race v0.073](https://github.com/1freetech/HashRace/releases/download/v0.073/HashRace-v0.073-linux-x64.tar.gz)**
- **[Hash Race v0.073 release page](https://github.com/1freetech/HashRace/releases/tag/v0.073)**
- **[Latest verified release page](https://github.com/1freetech/HashRace/releases/latest)**

v0.073 upgrades the live player and NPC/company representatives to a reusable **high-density procedural pixel-character rig** based on the approved detailed reference direction. The same on-screen footprint now uses a finer 3-pixel source grid, directional front/back/left/right silhouettes, five body builds, four hair families, layered armor, headset/ear protection, neon scanner visors, gloves, segmented boots, company-colored IDs, and reusable mining/victory action poses. Character names remain directly above the sprite and the existing wardrobe skin-tone/outfit system still drives the player. The public v0.073 desktop packages are published only after the Godot boot, overworld validator, rendered close-up proof, Windows export, Linux export, and Linux binary boot checks pass.\n\nv0.072 adds an original **battle-style negotiation scene** for rival-company encounters. Rival buildings and representatives can launch a full-screen animated deal table with **MAKE OFFER, COUNTER, THREATEN, and WALK AWAY** choices. Live company reputation and leverage are compared with rival power and greed, and successful flexible-capacity contracts transfer cash and add real MW to the player. The scene is managed separately from the world so the same framework can later drive mergers, PPAs, hardware supply, financing, land, and faction negotiations.\n\nv0.070 is the modular-architecture upgrade. The persistent HUD is now one compact **Mining Ops** panel mounted in the **upper-right** by default. It keeps the six live cards — **Hashrate, Power, Efficiency, Uptime, BTC Treasury, and USD Cash** — and folds company/date/turn context into the same surface so the old full-width persistent stat strip is hidden instead of duplicating values.

The infrastructure catalog is now backed by **34 native Godot `.tres` ItemResource files** rather than one giant hardcoded dictionary. Physical rack containers expose typed hardware slots, a world-space placement grid tracks actual deployment positions, and a dedicated **SimulationManager** runs a fixed one-second live tick for power balance, thermal state, throttling telemetry, and the Mining Ops snapshot. Existing strategic turn settlement remains intact while the real-time operational layer is decoupled from UI rendering.

The desktop game uses **Godot 4.7.2 and GDScript**. The repository preserves useful native simulation work for heavier systems while Godot remains the primary gameplay, UI, map, event, and franchise client.

## Game structure

All playable companies and league rivals are Bitcoin miners. AI, semiconductor, robotics, energy, telecommunications, finance, real-estate, infrastructure, service, sports, and other companies exist as external NPC organizations that can provide partnerships and strategic advantages.

A campaign includes mining, buying hardware, securing power, acquiring land, improving technology, managing BTC, borrowing and repaying capital, signing external deals, exploring company towns, competing with rivals, and optionally completing one merger.

## Five league metrics + six live Mining Ops metrics

The league comparison card keeps its five real-unit competitive metrics. The draggable Mining Ops HUD adds uptime and BTC treasury to create a six-card live operating view:

- **Hashrate** — PH/s or EH/s
- **Power capacity** — MW
- **Fleet efficiency** — J/TH
- **Cash** — dollars
- **Profit** — dollars per selected period

Electricity price, uptime, BTC holdings, debt, land, machine count and generations, assets, research, staff, partnerships, cooling, financing, and other detailed values remain part of the simulation.

## Infrastructure inventory

The live infrastructure catalog currently contains **34 functional assets** across nine categories: miners, power, energy, cooling, facilities, network, maintenance, resilience, and strategic supply. Energy inventory now includes solar farms, wind farms, natural-gas turbines, hydro turbines, oil-field generation, coal power blocks, grid batteries, and nuclear SMR campuses alongside ASIC racks, transformers, switchgear, PDUs, cooling, facilities, networking, repair equipment, resilience systems, and strategic supply investments.

The inventory is now driven by native Godot **ItemResource** files under `Godot/data/items/`. New hardware can be added or balanced in the Inspector without editing the inventory core. A compatibility bridge still exposes the older dictionary-shaped API where existing UI code needs it, but the resource files are the source of truth.

Owned quantities are tracked separately from deployed quantities. Equipment in warehouse storage does not generate hashrate or site capacity until it is deployed. v0.070 also introduces physical rack/slot nodes and a placement grid so deployed mining hardware has a world-space representation instead of existing only as a global stat tally.

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

## Negotiations\n\nv0.072 introduces a dedicated Godot negotiation scene with a fast battle-style intro, two opposing company cards, a live deal-read meter, and four actions: **MAKE OFFER, COUNTER, THREATEN, and WALK AWAY**. The first implemented negotiation is a rival flexible-power access contract. A successful deal deducts the negotiated cash price, credits the rival, and adds the negotiated MW capacity to the player. Hard-pressure tactics can improve terms but can reduce reputation.\n\nThe older mining-company merger model remains available separately. Merger offer strength, relative company size, reputation, and aggression contribute to a visible 1–99% acceptance chance with LONG SHOT, UNLIKELY, MEDIUM, LIKELY, and VERY LIKELY bands.

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
- **INFRASTRUCTURE** — browse owned, deployed, and warehouse equipment
- **ENERGY** — buy and deploy generation assets that add live site capacity

## Technology

Hash Race uses **Godot** as its primary engine:

- **GDScript** — live gameplay, UI, maps, events, Resource-backed content, physical placement, fixed-tick operations simulation, rival AI, and company culture
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
