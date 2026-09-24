# Hash Race source-code report

## Official Godot implementation basis

Godot 4.7 SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Godot 4.7 ImageTexture: https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html

Godot 4.7 ResourceLoader: https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html

Imported project textures stay Godot resources loaded through `load`/`preload`/ResourceLoader; the ImageTexture documentation explicitly warns that filesystem Image loading may fail in exported projects. `SpriteFrames.add_frame()` appends explicitly supplied Texture2D frames, so walking order must come from visually verified authored poses rather than numeric parity.

## Proven repository implementation inspected

The last intact runtime tree `63439529e3ef866463d692acd2018d6030761483` was inspected before the repair series. Its character implementation uses explicit facing regions/SpriteFrames and its imported art uses `res://` resources. The current live entry point is deliberately stable: `Godot/scenes/world.tscn -> res://scripts/world.gd`.

The last successful wind proof establishes the screenshot cadence used here: instantiate the real world, wait 12 process frames, validate live wiring, request redraw, wait another 12 frames plus 0.25 seconds, then read the root viewport.

## Current semantic runtime API

Commit `c97f462da5e55ee42068ce59cf9ae5993c1da01c` rebuilt `Godot/scripts/world.gd` around unnumbered APIs: `move_player()`, `runtime_ready()`, `infrastructure_ready(asset_id)`, `infrastructure_rect(asset_id)`, and `infrastructure_footprint(asset_id)`. `debug_wind_ready()` and `debug_runtime_ready()` remain only unnumbered compatibility wrappers while callers migrate.

Commit `bc64b1d9f3c50e4b1a79ecaa8502ce2c15129529` changed `Godot/scripts/validate_overworld.gd` to call those semantic APIs. Exact-head CI subsequently passed fresh import/decode, walking cadence/four-way idle, campaign boot, company-town boot, and the selected-company/playable-town validator. The validator printed `HASH RACE WORLD OK: semantic runtime APIs, five collision footprints, camera and movement validated`.

## Current CI repairs

Exact head `bc64b1d9f3c50e4b1a79ecaa8502ce2c15129529` exposed two remaining stale callers rather than a gameplay parse/import failure.

Commit `68146d786795c52d548ac8105bb4044fbdc00600` changed `tools/test_v161_solar_overview.py`. Binary integrity remains strict: PNG signature/CRC, SHA-256 `06b542233279854dea18a10cf10e16b32772057add0bec8f896fc2a282ab407f`, 128x136 dimensions and transparency. Live wiring now checks the stable `SOLAR_ART` preload, `CAMPUS.solar`, `_draw_asset`, shared collision registration, and semantic `infrastructure_ready("solar")` implementation instead of demanding the removed literal `SOLAR_ART != null` expression.

Commit `d4a61b2ea5e5671409be7676579622c7777652d7` changed `Godot/scripts/capture_screenshot.gd`. The failed exact-head job proved fresh Godot 4.7.2 import/decode and semantic overworld validation were green, then the old screenshot harness rejected the stable world because it demanded `BootFallback`/`hashrace_v124...`/`debug_v138_ready`/other numbered metadata. The replacement instantiates actual `world.tscn`, waits the proven 12-frame cadence, requires `runtime_ready()` and all five `infrastructure_ready()` assets, redraws, waits 12 frames plus 0.25 seconds, reads the viewport, writes `visual-proof/hashrace-screenshot.png`, and preserves the nonblank histogram gate.

## Asset provenance and runtime wiring

Wind: `Godot/art/energy/wind_turbine_directional_sheet.png` -> `res://art/energy/wind_turbine_directional_sheet.png`; 2278 bytes; 128x128; SHA-256 `5087f4b52e2fe324669efc6ffee0b4bbfd000b80d2280b7f73869ded94330c7d`. Live placement is `CAMPUS.wind = Rect2(1310, 260, 220, 220)`; `_draw_wind()` uses that destination and `infrastructure_footprint("wind")` resolves the same grounded collision footprint.

Solar: `Godot/art/energy/solar_array_overview.png` -> `res://art/energy/solar_array_overview.png`; 128x136 transparent PNG; SHA-256 `06b542233279854dea18a10cf10e16b32772057add0bec8f896fc2a282ab407f`. It is preloaded as `SOLAR_ART`, drawn at `CAMPUS.solar`, and its grounded footprint is registered through the same `_ground_foot()` path.

The exact-head import log for `bc64b1d9...` explicitly reimported `default_player_sheet.png`, `c01_mining_container.png`, `substation_transformer_rear.png`, `solar_array_overview.png`, `wind_turbine_directional_sheet.png`, and `asic_air_s19j_directional.png` under Godot 4.7.2 before runtime validation passed.

## Walking state

No new alternating-leg visual fix is claimed. CI proves the existing 4-frame-per-direction, 8 FPS, 72 px cycle and four-way idle contract, but that is not proof that the authored pixels visibly alternate left/right legs. Numeric frame indices remain unacceptable evidence. Walking remains gated on visual inspection of the actual sheet followed by fresh rendered motion proof.

## Screenshot and exact-head gate

At `bc64b1d9...`, screenshot capture failed before viewport read only because the harness still required retired numbered metadata; therefore that run is not counted as visual proof. `d4a61b2e...` repairs that harness using the already-proven capture cadence. This report commit changes the exact head again, so fresh exact-head Godot import/decode, actual gameplay screenshot artifact, and all required CI must still pass before merge. No additional 34-point visual item is counted from source or test wiring alone.
