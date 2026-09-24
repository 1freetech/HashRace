# Hash Race source-code report

## Official Godot implementation basis

Godot 4.7 SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Godot resource loading guidance: https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html

Imported project textures are loaded as Godot resources (`load`/`preload`/ResourceLoader) rather than depending on source-file filesystem access in exported builds. `SpriteFrames.add_frame()` appends explicitly supplied Texture2D frames; walking order therefore requires visually verified authored poses and is never inferred from numeric frame parity.

## Proven repository implementation inspected

The last intact PR runtime tree `63439529e3ef866463d692acd2018d6030761483` was inspected before the current repair. Its player catalog uses explicit per-facing frame regions and SpriteFrames, and its imported art uses `res://` project resources. The recovered live entry point is intentionally stable: `Godot/scenes/world.tscn -> res://scripts/world.gd`.

## Current source and contract repair

Gameplay commit `51c82fd7486df60f5a33e7d7ad2ec9d7d07a5f6b` changed `Godot/scripts/world.gd`. `CAMPUS` contains the actual wind destination `Rect2(1310, 260, 220, 220)`. `_ready()` registers its grounded navigation footprint through `grid_nav.block_rect(_ground_foot(rect))`; `_draw_wind()` draws to that same placement; `debug_wind_ready()` verifies the imported 128x128 Texture2D and non-walkable grounded footprint.

Contract commit `30e1d206aa8a9d4ff329d0ddc9744fb66449f709` changed `tools/test_v164_wind_asset.py`. The wind PNG signature, CRC, SHA-256 `5087f4b52e2fe324669efc6ffee0b4bbfd000b80d2280b7f73869ded94330c7d`, byte length 2278 and 128x128 dimensions remain mandatory.

Runtime-proof commit `e05de960c39d174338b57f98aa3ef08cbf320041` changed `Godot/scripts/capture_v164_wind.gd` to instantiate real `world.tscn`, require `debug_wind_ready()`, center on the live placement, wait for rendered frames and write `visual-proof/v164-wind-overview.png`.

Latest contract repair commit `45318e0d9c3d8b7ce74c6cc83e571566827fcf70` changes `tools/test_v161_solar_overview.py`. The failing preservation assertion no longer treats historical `world_v164.gd` as the live scene. It now verifies the actual stable entry point, the imported `SOLAR_ART` preload at `res://art/energy/solar_array_overview.png`, the `CAMPUS.solar` placement, live `_draw_asset(SOLAR_ART, CAMPUS.solar)` call, and the shared grounded collision registration. The original solar PNG SHA-256, PNG signature/CRC, 128x136 dimensions and transparency checks remain unchanged.

## Asset provenance and binary/decode evidence

Wind repository binary: `Godot/art/energy/wind_turbine_directional_sheet.png`; runtime path `res://art/energy/wind_turbine_directional_sheet.png`; baseline Git blob `f908cc6993452c8d9d2f43c612535b3d90a0e236`.

Solar repository binary: `Godot/art/energy/solar_array_overview.png`; runtime path `res://art/energy/solar_array_overview.png`; required SHA-256 `06b542233279854dea18a10cf10e16b32772057add0bec8f896fc2a282ab407f`.

At exact head `57b742804ce73a6230f366e3ac288f7693595551`, GitHub's Godot smoke job successfully completed fresh-checkout image import/decode, live walking cadence validation, campaign boot and character preview before later failing an unrelated selected-company transition. The dedicated `v0.164 exact-head wind proof` workflow completed successfully at that same head. The multi-language Python job failed specifically at the stale solar live-wiring contract repaired by `45318e0d...`.

## Walking state

No new walking fix is claimed. The stable `world.gd` still draws one player-sheet region. The repository binary could not be visually inspected through the GitHub text connector in this pass, so numeric frame indices are not accepted as evidence of alternating left/right legs. A walking change must wait for visible pose verification, then construct the explicit sequence with SpriteFrames/AnimatedSprite2D and render it in gameplay.

## Exact-head gate

The contract repair changes the exact head. Therefore the successful wind screenshot/CI from `57b742804...` cannot by itself authorize merge of the new head. The new exact head must rerun fresh Godot import/decode, runtime render/screenshot and all required CI. No new 34-point gameplay item is counted until those gates succeed.
