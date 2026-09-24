# RPG and strategy code references

Hash Race uses a mixture of directly reusable open-source code and independently implemented design ideas. This document records the distinction.

## Python-Monsters — direct code adaptation

Upstream: https://github.com/clear-code-projects/Python-Monsters

License: CC0 for the code, as stated in the upstream README.

Hash Race adapts the direction-state and axis-separated collision structure from `code (finish)/entities.py` into `Godot/scripts/rpg_movement.gd`. The resulting GDScript helper is used by the live company representative for facing direction, idle/walk state, target-facing and collision-safe movement against Hash Race's navigation grid.

The original Python-Monsters artwork is not included. Hash Race uses original company, representative and world visuals.

## LawlessPlay Gridbased Pathfinding Tutorial — architecture reference

Upstream: https://github.com/LawlessPlay/Gridbased-Pathfinding-Tutorial

No repository software license was found during integration, so Hash Race does not copy its C# source. The general ideas of keeping a logical navigation grid separate from the visual map, scanning reachable cells and constraining path searches to a reachable set were implemented independently in `Godot/scripts/grid_navigation.gd`.

## Unity Turn-Based Strategy Game tutorial — architecture reference

Upstream: https://github.com/tutorial-work/Unity-Turn-Based-Strategy-Game

No repository software license was found during integration, so Hash Race does not copy its C# source. The project is used only as a reference for separating selected actions, busy/input state and turn progression. Hash Race keeps its own quarterly company-turn model rather than importing combat/unit mechanics.

## Battle for Wesnoth — architecture reference

Upstream: https://github.com/wesnoth/wesnoth

License: GPL-2.0 or later for the upstream project.

No Wesnoth source code is copied into Hash Race. General strategy-game ideas such as readable terrain, movement constraints, side/turn state and scenario/event presentation are used only as design references and are implemented independently for a Bitcoin-mining business simulation.
