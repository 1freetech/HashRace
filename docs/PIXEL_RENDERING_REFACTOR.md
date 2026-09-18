# Hash Race Pixel Rendering Refactor

## Objective

Keep the detailed procedural Hash Race world crisp without turning the entire game into a blurry low-resolution screenshot. The live renderer should prefer source-level pixel construction, whole-pixel camera/character placement, nearest filtering and integer-friendly scaling. LCD simulation is a finishing effect, not a substitute for good source art.

## Findings from the supplied references

### SameBoy

The useful transferable rendering idea is sampling the **center of a logical texel**, not an arbitrary UV position. Its LCD filters also separate source sampling from display-cell simulation. Hash Race adopts those concepts in independent Godot code rather than importing emulator runtime code.

### slang-shaders

The useful principle is that fractional scaling causes uneven pixel widths and shimmer. Hash Race therefore keeps a 360x225 post-process profile for the 1440x900 viewport because it produces an exact 4x scale. The supplied 160x144 profile remains useful only as an intentional handheld mode with aspect handling/letterboxing.

### pokered

The repository does not provide a top-level license file, so its source is treated as concept/reference only. Useful architectural ideas are fixed logical tile/block IDs, explicit passability/collision data, small palette families, sprite asset reuse and updating only changed map regions. Hash Race already follows much of this through `art_cells`, tile IDs, grid navigation and procedural palette families; future performance work should cache static terrain and invalidate only changed chunks.

## Bottlenecks / correctness issues found

1. The supplied Godot shader declares `screen_texture` but samples `SCREEN_TEXTURE`. Godot 4 screen-reading shaders should sample the declared `hint_screen_texture` uniform.
2. `smoothstep(1.0, 1.0 - gap, x)` reverses its edge arguments. Results are undefined when `edge0 >= edge1`.
3. Sampling the unsnapped screen UV does not truly pixelate the scene. The sample must be moved to the center of a logical pixel cell.
4. For Hash Race, 160x144 is not an aspect-compatible default for 1440x900. 360x225 maps exactly 4x and preserves square logical pixels.
5. Applying a complex multi-neighbor LCD shader to every pixel is unnecessary for the normal game view. The refactored post shader keeps the sampling path minimal and only takes the second snapped lookup when source snapping is enabled.
6. The old building palette quantizer used `steps` as the denominator, which can produce `steps + 1` distinct endpoint-inclusive levels. The refactor uses `steps - 1` for exactly N quantization levels.

## Recommended live pipeline

1. Author/redraw buildings on a hard source grid. Use `building_pixelate.gdshader` only as a fallback for legacy high-resolution sprites.
2. Keep `textures/canvas_textures/default_texture_filter=0`, pixel transform snapping and viewport stretch enabled.
3. Keep characters/buildings snapped to whole pixels and sort by ground-contact Y.
4. Keep the normal Hash Race view at its current detailed procedural resolution.
5. Add `gbc_lcd_post.gdshader` only as an optional display profile. Default it to 360x225 for a strong 4x pixel effect; use 160x144 only for a deliberately framed Game Boy-style mode.
6. For the next performance pass, cache static terrain/roads/lots into chunk textures or retained TileMap layers and redraw only animated water, entities, selection feedback and modified construction chunks.

## Suggested display presets

- **Hash Race Crisp:** `target_resolution = 360x225`, grid 0.12-0.20, gap 0.06-0.10, desaturation 0.05-0.12.
- **Handheld GBC:** `target_resolution = 160x144`, grid 0.18-0.28, gap 0.08-0.14, desaturation 0.10-0.18, with aspect-preserving letterbox.
- **No LCD:** skip the post shader entirely; retain nearest filtering and source-level pixel art.

## Source-use boundary

SameBoy's Expat-licensed shader architecture informed the texel-center sampling approach. The supplied slang shader collection contains mixed per-file licenses, so only general scaling/display concepts were used. Pokémon Red source was used only to identify general rendering architecture because the supplied repository has no top-level license file.
