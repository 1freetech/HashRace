# Hash Race Downloads

Current public version target: **v0.008**

- [Windows x64 — Hash Race v0.008](https://github.com/1freetech/HashRace/releases/download/v0.008/HashRace-v0.008-windows-x64.zip)
- [Linux x64 — Hash Race v0.008](https://github.com/1freetech/HashRace/releases/download/v0.008/HashRace-v0.008-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.008 gameplay change

The quarterly front office now has a **BTC HOLD POLICY** control. Players can cycle between holding 0%, 25%, 50%, 75%, or 100% of newly mined Bitcoin. The remainder is sold for operating cash when the quarter settles. This turns treasury management into a real strategy decision: a miner can sell more BTC when cash is tight or hold more when it wants greater Bitcoin exposure. Changing the policy cancels a pending quarter confirmation and immediately recalculates the projected cash result, so the player can compare the tradeoff before advancing time.

The existing **SELL 25% BTC TREASURY** action remains available for converting already-held sats to cash. The competitive model also remains unchanged: all ten selectable/rival companies are Bitcoin miners. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain outside NPC partners and suppliers.

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
