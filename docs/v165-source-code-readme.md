# Hash Race v0.165 source-code report

## Scope

This report records source changes and validation state only. It does not count source presence, concept art, or an unrendered change as an integrated gameplay fix.

## Official Godot implementation basis

Godot 4.7 Import Process: https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/import_process.html

Godot 4.7 ImageTexture: https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html

Godot 4.7 SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

The import documentation states that imported assets must be accessed through ResourceLoader so internal imported-file remapping is honored in exported projects. ImageTexture documentation likewise recommends `load()` for imported textures instead of filesystem `Image.load()`. SpriteFrames is the ordered frame library used by AnimatedSprite2D; frame order must therefore come from visually verified authored poses, not numeric-index assumptions.

## Proven repository implementation inspected

The current main baseline at `69e4343051f08e5dc6afd93d32d435d4051bd2d6` was inspected before selecting the repair method. Existing successful catalogs including `Godot/scripts/dirt_road_catalog.gd`, `Godot/scripts/grass_terrain_catalog.gd`, `Godot/scripts/utility_props_catalog.gd`, `Godot/scripts/asic_air_s19j_catalog.gd`, and `Godot/scripts/default_player_sprite_sheet.gd` resolve committed project textures through `ResourceLoader.exists()` plus `load()`/Texture2D rather than depending on an absolute source PNG path.

## Source change

Code commit: `ebd48840d5268d0677b5b5f74b92e2195badd35d`

Changed path: `Godot/scripts/wind_turbine_catalog.gd`

Changed function: `HashRaceWindTurbineCatalog.load_texture()`.

Removed the `ProjectSettings.globalize_path()` + `FileAccess.file_exists()` + `Image.load()` source-file dependency. The catalog now verifies `res://art/energy/wind_turbine_directional_sheet.png` as an imported `Texture2D` with `ResourceLoader.exists()`, loads the imported Texture2D through ResourceLoader, obtains an Image copy through `Texture2D.get_image()`, removes only the known authored gray matte from that copy, and creates the transparent runtime ImageTexture. `debug_ready()` now validates the imported Texture2D resource path rather than an absolute source-file path.

The matte conversion does not rewrite or replace the repository PNG binary. It operates on the decoded image copy after Godot resource loading.

## Asset provenance and binary path

Repository asset: `Godot/art/energy/wind_turbine_directional_sheet.png`.

Runtime resource path: `res://art/energy/wind_turbine_directional_sheet.png`.

The existing v0.164/v0.165 contracts remain responsible for PNG signature/CRC/dimensions and live renderer assertions. No new binary was generated in this source repair.

## Walking contract

No walking-frame order was changed in this commit. Main's `Godot/scripts/default_player_sprite_sheet.gd` was inspected as part of the proven ResourceLoader pattern. No animation change is claimed as a fix because no new visually verified left/right-leg sequence and fresh gameplay render were produced in this commit.

## Runtime, screenshot, and CI state

At the moment the code commit was created, PR #94 exact-head workflows for the preceding head were still queued/in progress. Because `ebd48840d5268d0677b5b5f74b92e2195badd35d` changes the exact head, all required fresh-head checks must rerun. No screenshot from an older SHA is accepted as proof for this commit.

Required before integration can be claimed: fresh Godot 4.7.2 import/decode on the exact head; actual deployed wind/diesel gameplay run; fresh screenshot showing the changed runtime; exact-head CI green. Until all gates pass, the change remains source-complete but not counted as an integrated 34-point visual fix and must not be merged.
