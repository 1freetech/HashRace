# Hash Race Downloads

Current public version target: **v0.023**

- [Windows x64 — Hash Race v0.023](https://github.com/1freetech/HashRace/releases/download/v0.023/HashRace-v0.023-windows-x64.zip)
- [Linux x64 — Hash Race v0.023](https://github.com/1freetech/HashRace/releases/download/v0.023/HashRace-v0.023-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.023 gameplay change

The live Godot world now adds **Life + Operations** to the mining-company management loop. The operator has Energy, Focus, and Social ratings on Hash Race's universal 0-100 scale. Those ratings decay according to actual elapsed game days, so a DAY turn changes them much less than a MONTH or QUARTER turn. Players can spend company cash on RECOVER, TRAIN, or NETWORK routines and can queue one routine to repeat automatically after a successfully settled turn when cash allows.

The same panel adds a **facility preview and Site Fit rating from 0-100**. Site Fit compares installed mining hardware with available MW and land, giving the player a quick warning that operational expansion is becoming poorly matched. All ten league companies remain Bitcoin miners; outside industries remain NPC partners and suppliers.

## Open-source simulation references used for v0.023

Hash Race uses original code and original game content, but this update studied reusable design/architecture ideas from these open-source projects:

- [FreeSO](https://github.com/riperiperi/FreeSO) — its separated simulation/VM architecture informed the idea of a persistent operator-state layer that advances with simulation time.
- [OpenTS2](https://github.com/LazyDuchess/OpenTS2) — its neighborhood-oriented client structure informed the compact facility/site preview rather than hiding context across unrelated screens.
- [FreeSims](https://github.com/francot514/FreeSims) — its work/life/neighborhood simulation direction informed explicit RECOVER, TRAIN, and NETWORK management routines.
- [The Sims Resource Downloader](https://github.com/Xientraa/The-Sims-Resource-Downloader) — its persisted download-queue/configuration pattern inspired the small persistent routine queue, adapted to gameplay rather than downloading content.
- [Microsoft Sims](https://github.com/microsoft/Sims) — this repository is a geographic region-similarity project rather than a life-simulation game; its similarity-scoring concept informed Hash Race's 0-100 Site Fit score instead of importing unrelated code.

No protected Sims assets, characters, names, proprietary game content, or required original-game files are included in Hash Race.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot CanvasLayer documentation](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html), and [Godot Button documentation](https://docs.godotengine.org/en/stable/classes/class_button.html).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
