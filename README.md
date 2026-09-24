# Hash Race

Hash Race is a 2D Bitcoin mining strategy simulation built with Godot.

The game world is an industrial mining campus organized around mining containers, ASIC hardware, electrical distribution, energy generation, semiconductor infrastructure, service roads and an explorable player character.

## Source

The runtime begins at `Godot/scenes/world.tscn` and `Godot/scripts/world.gd`. Source modules use stable feature names. Release history and release numbers are kept on GitHub Releases rather than in runtime architecture.

## Artwork

Artwork under `Godot/art/` is game-source artwork. Existing image binaries are preserved during architecture work. An image counts as integrated only when the actual runtime renders it in fresh screenshot proof.

## Visual rules

Infrastructure must be grounded, correctly scaled, inside world boundaries and separated from the player and other infrastructure. Roads remain sparse service roads. The campus should read as mining and energy infrastructure without relying on labels.

## Validation

Gameplay changes require a fresh Godot import, actual runtime execution, fresh screenshot proof from the exact source head and passing CI.

## Releases

Downloads and release notes are maintained on the GitHub Releases page:
https://github.com/1freetech/HashRace/releases
