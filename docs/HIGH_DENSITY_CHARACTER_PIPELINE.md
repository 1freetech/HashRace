# Hash Race High-Density Character Pipeline

Hash Race v0.087 uses two compatible character paths.

1. **Live procedural path.** `world_v073.gd` keeps the proven directional silhouette, walk/run/mining/victory poses, and runtime customization. `world_v087.gd` adds a one-pixel finishing pass for hair strands, eye catchlights, headset hardware, visor scanlines, armor seams/rivets, glove knuckles, and boot tread. This keeps the game asset-light while making close-up characters read more like authored 2D sprites.
2. **Production sprite-sheet path.** `character_sprite_rig.gd` is ready for transparent high-detail atlases. Body, hair, visor, and armor layers share one frame grid and animate in lockstep. `character_palette_swap.gdshader` recolors four three-step shading ramps, so one master sheet can support many skin, hair, suit, and accent colors without a separate sheet for every variant.

## Recommended source art contract

- Frame size: **96x128** or **128x128** per character frame.
- One-pixel hard outline with no antialiasing.
- Three or more values per material: shadow, midtone, highlight.
- Keep feet on the same baseline in every frame.
- Required pose rows: idle down/up/side, walk down/up/side, run down/up/side, mining, victory.
- Left-facing side animation is mirrored from the right-facing side row unless a unique left row is needed.
- Import PNGs with nearest filtering, mipmaps off, repeat disabled, and lossless/uncompressed texture data.

## Palette authoring

The palette shader reserves four three-color key ramps: skin, hair, suit, and accent. Paint the base sheet with those exact key colors, then call `HashRaceCharacterSpriteRig.set_palette()` at runtime. Replacing complete ramps preserves shading and material definition; replacing only one flat color does not.

## Uploaded reference-source use

The uploaded sprite-sheet creator demonstrates useful workflow ideas such as fixed animation grids, frame extraction, preview FPS, per-sprite scale, and mirrored side movement. The uploaded Universal LPC generator demonstrates layered compositing, palette variants, caching, and a single source sheet feeding many recolors. Hash Race implements those ideas independently in Godot; no GPL LPC source code and no unlicensed sprite-creator source code is copied into the repository.
