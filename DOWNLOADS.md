# Hash Race Downloads

Current public version target: **v0.012**

- [Windows x64 — Hash Race v0.012](https://github.com/1freetech/HashRace/releases/download/v0.012/HashRace-v0.012-windows-x64.zip)
- [Linux x64 — Hash Race v0.012](https://github.com/1freetech/HashRace/releases/download/v0.012/HashRace-v0.012-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.012 gameplay change

The quarterly front office now has a **PREPARE SAFE QUARTER** button. One click applies the existing advisor's recommended **CASH**, **BALANCED**, or **HODL** plan and then checks projected quarter-end cash. If the projection is below the $10,000 operating-reserve target and the company has a BTC treasury, it sells only the minimum sats needed to target that reserve. If no treasury sale is needed, no Bitcoin is sold. If the company still cannot survive the quarter after available treasury funding, the game clearly warns that financing, expansion delay, or cost cuts are still required.

The shortcut does not advance time automatically. The player still reviews the projection and uses the separate **END QUARTER / CONFIRM END QUARTER** control. Detailed **USE RECOMMENDED PLAN**, **QUARTER PLAN**, **BTC HOLD POLICY**, **SELL 25% BTC TREASURY**, and **AUTO-FUND NEXT QUARTER** controls remain available for manual strategy. The competitive model remains unchanged: all ten selectable/rival companies are Bitcoin miners. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain outside NPC partners and suppliers.

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
