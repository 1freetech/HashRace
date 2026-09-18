# Hash Race Gen-2 Microtile Reference

Hash Race v0.082 uses the uploaded Pokemon-gen-2-style-tilemap repository as an MIT-licensed structural reference. The project is credited to Niko in its LICENSE file. Hash Race does not bundle or copy Pokemon artwork.

## Useful ideas adopted

- 8x8 source tiles. The reference repository treats 8x8 pixels as the basic tile unit and composes people, trees, buildings and furniture from multiple tiles. Hash Race's existing 48x48 terrain cell divides exactly into a 6x6 grid of 8x8 microtiles, so the concept fits without changing world scale or collision.
- Named tile catalog. The reference compiler reads named tiles and emits atlas coordinates. Hash Race mirrors that discipline with named procedural motifs such as grass_flat, path_gravel, water_wave, lot_panel and building_cladding in gen2_microtile_rules.gd.
- Deterministic variants. Instead of arbitrary vector noise, terrain details are selected from repeatable 8x8-aligned motif slots. This creates a more authored, cartridge-era appearance while preserving procedural generation.
- Composite buildings. Facility facade detail is now assembled from repeated 8px cladding modules. Large buildings therefore read as combinations of smaller pixel components rather than smooth vector rectangles.
- Edge-aware terrain. Road and water cells examine their north/east/south/west neighbors and draw boundary modules only where the material ends. This is an autotile-style rule rather than unconditional decoration.
- Missing-tile discipline. The reference compiler uses a bright fallback tile for missing art. Hash Race retains the same philosophy through explicit motif contracts/debug methods instead of silently accepting invalid tile definitions.

## Performance choice

The reference repository's visual language does not mean drawing all 36 microtiles inside every 48px Hash Race cell. That would multiply CanvasItem draw calls dramatically. v0.082 uses the 8px grid as a placement discipline, but draws only selected motifs and exposed boundaries. Static terrain can later be cached into retained chunks without changing the logical microtile rules.

## Live files

- Godot/scripts/gen2_microtile_rules.gd — 8px tile constants, named motifs, deterministic slots and neighbor masks.
- Godot/scripts/world_v082.gd — live terrain/building integration layered on top of v0.080.
- Godot/scenes/world.tscn — boots the v0.082 renderer.

## Source boundary

The uploaded reference is MIT licensed. Hash Race adapts its general compiler/tile-composition ideas in independent Godot code and does not redistribute Pokemon sprites, maps, names, or other copyrighted game assets.
