# Hash Race Pixel-Art Building Pipeline

Hash Race uses a procedural pixel world, so building art must obey the same source-pixel rules as characters and terrain instead of relying on smooth vector-style gradients.

## Live rendering contract

- Godot canvas textures use nearest-neighbor filtering and disabled repeat.
- 2D transforms and vertices snap to pixels.
- The live world uses `viewport` stretch so the entire rendered frame scales as one image.
- Character and building draw positions are snapped to integer pixels.
- v0.080 facilities use a 4 px construction grid, hard palette steps, rectangular highlights and shadows, and no interpolated roof gradient.
- The camera disables position smoothing in the live overworld and follows the representative on whole pixels.
- Procedural entities are painter-sorted by their ground-contact Y value so the player/NPC can pass visually in front of or behind buildings.

## Imported building sprites

Preferred source art should be redrawn to the same density as the game before import:

1. Downscale or author directly on a deliberate pixel grid.
2. Use the same restrained dark-metal, terrain and accent palette families as the live world.
3. Replace soft gradients with hard highlight/shadow bands and optional dithering.
4. Keep outlines consistent with the character silhouette.
5. Put the sprite origin at the building ground-contact point, not its visual center.
6. Keep mipmaps off and use nearest-neighbor filtering.

If a legacy high-resolution sprite cannot be redrawn immediately, apply
`res://shaders/building_pixelate.gdshader` as a temporary fallback. It snaps UV
sampling to blocks and quantizes colors, but it is intentionally secondary to
proper source art.
