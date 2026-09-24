# Hash Race source-code report

## Official Godot implementation basis

Godot 4.7 SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Godot 4.7 TSCN/resources: https://docs.godotengine.org/en/4.7/engine_details/file_formats/tscn.html

Godot SceneTree scene loading: https://docs.godotengine.org/en/latest/tutorials/scripting/scene_tree.html

Imported project textures are loaded as Godot resources (`load`/`preload`/ResourceLoader). `SpriteFrames.add_frame()` appends explicitly supplied Texture2D frames; walking order therefore requires visually verified authored poses and is never inferred from numeric frame parity.

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

League-contract commit `13a2930d2732b1137b21de8486d5f0ee2651b13b` changed `tools/test_league_contract.py` to remove obsolete numbered-world coupling while retaining the league/company assertions.

Stable-world validation commits `b16189aa3314345974940ab0db86046c747ad54a` and `83165c50ca3c3dcf0a7e7d04ba7a86cb194fe926` changed `Godot/scripts/validate_overworld.gd`. The old validator still required dozens of retired `debug_vXXX_ready` methods even though `world.tscn` now deliberately enters `world.gd`. The replacement validates the actual PackedScene load/instantiate path, `debug_runtime_ready()`, `debug_wind_ready()`, the live Camera2D, all five registered infrastructure collision footprints, and real open-terrain player movement. It does not weaken those current-runtime checks by pretending removed historical layers are still gameplay architecture.

## Asset provenance and binary/decode evidence

Wind repository binary: `Godot/art/energy/wind_turbine_directional_sheet.png`; runtime path `res://art/energy/wind_turbine_directional_sheet.png`; Git blob `f908cc6993452c8d9d2f43c612535b3d90a0e236`; 2278 bytes; 128x128; required SHA-256 `5087f4b52e2fe324669efc6ffee0b4bbfd000b80d2280b7f73869ded94330c7d`.

Solar repository binary: `Godot/art/energy/solar_array_overview.png`; runtime path `res://art/energy/solar_array_overview.png`; required SHA-256 `06b542233279854dea18a10cf10e16b32772057add0bec8f896fc2a282ab407f`.

At exact head `39d376d9cd6f1b7e78179188ece6835bf346ce67`, the dedicated wind proof was green. The main Godot job successfully imported/decoded fresh-checkout runtime image binaries, validated walking distance/animation cadence/four-way idle, booted campaign setup, validated character preview, and booted the real company town network. It failed only when the obsolete selected-company/legacy-overworld validator ran, so screenshot stages were skipped. The clean-runtime proof also failed later and therefore supplied no qualifying screenshot artifact. No skipped screenshot is counted as visual proof.

## Walking state

No new alternating-leg fix is claimed. Godot 4.7 defines SpriteFrames as the frame library for AnimatedSprite2D and `add_frame()` appends frames in explicit order. Although CI validates movement distance, cadence and four-way idle, the actual player-sheet pixels have not been visually established in this run as alternating left/right poses. Numeric indices are not accepted as evidence. Walking remains gated on visible pose verification plus fresh rendered motion proof.

## Exact-head gate

Current source repair head before this report: `83165c50ca3c3dcf0a7e7d04ba7a86cb194fe926`. This report commit changes the exact head again. Fresh exact-head Godot import/decode, actual gameplay screenshot artifact and all required CI must pass before merge. No new 34-point gameplay item is counted solely from source wiring or a code-only validation repair.
