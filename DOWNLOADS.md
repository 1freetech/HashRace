# Hash Race Downloads

Current public version target: **v0.022**

- [Windows x64 — Hash Race v0.022](https://github.com/1freetech/HashRace/releases/download/v0.022/HashRace-v0.022-windows-x64.zip)
- [Linux x64 — Hash Race v0.022](https://github.com/1freetech/HashRace/releases/download/v0.022/HashRace-v0.022-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot/export checks and publishes both assets. Do not treat a version as downloadable until its release assets exist.

## v0.022 gameplay change

The shipped Godot world now has a **Bitcoin Mining League standings screen**. A persistent `LEAGUE #x / 10` indicator shows the player's current competitive position, and the STANDINGS control opens all ten mining companies ranked by live company asset value. Hardware, energized MW, land, cash, BTC treasury value, and the broader company-building loop therefore feed a visible sports-franchise-style race instead of leaving the player without a clear league position.

All ten league entries remain Bitcoin mining companies. AI, robotics, semiconductor, energy, telecom, real-estate, finance, infrastructure, retail/quick-service, and sports organizations remain external NPC partners, suppliers, sponsors, landlords, financiers, or strategic allies. The standings layer sits above the existing dynamic 0-100 company culture, material rating effects, flexible day/week/month/quarter clock, RPG towns, and 0-100 BTC hold strategy.

The automated test suite now includes a dedicated ten-miner league contract in addition to the Godot 4.7.2 boot/render validation and the existing Python, C++, Rust, and TypeScript checks.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot CanvasLayer documentation](https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html), and [Godot Button documentation](https://docs.godotengine.org/en/stable/classes/class_button.html).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
