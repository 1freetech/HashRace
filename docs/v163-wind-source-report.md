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


## 2026-09-23 lateral walk + NPC render refactor

Official Godot 4.7 `SpriteFrames` reference: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Godot's 2D animation guidance uses `AnimatedSprite2D` + `SpriteFrames` for ordered sprite-sheet animation. The inspected Hash Race Library source `Hash Race Pixel Art Sprite Sheet.png` visibly contains alternating stride poses for WALK LEFT and WALK RIGHT. Repository history in `docs/default-character-32-frame.md` also states that movement should visit all seven authored walking poses. The later four-pose reduction had changed the source selection to `[1,3,5,7]`, skipping every even in-between pose.

Source changes:
- `Godot/scripts/default_player_sprite_sheet.gd` commit `c1149078402914909b46ace05f82d66c9429fd56`: restores seven ordered walking poses per direction, indices 1 through 7, while retaining frame 0 as idle. `build_frames()` now constructs each walk animation from all seven authored regions.
- `Godot/scripts/rpg_movement.gd` commit `ed0c272e730aacb02d2333582c3690632c7ef09a`: changes distance-synchronized cycle length from 72 px to 126 px so 7 poses at 8 FPS remain synchronized with 144 px/s movement.
- `Godot/scripts/validate_player_walk_motion.gd` commit `b6d7bf20a703281888b634cd183082f2d79f6463`: requires all seven authored poses and verifies each displacement phase reaches the matching source crop.
- `Godot/scripts/capture_player_sprite.gd` commit `4d18abbc2e71aa97447411dbfbe742a174003253`: expands actual-world capture from five states to idle + seven walking states in every direction and keeps controlled-distance movement capture.
- `tools/test_walk_sync_contract.py` commit `118a810b74c1b2ff0e6e8bcf1140367abe40e606`: updates the historical regression contract so the four-pose skip cannot silently return.
- `Godot/scripts/world_v163.gd` commit `040ffd7330d457b6588eb759ef16de01dec19be3`: NPCs now use the same validated default-player binary, exact region crops, foot anchor and texture-rendering path as the player, with deterministic skin/suit variants instead of reusing the player's identical derived texture. The white/orange palette pair follows the visually inspected Library source `Pixel Art Cybernetic Character Sprite Sheet.png`.

Binary/art evidence:
- Existing runtime source remains `Godot/art/characters/default_player_sheet.png`, whose repository contract records 1536x1024 RGBA and SHA-256 `2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211`.
- Library `Hash Race Pixel Art Sprite Sheet.png` was visually inspected during this pass; WALK LEFT and WALK RIGHT each visibly contain changing opposite-leg stride poses.
- Library `Pixel Art Cybernetic Character Sprite Sheet.png` was visually inspected; it contains two clean front-facing white/orange operator variants. No uncommitted derivative binary is counted as integrated. NPC production rendering deliberately reuses the already validated runtime character binary and derives palette variants through `build_customized_texture()`.

Verification gate:
- Current implementation head before this report: `040ffd7330d457b6588eb759ef16de01dec19be3`.
- GitHub Actions had no workflow run attached to that exact head when checked.
- Therefore alternating-leg walking and the NPC variants are **source-integrated but not yet counted as visually proven fixes**. The required completion evidence remains a fresh Godot gameplay capture from the exact head plus green exact-head CI. No merge is authorized before both exist.
