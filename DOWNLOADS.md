# Hash Race Downloads

Current public version: **v0.006**

- [Windows x64 — Hash Race v0.006](https://github.com/1freetech/HashRace/releases/download/v0.006/HashRace-v0.006-windows-x64.zip)
- [Linux x64 — Hash Race v0.006](https://github.com/1freetech/HashRace/releases/download/v0.006/HashRace-v0.006-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

These links are populated by the Godot release workflow after the versioned Windows and Linux exports pass the headless boot/export jobs. The repository should not describe a version as downloadable until its release assets exist.

## v0.006 gameplay change

The END QUARTER preview now acts like a simple front-office risk screen. Before the player commits roughly 91 days, Hash Race shows the projected quarterly cash result and projected ending cash. Losing quarters also show estimated operating-cost runway, while a quarter projected to push cash below zero gets a clear danger warning with practical recovery choices such as financing, selling BTC, cutting costs, or delaying expansion. The goal is to make long campaign turns easier to understand and reduce accidental bankruptcies without removing risk.

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
