# Hash Race v0.163 — source-code change record

Branch: `refactor/v163-industrial-visual-pass`. Scope: **only changes actually committed to this branch**.

| Changed repository path | Actual code/binary change | Verification |
|---|---|---|
| `Godot/scripts/world_v163.gd` | Live v0.163 world inheriting v0.162; validates and renders the 192×64 industrial atlas. | `_ready()`, `_v163_valid_atlas()`, `debug_v163_ready()` |
| `Godot/art/buildings/industrial_overhead_atlas.png` | Transparent PNG with three 64×64 top-down cells: Command Center, cooling, power/distribution. | 192×64; SHA-256 `9d5fdf09174676544fd68d929406b9b912331345244ced0b7c85660e007398c7` |
| `Godot/scripts/world_v163.gd` | Routes non-HQ facilities to atlas art, restores C-01 container HQ art, replaces procedural Command Center hut, reduces roads to one through route plus connector, suppresses detached cable tray. | `_v158_draw_facility()`, `_draw_mining_hq()`, `_v128_draw_command_hut()`, `_build_art_tilemap()`, `_v159_draw_cable_tray()` |
| `Godot/scripts/default_player_sprite_sheet.gd` | Commit `48e6ac3a84561494cb952e254d2be9fff665b9f9`: makes the four authored walking source poses explicit as `WALK_SOURCE_INDICES = [1,3,5,7]`; both SpriteFrames construction and direct runtime `frame_region()` now consume the same sequence. Idle remains source frame 0. `debug_ready()` asserts the bilateral cadence contract. | Source-level verification only until fresh runtime capture proves visible alternating-leg motion. |
| `Godot/scenes/world.tscn` | Live scene points at `world_v163.gd`. | `ext_resource id="1_world"` |
| `Godot/scripts/validate_modular_scripts.gd` | Includes `world_v163.gd` in parser/instantiation gate. | `SCRIPTS` array |
| `tools/test_v163_industrial_visual_contract.py` | Binary/source regression contract for v0.163 atlas, scene wiring, roads and inherited capacity tiers. | Python contract; CI must be checked on the exact new head. |

## Validation gate

The infrastructure PNG has a recorded decoded size and SHA-256 above. PR #92 remains draft and **must not merge** until exact-head CI is green and a fresh Godot gameplay screenshot proves the atlas replacements and walk cadence visually. The walk refactor commit is source-verified but is deliberately **not counted as a completed visual fix yet** because no fresh post-commit runtime render has been inspected.

PR #91 remains open and mergeable but its own fresh gameplay inspection explicitly failed the visual integration gate: its solar replacement was not visibly demonstrated. It should not merge merely because its earlier CI was green.

## Godot implementation basis

Godot 4.7 `SpriteFrames` is the frame library used by `AnimatedSprite2D`; frame animations are constructed by adding ordered texture frames and setting animation speed/loop behavior. Hash Race keeps its current direct atlas-region renderer, but the ordered walk regions are now sourced from the same explicit sequence used by `build_frames()` so the two code paths cannot silently disagree.
