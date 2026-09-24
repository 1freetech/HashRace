# Hash Race source-code report

## Official Godot implementation basis

Godot 4.7 SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Godot 4.7 Texture2D: https://docs.godotengine.org/en/4.7/classes/class_texture2d.html

Godot 4.7 nodes/scene instances: https://docs.godotengine.org/en/4.7/tutorials/scripting/nodes_and_scene_instances.html

`SpriteFrames.add_frame()` appends the explicitly supplied `Texture2D` at the end of an animation unless an insertion position is supplied. `AnimatedSprite2D` consumes a SpriteFrames resource for frame playback. Imported project textures are Texture2D resources and the live player sheet remains `res://art/characters/default_player_sheet.png` rather than a runtime filesystem image dependency.

## Proven repository implementation inspected

The intact character implementation in `Godot/scripts/default_player_sprite_sheet.gd` was inspected before editing the stable runtime. It already builds `SpriteFrames` from exact authored `Rect2i` regions with `AtlasTexture`, uses four directional `walk_*` animations at 8 FPS, and keeps the approved source binary SHA-256 `2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211`.

The current live entry point remains `Godot/scenes/world.tscn -> res://scripts/world.gd`. The stable runtime had regressed to `_draw_player()`, which always drew the first sheet region and therefore could not display walking even though the proven SpriteFrames builder remained in the repository.

## Visual frame verification

Before wiring animation, the actual Library source `Retro Sci-Fi Hero Sprite Sheet.png` was visually inspected. Its four rows are DOWN, LEFT, RIGHT, UP; each row contains one idle plus seven authored walk poses. The side-facing LEFT and RIGHT rows visibly change stride: forward and rear legs exchange position across the sequence rather than merely translating a static body. The implementation therefore uses the existing explicitly authored source-region order `[1, 3, 5, 7]` from the repository SpriteFrames builder; the decision is based on visible pose contents, not numeric parity alone.

## Live walking source changes

Commit `65a1d6f6c36841f0671f3955d6472f12157685a2` changes `Godot/scripts/world.gd`:

- preloads `default_player_sprite_sheet.gd` as `PlayerSheet`;
- creates a real `AnimatedSprite2D` named `PlayerSprite` in `_build_player_sprite()`;
- assigns `PlayerSheet.build_frames()` and nearest-neighbor texture filtering;
- removes `_draw_player()` from the CanvasItem draw path so the obsolete fixed first-frame renderer cannot cover the animated player;
- makes `move_player()` return whether a legal movement occurred and keeps the sprite position synchronized with `rep_pos`;
- adds `_set_player_facing()` and `_update_player_animation()` so movement selects `walk_left`, `walk_right`, `walk_up`, or `walk_down`, while stationary state selects the matching idle animation;
- adds `player_animation_ready()` and includes it in `runtime_ready()`.

Commit `e5580afa4fc26ae94ebc7e89e4140ff10eb6b990` changes `Godot/scripts/validate_overworld.gd` to require the live `AnimatedSprite2D`, four walk frames for every direction, and activation of `walk_right` during a real legal movement.

## Current semantic runtime API

The live world uses unnumbered APIs: `move_player()`, `runtime_ready()`, `infrastructure_ready(asset_id)`, `infrastructure_rect(asset_id)`, `infrastructure_footprint(asset_id)`, and `player_animation_ready()`. Historical release-numbered scripts are not the `world.tscn` entry point.

## Asset provenance and runtime wiring

Player: `Godot/art/characters/default_player_sheet.png` -> `res://art/characters/default_player_sheet.png`; 1536x1024 approved sheet; SHA-256 `2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211`. The imported Texture2D is consumed by `PlayerSheet.build_frames()` through AtlasTexture regions and by the new live `AnimatedSprite2D`.

Wind: `Godot/art/energy/wind_turbine_directional_sheet.png` -> `res://art/energy/wind_turbine_directional_sheet.png`; 2278 bytes; 128x128; SHA-256 `5087f4b52e2fe324669efc6ffee0b4bbfd000b80d2280b7f73869ded94330c7d`. Live placement remains `CAMPUS.wind = Rect2(1310, 260, 220, 220)` with collision from `infrastructure_footprint("wind")`.

Solar: `Godot/art/energy/solar_array_overview.png` -> `res://art/energy/solar_array_overview.png`; 128x136 transparent PNG; SHA-256 `06b542233279854dea18a10cf10e16b32772057add0bec8f896fc2a282ab407f`. It remains preloaded as `SOLAR_ART`, drawn at `CAMPUS.solar`, and grounded through `_ground_foot()`.

## Screenshot and exact-head gate

The preceding exact head `d6ac6455ffc02c3be846dc1faab91a45fd61a2d2` had its four GitHub Actions workflows queued when this walking repair began, so it was not treated as final proof. The new source commits change the exact head again. The walking source integration is therefore **not yet counted as a completed visual inspection item**: a fresh Godot 4.7 import/decode, actual gameplay run, screenshot/artifact showing the animated player, and green exact-head CI are still mandatory before merge. No merge is authorized from source presence alone.
