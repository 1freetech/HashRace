# Hash Race source-code report

## Official Godot implementation basis

Godot 4.7 SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Godot 4.7 DirAccess / exported-resource guidance: https://docs.godotengine.org/en/4.7/classes/class_diraccess.html

Godot import process: https://docs.godotengine.org/en/latest/tutorials/assets_pipeline/import_process.html

Imported project textures are loaded as Godot resources (`load`/`preload`/ResourceLoader) rather than depending on source-file filesystem access in exported builds. Godot documents that imported assets may not retain their source files in exported PCKs and recommends ResourceLoader. `SpriteFrames.add_frame()` appends explicitly supplied Texture2D frames; walking order therefore requires visually verified authored poses and is never inferred from numeric frame parity.

## Proven repository implementation inspected

The last intact PR runtime tree `63439529e3ef866463d692acd2018d6030761483` was inspected before the repair series. Its player catalog uses explicit per-facing frame regions and SpriteFrames, and its imported art uses `res://` project resources. The recovered live entry point is intentionally stable: `Godot/scenes/world.tscn -> res://scripts/world.gd`.

The successful exact-head wind capture is also the proven screenshot method for this run: instantiate the live scene, wait for `_ready()` and imports, validate live wiring, request redraw, wait additional frames/timer, then read viewport pixels.

## Current source and contract repairs

Gameplay commit `51c82fd7486df60f5a33e7d7ad2ec9d7d07a5f6b` changed `Godot/scripts/world.gd`. `CAMPUS` contains the actual wind destination `Rect2(1310, 260, 220, 220)`. `_ready()` registers its grounded navigation footprint through `grid_nav.block_rect(_ground_foot(rect))`; `_draw_wind()` draws to that same placement; `debug_wind_ready()` verifies the imported 128x128 Texture2D and non-walkable grounded footprint.

Contract commit `30e1d206aa8a9d4ff329d0ddc9744fb66449f709` changed `tools/test_v164_wind_asset.py`. The wind PNG signature, CRC, SHA-256 `5087f4b52e2fe324669efc6ffee0b4bbfd000b80d2280b7f73869ded94330c7d`, byte length 2278 and 128x128 dimensions remain mandatory.

Runtime-proof commit `e05de960c39d174338b57f98aa3ef08cbf320041` changed `Godot/scripts/capture_v164_wind.gd` to instantiate real `world.tscn`, require `debug_wind_ready()`, center on the live placement, wait for rendered frames and write `visual-proof/v164-wind-overview.png`.

Solar preservation commit `45318e0d9c3d8b7ce74c6cc83e571566827fcf70` changed `tools/test_v161_solar_overview.py` so the preservation assertion follows the stable runtime instead of historical `world_v164.gd` wiring. It verifies the imported `SOLAR_ART` preload, `CAMPUS.solar`, live draw call and shared grounded collision registration without weakening binary checks.

Core-contract commit `7a499ff27b27aa2f745dd3ef5ce1184b9e2fa16b` changed `tools/smoke_test.py` so the live-world assertion accepts the stable `world.gd` entry point or a historical numbered world while still requiring the resolved script to exist.

Gameplay-proof repair commit `8705dd0563ad84867ecf7d4fe542cb6966c6efa0` changes `Godot/scripts/gameplay_capture.gd`. Exact head `f6104c1947231305d82fc1c8f31b0cd9edda3156` completed fresh Godot import but failed specifically at `Render gameplay`; artifact upload was skipped. The old capture read `root.get_texture().get_image()` immediately after runtime validation. The repair reproduces the already-green wind capture sequence: wait 12 frames after scene instantiation, validate `debug_runtime_ready()`, `queue_redraw()`, wait another 12 frames plus 0.25 seconds, await `RenderingServer.frame_post_draw`, then read/save the viewport. Failure paths now distinguish missing viewport pixels from PNG-save failure.

## Asset provenance and binary/decode evidence

Wind repository binary: `Godot/art/energy/wind_turbine_directional_sheet.png`; runtime path `res://art/energy/wind_turbine_directional_sheet.png`; baseline Git blob `f908cc6993452c8d9d2f43c612535b3d90a0e236`.

Solar repository binary: `Godot/art/energy/solar_array_overview.png`; runtime path `res://art/energy/solar_array_overview.png`; required SHA-256 `06b542233279854dea18a10cf10e16b32772057add0bec8f896fc2a282ab407f`.

At exact head `f6104c1947231305d82fc1c8f31b0cd9edda3156`, the dedicated `v0.164 exact-head wind proof` completed successfully. The clean runtime workflow completed checkout, exact-head verification, Godot 4.7.2 installation and fresh import, then failed specifically at `Render gameplay`. The screenshot artifact was not uploaded. That render/capture defect is repaired by `8705dd0...`; the new head must prove it independently.

## Walking state

No new walking fix is claimed. Godot 4.7 defines SpriteFrames as the frame library for AnimatedSprite2D and `add_frame()` appends frames in explicit order. The repository player-sheet pixels still have not been visually established in this run as alternating left/right poses, so numeric indices are not accepted as evidence. A walking change remains gated on visible pose verification plus fresh rendered motion proof.

## Exact-head gate

This report commit follows gameplay-proof repair `8705dd0...` and therefore changes the exact head again. Previous green wind proof cannot authorize merge of the new head. Fresh exact-head Godot import/decode, actual gameplay screenshot artifact and required CI must pass before merge. No new 34-point gameplay item is counted solely from source wiring or a code-only capture repair.
