# Hash Race v0.165 source-code report

## Scope

This report records source changes and validation state only. It does not count source presence, concept art, or an unrendered change as an integrated gameplay fix.

## Official Godot implementation basis

Godot 4.7 Import Process: https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html

Godot 4.7 ImageTexture: https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html

Godot 4.7 SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

The import documentation states that imported assets must be accessed through ResourceLoader so internal imported-file remapping is honored in exported projects. ImageTexture documentation likewise recommends `load()` for imported textures instead of filesystem `Image.load()`. SpriteFrames is the ordered frame library used by AnimatedSprite2D; frame order must therefore come from visually verified authored poses, not numeric-index assumptions.

## Proven repository implementation inspected

The current main baseline at `69e4343051f08e5dc6afd93d32d435d4051bd2d6` and the last intact PR runtime tree at `63439529e3ef866463d692acd2018d6030761483` were inspected before selecting the repair method. Existing successful catalogs including `Godot/scripts/dirt_road_catalog.gd`, `Godot/scripts/grass_terrain_catalog.gd`, `Godot/scripts/utility_props_catalog.gd`, `Godot/scripts/asic_air_s19j_catalog.gd`, and `Godot/scripts/default_player_sprite_sheet.gd` resolve committed project textures through `ResourceLoader.exists()` plus `load()`/Texture2D rather than depending on an absolute source PNG path.

## Source changes

Wind ResourceLoader repair commit: `ebd48840d5268d0677b5b5f74b92e2195badd35d`.

Changed path: `Godot/scripts/wind_turbine_catalog.gd`.

Changed function: `HashRaceWindTurbineCatalog.load_texture()`.

Removed the `ProjectSettings.globalize_path()` + `FileAccess.file_exists()` + `Image.load()` source-file dependency. The catalog verifies `res://art/energy/wind_turbine_directional_sheet.png` as an imported `Texture2D` with `ResourceLoader.exists()`, loads the imported Texture2D through ResourceLoader, obtains an Image copy through `Texture2D.get_image()`, removes only the known authored gray matte from that copy, and creates the transparent runtime ImageTexture. `debug_ready()` validates the imported Texture2D resource path rather than an absolute source-file path.

The matte conversion does not rewrite or replace the repository PNG binary. It operates on the decoded image copy after Godot resource loading.

### Destructive-refactor recovery

Recovery commit: `7fadad050b549cdf9e6082c94fdadc82b83dc1b6`.

The immediately preceding commits `c5f9019dfed670e7c79165dcb980d932bfbdff40` and `9d7b927fa29f9a0f60f4ae6766e5622367d01a37` removed large portions of the proven runtime, including gameplay proof scripts and workflows. The exact-head Gameplay proof then remained stuck in its runtime screenshot step after fresh import succeeded. The recovery commit restores the complete known intact tree from `63439529e3ef866463d692acd2018d6030761483` while keeping the destructive commits in history for auditability. The PR branch was advanced normally to the recovery commit; history was not force-rewritten.

This recovery restores the source paths needed for the validated asset pipeline, including the actual gameplay capture scripts, v0.164 wind proof, imported-art catalogs, player animation code, tests, and CI workflows. It is a source repair, not a claimed integrated visual fix.

## Asset provenance and binary path

Repository asset: `Godot/art/energy/wind_turbine_directional_sheet.png`.

Runtime resource path: `res://art/energy/wind_turbine_directional_sheet.png`.

The existing v0.164/v0.165 contracts remain responsible for PNG signature/CRC/dimensions and live renderer assertions. No new binary was generated in this recovery.

## Walking contract

No walking-frame order was changed in the recovery commit. `Godot/scripts/default_player_sprite_sheet.gd` remains subject to the rule that movement order must be built only from visually verified authored left/right leg poses. Numeric sprite-sheet index parity is not accepted as evidence. Godot `SpriteFrames.add_frame()` appends the supplied Texture2D in explicit animation order, so a future walking repair must record the visibly inspected pose order and render it before claiming success.

## Runtime, screenshot, and CI state

The obsolete exact-head Gameplay proof for `9d7b927fa29f9a0f60f4ae6766e5622367d01a37` passed checkout, exact-head verification, Godot installation, and fresh import, but remained stuck at runtime screenshot after the source-removal commits. That run is not accepted as visual proof.

Because recovery commit `7fadad050b549cdf9e6082c94fdadc82b83dc1b6` and this report commit change the exact head, all required checks must run again. No screenshot from an older SHA is accepted as proof.

Required before integration can be claimed: fresh Godot 4.7.2 import/decode on the exact head; actual deployed wind gameplay run; fresh screenshot showing the runtime; exact-head CI green. Until all gates pass, the branch must not be merged and no additional 34-point visual item is counted as fixed.
