# Hash Race Downloads

Current public version target: **v0.028**

- [Windows x64 — Hash Race v0.028](https://github.com/1freetech/HashRace/releases/download/v0.028/HashRace-v0.028-windows-x64.zip)
- [Linux x64 — Hash Race v0.028](https://github.com/1freetech/HashRace/releases/download/v0.028/HashRace-v0.028-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.028 gameplay playability update

Life + Operations now has an **AUTO routine queue**. About once per simulated month, AUTO checks Energy, Focus and Social, finds the weakest rating below 85/100, and chooses RECOVER, TRAIN or NETWORK for that need. This reduces repetitive management without removing player control: NONE and all three fixed routines remain selectable, automatic spending still requires enough company cash, and no routine runs when the operator is already healthy enough.

Queued routines continue to follow simulated elapsed time rather than turn count, so DAY, WEEK, MONTH and QUARTER turns have the same long-term routine opportunity rate. Energy, Focus, Social, Site Fit and other rating-style gameplay measures remain on the universal 0-100 scale.

All ten league companies remain Bitcoin mining companies. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service and sports organizations remain external NPC partners, suppliers, sponsors, landlords, financiers or strategic allies.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), [FreeSims](https://github.com/francot514/FreeSims), [The Sims Resource Downloader](https://github.com/Xientraa/The-Sims-Resource-Downloader), and [Microsoft Sims](https://github.com/microsoft/Sims). No protected Sims assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot CanvasLayer documentation](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html), and [Godot Button documentation](https://docs.godotengine.org/en/stable/classes/class_button.html).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
