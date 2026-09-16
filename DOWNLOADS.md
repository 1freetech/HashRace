# Hash Race Downloads

Current public version target: **v0.010**

- [Windows x64 — Hash Race v0.010](https://github.com/1freetech/HashRace/releases/download/v0.010/HashRace-v0.010-windows-x64.zip)
- [Linux x64 — Hash Race v0.010](https://github.com/1freetech/HashRace/releases/download/v0.010/HashRace-v0.010-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.010 gameplay change

The quarterly front office now has a **QUARTER PLAN** button with three fast strategy presets: **CASH**, **BALANCED**, and **HODL**. CASH sells newly mined Bitcoin for operating cash, BALANCED keeps half and sells half, and HODL keeps all newly mined Bitcoin in treasury. Each click immediately updates the existing BTC hold policy and recalculates the projected quarter cash result and risk warning before the player confirms the turn.

The detailed **BTC HOLD POLICY**, **SELL 25% BTC TREASURY**, and **AUTO-FUND NEXT QUARTER** controls remain available. The preset is a faster front-office decision, not a replacement for manual treasury management. The competitive model also remains unchanged: all ten selectable/rival companies are Bitcoin miners. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain outside NPC partners and suppliers.

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
