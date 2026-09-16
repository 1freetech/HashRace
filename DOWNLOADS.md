# Hash Race Downloads

Current public version target: **v0.009**

- [Windows x64 — Hash Race v0.009](https://github.com/1freetech/HashRace/releases/download/v0.009/HashRace-v0.009-windows-x64.zip)
- [Linux x64 — Hash Race v0.009](https://github.com/1freetech/HashRace/releases/download/v0.009/HashRace-v0.009-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.009 gameplay change

The quarterly front office now has **AUTO-FUND NEXT QUARTER**. When the quarter preview predicts a cash shortage, the game calculates the shortfall and sells only enough of the player's existing Bitcoin treasury to cover the projected quarter while targeting a $10,000 operating reserve. It preserves the rest of the sats instead of making the player repeatedly sell fixed 25% chunks. If the entire treasury is not enough, the game says so clearly and points the player toward financing, a lower BTC hold policy, or cost cuts.

The existing **BTC HOLD POLICY** and **SELL 25% BTC TREASURY** controls remain available, so automatic rescue is optional rather than forced. The competitive model also remains unchanged: all ten selectable/rival companies are Bitcoin miners. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain outside NPC partners and suppliers.

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
