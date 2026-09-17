# Hash Race 2D Visual Reference Stack

Hash Race v0.030 improves the Godot pixel overworld by adapting one small rendering idea from each of nine public GitHub projects. The game does **not** bundle these engines or runtimes. The techniques are reimplemented in GDScript so the existing Godot simulation, controls, economics, and test rules remain intact.

| Reference | License signal checked on GitHub | Hash Race adaptation |
| --- | --- | --- |
| `pixijs/pixijs` | MIT | Whole-pixel coordinate snapping keeps representatives and facilities crisp. |
| `GraphiteEditor/Graphite` | Apache-2.0 | Deterministic procedural tile variation breaks up repeated checker patterns. |
| `jonobr1/two.js` | MIT | Stroke width is compensated against camera zoom so borders remain readable. |
| `ecomfe/zrender` | BSD-3-Clause | Odd-width road and prop lines are shifted to crisp half-pixel boundaries. |
| `galacean/engine` | MIT | Explicit linear interpolation drives visible light and pose transitions. |
| `EsotericSoftware/spine-runtimes` | Custom / NOASSERTION | Concept only: normalized animation mix time is independently reimplemented; no Spine runtime source is copied. |
| `simple2d/simple2d` | MIT | Four-corner colored quads add gradient-like shading to solar panels and facility roofs. |
| `JuliaGraphics/Luxor.jl` | GitHub metadata: NOASSERTION | Concept only: regular polygon geometry is independently implemented for industrial fan housings. |
| `audulus/vger-rs` | MIT | Layered fill/stroke rectangles add stronger facility, sign, and player outlines. |

## Visible result

The overworld now has less repetitive terrain, sharper roads, richer facility roofs, double-outline signs, animated octagonal cooling fans, better solar-panel shading, and pixel-snapped representatives with a subtle mixed step/breathing pose. The changes are intentionally visual and do not alter mining economics or the 0-100 company systems.

## Code locations

- `Godot/scripts/visual_reference_stack.gd` contains the nine small reusable techniques and a self-check.
- `Godot/scripts/world_gbc.gd` applies them to terrain, roads, props, buildings, and representatives.
- `Godot/scripts/validate_overworld.gd` requires all nine references to initialize successfully.

The GitHub Actions smoke test still boots the real scene, runs the overworld contract, renders an actual frame, rejects script errors, and uploads the rendered visual proof.
