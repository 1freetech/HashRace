# Hash Race Downloads

Current public version target: **v0.016**

- [Windows x64 — Hash Race v0.016](https://github.com/1freetech/HashRace/releases/download/v0.016/HashRace-v0.016-windows-x64.zip)
- [Linux x64 — Hash Race v0.016](https://github.com/1freetech/HashRace/releases/download/v0.016/HashRace-v0.016-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.016 gameplay change

The shipped Godot RPG strategy world now has a visible **BTC TREASURY // LIQUIDITY** panel. **SELL 25% BTC TREASURY** converts one quarter of held sats into cash at the current simulated Bitcoin price. **AUTO-FUND SAFE QUARTER** calculates the live quarter projection and sells only the sats needed to target a $10,000 quarter-end operating reserve, preserving the rest of the company's Bitcoin whenever possible. If the entire treasury is insufficient, the game tells the player that financing or cost cuts are still required.

Treasury sales also cancel any pending **CONFIRM END QUARTER** state. That prevents a player from previewing one financial plan, changing cash through a BTC sale, and then accidentally settling the quarter from a stale confirmation. The competitive model remains unchanged: all ten selectable/rival companies are Bitcoin miners. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain outside NPC partners and suppliers.

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
