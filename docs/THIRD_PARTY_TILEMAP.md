# Third-party tilemap code used by Hash Race

Hash Race uses small, attributed code adaptations from open-source Game Boy development projects to improve the live Godot map renderer.

## GB Studio

Upstream: https://github.com/chrismaltby/gb-studio

License: MIT

Copyright (c) 2019-2026 Chris Maltby.

`Godot/scripts/gbstudio_paint.gd` ports the structure of GB Studio's generic `paint` and Bresenham-style `paintLine` helpers from `src/shared/lib/helpers/paint.ts` into GDScript. Hash Race uses those helpers to paint grid-aligned roads, lots and terrain into the live company world.

The MIT permission notice from GB Studio applies to the adapted portions. The upstream MIT license permits use, modification, distribution and sublicensing provided the copyright and permission notice are retained.

## Tilemap Studio

Upstream: https://github.com/Rangi42/tilemap-studio

License: GNU LGPL-3.0

`Godot/scripts/tilemap_studio_ops.gd` is an isolated GDScript adaptation of the queue-based `flood_fill`, `substitute_tile`, and `swap_tiles` tilemap operations in Tilemap Studio's `src/main-window.cpp`. The adapted file keeps its LGPL-3.0 notice and remains independently identifiable from the rest of Hash Race.

The live map uses these operations to convert temporary road paint into final road tiles and to flood-fill connected terrain regions. Hash Race's own art, business simulation, company data, dialogue, map layout and game logic are separate original work.

The complete Tilemap Studio LGPL-3.0 license is available in the upstream repository at `LICENSE.md`: https://github.com/Rangi42/tilemap-studio/blob/master/LICENSE.md

## Design references only

The broader `gbdev/awesome-gbdev` resource list, µCity, and Meowa HD2D examples are used as design/architecture references. Their copyrighted art and commercial-game assets are not copied into Hash Race.
