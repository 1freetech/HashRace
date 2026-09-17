# Hash Race Downloads

Current public version target: **v0.035**

- [Windows x64 — Hash Race v0.035](https://github.com/1freetech/HashRace/releases/download/v0.035/HashRace-v0.035-windows-x64.zip)
- [Linux x64 — Hash Race v0.035](https://github.com/1freetech/HashRace/releases/download/v0.035/HashRace-v0.035-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.035 gameplay and visual update

The playable Godot world now uses an original Game Boy Color-style Hash Race operator based on the approved character direction. The player has brown skin, rounded textured dark hair, a sleek white and graphite futuristic field suit, orange mining-tech accents and a bright green one-eye scanner. The design is drawn procedurally in GDScript so it stays crisp with the existing pixel renderer and does not depend on protected character artwork.

The character is animated by the existing RPG movement code. Walking left, right, up and down changes the character direction; moving alternates the legs and arms and adds a pixel-step bob, while stopping returns the operator to an idle state. Rival mining-company representatives and external NPC partner representatives keep their existing presentation, so the player remains visually distinct without changing the ten-miner company model.

All ten league companies remain Bitcoin mining companies. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service and sports organizations remain external NPC partners, suppliers, sponsors, landlords, financiers or strategic allies.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), and [FreeSims](https://github.com/francot514/FreeSims). No protected assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot custom drawing documentation](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html), and [Godot 2D documentation](https://docs.godotengine.org/en/stable/tutorials/2d/).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
