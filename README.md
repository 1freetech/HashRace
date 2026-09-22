# Hash Race

**Hash Race** is a 2D Bitcoin mining strategy simulation built around competition between fictional Bitcoin mining companies. The game combines hardware deployment, power and land expansion, BTC treasury management, financing, research, partnerships, mergers, company culture, market cycles, and an explorable top-down company world.

## v0.139 — approved 32-pose default character

The default player uses the approved spiky-haired character with brown skin, a green eyepiece, white armor and orange accents. Its genuine transparent PNG contains 32 poses: down, left, right and up, each with one idle pose and seven walking phases. Explicit source regions and a common foot anchor keep the character aligned without stretching. The original colors are preserved.

The work continues on the consolidated v0.138 recovery world. The obsolete v0.130 overview JPEG was corrupt and no longer referenced by that world; it has been removed. The live Command Center still uses the C-01 container loader. Healthy terrain and energy artwork replaces the damaged repository copies.

See [character asset and validation details](docs/default-character-32-frame.md). [Latest published game downloads](https://github.com/1freetech/HashRace/releases/latest) remain separate from changes awaiting release validation.

## v0.128 — one-road city layouts + C-01 mining containers

v0.128 removes the road pile-up that could occur when the inherited asphalt, dirt-road, and industrial-road layers all rendered inside the same mining campus. The live v0.128 layer owns the campus ground draw, keeps the authored grass underneath, and draws **one straight local road stretch only**. Each of the ten cities now has a selected local road language (industrial, dirt, gravel, or asphalt variants) without stacking multiple road systems on the same tiles.

The supplied **C-01 mining-container artwork** is now a real game-source asset at `Godot/art/buildings/c01_mining_container.svg`. Mining HQs and the player's live mining site render that container instead of the older house-like/procedural HQ facade. Capacity still scales through the existing 2x2 / 4x4 / 6x6 / 8x8 contract, while the live site is reduced to a container, one energy source, one transformer, and one command hut with deliberate negative space.

## v0.127 — uploaded game-asset bundle

v0.127 treats the latest uploads as **game assets, not references**. The live Godot world now loads and draws the industrial-road atlas, utility-prop atlas, directional wind turbine, directional air-cooled ASIC, and the existing 16-frame directional player sheet. The industrial road is used as a service-road spur, utility poles/fence/gate/cabinet/cones/pallets are placed as sparse campus props, and wind/ASIC orientation frames are rendered directly from the uploaded atlases. Runtime screenshot validation refuses to pass unless all five asset families report loaded.

## Priority campus asset policy

The approved Hash Race campus composition is now stored under `Godot/art/priority/` and registered by `priority_asset_catalog.gd`. It is a **game-source asset**, not reference-only artwork. It may be sampled, sliced, or decomposed into live HUD, building, terrain, power, storage, signage, road, shoreline, and player components as the runtime implementation advances. Runtime screenshots remain proof of what is actually live.

## v0.125 — authored dirt-road atlas

v0.125 integrates the supplied dirt-road artwork into the **live Godot world** instead of approximating it with flat brown rectangles. The transparent game atlas lives at `Godot/art/terrain/dirt_road_tilesheet.png`; `dirt_road_catalog.gd` maps authored straight, junction, end, shoulder, and worn-surface regions; and `world_v125.gd` uses neighbor-aware tile selection to build mining-campus service roads beneath the structures. The public town road stays paved, while mining access, transformer frontage, storage access, and expansion lanes use dirt.

The real gameplay screenshot gate now verifies that the v0.125 dirt-road layer and uploaded texture are actually loaded before a capture can count as proof.

## v0.124 — screenshot-match environment pass

v0.124 continues the locked visual-target work in the **actual live Godot world**. It adds the missing large composition cues from the approved screenshot: a lattice transmission tower with sagging power conductors, a rocky shoreline/water corner, sparse tree and rock clusters, and stronger campus framing around the existing v0.123 mining building, transformer, power module, storage yard, signs, road, HUD, and green player. The HUD now reads the repository version dynamically instead of hard-coding a stale build number.

The Godot screenshot validator now refuses to count a capture as proof unless the live scene reports the **v0.124 visual-target revision**. Reference art remains a target only; runtime capture remains the proof.

## v0.123 — locked runtime visual target

v0.123 makes the approved Hash Race screenshot a **design specification rather than fake proof**. The live Godot world now owns a compact neon-green top HUD, a larger player mining-rig building, transformer, power module, fenced storage yard, roadside signs, lamps, lane striping, and a compact live load meter. The player renderer also remaps the warm suit accents to the target green/black visual language at runtime while preserving skin and dark armor. The reference specification is documented in `docs/visual_target_v121.md`.

**Proof rule:** only `visual-proof/hashrace-screenshot.png` produced by the Godot 4.7.2 workflow counts as proof that the runtime matches the source. Reference/concept images are never runtime proof.

## Play Hash Race

- **[Latest release page](https://github.com/1freetech/HashRace/releases/latest)**

- **[Windows x64 — v0.128](https://github.com/1freetech/HashRace/releases/download/v0.128/HashRace-v0.128-windows-x64.zip)**
- **[Linux x64 — v0.128](https://github.com/1freetech/HashRace/releases/download/v0.128/HashRace-v0.128-linux-x64.tar.gz)**

v0.117 completes the **13-system energy-library wiring**. Battery storage, solar, wind, natural-gas turbine, hydro, oil-field generation, coal, nuclear SMR, methane/CH4, diesel, geothermal, LPG/propane, and hydrogen fuel-cell modules are all native inventory/deployment items and all render from the authored four-direction atlas. The live world chooses **UP/DOWN/LEFT/RIGHT** frames from each module's position relative to the electrical bus/transformer. Facility growth now follows **2x2 -> 4x4 -> 6x6 -> 8x8** footprints through 100 MW, then compresses into bounded 8x8 campus/district blocks for 100 MW, GW, 10-100 GW, and TW-scale companies so exact simulation capacity can keep growing without filling the town with literal container counts. CI deploys and renders all 13 systems together as the live energy-site proof.

v0.116 renders the uploaded **semiconductor-fab sheet from a real JPEG file inside the Godot project**. The live FoundryWorks Silicon partner building now draws the stationary DOWN/front orientation directly from `Godot/assets/imported/v115/semiconductor_fab.jpg`, while the other three authored views remain available in the same 2x2 sheet. A dedicated rendered proof capture is part of CI so this asset cannot silently fall back to the old procedural building.

v0.114 renders the authored **13-system energy atlas directly in the live overworld** and turns the agreed facility-scale concept into gameplay code: roughly **1 MW = 2x2 tiles, 10 MW = 4x4 tiles, and 100 MW = 8x8 tiles**, with larger GW/TW tiers compressed into readable district blocks instead of one visible object per physical unit. Every mining site now composes around four essentials only — a capacity-tier mining container, one energy source, a transformer/distribution object, and a compact command/control object — with large negative space preserved between them. The player site prefers actually deployed generation; rival sites receive deterministic power-source variety from the same visual catalog.

v0.112 is the imported-art integration pass. The live world now has a canonical registry for the supplied **4x4 directional character sheets**, ASIC cooling variants, BESS, coal, gas-turbine, hydro, LPG, command-center, transformer, tree, plane, grass, asphalt, and gravel art. The renderer maps the 16-frame player sheet as **down/up/left/right × four frames**, keeps idle on frame 0 of the last facing direction, and uses supplied stationary infrastructure art as fixed site objects. Mining campuses are intentionally sparse: one mining module, one energy source, one transformer/distribution object, one command/control object, and restrained landscaping, preserving negative space and map readability. The v0.111 capacity-tier scaling rules remain active underneath so facility art can grow from MW modules into compressed GW/TW representations without one-object-per-machine clutter.

v0.103 is the current live-source composition upgrade. Important buildings use more of their safe parcel while secondary partner offices visually recede; broad grass buffers replace decorative town-center cross paths; every building receives a consistent lower-right cast shadow from a fixed top-left light source; roads, paths, lots, grass, and water now meet through layered/dithered transition bands instead of a single hard seam; and repeated landscaping has been reduced to a few terrain-safe details. v0.102's infrastructure cleanup remains in the inheritance chain, including the inventory-driven **AI Operations Rack** and removal of the old decorative energy-yard clutter.

v0.097 introduced the pixel-art graphics rebuild. It replaces the older blocky facility treatment with a cohesive RPG-style pixel-art terrain/building renderer, adjacency-aware terrain edges, landscaping details, stronger 3/4 roof silhouettes, and corrected renderer typing/instancing so the visual layer boots cleanly. The release metadata and automated contracts now follow the live `world_v###.gd` layer instead of relying on stale hard-coded release numbers.

v0.095 moves every interactive facility onto a **roadside parcel** instead of allowing building footprints or paved lots to cover live road/water tiles. The same update finishes the player scouter customization path: campaign setup offers eight lens colors plus left/right eye placement with a live character preview, and the in-game Wardrobe can change skin tone, presentation, outfit, scouter color, and scouter eye at any time. The active high-density player renderer now uses those scouter choices directly rather than falling back to the company representative's fixed visor side or the outfit's neon color.

v0.094 introduces a **world-first navigation shell** for gameplay. Normal play now leaves only one small NAV control on-screen; Company, Market, Mining Ops, Infrastructure, BTC Treasury, Life + Site, League, Wardrobe, Dialogue, and Tools are opened one at a time, with the other interfaces minimized automatically. The old persistent menu button and always-on control prompt are hidden, the large dialogue panel no longer occupies the bottom of the screen during ordinary movement, and routine feedback appears as a temporary toast instead of reopening a large interface. The NAV panel also keeps turn preview/confirmation directly accessible without restoring the old dashboard clutter.

v0.093 adds a live player-model preview to the campaign setup screen so skin tone and presentation changes are visible immediately, compresses the Mining Ops dashboard from 326 px to 248 px tall while keeping all six live metrics and resize/drag behavior, removes the legacy full-width `HASH RACE // COMPANY OVERWORLD` header from gameplay, and extends selectable campaign length from 20 years to 100 years with matching runtime caps so long campaigns are not silently truncated.

v0.091 is the interaction-quality pass on top of v0.090: Space is interaction-only so talking/opening a target cannot accidentally advance the economy; buildings use their visible front-door position for interaction range; clicking a distant entity routes the player there and opens it on arrival; failed routes report clearly; the persistent scanner control is removed from the field while the compact menu remains available; turn-phase text only appears during confirmation; and building/town labels are limited to the nearest relevant location to keep the map readable.

v0.090 upgrades strategy and simulation correctness: deployed batteries are finite 4 MWh / 2 MW storage assets with 90% round-trip efficiency and a direct 0–100 reserve policy; strategic turn previews use the same finite energy budget and bill charging input correctly; rivals expose a utility-scored next intent before their monthly action; and normal overworld routing now uses Godot's native AStarGrid2D. The same release also fixes duplicate Mining Ops history sampling, throttles compact-HUD polling instead of recomputing it every rendered frame, converts bursty world redraws into phase-based updates, restores true neon-green character labels, adds readable building-name plates, gives trend text semantic warning states, and declutters navigation with a single destination reticle.

v0.088 upgrades overworld scale and connectivity: larger believable building footprints, a wider default CITY camera view with discrete zoom presets, front-door interaction cues, navigation collisions that match visible architecture, roof-cutaway ordering for the procedural map, a reusable roof-fade Area2D for node-based buildings, and a persistent SceneManager + Doorway template that can push interiors without destroying the live mining simulation.

v0.087 upgrades the live 2D characters toward the supplied high-detail chibi pixel references. The directional procedural renderer now gets a **one-pixel finishing pass** for eye catchlights, visor scanlines/specular highlights, headset hardware, hair streaks, armor seams/rivets, glove detail, and boot tread. The repository also includes a layered **96×128 sprite-rig path** plus a four-material, three-ramp **palette-swap shader**, allowing future authored body/hair/visor/armor atlases to share one animation grid without generating separate sprite sheets for every color combination.

v0.086 adds proactive **computer-company supplier offers** to the live negotiation system. External computer companies can contact the player during normal play on a randomized real-time cadence, independent of turn settlement. Their offers use the same **MAKE OFFER, COUNTER, WALK AWAY** interface and can provide current-generation machines plus bounded fleet-efficiency improvements when closed. Computer companies remain external NPC suppliers and do not become mining-league rivals.

v0.073 upgrades the live player and NPC/company representatives to a reusable **high-density procedural pixel-character rig** based on the approved detailed reference direction. The same on-screen footprint now uses a finer 3-pixel source grid, directional front/back/left/right silhouettes, five body builds, four hair families, layered armor, headset/ear protection, neon scanner visors, gloves, segmented boots, company-colored IDs, and reusable mining/victory action poses. Character names remain directly above the sprite and the existing wardrobe skin-tone/outfit system still drives the player. The public v0.073 desktop packages are published only after the Godot boot, overworld validator, rendered close-up proof, Windows export, Linux export, and Linux binary boot checks pass.

v0.072 adds an original **battle-style negotiation scene** for rival-company encounters. Rival buildings and representatives can launch a full-screen animated deal table with **MAKE OFFER, COUNTER, and WALK AWAY** choices. Live company reputation and leverage are compared with rival power and greed, and successful flexible-capacity contracts transfer cash and add real MW to the player. The scene is managed separately from the world so the same framework can later drive mergers, PPAs, hardware supply, financing, land, and faction negotiations.

v0.070 is the modular-architecture upgrade. The persistent HUD is now one compact **Mining Ops** panel mounted in the **upper-right** by default. It keeps the six live cards — **Hashrate, Power, Efficiency, Uptime, BTC Treasury, and USD Cash** — and folds company/date/turn context into the same surface so the old full-width persistent stat strip is hidden instead of duplicating values.

The infrastructure catalog is now backed by **40 native Godot `.tres` ItemResource files** rather than one giant hardcoded dictionary. Physical rack containers expose typed hardware slots, a world-space placement grid tracks actual deployment positions, and a dedicated **SimulationManager** runs a fixed one-second live tick for power balance, thermal state, throttling telemetry, and the Mining Ops snapshot. Existing strategic turn settlement remains intact while the real-time operational layer is decoupled from UI rendering.

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

The live infrastructure catalog currently contains **35 functional assets** across nine categories: miners, power, energy, cooling, facilities, network, maintenance, resilience, and strategic supply. Energy inventory now includes solar farms, wind farms, natural-gas turbines, hydro turbines, oil-field generation, coal power blocks, grid batteries, and nuclear SMR campuses alongside ASIC racks, transformers, switchgear, PDUs, cooling, facilities, networking, repair equipment, resilience systems, and strategic supply investments.

The inventory is now driven by native Godot **ItemResource** files under `Godot/data/items/`. New hardware can be added or balanced in the Inspector without editing the inventory core. A compatibility bridge still exposes the older dictionary-shaped API where existing UI code needs it, but the resource files are the source of truth.

Owned quantities are tracked separately from deployed quantities. Equipment in warehouse storage does not generate hashrate or site capacity until it is deployed. v0.070 also introduces physical rack/slot nodes and a placement grid so deployed mining hardware has a world-space representation instead of existing only as a global stat tally.

## Flexible turn system

Campaign length is selectable from **1 to 100 years**. The default strategic turn is **one month**, but the live game supports three clear time references:

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

v0.072 introduces a dedicated Godot negotiation scene with a fast battle-style intro, two opposing company cards, a live deal-read meter, and three actions: **MAKE OFFER, COUNTER, and WALK AWAY**. The first implemented negotiation is a rival flexible-power access contract. A successful rival deal deducts the negotiated cash price, credits the rival, and adds the negotiated MW capacity to the player. Computer-company supplier offers can also appear during normal play and award current-generation machines plus fleet-efficiency improvements when successfully negotiated.

The older mining-company merger model remains available separately. Merger offer strength, relative company size, reputation, and aggression contribute to a visible 1–99% acceptance chance with LONG SHOT, UNLIKELY, MEDIUM, LIKELY, and VERY LIKELY bands.

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
