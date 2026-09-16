# Hash Race Downloads

Current public version target: **v0.015**

- [Windows x64 — Hash Race v0.015](https://github.com/1freetech/HashRace/releases/download/v0.015/HashRace-v0.015-windows-x64.zip)
- [Linux x64 — Hash Race v0.015](https://github.com/1freetech/HashRace/releases/download/v0.015/HashRace-v0.015-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.015 gameplay change

The active Godot RPG world now protects the **END QUARTER** action itself. The first click calculates the current quarter's projected cash result and projected ending cash using the live mining revenue, BTC treasury policy, power cost, uptime, operating expense, recurring partner income, and debt interest. The button changes to **CONFIRM END QUARTER** and clearly warns when the quarter is projected to lose cash or push the company below $0. A second click is required to settle roughly 91 days of simulation, while **Escape** cancels the pending settlement and returns the player to planning.

This closes a playability gap between the separate quarter-safety prototype and the actual RPG world used by the shipped Godot scene. The competitive model remains unchanged: all ten selectable/rival companies are Bitcoin miners. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain outside NPC partners and suppliers.

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
