# Hash Race Downloads

Current public version target: **v0.020**

- [Windows x64 — Hash Race v0.020](https://github.com/1freetech/HashRace/releases/download/v0.020/HashRace-v0.020-windows-x64.zip)
- [Linux x64 — Hash Race v0.020](https://github.com/1freetech/HashRace/releases/download/v0.020/HashRace-v0.020-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.020 gameplay change

The live Godot treasury panel now gives the player a **fully adjustable 0-100 BTC hold strategy**. The old handful of preset percentages has been replaced by a one-point slider, so a mining company can choose any policy from 0/100 through 100/100. Moving the slider immediately changes how much newly mined Bitcoin will be retained versus sold for operating cash and refreshes the projected turn-end cash figure.

The treasury projection now also respects the active flexible season clock. A day turn forecasts one day, a week forecasts seven days, a month forecasts about 30.44 days, and a quarter forecasts about 91.31 days. Changing the strategy cancels any stale settlement confirmation and restores the correct END DAY/WEEK/MONTH/QUARTER TURN label.

The competitive model remains unchanged: all ten selectable/rival companies are Bitcoin miners. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain external NPC partners, suppliers, sponsors, landlords, financiers, or strategic allies.

Useful implementation references: [Godot Range/HSlider documentation](https://docs.godotengine.org/en/stable/classes/class_hslider.html), [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), and [Godot's time-scale documentation](https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-property-time-scale).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
