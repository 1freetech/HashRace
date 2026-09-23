# Hash Race v0.163 wind source-code report

## Scope

PR #93, branch `automation/v163-wind-runtime-asset`. This report records source-code and automated verification only. A visual fix is not counted complete until the exact branch head produces a fresh gameplay screenshot and CI passes.

## Godot implementation basis

Godot 4.7 import process: https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html

Godot 4.7 ImageTexture: https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html

Godot 4.7 documentation says imported project textures should be loaded through the resource loader (`load`/`preload`) rather than filesystem `Image.load()` for exported projects. The wind catalog follows that resource path model.

## Runtime source paths

- `Godot/art/energy/wind_turbine_directional_sheet.png`: existing authored directional wind binary selected for live integration.
- `Godot/scripts/wind_turbine_catalog.gd`: owns the imported resource path, texture loading and directional source regions.
- `Godot/scripts/world_v163.gd::_ready()`: loads the catalog texture before inherited world setup and records the live asset path.
- `Godot/scripts/world_v163.gd::_v114_draw_energy_source()`: intercepts only `wind_farm`, calculates destination and ground footprint, blocks the footprint in navigation and draws the selected authored region. Other energy assets remain inherited.
- `Godot/scripts/world_v163.gd::debug_v163_wind_ready()`: requires texture, catalog validation, actual draw execution, nonzero destination/footprint and blocked ground contact.
- `Godot/scripts/capture_v163_wind.gd::_capture()`: creates a real gameplay world, uses the real `InfrastructureInventory` API to isolate wind from higher-priority deployed energy sources, deploys wind, verifies the live selector returns `wind_farm`, renders gameplay and saves `visual-proof/v163-wind-runtime.png`.

## Failure found and repaired

Exact-head run for `b63ec3104b5a45fc895b08e55ec3222aabf9b9e4` passed fresh Godot 4.7.2 import and `tools/test_v127_asset_bundle_contract.py`, but failed the gameplay proof because an already-deployed higher-priority energy source was selected before wind. The runtime selector order in `world_v114.gd::_v114_primary_energy_id()` is nuclear, hydro, gas, coal, solar, wind, oil, battery. The proof fixture had added wind without isolating those existing deployments, so `_v114_draw_energy_source()` never executed the wind branch.

Commit `b6af65f6dc641d17e34b8e7af8afd12b6aac10a4` repairs the fixture without changing production selection semantics. `capture_v163_wind.gd` now undeploys only the five higher-priority sources through `InfrastructureInventory.undeploy()` before deploying wind. It does not mutate inventory dictionaries directly.

## Verification status

Previous exact-head evidence (`b63ec3104b5a45fc895b08e55ec3222aabf9b9e4`):

- Fresh Godot 4.7.2 checkout/import: PASS.
- `tools/test_v127_asset_bundle_contract.py`: PASS (`Hash Race v0.127 live asset-bundle contract: PASS`).
- Runtime wind screenshot gate: FAIL because wind was not the selected source; screenshot upload was skipped.
- Merge: prohibited.

Current source-fix commit: `b6af65f6dc641d17e34b8e7af8afd12b6aac10a4`.

At report creation its exact-head workflows were queued/in progress. Therefore the wind asset is **not yet counted as a completed gameplay visual fix** and PR #93 must not merge until both exact-head CI and fresh screenshot proof pass.
