# Hash Race source integration report

## Current proof target
PR #94 branch `automation/v164-wind-forward-port`.

## Godot implementation contract
Godot 4.7 SpriteFrames documents that `add_frame()` appends a Texture2D when no insertion position is supplied and that animation FPS controls playback:
https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Godot 4.7 ImageTexture documentation recommends `load()` for imported textures instead of filesystem Image loading because filesystem loading may fail in exported projects:
https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html

## Proven repository method
The player implementation preserves the previously rendered walking method from commit `9f3e8c2`: four visually inspected authored poses per facing in explicit source order 1, 3, 5, 7 at 8 FPS. Current path: `Godot/scripts/default_player_sprite_sheet.gd`.

## Current asset/runtime evidence
The infrastructure runtime uses imported `res://art/...` Texture2D resources and live Sprite2D nodes. Wind exact-head proof is green. Binary-specific validators remain responsible for PNG signature, dimensions/alpha/hash/decode evidence.

## 2026-09-26 clean-runtime repair
Changed `.github/workflows/gameplay-proof.yml` Fresh import from `--quit-after 2` to `--quit-after 120`. The prior exact-head log showed Godot leaving fresh import before PNG resources had loaders, then `world.gd` failed parsing every preloaded PNG. This change gives the editor import scan time to complete before gameplay capture.

Commit: `0eb713190547d1591e8b127ca9dfa321fbd50e32`.

## Acceptance gate
Do not count an inspection item complete until the exact head has a successful fresh Godot import, actual gameplay execution, a non-empty fresh screenshot showing the change, and green applicable CI. Do not merge PR #94 before those gates pass.


## 2026-09-26 exact-head runtime repair and inspected proof
Changed `Godot/scripts/world.gd::npc_population_ready()` so palette uniqueness uses Godot's `str()` conversion for Color values rather than invalid constructor-style `String(Color)` calls. Commit `d432e124158a58782f740c65370c1df7e2ba87c1`.

Changed `tools/test_energy_visual_contract.py` to validate the live `Sprite2D` / `AtlasTexture` infrastructure path and reject the obsolete CanvasItem `_draw_asset` / `_draw_wind` / `draw_texture_rect_region` renderer. Commit `3c8b5ac02f008e320a925fcef3662e8c81aa5e6f`.

At exact head `3c8b5ac02f008e320a925fcef3662e8c81aa5e6f`, both **Clean runtime gameplay proof** and **v0.164 exact-head wind proof** completed successfully. The clean-runtime artifact `gameplay-clean-runtime.png` was downloaded and visually inspected: it shows the live campus with the imported container, solar unit, transformer, ASIC hardware, wind turbine and five character sprites. The four NPCs visibly use different palettes and are separated spatially. The screenshot also exposes remaining 34-point work rather than hiding it: the wind tile retains a large gray rectangular background, asset scale/style remains inconsistent, and the campus composition still has substantial unstructured negative space. Those items remain open.

Walking remains wired through `Godot/scripts/default_player_sprite_sheet.gd::build_frames_from_texture()` using the previously visually proven explicit source order `[1, 3, 5, 7]` for every facing and `AnimatedSprite2D` / `SpriteFrames`; this report does not claim a new walking visual fix from the single inspected still frame.

Official implementation references:
- SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html
- AnimatedSprite2D: https://docs.godotengine.org/en/4.7/classes/class_animatedsprite2d.html
- AtlasTexture: https://docs.godotengine.org/en/4.7/classes/class_atlastexture.html
- ResourceLoader: https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html
