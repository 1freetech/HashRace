# Hash Race source-code report

## Official Godot implementation basis

Godot 4.7 ImageTexture: https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html

Godot 4.7 SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Godot 4.7 DirAccess/resource export guidance: https://docs.godotengine.org/en/4.7/classes/class_diraccess.html

Imported project textures are loaded as Godot resources (`load`/`preload`/ResourceLoader) rather than depending on source-file filesystem access in exported builds. `SpriteFrames.add_frame()` appends explicitly supplied Texture2D frames; walking order therefore requires visually verified authored poses and is never inferred from numeric frame parity.

## Proven repository implementation inspected

Before the repair, the last intact PR runtime tree `63439529e3ef866463d692acd2018d6030761483` was inspected. Its player catalog uses explicit per-facing frame regions and SpriteFrames, and its imported art uses `res://` project resources. The current recovered stable entry point is `Godot/scenes/world.tscn -> res://scripts/world.gd`.

## Current source repair

Gameplay commit `51c82fd7486df60f5a33e7d7ad2ec9d7d07a5f6b` changes `Godot/scripts/world.gd`. `CAMPUS` now includes the actual wind destination `Rect2(1310, 260, 220, 220)`. `_ready()` therefore registers the wind ground footprint through the same `grid_nav.block_rect(_ground_foot(rect))` path used by other infrastructure. `_draw_wind()` now draws to `CAMPUS.wind` instead of duplicating coordinates. New `debug_wind_ready()` verifies the imported 128x128 Texture2D and verifies that the grounded footprint center is not walkable. `debug_runtime_ready()` includes that contract.

Contract commit `30e1d206aa8a9d4ff329d0ddc9744fb66449f709` changes `tools/test_v164_wind_asset.py`. The PNG signature, CRC, SHA-256 `5087f4b52e2fe324669efc6ffee0b4bbfd000b80d2280b7f73869ded94330c7d`, byte length 2278, and 128x128 dimensions remain mandatory. The live-wiring assertions now inspect the actual stable `world.gd` entry point instead of the obsolete numbered world entry.

Runtime-proof commit `e05de960c39d174338b57f98aa3ef08cbf320041` changes `Godot/scripts/capture_v164_wind.gd`. It instantiates the real `world.tscn`, requires `debug_wind_ready()`, centers the camera on the live wind placement, waits for rendered frames, and writes `visual-proof/v164-wind-overview.png`. Removed calls to obsolete numbered-world deployment APIs.

## Asset provenance and binary evidence

Repository binary: `Godot/art/energy/wind_turbine_directional_sheet.png`. Runtime resource path: `res://art/energy/wind_turbine_directional_sheet.png`. Git blob at the repaired baseline: `f908cc6993452c8d9d2f43c612535b3d90a0e236`. The source contract validates the original binary before runtime proof; no concept art or unvalidated replacement is counted.

## Walking state

No walking change is claimed in this pass. The recovered stable `world.gd` currently draws one player-sheet region, so alternating-leg walking remains unresolved. Historical `default_player_sprite_sheet.gd` was inspected for the proven SpriteFrames construction method, but its numeric source order is not accepted as visual proof by itself. A later walking commit must first visually verify the sheet poses, record explicit left/right ordering, then render that exact animation.

## CI and screenshot state

Exact head before the repair, `21e9e1622f32116c3cc1be9d5c7601d1c88adb1b`, failed the wind workflow at `Validate real wind PNG binary and live wiring`; fresh import and rendering were skipped. Inspection showed the stale contract expected `world_v164.gd` directly in `world.tscn`, while the recovered current scene actually uses `world.gd`.

The report commit changes the exact head again. No older screenshot is accepted. Integration remains unclaimed until the final exact head completes fresh Godot 4.7.2 import/decode, actual runtime wind rendering, fresh screenshot artifact, and green exact-head CI. Do not merge before those gates pass.
