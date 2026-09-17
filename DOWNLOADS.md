# Hash Race Downloads

Current public version target: **v0.034**

- [Windows x64 — Hash Race v0.034](https://github.com/1freetech/HashRace/releases/download/v0.034/HashRace-v0.034-windows-x64.zip)
- [Linux x64 — Hash Race v0.034](https://github.com/1freetech/HashRace/releases/download/v0.034/HashRace-v0.034-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.034 gameplay playability update

Manual Life + Operations routines now protect company cash. RECOVER refuses to charge $500 when both Energy and Focus are already at or above 85/100, TRAIN refuses to charge $1,500 when Focus is already at or above 85/100, and NETWORK refuses to charge $1,000 when Social is already at or above 85/100. Each blocked action gives the player a clear explanation instead of silently wasting money.

This makes manual controls consistent with the existing AUTO and queued-routine logic. High Burnout still locks unsafe TRAIN actions before the normal Focus check, so the burnout safety system remains intact. Energy, Focus, Social and Burnout remain on the shared 0-100 scale.

All ten league companies remain Bitcoin mining companies. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service and sports organizations remain external NPC partners, suppliers, sponsors, landlords, financiers or strategic allies.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), and [FreeSims](https://github.com/francot514/FreeSims). No protected assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot CanvasLayer documentation](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html), and [Godot Button documentation](https://docs.godotengine.org/en/stable/classes/class_button.html).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
