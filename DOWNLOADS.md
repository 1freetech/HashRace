# Hash Race Downloads

Current verified public version: **v0.073**

- [Windows x64 — Hash Race v0.073](https://github.com/1freetech/HashRace/releases/download/v0.073/HashRace-v0.073-windows-x64.zip)
- [Linux x64 — Hash Race v0.073](https://github.com/1freetech/HashRace/releases/download/v0.073/HashRace-v0.073-linux-x64.tar.gz)
- [Hash Race v0.073 release](https://github.com/1freetech/HashRace/releases/tag/v0.073)
- [All releases](https://github.com/1freetech/HashRace/releases)

The version-specific links above are published only after the [Godot release workflow](https://github.com/1freetech/HashRace/actions) finishes its headless boot, rendered-frame proof, export, packaging, and playable-build checks.

## v0.073 reusable high-detail character update

The player and company/NPC representatives now use a shared high-density procedural pixel-character rig with a finer 3-pixel source grid, crisp nearest-neighbor rendering, front/back/left/right silhouettes, five body builds, four hair families, layered cyber workwear, headset/ear protection, scanner visors, gloves, segmented boots, and company-colored identifiers.

The same system supports directional idle, walk and run pose names plus reusable mining and victory actions. Existing skin-tone, presentation and outfit choices continue to drive the player build, while NPCs receive deterministic body, hair, skin and facing variation so the world can reuse one visual system without making every representative look identical.

The v0.073 release passed Godot source boot, live overworld validation, rendered overworld and close-up proofs, Windows export, Linux export, and exported Linux binary boot verification before its desktop packages were published.

## v0.059 data-center infrastructure update

The mining-town infrastructure now uses a denser procedural rack style based on the supplied Godot drawing code and pixel references. Each compute pod contains four visible rack faces with individual server sleds, intake grilles, multi-color activity LEDs, company-color service accents, cooling fans, and short colored patch leads.

The neighboring power equipment is now drawn as vented electrical/cooling cabinets with fan faces, hazard striping, live status lights, and top hardware. A compact network switch and a three-lane blue/green/orange cable tray appear around the town being explored, so the site reads as connected compute infrastructure without filling the whole map with cords or text.

The release gate now requires the v0.059 infrastructure controller to initialize before the close-up render proof and packaged desktop builds are published.

## v0.055 procedural-building update

The live overworld now renders facilities from code-generated 96×128 RGBA pixel textures instead of relying on flat building blocks. Headquarters, partner offices, machine markets, power buildings, banks, and land offices each receive a distinct facade style with foundations, roofs, windows or equipment intakes, doors, masonry or panel detail, shadows, and company-colored accents.

The new renderer uses transparent building backgrounds so facilities sit naturally on the existing terrain instead of carrying a sky-colored rectangle. Nearest-neighbor filtering keeps the pixel edges crisp, while a texture cache avoids rebuilding the same facade every draw. The wider campus spacing and proximity-gated building labels remain in place to keep the map readable.

The v0.055 release includes CI-rendered overworld and close-up visual proofs. Windows and Linux exports both passed the release gate, and the exported Linux binary was boot-tested before publication.

## Open-source simulation references

Hash Race uses original code and original game content. The Life + Operations layer was informed by reusable design ideas from [FreeSO](https://github.com/riperiperi/FreeSO), [OpenTS2](https://github.com/LazyDuchess/OpenTS2), and [FreeSims](https://github.com/francot514/FreeSims). No protected assets, characters, names, proprietary game content, or required original-game files are included.

Useful implementation references: [Godot GDScript documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/), [Godot custom drawing documentation](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html), and [Godot 2D documentation](https://docs.godotengine.org/en/stable/tutorials/2d/).

## Build stack

The primary playable client is exported from [Godot 4.7.2](https://godotengine.org/), with gameplay written mainly in [GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/). Hash Race keeps supporting C#, C++, Rust, and TypeScript components only where they provide a concrete engineering benefit.
