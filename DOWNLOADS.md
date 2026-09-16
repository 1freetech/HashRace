# Hash Race Downloads

Current public version target: **v0.017**

- [Windows x64 — Hash Race v0.017](https://github.com/1freetech/HashRace/releases/download/v0.017/HashRace-v0.017-windows-x64.zip)
- [Linux x64 — Hash Race v0.017](https://github.com/1freetech/HashRace/releases/download/v0.017/HashRace-v0.017-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.017 gameplay change

The shipped Godot RPG strategy world now puts **BTC HOLD POLICY** directly inside the live treasury panel. Players can cycle through **0%, 25%, 50%, 75%, and 100%** hold targets before ending a quarter. The selected percentage controls how much newly mined Bitcoin stays in treasury; the remainder is sold for operating cash. The projected quarter-end cash display updates immediately, making the tradeoff between liquidity and long-term BTC accumulation visible before the player commits roughly 91 days.

Changing the hold policy also cancels a pending **CONFIRM END QUARTER** state so the preview can never settle using stale assumptions. The existing **SELL 25% BTC TREASURY** and **AUTO-FUND SAFE QUARTER** controls remain available. The competitive model remains unchanged: all ten selectable/rival companies are Bitcoin miners. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain outside NPC partners and suppliers.

This control follows the broader open-source Godot pattern of keeping persistent economy/run state visible and player-adjustable instead of burying important simulation choices. Useful references: [SimpleTowerDefense's MIT-licensed GameState/save architecture](https://github.com/IronWolve/SimpleTowerDefense) and [Godot's GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
