# Hash Race

Hash Race is a 2D Bitcoin mining strategy simulation built with Godot. Players build and operate a mining company by deploying ASIC infrastructure, securing electrical capacity, managing cooling and efficiency, expanding facilities, managing BTC and cash, researching technology, negotiating partnerships, and competing with other mining companies.

## Gameplay

The playable world is an industrial Bitcoin-mining campus. Its visual hierarchy is generation to transformer/distribution to mining load, with a Command Center, sparse service roads, deliberate negative space, and readable infrastructure footprints. Facilities scale from MW modules toward compressed large-campus representations so growth remains understandable.

Core systems include ASIC deployment, air/hydro/immersion cooling, energy generation and storage, electrical distribution, company finance, BTC treasury management, research, partnerships, negotiation, character customization, navigation, and an explorable top-down world.

## Source architecture

`Godot/scenes/world.tscn` loads `Godot/scripts/world.gd`, the stable runtime entry point. Runtime source uses purpose-based names rather than release-number inheritance. Git commits and GitHub Releases carry release history.

Reusable systems such as `grid_navigation.gd` and `infrastructure_inventory.gd` remain independent modules. Rendering and simulation should stay separated where practical so changing an asset does not require creating another world layer.

## Game artwork

Authored PNG, JPG and SVG files under `Godot/art/` are game-source assets. Validated artwork is preserved during source refactors. Current runtime artwork includes the player sheet, mining container, ASIC artwork, transformer, solar equipment, wind equipment, terrain and road assets.

An asset counts as integrated only when a fresh run of the actual game visibly renders it. Source images, concept art, imports, or code references alone are not proof.

## Visual rules

Campus composition comes before decorative detail. Infrastructure must be grounded, correctly scaled, inside world boundaries, and separated from characters, labels and unrelated objects. Roads are sparse industrial service roads. The zoomed-out silhouette should read as a mining and energy campus without relying on labels.

## Development and validation

Hash Race targets Godot 4.7.2. Open the project under `Godot/`.

Gameplay or visual changes require a fresh Godot import, actual runtime execution, fresh screenshot proof from the exact source head, and passing CI. Tests should validate current behavior and assets rather than historical release identifiers.

## Releases

Downloads, release numbers and release notes are maintained on the GitHub Releases page:

https://github.com/1freetech/HashRace/releases
