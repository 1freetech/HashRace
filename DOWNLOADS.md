# Hash Race Downloads

Current public version target: **v0.007**

- [Windows x64 — Hash Race v0.007](https://github.com/1freetech/HashRace/releases/download/v0.007/HashRace-v0.007-windows-x64.zip)
- [Linux x64 — Hash Race v0.007](https://github.com/1freetech/HashRace/releases/download/v0.007/HashRace-v0.007-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.007 gameplay change

The quarterly front-office screen now has a **SELL 25% BTC TREASURY** action. A mining company that has accumulated sats can convert one quarter of those holdings to operating cash at the current simulated BTC price before ending the quarter. The action makes the existing cash-danger preview useful: instead of merely warning the player to sell BTC, the game now provides the control needed to do it. A sale cancels any pending END QUARTER confirmation so the player can review the improved cash position before advancing time.

The competitive model remains unchanged: all ten selectable/rival companies are Bitcoin miners. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain outside NPC partners and suppliers.

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
