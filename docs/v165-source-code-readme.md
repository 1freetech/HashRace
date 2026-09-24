# Hash Race source-code report

## Official Godot implementation basis

Godot 4.7 SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Godot 4.7 importing images: https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html

Imported project textures are loaded as Godot resources (`load`/`preload`/ResourceLoader) so runtime uses imported Texture2D resources. `SpriteFrames.add_frame()` appends explicitly supplied Texture2D frames; walking order therefore requires visually verified authored poses and is never inferred from numeric frame parity.

## Proven repository implementation inspected

The last intact PR runtime tree `63439529e3ef866463d692acd2018d6030761483` was inspected before the repair series. Its player catalog uses explicit per-facing frame regions and SpriteFrames, and its imported art uses `res://` project resources. The recovered live entry point is intentionally stable: `Godot/scenes/world.tscn -> res://scripts/world.gd`.

The successful exact-head wind capture is the proven screenshot method: instantiate the live scene, wait 12 process frames, validate live wiring, request redraw, wait 12 more process frames plus 0.25 seconds, then read the root viewport.

## Current source and contract repairs

Gameplay commit `51c82fd7486df60f5a33e7d7ad2ec9d7d07a5f6b` changed `Godot/scripts/world.gd`. `CAMPUS` contains the actual wind destination `Rect2(1310, 260, 220, 220)`. `_ready()` registers its grounded navigation footprint through `grid_nav.block_rect(_ground_foot(rect))`; `_draw_wind()` draws to that same placement; `debug_wind_ready()` verifies the imported 128x128 Texture2D and non-walkable grounded footprint.

Contract commit `30e1d206aa8a9d4ff329d0ddc9744fb66449f709` changed `tools/test_v164_wind_asset.py`. The wind PNG signature, CRC, SHA-256 `5087f4b52e2fe324669efc6ffee0b4bbfd000b80d2280b7f73869ded94330c7d`, byte length 2278 and 128x128 dimensions remain mandatory.

Runtime-proof commit `e05de960c39d174338b57f98aa3ef08cbf320041` changed `Godot/scripts/capture_v164_wind.gd` to instantiate real `world.tscn`, require `debug_wind_ready()`, center on the live placement, wait for rendered frames and write `visual-proof/v164-wind-overview.png`.

Solar preservation commit `45318e0d9c3d8b7ce74c6cc83e571566827fcf70` changed `tools/test_v161_solar_overview.py` so the preservation assertion follows the stable runtime instead of historical numbered wiring. It verifies the imported `SOLAR_ART` preload, `CAMPUS.solar`, live draw call and shared grounded collision registration without weakening binary checks.

Core-contract commit `7a499ff27b27aa2f745dd3ef5ce1184b9e2fa16b` changed `tools/smoke_test.py` so the live-world assertion accepts the stable `world.gd` entry point or a historical numbered world while still requiring the resolved script to exist.

Gameplay capture commit `94ec44f0e9e49f5c98350c8426e9c584b364ebd5` changed `Godot/scripts/gameplay_capture.gd` to reproduce the already-green wind cadence: 12 process frames, runtime validation, redraw, 12 process frames, 0.25-second timer, root viewport read/save.

League-contract commit `13a2930d2732b1137b21de8486d5f0ee2651b13b` changes `tools/test_league_contract.py`. Exact head `98526459a2a43598da61826182a39aebdf9a33f4` proved fresh Godot import/decode and the core mining/concept contract, then failed at the ten-miner league contract because that test still required `world_v###.gd` and VERSION coupling. The live scene actually declares `res://scripts/world.gd`. The repair accepts `world.gd` or historical numbered worlds, still requires the resolved script to exist, and preserves every league/company/inheritance assertion. It removes only obsolete runtime-version coupling.

## Asset provenance and binary/decode evidence

Wind repository binary: `Godot/art/energy/wind_turbine_directional_sheet.png`; runtime path `res://art/energy/wind_turbine_directional_sheet.png`; Git blob `f908cc6993452c8d9d2f43c612535b3d90a0e236`; 2278 bytes; 128x128; required SHA-256 `5087f4b52e2fe324669efc6ffee0b4bbfd000b80d2280b7f73869ded94330c7d`.

Solar repository binary: `Godot/art/energy/solar_array_overview.png`; runtime path `res://art/energy/solar_array_overview.png`; required SHA-256 `06b542233279854dea18a10cf10e16b32772057add0bec8f896fc2a282ab407f`.

At exact head `98526459a2a43598da61826182a39aebdf9a33f4`, the dedicated wind proof was green and the main Godot job successfully imported and decoded fresh-checkout runtime image binaries. The main Godot job then failed later at selected-company transition, while the Python job failed at the obsolete league entry-point assertion. The clean-runtime job fresh-imported successfully but failed at Render gameplay. No skipped screenshot is counted as visual proof.

## Walking state

No new walking fix is claimed. Godot 4.7 defines SpriteFrames as the frame library for AnimatedSprite2D and `add_frame()` appends frames in explicit order. The repository player-sheet pixels have not been visually established in this run as alternating left/right poses, so numeric indices are not accepted as evidence. A walking change remains gated on visible pose verification plus fresh rendered motion proof.

## Exact-head gate

The league source-contract repair is `13a2930d2732b1137b21de8486d5f0ee2651b13b`. This report commit changes the exact head again. Fresh exact-head Godot import/decode, actual gameplay screenshot artifact and all required CI must pass before merge. No new 34-point gameplay item is counted solely from source wiring or a code-only contract repair.
