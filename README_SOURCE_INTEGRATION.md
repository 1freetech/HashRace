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
