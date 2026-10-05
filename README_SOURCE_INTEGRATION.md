# Current report boundary

The entries below are dated historical work logs, not a description of the current
head. The current runtime/deployment/proof scope is documented in
[docs/v165-source-code-readme.md](docs/v165-source-code-readme.md). PR #94 now
includes stable runtime repairs and actual diesel integration; its title/body
must describe that expanded scope. Fresh exact-head CI and inspected current-world
proof remain mandatory before merge.

# Hash Race source integration report

## Current proof target
PR #94 branch `automation/v164-wind-forward-port`.

## Godot implementation contract
Godot 4.7 SpriteFrames documents that `add_frame()` appends a Texture2D when no insertion position is supplied and that animation FPS controls playback:
https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html

Godot 4.7 ImageTexture documentation recommends `load()` for imported textures instead of filesystem Image loading because filesystem loading may fail in exported projects:
https://docs.godotengine.org/en/4.7/classes/class_imagetexture.html

## Proven repository method
The player implementation preserves the previously rendered walking method from commit `9f3e8c2`: four visually inspected authored poses per facing in explicit source order 1, 3, 5, 7 at 8 FPS. Current path: `Godot/scripts/default_player_sprite_sheet.gd`.

## Current asset/runtime evidence
The infrastructure runtime uses imported `res://art/...` Texture2D resources and live Sprite2D nodes. Wind exact-head proof is green. Binary-specific validators remain responsible for PNG signature, dimensions/alpha/hash/decode evidence.

## 2026-09-26 clean-runtime repair
Changed `.github/workflows/gameplay-proof.yml` Fresh import from `--quit-after 2` to `--quit-after 120`. The prior exact-head log showed Godot leaving fresh import before PNG resources had loaders, then `world.gd` failed parsing every preloaded PNG. This change gives the editor import scan time to complete before gameplay capture.

Commit: `0eb713190547d1591e8b127ca9dfa321fbd50e32`.

## Acceptance gate
Do not count an inspection item complete until the exact head has a successful fresh Godot import, actual gameplay execution, a non-empty fresh screenshot showing the change, and green applicable CI. Do not merge PR #94 before those gates pass.


## 2026-09-26 exact-head runtime repair and inspected proof
Changed `Godot/scripts/world.gd::npc_population_ready()` so palette uniqueness uses Godot's `str()` conversion for Color values rather than invalid constructor-style `String(Color)` calls. Commit `d432e124158a58782f740c65370c1df7e2ba87c1`.

Changed `tools/test_energy_visual_contract.py` to validate the live `Sprite2D` / `AtlasTexture` infrastructure path and reject the obsolete CanvasItem `_draw_asset` / `_draw_wind` / `draw_texture_rect_region` renderer. Commit `3c8b5ac02f008e320a925fcef3662e8c81aa5e6f`.

At exact head `3c8b5ac02f008e320a925fcef3662e8c81aa5e6f`, both **Clean runtime gameplay proof** and **v0.164 exact-head wind proof** completed successfully. The clean-runtime artifact `gameplay-clean-runtime.png` was downloaded and visually inspected: it shows the live campus with the imported container, solar unit, transformer, ASIC hardware, wind turbine and five character sprites. The four NPCs visibly use different palettes and are separated spatially. The screenshot also exposes remaining 34-point work rather than hiding it: the wind tile retains a large gray rectangular background, asset scale/style remains inconsistent, and the campus composition still has substantial unstructured negative space. Those items remain open.

Walking remains wired through `Godot/scripts/default_player_sprite_sheet.gd::build_frames_from_texture()` using the previously visually proven explicit source order `[1, 3, 5, 7]` for every facing and `AnimatedSprite2D` / `SpriteFrames`; this report does not claim a new walking visual fix from the single inspected still frame.

Official implementation references:
- SpriteFrames: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html
- AnimatedSprite2D: https://docs.godotengine.org/en/4.7/classes/class_animatedsprite2d.html
- AtlasTexture: https://docs.godotengine.org/en/4.7/classes/class_atlastexture.html
- ResourceLoader: https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html


