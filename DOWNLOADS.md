# Hash Race Downloads

Current public version target: **v0.029**

- [Windows x64 — Hash Race v0.029](https://github.com/1freetech/HashRace/releases/download/v0.029/HashRace-v0.029-windows-x64.zip)
- [Linux x64 — Hash Race v0.029](https://github.com/1freetech/HashRace/releases/download/v0.029/HashRace-v0.029-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.029 gameplay playability update

Life + Operations now includes **BURNOUT RISK** on the shared 0-100 rating scale. When Energy or Focus falls below 35/100, burnout begins to rise. At extreme burnout the operator can lose up to three percentage points of mining uptime, giving RECOVER and TRAIN a direct operational purpose instead of making the life ratings feel decorative.

The live Life + Site display shows burnout risk and its current uptime penalty. Healthy Energy and Focus create no burnout penalty. The existing AUTO routine queue, elapsed-time normalization, flexible DAY/WEEK/MONTH/QUARTER turns, Site Fit, treasury strategy, league standings and company effects remain in place.

All ten league companies remain Bitcoin mining companies. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service and sports organizations remain external NPC partners, suppliers, sponsors, landlords, financiers or strategic allies.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), [FreeSims](https://github.com/francot514/FreeSims), [The Sims Resource Downloader](https://github.com/Xientraa/The-Sims-Resource-Downloader), and [Microsoft Sims](https://github.com/microsoft/Sims). No protected Sims assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot CanvasLayer documentation](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html), and [Godot Button documentation](https://docs.godotengine.org/en/stable/classes/class_button.html).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
