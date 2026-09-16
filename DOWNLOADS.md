# Hash Race Downloads

Current public version target: **v0.027**

- [Windows x64 — Hash Race v0.027](https://github.com/1freetech/HashRace/releases/download/v0.027/HashRace-v0.027-windows-x64.zip)
- [Linux x64 — Hash Race v0.027](https://github.com/1freetech/HashRace/releases/download/v0.027/HashRace-v0.027-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.027 gameplay playability fix

Queued Life + Operations routines are now **smart routines**. The automatic monthly RECOVER, TRAIN and NETWORK queue checks the related operator rating before spending company cash. If the target need is already 85/100 or higher, the automatic routine skips the purchase instead of repeatedly charging the company for little or no benefit. RECOVER considers both Energy and Focus because it improves both. Manual routine buttons remain available for deliberate player choices. The Life + Site overview clearly shows the 85/100 smart-queue threshold.

Queued routines still follow simulated elapsed time rather than turn count, so DAY, WEEK, MONTH and QUARTER turns have the same long-term routine opportunity rate. Energy, Focus, Social, Site Fit and other rating-style gameplay measures remain on the universal 0-100 scale.

All ten league companies remain Bitcoin mining companies. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service and sports organizations remain external NPC partners, suppliers, sponsors, landlords, financiers or strategic allies.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), [FreeSims](https://github.com/francot514/FreeSims), [The Sims Resource Downloader](https://github.com/Xientraa/The-Sims-Resource-Downloader), and [Microsoft Sims](https://github.com/microsoft/Sims). No protected Sims assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot CanvasLayer documentation](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html), and [Godot Button documentation](https://docs.godotengine.org/en/stable/classes/class_button.html).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