## 2026-09-26 wind backdrop optimization
Exact head `2d4120813968bdba607393bdcd7133aa72e4b05d` preserves the validated 128x128 wind source binary and applies a runtime `ShaderMaterial` only to `Infrastructure_wind`. The shader suppresses near-neutral gray backdrop pixels without rewriting the provenance-controlled PNG. `tools/test_energy_visual_contract.py` now requires the live material path. Exact-head **Clean runtime gameplay proof** and **v0.164 exact-head wind proof** both completed successfully; the wind proof produced the non-empty `hashrace-v164-live-wind-proof` artifact. The artifact was downloaded for inspection. Commit sequence: `618db2d8f0d6246470ea85e3c3cf728d003c574c`, `2d4120813968bdba607393bdcd7133aa72e4b05d`.


## 2026-09-26 normalized campus scale proof
Exact source head `19e8dfe88370c39a343bf88dee779180958b8370` passed **Clean runtime gameplay proof** and **v0.164 exact-head wind proof** after `dcd43660476544d21976b3ba658493d064faaaa0` normalized the live CAMPUS bounds and `19e8dfe88370c39a343bf88dee779180958b8370` repaired the wind proof's stale geometry assertion. The fresh clean-runtime artifact `hashrace-clean-runtime-gameplay` (81,161 bytes) was downloaded and visually inspected. It shows the imported C-01 mining container, solar equipment, wind turbine, transformer, ASIC equipment, player and four NPCs in actual gameplay. The former gray wind rectangle is absent and the reduced infrastructure bounds are visible. Remaining screenshot defects include excessive unstructured empty grass, weak source→distribution→load grouping, and the transformer still reading large relative to characters/miners. These remain open and are not counted as fixed.


## 2026-09-26 transformer gameplay-scale repair
Official Godot 4.7 contract rechecked before this edit: AnimatedSprite2D uses SpriteFrames for Texture2D animation frames, SpriteFrames.add_frame() appends supplied Texture2D frames in explicit order, and ResourceLoader/load operate on imported project resources. References: https://docs.godotengine.org/en/4.7/classes/class_animatedsprite2d.html ; https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html ; https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html .

Proven-history comparison: commit `9f3e8c2cb54b2a791310b7bfec6793080d7e29ac` established the visually inspected player walk source poses 1, 3, 5, 7. Current `Godot/scripts/default_player_sprite_sheet.gd::build_frames_from_texture()` preserves that explicit order through `WALK_SOURCE_ORDER`; no numeric alternation was newly inferred in this run.

Source change: `Godot/scripts/world.gd::CAMPUS`, transformer entry only, changed from `Rect2(970, 540, 144, 130)` to `Rect2(982, 556, 120, 108)`. The change preserves `TRANSFORMER_ART = preload("res://art/electrical/substation_transformer_rear.png")`, `_aspect_fit_rect()`, live `Sprite2D`, Y-sort and `_ground_foot()` collision blocking. It does not reintroduce an obsolete house/draw renderer.

Asset provenance/runtime path: repository binary `Godot/art/electrical/substation_transformer_rear.png`, runtime `res://art/electrical/substation_transformer_rear.png`. Existing validator: `tools/test_v160_transformer_sprite.py`. Candidate source commit: `966e135f69f7a2545b678646b76a5003d21e3e7e`.

Proof status at report write: source committed; fresh exact-head CI/gameplay screenshot not yet complete. Therefore this transformer scale item is **not counted as fixed yet**. It becomes countable only after the new report head completes fresh import, actual gameplay screenshot proof showing the reduced transformer, and applicable exact-head CI.


## 2026-09-27 click-to-move bounds and collision repair
Official Godot contract rechecked before editing: Godot 4.7 SpriteFrames stores the ordered Texture2D animation data used by AnimatedSprite2D, and ResourceLoader requires imported project resources before load(); the existing explicit walk source order [1, 3, 5, 7] and preload-based infrastructure path remain unchanged. References: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html ; https://docs.godotengine.org/en/stable/classes/class_resourceloader.html .

Proven-history comparison: commit `9f3e8c2cb54b2a791310b7bfec6793080d7e29ac` remains the last visually established alternating-leg source sequence. This repair does not infer new sprite ordering.

