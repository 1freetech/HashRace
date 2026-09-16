# Hash Race Downloads

Current public version target: **v0.024**

- [Windows x64 — Hash Race v0.024](https://github.com/1freetech/HashRace/releases/download/v0.024/HashRace-v0.024-windows-x64.zip)
- [Linux x64 — Hash Race v0.024](https://github.com/1freetech/HashRace/releases/download/v0.024/HashRace-v0.024-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.024 gameplay change

Life management now changes the actual mining business instead of acting mainly as a status display. **Energy** modifies mining uptime by up to ±2.5 percentage points, **Focus** modifies research cost by up to ±8%, and **Social** modifies partner/deal cost by up to ±8%. The effects are deliberately bounded and combine with the existing mining-company culture effects rather than replacing them.

This makes RECOVER, TRAIN, NETWORK and the persistent routine queue real strategic decisions. Long MONTH or QUARTER turns create more operator pressure than DAY or WEEK turns, so a player can either spend money maintaining the operator or accept measurable operational penalties. All life, skill and strategy ratings remain on Hash Race's universal 0-100 scale. All ten league companies remain Bitcoin mining companies; outside industries remain NPC partners, suppliers, sponsors, landlords, financiers or strategic allies.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), [FreeSims](https://github.com/francot514/FreeSims), [The Sims Resource Downloader](https://github.com/Xientraa/The-Sims-Resource-Downloader), and [Microsoft Sims](https://github.com/microsoft/Sims). No protected Sims assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot CanvasLayer documentation](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html), and [Godot Button documentation](https://docs.godotengine.org/en/stable/classes/class_button.html).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
