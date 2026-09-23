# Asset integration sequence

This ledger prevents the three approved infrastructure integrations from being repeated or skipped. An asset is complete only after its exact PR head is green and its fresh Godot gameplay render has been independently inspected.

| Order | Asset | Status | Asset SHA-256 | Live layer | PR / evidence |
|---|---|---|---|---|---|
| 1 | Solar power | VERIFIED, READY TO MERGE | `06b542233279854dea18a10cf10e16b32772057add0bec8f896fc2a282ab407f` | `world_v161.gd` | PR #88; exact head `a427445fc94e83378efe813510f5b4c45fdd14ed` passed Actions run 35847296962. Fresh `hashrace-v161-live-solar-proof` was independently inspected: solar is visible on grass with road/core-object clearance and no character overlap. |
| 2 | Diesel generator | PENDING | `7d2da59dd0b0313407424e432dad902193d67352a8cfcd7dce688b6e45e03f09` | next sequential live layer | Must use only approved `diesel_generator.png`; do not start until solar is merged/verified. |
| 3 | Hydrogen power | PENDING | `9589c18f93becf6076ad33d72ecfb6bbf50e52ed2067c7f8b0cfb90503128350` | next sequential live layer | Must use only approved `hydrogen_fuel_cell.png`; do not start until diesel is merged/verified. |

## Solar evidence

- Live routing: `Godot/scenes/world.tscn` -> `Godot/scripts/world_v161.gd` -> `HashRaceSolarOverviewSprite` -> `Godot/art/energy/solar_array_overview.png`.
- Renderer override replaces only `solar_array`; every other nonempty energy renderer delegates to `super._v114_draw_energy_source(...)`.
- Ground contact is registered with `grid_nav.block_rect(foot)` and draw order is selected against the player's foot Y.
- Capacity footprint contract remains 2x2 / 4x4 / 6x6 / 8x8.
- CI run: https://github.com/1freetech/HashRace/actions/runs/35847296962
- Runtime proof artifact: `hashrace-v161-live-solar-proof` / `visual-proof/v161-solar-overview.png`.