Source change: `Godot/scripts/world.gd::_unhandled_input()` now clamps mouse destinations to the same 40 px playable margin enforced by `move_player()`, rejects blocked infrastructure cells before starting a walk, and does not enter walking state for clicks already within the 5 px arrival radius. This fixes the prior mismatch where `GridNavigation.world_to_cell()` clamps off-map coordinates to an edge cell, causing an off-map click to send the representative toward an unrelated map edge. It also removes the one-frame false walking state for clicks directly on blocked infrastructure.

Asset/runtime preservation: no binary was rewritten. Existing imported `res://art/...` Texture2D resources, Sprite2D/AtlasTexture rendering, Y-sort and `_ground_foot()` collision remain unchanged. Immediately preceding exact head `0f25a4c07660c6e568fa9e39a212367fe3b5748f` had green fresh Clean runtime gameplay proof and green v0.164 exact-head wind proof, with artifacts tied to that SHA.

Gameplay source commit: `0e5f79161c3e3e1324727c7cc808e329c2c3a593`.

Proof status at this report write: source committed; this README commit advances the exact head, so prior screenshots are historical evidence only. The click-to-move repair is **not counted as runtime-integrated** until fresh exact-head Godot import, actual gameplay screenshot, and applicable CI complete on the report head.


## 2026-09-27 infrastructure Y-sort ground-anchor repair
Official Godot 4.7 contract rechecked before editing: SpriteFrames is the ordered animation-data resource for AnimatedSprite2D, and imported images are textures in Godot's asset pipeline. References: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html ; https://docs.godotengine.org/en/4.7/tutorials/assets_pipeline/importing_images.html .

Proven-history comparison: commit `9f3e8c2cb54b2a791310b7bfec6793080d7e29ac` remains the visually established player walk sequence; current `WALK_SOURCE_ORDER` remains explicit [1, 3, 5, 7] for every facing and was not altered.

Fresh baseline proof: exact head `1aea4eb97b5df8e89db7c46c09e111438608370a` passed Clean runtime gameplay proof and v0.164 exact-head wind proof. The clean artifact `hashrace-clean-runtime-gameplay` (80,310 bytes, sha256:f59689d999393b04269e4d3f4b53e03c77ccd0d3d4c769991310a1efb60efd8a) was downloaded and visually inspected. It visibly renders the C-01 container, solar equipment, wind turbine, transformer, ASIC equipment, player and four differentiated NPCs.

Source defect and repair: `Godot/scripts/world.gd::_build_infrastructure_sprites()` enabled parent Y-sort but positioned each non-wind Sprite2D at its fitted top-left corner; the wind Sprite2D likewise used its top-left render position. Godot Y-sort compares child Node2D positions, so infrastructure ordering was based on roof/top edges rather than ground contact. Commit `a76b935b8b06d882e6adc4651ea1cb1348896348` moves every infrastructure node's Y coordinate to the fitted visual bottom and uses Sprite2D.offset to draw the pixels upward without changing the rendered footprint. Wind receives the same bottom-anchor contract with its AtlasTexture source size. This preserves all validated binaries, preload paths, aspect-fit scale, placement, collision footprints and the wind shader while making player/building occlusion follow feet/ground contact.

Asset provenance/runtime path: unchanged imported binaries under `res://art/buildings/c01_mining_container.png`, `res://art/electrical/substation_transformer_rear.png`, `res://art/energy/solar_array_overview.png`, `res://art/energy/wind_turbine_directional_sheet.png`, and `res://art/machines/asic_air_s19j_directional.png`.

Proof status at report write: the source repair is committed, but this README update advances exact head again. Therefore the Y-sort repair is **not counted as runtime-integrated** until fresh exact-head Godot import, gameplay screenshot and applicable CI pass on the report head.


## Character foot-anchor Y-sort repair — 2026-09-27

