# Hash Race Downloads

Current public version target: **v0.018**

- [Windows x64 — Hash Race v0.018](https://github.com/1freetech/HashRace/releases/download/v0.018/HashRace-v0.018-windows-x64.zip)
- [Linux x64 — Hash Race v0.018](https://github.com/1freetech/HashRace/releases/download/v0.018/HashRace-v0.018-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.018 gameplay change

Hash Race now has a **flexible season clock** in the shipped Godot RPG strategy world. One strategic turn can represent **one day, one week, one month, or one quarter**, with **one month per turn as the default**. The player can change the turn length during a campaign, allowing close day-by-day management around important decisions or faster month/quarter progression when the company plan is stable.

Changing the turn length does not change the underlying mining metrics. BTC production, electricity use, operating expense, debt interest, recurring partner income, rival development, market movement, and Bitcoin halving timing are scaled against the actual number of elapsed simulation days. The existing two-click financial preview remains in place and now previews the selected turn length before settlement; changing the scale cancels a stale confirmation.

The competitive model remains unchanged: all ten selectable/rival companies are Bitcoin miners. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain external NPC partners, suppliers, sponsors, landlords, financiers, or strategic allies.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/) and [Godot's time-scale documentation](https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-property-time-scale). Hash Race uses its own strategic elapsed-day clock rather than changing the engine frame-time scale, because a turn represents simulated calendar time rather than animation speed.

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
