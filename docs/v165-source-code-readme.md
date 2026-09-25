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

Before wiring animation, the actual Library source `Retro Sci-Fi Hero Sprite Sheet.png` was visually inspected. Its four rows are DOWN, LEFT, RIGHT, UP; each row contains one idle plus seven authored walk poses. The side-facing LEFT and RIGHT rows visibly change stride: forward and rear legs exchange position across the sequence rather than merely translating a static body. The current sheet was re-inspected directly on 2026-09-24. Each directional row contains one idle pose followed by the authored WALK 1-7 sequence, and the side rows visibly exchange the leading/trailing foot and opposing arm across that sequence. Commit `5b440b33407cb820f03b060ab1481568134f9106` therefore records an explicit per-facing `WALK_SOURCE_ORDER` of `[1, 2, 3, 4, 5, 6, 7]`. This is an authored visual order, not an odd/even or numeric-parity inference.

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


## 34-point priority pass — 2026-09-24

This pass intentionally ignored unrelated legacy-contract cleanup and worked only on a user-visible item from the 34-point inspection: the player walking presentation.

Official Godot 4.7 basis: `SpriteFrames` is the animation library used by `AnimatedSprite2D`; `SpriteFrames.add_frame()` appends the supplied `Texture2D` frame in the order provided unless an insertion position is specified. Reference: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Visual source evidence: Library asset `Retro Sci-Fi Hero Sprite Sheet.png` was opened and inspected directly. It is a 4-row DOWN/LEFT/RIGHT/UP sheet with one idle plus seven WALK poses per direction. LEFT and RIGHT visibly alternate stride/arm state across the authored WALK 1-7 progression.

Source change: `Godot/scripts/default_player_sprite_sheet.gd` now defines `WALK_SOURCE_ORDER` explicitly for every facing and `build_frames()` constructs each `walk_*` animation from that verified order. `debug_ready()` now also verifies the four direction mappings and seven-frame left/right sequences. Commit: `5b440b33407cb820f03b060ab1481568134f9106`.

Live runtime path remains `world.tscn -> world.gd -> PlayerSheet.build_frames() -> AnimatedSprite2D PlayerSprite`. The obsolete procedural/fixed player draw is not in the live draw path.

Proof status: source and visual frame-order evidence are complete for this pass. This item is still NOT marked integrated until the exact new head completes a fresh Godot import, gameplay run, screenshot showing the walking sprite, and green CI.


## Export-safe player texture gate — 2026-09-24

Official Godot 4.7 ImageTexture guidance warns that dynamically loading source image files with `Image.load()` may not work in exported projects and recommends loading imported textures with `load()`: https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html

Commit `b4449d555b152203ed8c0e8f66910d8fc0b52ff5` changes `Godot/scripts/default_player_sprite_sheet.gd::load_texture()`. The live walking path now accepts only the imported `res://art/characters/default_player_sheet.png` Texture2D through `ResourceLoader.exists()` + `load()`, validates its 1536x1024 dimensions, and removes the filesystem `Image.load()` / `ImageTexture.create_from_image()` fallback. This makes a missing/failed Godot import fail closed instead of silently producing a development-only texture path.

Asset provenance remains the approved 32-pose player binary, SHA-256 `2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211`. The visually verified explicit WALK 1-7 order from commit `5b440b33407cb820f03b060ab1481568134f9106` is unchanged.

Exact-head proof gate: not counted as integrated until this new head completes import/decode, gameplay render, walking screenshot evidence, and green CI.


## 34-point infrastructure scale pass — 2026-09-24

Targeted inspection defect: inconsistent infrastructure scale / stretched pasted-looking assets. Before editing, the proven repository implementation in `world_v163.gd::_draw_power_building()` was re-inspected. That implementation deliberately preserves the validated PNG aspect ratio and grounds the rendered image at its contact footprint rather than stretching it into the obsolete house rectangle.

Official Godot 4.7 basis: `Texture2D.get_size()/get_width()/get_height()` expose the imported texture dimensions and `draw_texture_rect()` draws the imported Texture2D into the destination rectangle. Reference: https://docs.godotengine.org/en/4.7/classes/class_texture2d.html. Imported project textures remain preloaded resources; no filesystem image loader was introduced.

