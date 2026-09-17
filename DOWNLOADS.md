# Hash Race Downloads

Current public version target: **v0.053**

- [Windows x64 — Hash Race v0.053](https://github.com/1freetech/HashRace/releases/download/v0.053/HashRace-v0.053-windows-x64.zip)
- [Linux x64 — Hash Race v0.053](https://github.com/1freetech/HashRace/releases/download/v0.053/HashRace-v0.053-linux-x64.tar.gz)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above become live only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot, rendered-frame proof, export and packaging checks. Do not treat a version as downloadable until its release assets exist.

## v0.053 character-detail update

The player and world representatives now share a higher-detail procedural pixel character build. The new construction adds a stronger spiky-hair silhouette, white headset/ear protection, layered face shading, a neon one-eye scanner visor, articulated suit panels, shoulder guards, knee pads, gloves, boots and a readable chest mark. The default Operator Suit uses the approved light shell, orange armor pads and neon-green scanner palette.

NPC representatives use the same detailed body construction rather than falling back to the older low-detail worker shape. Their company or partner accent colors are applied to armor trim and field-ID pixels, so they remain visually distinct while matching the player's detail level. The existing neon-green name labels remain directly above every character.

The renderer remains original GDScript and uses the existing nearest-neighbor pixel pipeline. No protected character artwork or sprite sheets are included.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), and [FreeSims](https://github.com/francot514/FreeSims). No protected assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot custom drawing documentation](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html), and [Godot 2D documentation](https://docs.godotengine.org/en/stable/tutorials/2d/).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
