# Hash Race v0.165 runtime repair

The campaign still opens `Godot/scenes/world.tscn`, whose root script is
`res://scripts/world.gd` extending `Node2D`. It does not inherit a numbered
world layer. `world_v165.gd` was removed because its diesel implementation was
unreachable from this entry point.

## Diesel in the actual world

The current world uses `res://systems/energy_visual_catalog.gd` and the existing
512x512 WebP atlas stored in eight `Godot/assets/energy/atlas_parts/*.b64`
chunks. Diesel is catalog index 9; the UP view is the 64x64 region at (128,256).
No new diesel PNG or rewritten source asset is claimed.

`deploy_infrastructure("diesel_generator")` deploys one owned module using the
real inventory and company dictionary. `deployment_changed` updates a live
AtlasTexture/Sprite2D in `DIESEL_SLOT = Rect2(780,310,120,120)`, bottom-anchored
for Y-sort and blocked at its ground footprint. Undeployment hides the sprite,
reverses the inventory power effect and rebuilds navigation from the remaining
footprints. Stored equipment does not render. Press E to deploy a stored module,
store a deployed module, or purchase/deploy one if the company can afford it.

The module price/output remain sourced from `diesel_generator.tres`; a new
campaign is not granted free equipment. The capture grants one stored module
as a controlled scenario and then exercises the same deployment API as the game.

## Current artwork and animation

The player still uses the original approved 1536x1024 PNG, SHA-256
`2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211`.
Each facing has one idle and four walking poses from explicit source order
[1,3,5,7], at 8 FPS and 144 px/s (72 px per cycle). Campaign skin, suit and
scouter color choices now reach the actual player SpriteFrames at startup;
the default suit is green. No new leg artwork or source frame ordering was invented.

Current permanent placements are container (410,390,192,153), solar
(1040,350,176,176), transformer (890,450,120,108), ASIC (650,480,80,80), and
wind (1280,300,176,176). ASIC placement was moved clear of the service road.
The HUD is a CanvasLayer so camera framing cannot clip it.

## Validation scope

- Current world: `validate_overworld.gd`, clean gameplay screenshot, wind,
  permanent solar, diesel lifecycle, and 20-pose/16-motion player captures.
- Historical source/integration fixture: `historical_world.tscn` loads
  `world_v164.gd` and the preserved numbered inheritance chain. Its old
  composition, energy-library, widget and fab checks protect that code only.
  Historical artifacts are explicitly labeled and do not certify those features
  as integrated into the current campaign world.
- `assert_world_inherits` still strictly follows the current scene. Historical
  tests explicitly call `assert_historical_world_inherits`; no fake ancestry,
  silent skips or blanket assertion bypasses were added.
- The v0.103 test checks current placement bounds, road clearance, non-overlap,
  generation/distribution/load ordering, ground anchors and Y-sort while
  retaining the original historical source assertions.
- The overworld validator supplies both arguments to the current animation API.
- Capture jobs wait for `--editor --import` completion, reject script/import
  errors, require success markers and nonempty files, and use bounded timeouts.
  Smoke-test checkout uses the proposed head SHA instead of the PR merge ref.

Local verification is preliminary. A merge requires successful applicable CI
and fresh inspected current-world artifacts on the exact pushed head. Neither
older screenshots nor historical fixture captures substitute for that gate.

## Godot implementation references

- https://docs.godotengine.org/en/4.7/classes/class_atlastexture.html
- https://docs.godotengine.org/en/4.7/classes/class_sprite2d.html
- https://docs.godotengine.org/en/4.7/classes/class_animatedsprite2d.html
- https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html
