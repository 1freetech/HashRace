# Hash Race Downloads

Current public version target: **v0.031**

- [Windows x64 — Hash Race v0.031](https://github.com/1freetech/HashRace/releases/download/v0.031/HashRace-v0.031-windows-x64.zip)
- [Linux x64 — Hash Race v0.031](https://github.com/1freetech/HashRace/releases/download/v0.031/HashRace-v0.031-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.031 gameplay playability update

AUTO Life + Operations management is now burnout-safe. When burnout reaches 50/100, AUTO prioritizes RECOVER before TRAIN or NETWORK. This prevents automatic management from choosing a lower Social rating while an exhausted operator is already losing mining uptime.

The Life + Site display shows `AUTO→RECOVER` while this protection is active. Burnout remains on the shared 0-100 scale and can still reduce uptime by up to three percentage points. Manual RECOVER, TRAIN and NETWORK controls remain available, and normal AUTO behavior returns when burnout drops below the danger point.

All ten league companies remain Bitcoin mining companies. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service and sports organizations remain external NPC partners, suppliers, sponsors, landlords, financiers or strategic allies.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), [FreeSims](https://github.com/francot514/FreeSims), [The Sims Resource Downloader](https://github.com/Xientraa/The-Sims-Resource-Downloader), and [Microsoft Sims](https://github.com/microsoft/Sims). No protected Sims assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot CanvasLayer documentation](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html), and [Godot Button documentation](https://docs.godotengine.org/en/stable/classes/class_button.html).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