- Gameplay commit: `b0dcb27ee9dd321cb2972d6396b1f7ca7d10e2ba`.
- Changed path/function: `Godot/scripts/world.gd`; `_build_player_sprite()` and `_build_npc_population()`, plus shared `CHARACTER_FOOT_DRAW_OFFSET`.
- Proven source geometry: `default_player_sprite_sheet.gd` pads every AtlasTexture frame to `FRAME_SIZE = 160x240` and declares the authored ground contact at `FOOT_ANCHOR = (80,232)`. With AnimatedSprite2D centered by default, the Node2D origin was therefore 112 source pixels above the feet. Infrastructure had already been corrected to sort at its ground line, leaving characters on a mismatched Y-sort origin.
- Repair: set AnimatedSprite2D drawing offset to `(0,-112)` for the player and all four campus NPCs. Navigation/patrol coordinates and Node2D positions remain unchanged and now represent the visible foot/ground contact used by Y-sort.
- Animation integrity: no SpriteFrames regions or order changed. The visually proven walk source order remains explicit `[1,3,5,7]` in every direction.
- Asset provenance/binary: no binary changed. Player source remains `res://art/characters/default_player_sheet.png`, expected 1536x1024, SHA-256 `2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211`, loaded through Godot's imported project resource path.
- Official Godot basis: AnimatedSprite2D documents `centered=true` by default and defines `offset` as the texture drawing offset: https://docs.godotengine.org/en/4.7/classes/class_animatedsprite2d.html . SpriteFrames is the animation frame library used by AnimatedSprite2D and preserves explicitly appended frame order: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html .
- Verification boundary: preceding head `4cc61db707ca094321e9a3dd666d98ff16912e6f` had fresh exact-head workflows queued when this defect was identified. This commit intentionally invalidates that pending proof. Do not count this repair as integrated and do not merge until a fresh checkout/import, gameplay render screenshot, and exact-head CI pass on the new report head.


## Transformer service-road clearance — 2026-09-27

- Gameplay commit: `32dcad014ab1f05a9bdfa03c7275bb9738ed0e27`.
- Evidence baseline: exact head `c81d0b7da6f55a03bef08bf48a898b2098b94770` passed Clean runtime gameplay proof run 184 and v0.164 exact-head wind proof run 221. The downloaded clean-runtime screenshot visibly showed the validated transformer overlapping the horizontal service road/player corridor.
- Changed path: `Godot/scripts/world.gd`, `CAMPUS.transformer`: `Rect2(890,520,120,108)` -> `Rect2(890,450,120,108)`. The footprint now ends at y=558, leaving 12 px before the service road begins at y=570.
- Asset integrity: no transformer binary, preload path, aspect-fit scale, Sprite2D ground-anchor/Y-sort code, or collision derivation changed. Runtime remains `res://art/electrical/substation_transformer_rear.png` through the imported project resource preload.
- Collision: `_ready()` still derives the navigation block from the same CAMPUS Rect2 via `_ground_foot(rect)`, so collision moves with the visible transformer instead of leaving an invisible road obstacle.
- Animation integrity: player/NPC SpriteFrames and explicit visually proven walk order `[1,3,5,7]` are unchanged.
- Official Godot basis: Rect2 position is the origin/top-left and end is position + size: https://docs.godotengine.org/en/4.7/classes/class_rect2.html . Sprite2D offset remains the texture drawing offset used by the existing ground-anchor implementation: https://docs.godotengine.org/en/4.7/classes/class_sprite2d.html .
- Verification boundary: this placement commit requires a new exact-head checkout/import/gameplay screenshot and green CI. The preceding screenshot proves the defect, not this repair.


## 2026-09-27 solar-to-transformer grouping candidate
Pre-change implementation research revalidated Godot 4.7 SpriteFrames/AnimatedSprite2D behavior and compared current walking against successful commit `9f3e8c2cb54b2a791310b7bfec6793080d7e29ac`. The explicit visually proven walk source order remains `1,3,5,7`; this run does not infer or alter walking frames.

One-asset source change: `Godot/scripts/world.gd::CAMPUS` moves only `solar` from `Rect2(1060, 300, 176, 176)` to `Rect2(1040, 350, 176, 176)` to reduce isolated empty grass and strengthen generation-to-transformer visual grouping. Runtime asset remains imported `res://art/energy/solar_array_overview.png` through `SOLAR_ART = preload(...)`. Existing `Sprite2D`, `_aspect_fit_rect()`, ground-contact Y-sort anchor, `_ground_foot()` collision block, dimensions and source binary are unchanged. Candidate commit: `cd95d99fe079bd0959eae6844c4bdf555b942638`.

Official references: https://docs.godotengine.org/en/4.7/classes/class_spriteframes.html and https://docs.godotengine.org/en/4.7/classes/class_animatedsprite2d.html . Proof status at report write: source committed, but fresh exact-head gameplay screenshot and CI are pending; therefore this item is not yet counted against the 34-point inspection.
