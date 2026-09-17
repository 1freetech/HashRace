# Hash Race Downloads

Current public version target: **v0.033**

- [Windows x64 — Hash Race v0.033](https://github.com/1freetech/HashRace/releases/download/v0.033/HashRace-v0.033-windows-x64.zip)
- [Linux x64 — Hash Race v0.033](https://github.com/1freetech/HashRace/releases/download/v0.033/HashRace-v0.033-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.033 gameplay playability update

High burnout now protects the player from an easy self-defeating action. When Burnout Risk reaches 50/100, manual TRAIN is temporarily locked and the game tells the player to RECOVER first. This prevents a training click from spending company cash, draining more Energy, increasing burnout and reducing Bitcoin-mining uptime while the operator is already exhausted.

The Life + Site display shows `TRAIN LOCKED` during the danger state. AUTO still chooses RECOVER at high burnout, and normal manual training returns when Burnout Risk falls below 50/100. Energy, Focus, Social and Burnout remain on the shared 0-100 scale.

All ten league companies remain Bitcoin mining companies. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service and sports organizations remain external NPC partners, suppliers, sponsors, landlords, financiers or strategic allies.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), [FreeSims](https://github.com/francot514/FreeSims), [The Sims Resource Downloader](https://github.com/Xientraa/The-Sims-Resource-Downloader), and [Microsoft Sims](https://github.com/microsoft/Sims). No protected Sims assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot CanvasLayer documentation](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html), and [Godot Button documentation](https://docs.godotengine.org/en/stable/classes/class_button.html).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
