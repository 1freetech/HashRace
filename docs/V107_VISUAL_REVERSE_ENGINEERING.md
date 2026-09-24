# v0.107 visual reverse-engineering notes

Hash Race v0.107 converts the supplied top-down RPG references into original Godot rendering rules rather than copying commercial art.

## Pixel-to-code findings

1. **Hierarchy first.** The readable scenes use one dominant structure per parcel, smaller secondary buildings, and broad empty terrain around both. Hash Race now scales the player HQ to 1.18x, rival HQs to 1.08x, service buildings to 1.12x, and partner offices down to 0.88x.
2. **Ground contact sells depth.** Buildings now cast three hard-pixel shadow layers toward the lower-right from one fixed top-left light source. This gives mass without blurry vector effects.
3. **Paths are not perfect rectangles.** Adjacency-aware grass bites, soil seams, and sparse edge pixels break the square silhouette of walkway tiles while retaining the existing collision/navigation grid.
4. **Terrain boundaries need layers.** Water uses stepped bank bands, roads gain compact shoulders, and paths blend into grass through pixel-sized transition details.
5. **Props support landmarks instead of competing with them.** Mining campuses keep one terrain-safe tree; only the player campus gets one compact site marker. Repeated decorative equipment stays removed unless it represents owned/deployed infrastructure.
6. **Nearest-neighbor and base-Y ordering stay mandatory.** Existing 16x16 source textures are still enlarged to 48px world tiles with nearest-neighbor filtering, and the inherited v0.080 base-Y painter order continues to place lower feet/building bases in front.

## Open-source references

The implementation follows general, independently reimplemented ideas observed in SuperTux (grid snapping/editor discipline) plus Hash Race's existing Pixelorama/PokeSharp-inspired pixel pipeline. GPL or proprietary art/code is not copied into Hash Race. The commercial Pokémon/Pokémon Vortex screenshots are treated only as visual targets for spacing, silhouette, palette separation, and terrain readability.
