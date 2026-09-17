# Hash Race Downloads

Current verified public version: **v0.055**

- [Windows x64 — Hash Race v0.055](https://github.com/1freetech/HashRace/releases/download/v0.055/HashRace-v0.055-windows-x64.zip)
- [Linux x64 — Hash Race v0.055](https://github.com/1freetech/HashRace/releases/download/v0.055/HashRace-v0.055-linux-x64.tar.gz)
- [Hash Race v0.055 release](https://github.com/1freetech/HashRace/releases/tag/v0.055)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above are published only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot, rendered-frame proof, export, packaging, and playable-build checks.

## v0.055 procedural-building update

The live overworld now renders facilities from code-generated 96×128 RGBA pixel textures instead of relying on flat building blocks. Headquarters, partner offices, machine markets, power buildings, banks, and land offices each receive a distinct facade style with foundations, roofs, windows or equipment intakes, doors, masonry or panel detail, shadows, and company-colored accents.

The new renderer uses transparent building backgrounds so facilities sit naturally on the existing terrain instead of carrying a sky-colored rectangle. Nearest-neighbor filtering keeps the pixel edges crisp, while a texture cache avoids rebuilding the same facade every draw. The wider campus spacing and proximity-gated building labels remain in place to keep the map readable.

The v0.055 release includes CI-rendered overworld and close-up visual proofs. Windows and Linux exports both passed the release gate, and the exported Linux binary was boot-tested before publication.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), and [FreeSims](https://github.com/francot514/FreeSims). No protected assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot custom drawing documentation](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html), and [Godot 2D documentation](https://docs.godotengine.org/en/stable/tutorials/2d/).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