Commit `180940a1841c6768809fe0f9fd6475661aefb52e` changes `Godot/scripts/world.gd`:
- changes the C-01 mining-container campus bounds from the arbitrary stretched `330x190` box to `256x204`, an exact 2x multiple of the validated `128x102` binary;
- adds `_aspect_fit_rect()`, which derives render size from the imported Texture2D dimensions and bottom-centers it so visual ground contact stays aligned with the navigation footprint;
- routes `_draw_asset()` through the aspect-fit rectangle, preventing non-wind infrastructure from being distorted by mismatched destination proportions;
- adds a runtime dimension gate requiring the container Texture2D to decode as exactly `128x102`.

The existing `_ground_foot()` collision/navigation registration remains tied to the campus bounds, so the visual replacement remains non-walkable at its grounded footprint. The live runtime contains no generic house renderer for this container; it draws `CONTAINER_ART` directly from `res://art/buildings/c01_mining_container.png`.

Proof status: source correction is committed but is NOT counted as a completed 34-point visual fix until the exact head produces a fresh Godot import/gameplay screenshot and green CI.


## Immediate 34-point repair pass — 2026-09-24

Official Godot basis was rechecked before edits. Godot 4.7 documents `SpriteFrames` as the frame library consumed by `AnimatedSprite2D`, and `add_frame()` appends the supplied Texture2D in explicit order. Godot's 2D CanvasItem API draws imported Texture2D resources into local-space rectangles. References:
- https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html
- https://docs.godotengine.org/en/4.7/classes/class_texture2d.html

Repository history rechecked: `world_v163.gd::_draw_power_building()` is the last proven infrastructure-replacement method. It preserves source aspect ratio, omits the obsolete house body/foundation/door, aligns the art to a ground-contact footprint, registers that footprint with navigation, and uses player-foot position for draw ordering.

Commits in this pass:
- `75c8c68a336a4491b300f8437de6ce38484a8ff3`: fixes the live `world.gd` infrastructure renderer. `_draw_asset()` now calls `_aspect_fit_rect()`, preserving imported Texture2D proportions and bottom-centering art on its collision footprint. It also fixes the malformed CAMPUS comment and adds the exact 128x102 C-01 container decode gate.
- `59c195870374249a1eba62df8346fcfa6f53f947`: repairs `validate_overworld.gd`. The validator had stale four-frame assertions even though the visually inspected player sheet and live builder now use seven authored WALK poses. It now requires seven frames in all four directions and validates every live infrastructure asset.
- Screenshot harness commit follows this report's source pass and makes the runtime capture require actual `walk_right` frame advancement before saving proof, so an idle screenshot can no longer masquerade as walking evidence.

No visual inspection item is counted complete from these source changes alone. Fresh exact-head Godot import/gameplay execution, screenshot artifact, and green CI remain the completion gate.


## 34-point depth/grounding pass — 2026-09-24

Targets: floating/ungrounded infrastructure, incorrect player/building overlap, and pasted-looking draw order.

Official Godot rendering basis: Texture2D is the imported 2D texture resource; CanvasItem Y-sorting renders children with greater Y positions in front when they share a Z index. References: https://docs.godotengine.org/en/4.7/classes/class_texture2d.html and Godot CanvasItem Y-sort documentation.

The proven historical method in `world_v163.gd::_draw_power_building()` was inspected first. It explicitly compares player feet with the infrastructure ground/sort Y and defers the infrastructure draw when the player should pass behind it.

Commit `1b4c1df7cb7bba4ef778b3275635765b8b16773c` moves the five live infrastructure visuals out of unconditional root `_draw()` calls and into actual imported-texture `Sprite2D` nodes created by `_build_infrastructure_sprites()`. The world enables Y sorting; each infrastructure sprite is bottom-grounded and receives a Y-sort origin at its visual contact line. The player remains a live `AnimatedSprite2D` on the same sort plane. Wind uses an `AtlasTexture` region from the existing imported directional sheet rather than a filesystem image.

This removes the old failure mode where the player had z_index 20 and therefore rendered in front of every building regardless of foot position. `infrastructure_ready()` now also requires the corresponding Sprite2D to exist inside the live tree.

Commit `0722f7007a54c9efeef6829022bcc4fb0e1dbaee` extends `validate_overworld.gd` so the exact runtime must instantiate all five imported infrastructure Sprite2D nodes with live textures.

Proof gate remains unchanged: these source repairs are not counted as completed visual points until exact-head gameplay rendering and screenshot evidence pass.
