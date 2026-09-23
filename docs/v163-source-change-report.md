# Hash Race v0.163 — source-code change record

Branch: `refactor/v163-industrial-visual-pass`. Scope: **only changes actually committed to this branch**.

| Changed repository path | Actual code/binary change | Verification |
|---|---|---|
| `Godot/scripts/world_v163.gd` | Adds a new runtime world inheriting v0.162. Loads the 192×64 industrial atlas **before** inherited world startup; rejects missing/wrong-dimension image. | `_ready()`, `_v163_valid_atlas()`, `debug_v163_ready()` |
| `Godot/art/buildings/industrial_overhead_atlas.png` | Adds an original transparent PNG with three 64×64 top-down cells: Command Center, cooling building, power/distribution equipment. | Decoded PNG dimensions 192×64, SHA-256 `9d5fdf09174676544fd68d929406b9b912331345244ced0b7c85660e007398c7` |
| `Godot/scripts/world_v163.gd` | Replaces procedural non-HQ facility roofing/door drawing through an override of inherited `_v158_draw_facility()`. Draws atlas regions scaled from `WorldScale.size_for_kind()`, retains selection and nearest-object label hooks. | `_v158_draw_facility()`, `_v163_draw_industrial()` |
| `Godot/scripts/world_v163.gd` | Overrides v0.158's generic HQ renderer to restore approved C-01 PNG on player and rival mining HQs with inherited capacity scaling. | `_draw_mining_hq()` |
| `Godot/scripts/world_v163.gd` | Replaces the inherited rectangular procedural Command Center hut using atlas cell 0. Existing mining-container, transformer and solar PNG pipelines remain inherited. | `_v128_draw_command_hut()` |
| `Godot/scripts/world_v163.gd` | Removes inherited three-horizontal-road grid and paints one central through route with one north-south connector. Preserves inherited non-road cells including water. | `_build_art_tilemap()` |
| `Godot/scripts/world_v163.gd` | Suppresses the detached cable-tray grass strip without removing its valid binary or its inherited loader. | `_v159_draw_cable_tray()` |
| `Godot/scenes/world.tscn` | Changes the live gameplay scene's script resource from `world_v162.gd` to `world_v163.gd`. | `ext_resource id="1_world"` |
| `Godot/scripts/validate_modular_scripts.gd` | Includes `world_v163.gd` in inherited GDScript parse/instantiation gate. | `SCRIPTS` array |
| `tools/test_v163_industrial_visual_contract.py` | Adds source-and-binary regression assertions for scene wiring, image SHA-256/dimensions, atlas renderer, road layout, no legacy facility roof draw, and inherited capacity-tier debug checks. | Python test |

**Validation status:** The original PNG was generated and successfully decoded as an RGBA image locally; its dimensions and SHA-256 were checked, and GitHub returned the binary blob from the branch. `world.tscn` and the parse gate were updated in GitHub. No claim is made here that the modified branch has passed Godot runtime rendering or that the other screenshot defects are fixed; those are outside the committed changes in the table.

**Upstream implementation reference:** Godot's Sprite2D drawing/2D sprite-sheet workflow and the user's attached tilemap reference, which describes distinct layers, Y sorting and ground-contact collisions. The current v0.163 branch does not change player walk frames or claim a bilateral gait correction.
